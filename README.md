# Olist E-commerce Analytics Warehouse

A Snowflake warehouse built with Python, SQL and dbt using historical
Olist e-commerce CSV data.

## Architecture

CSV files → Python PUT → Snowflake internal stage → RAW tables
→ dbt staging → CORE dimensions and facts → reporting marts

Power BI reporting is planned; it is not yet implemented.

## Business questions

- How does delivered merchandise value change by purchase month and state?
- Which products and sellers generate the most merchandise value?
- What percentage of measurable delivered orders arrive late?
- How many customers place at least two delivered orders?

## Models

- Five staging views: customers, orders, order items, products and sellers.
- Four dimensions: customers, products, sellers and dates.
- Two facts: orders and order items.
- Seven reporting tables, including customer-level purchase summaries.

Order fact grain: order_id.
Item fact grain: (order_id, order_item_id).

Merchandise value, freight and total item value are separate.
Delivery metrics are calculated at order grain.
Repeat customers are identified using customer_unique_id.

## Verified execution

- 18 project models built successfully.
- 82 data tests passed.
- Simulated new orders and status updates reached the facts.
- Fact reruns preserved contents without duplicate keys.
- An invalid status blocked the order fact and downstream reporting.
- A corrected later batch restored a passing build.
- Incremental filtering skipped unchanged records.
- A later status update changed exactly one order.
- Python ingestion loaded a file and recorded its checksum in a ledger.

See evidence/ for saved dbt execution artifacts.
All historical updates are simulated changes, not live CDC.

## Security

- OLIST_LOAD: stage access and SELECT/INSERT on RAW.
- OLIST_TRANSFORM: read RAW and build staging, CORE and MARTS.
- OLIST_REPORT: read MARTS only.

Private keys and local connection profiles are excluded from Git.

## Local setup

1. Create a Python virtual environment.
2. Install requirements.txt.
3. Execute sql/setup scripts in numerical order using suitable roles.
4. Assign the roles to your Snowflake user.
5. Configure key-pair authentication.
6. Copy profiles.example.yml to profiles.yml.
7. Set the environment variables referenced by that profile.
8. Upload and load the source CSVs, or use scripts/ingest_csv.py.
9. Run dbt build.

From this repository root, with the environment activated:

    python -m pip install -r requirements.txt
    dbt debug --profiles-dir .
    dbt build --select path:models/staging path:models/core path:models/marts --profiles-dir .

Use dbt Core from the virtual environment if another dbt executable
is installed on your machine.

## Python ingestion

Required environment variables:

- SNOWFLAKE_ACCOUNT
- SNOWFLAKE_USER
- SNOWFLAKE_PRIVATE_KEY_PATH
- DBT_ENV_SECRET_KEY_PASSPHRASE

Example:

    python scripts/ingest_csv.py orders path/to/orders.csv simulated_008 8

Run one ingestion process at a time.
Each transaction covers one file and its ledger entry.
Unchanged ledger-backed replays skip; conflicting identities fail.
Earlier manual loads are not automatically adopted into the ledger.

## Validation

GitHub Actions is configured to check dependencies, Python syntax and
dbt parsing without Snowflake credentials.

Warehouse data tests run through dbt build against Snowflake.
A successful parse alone does not verify SQL execution or data quality.

## Limitations and remaining work

- Concurrent ingestion is not supported.
- Multi-file batches are not committed atomically.
- Deletes and business-key changes are not implemented.
- Corrections require higher batch sequences.
- Staging still reads RAW to select the latest records.
- Query-performance measurements are pending.
- Power BI and scheduled execution are pending.

See sql/demo/README.md for the simulated failure and recovery sequence.
