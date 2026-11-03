import os
from pathlib import Path
import snowflake.connector

def connect_loader():
    connection = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        private_key_file=str(
            Path(os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"]).expanduser()
        ),
        private_key_file_pwd=os.environ[
            "DBT_ENV_SECRET_KEY_PASSPHRASE"
        ],
        role="OLIST_LOAD",
        warehouse="OLIST_WH",
        database="OLIST",
        schema="RAW",
        session_parameters={"QUERY_TAG": "olist_python_ingestion"},
    )
    with connection.cursor() as cursor:
        cursor.execute("USE SECONDARY ROLES NONE")
    return connection

if __name__ == "__main__":
    with connect_loader() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT CURRENT_ROLE(), COUNT(*) "
                "FROM OLIST.RAW.INGESTION_FILES"
            )
            role, count = cursor.fetchone()
            print("Connected role:", role)
            print("Ledger entries:", count)
