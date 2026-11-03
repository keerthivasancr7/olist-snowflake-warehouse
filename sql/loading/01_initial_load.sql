-- Initial historical CSV load.

-- Upload files to initial/<table>/ before execution.

-- Run dbt build after all five loads complete.

USE ROLE OLIST_LOAD;

USE SECONDARY ROLES NONE;

USE WAREHOUSE OLIST_WH;


COPY INTO OLIST.RAW.CUSTOMERS (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
)
FROM (
    SELECT
        $1, $2, $3, $4, $5,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        'initial_001',
        1
    FROM @OLIST.RAW.OLIST_STAGE/initial/customers/
)
FILES = ('olist_customers_dataset.csv')
FILE_FORMAT = (
    FORMAT_NAME = 'OLIST.RAW.OLIST_CSV_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';



COPY INTO OLIST.RAW.ORDERS (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7, $8,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        'initial_001',
        1
    FROM @OLIST.RAW.OLIST_STAGE/initial/orders/
)
FILES = ('olist_orders_dataset.csv')
FILE_FORMAT = (
    FORMAT_NAME = 'OLIST.RAW.OLIST_CSV_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';



COPY INTO OLIST.RAW.ORDER_ITEMS (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        'initial_001',
        1
    FROM @OLIST.RAW.OLIST_STAGE/initial/order_items/
)
FILES = ('olist_order_items_dataset.csv')
FILE_FORMAT = (
    FORMAT_NAME = 'OLIST.RAW.OLIST_CSV_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';



COPY INTO OLIST.RAW.PRODUCTS (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7, $8, $9,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        'initial_001',
        1
    FROM @OLIST.RAW.OLIST_STAGE/initial/products/
)
FILES = ('olist_products_dataset.csv')
FILE_FORMAT = (
    FORMAT_NAME = 'OLIST.RAW.OLIST_CSV_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';



COPY INTO OLIST.RAW.SELLERS (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
)
FROM (
    SELECT
        $1, $2, $3, $4,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        'initial_001',
        1
    FROM @OLIST.RAW.OLIST_STAGE/initial/sellers/
)
FILES = ('olist_sellers_dataset.csv')
FILE_FORMAT = (
    FORMAT_NAME = 'OLIST.RAW.OLIST_CSV_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';
