import argparse
import csv
import hashlib
import io
import re
import tempfile
from pathlib import Path

from snowflake_connection import connect_loader

TABLES = {"customers", "orders", "order_items", "products", "sellers"}

def ingest(table, filename, batch_id, batch_seq, validate_only=False):
    # Run one ingestion process at a time.
    # This transaction covers one file, not a multi-file batch.
    if table not in TABLES:
        raise ValueError("Unsupported source table")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", batch_id):
        raise ValueError("Batch ID must contain letters, digits, _ or -")
    if batch_seq < 1:
        raise ValueError("Batch sequence must be positive")

    path = Path(filename).resolve()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", path.name):
        raise ValueError("Use a simple CSV filename")

    content = path.read_bytes()
    checksum = hashlib.sha256(content).hexdigest()

    with connect_loader() as connection:
        with connection.cursor() as cursor:
            cursor.execute(f"DESCRIBE TABLE OLIST.RAW.{table}")
            all_columns = [row[0].lower() for row in cursor.fetchall()]
            columns = all_columns[:all_columns.index("ingested_at")]

            reader = csv.reader(
                io.StringIO(content.decode("utf-8-sig"), newline="")
            )
            if next(reader, None) != columns:
                raise ValueError("CSV headers do not match the RAW table")

            expected_rows = 0
            for line, row in enumerate(reader, start=2):
                if len(row) != len(columns):
                    raise ValueError(f"Wrong field count on CSV record {line}")
                expected_rows += 1
            if expected_rows == 0:
                raise ValueError("CSV contains no records")

            print("Validated records:", expected_rows)
            print("SHA256:", checksum)
            if validate_only:
                print("Validation only: no upload or load performed")
                return

            cursor.execute(
                """SELECT batch_id, batch_seq, source_filename,
                          file_sha256, rows_loaded
                   FROM OLIST.RAW.INGESTION_FILES
                   WHERE source_table = %s
                     AND (batch_id = %s OR batch_seq = %s)""",
                (table, batch_id, batch_seq),
            )
            existing = cursor.fetchall()
            expected = (
                batch_id, batch_seq, path.name, checksum, expected_rows
            )
            if existing:
                if existing == [expected]:
                    print("Already loaded: unchanged file skipped")
                    return
                raise ValueError("Batch identity already used differently")

            # Do not adopt or replay earlier manual loads through this ledger.
            cursor.execute(
                f"""SELECT COUNT(*) FROM OLIST.RAW.{table}
                    WHERE batch_id = %s OR batch_seq = %s""",
                (batch_id, batch_seq),
            )
            if cursor.fetchone()[0]:
                raise ValueError("Batch identity exists in RAW without ledger")

            cursor.execute(f"SELECT MAX(batch_seq) FROM OLIST.RAW.{table}")
            latest = cursor.fetchone()[0]
            if latest is not None and batch_seq <= latest:
                raise ValueError("Use a sequence higher than existing RAW data")

            stage = (
                f"@OLIST.RAW.OLIST_STAGE/python/"
                f"{batch_id}/{table}/{checksum}/"
            )

            # Upload an immutable copy of the exact bytes validated above.
            with tempfile.TemporaryDirectory(prefix="olist_ingest_") as temp:
                upload = Path(temp) / path.name
                upload.write_bytes(content)
                if "'" in str(upload):
                    raise ValueError("Unsupported quote in temporary path")

                cursor.execute(
                    f"PUT 'file://{upload}' {stage} "
                    "AUTO_COMPRESS=FALSE OVERWRITE=FALSE"
                )
                put_columns = [item[0].lower() for item in cursor.description]
                put_results = [
                    dict(zip(put_columns, row))
                    for row in cursor.fetchall()
                ]
                if not put_results or any(
                    row["status"] not in ("UPLOADED", "SKIPPED")
                    for row in put_results
                ):
                    raise RuntimeError("Stage upload failed")

            target_columns = columns + [
                "ingested_at", "source_filename", "source_row_number",
                "batch_id", "batch_seq",
            ]
            fields = ", ".join(
                f"${number}" for number in range(1, len(columns) + 1)
            )

            cursor.execute("BEGIN")
            try:
                cursor.execute(
                    f"""COPY INTO OLIST.RAW.{table}
                        ({", ".join(target_columns)})
                        FROM (
                            SELECT {fields},
                                CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
                                METADATA$FILENAME,
                                METADATA$FILE_ROW_NUMBER,
                                '{batch_id}', {batch_seq}
                            FROM {stage}
                        )
                        FILES = ('{path.name}')
                        FILE_FORMAT = (
                            FORMAT_NAME = 'OLIST.RAW.OLIST_CSV_FORMAT'
                        )
                        ON_ERROR = 'ABORT_STATEMENT'
                        FORCE = TRUE"""
                )
                result_columns = [
                    item[0].lower() for item in cursor.description
                ]
                results = [
                    dict(zip(result_columns, row))
                    for row in cursor.fetchall()
                ]
                loaded = sum(int(row["rows_loaded"]) for row in results)
                if loaded != expected_rows:
                    raise RuntimeError("Loaded row count does not match CSV")

                cursor.execute(
                    """INSERT INTO OLIST.RAW.INGESTION_FILES
                       (batch_id, batch_seq, source_table, source_filename,
                        file_sha256, rows_loaded)
                       VALUES (%s, %s, %s, %s, %s, %s)""",
                    (
                        batch_id, batch_seq, table, path.name,
                        checksum, loaded,
                    ),
                )
                cursor.execute("COMMIT")
                print("Committed RAW records:", loaded)
                print("Committed ledger entries: 1")
            except Exception:
                cursor.execute("ROLLBACK")
                raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("table", choices=sorted(TABLES))
    parser.add_argument("file")
    parser.add_argument("batch_id")
    parser.add_argument("batch_seq", type=int)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    ingest(
        args.table, args.file, args.batch_id,
        args.batch_seq, args.validate_only,
    )
