-- Run after foundation, RAW tables and role grants.
USE ROLE SYSADMIN;

CREATE TABLE IF NOT EXISTS OLIST.RAW.INGESTION_FILES (
    batch_id        VARCHAR NOT NULL,
    batch_seq       NUMBER NOT NULL,
    source_table    VARCHAR NOT NULL,
    source_filename VARCHAR NOT NULL,
    file_sha256     VARCHAR NOT NULL,
    rows_loaded     NUMBER NOT NULL,
    loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Future-table grants in 03_roles.sql provide access.
-- Batch identity checks are enforced by the serial Python loader.
-- This table does not enforce uniqueness for concurrent writers.
