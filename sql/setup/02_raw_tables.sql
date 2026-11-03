USE ROLE SYSADMIN;

CREATE TABLE IF NOT EXISTS OLIST.RAW.CUSTOMERS (
    customer_id              VARCHAR,
    customer_unique_id       VARCHAR,
    customer_zip_code_prefix VARCHAR,
    customer_city            VARCHAR,
    customer_state           VARCHAR,
    ingested_at              TIMESTAMP_NTZ,
    source_filename          VARCHAR,
    source_row_number        NUMBER,
    batch_id                 VARCHAR,
    batch_seq                NUMBER
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.ORDERS (
    order_id                      VARCHAR,
    customer_id                   VARCHAR,
    order_status                  VARCHAR,
    order_purchase_timestamp      VARCHAR,
    order_approved_at              VARCHAR,
    order_delivered_carrier_date   VARCHAR,
    order_delivered_customer_date  VARCHAR,
    order_estimated_delivery_date  VARCHAR,
    ingested_at                   TIMESTAMP_NTZ,
    source_filename               VARCHAR,
    source_row_number             NUMBER,
    batch_id                      VARCHAR,
    batch_seq                     NUMBER
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.ORDER_ITEMS (
    order_id            VARCHAR,
    order_item_id       VARCHAR,
    product_id          VARCHAR,
    seller_id           VARCHAR,
    shipping_limit_date VARCHAR,
    price               VARCHAR,
    freight_value       VARCHAR,
    ingested_at         TIMESTAMP_NTZ,
    source_filename     VARCHAR,
    source_row_number   NUMBER,
    batch_id            VARCHAR,
    batch_seq           NUMBER
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.PRODUCTS (
    product_id                VARCHAR,
    product_category_name     VARCHAR,
    product_name_lenght        VARCHAR,
    product_description_lenght VARCHAR,
    product_photos_qty        VARCHAR,
    product_weight_g          VARCHAR,
    product_length_cm         VARCHAR,
    product_height_cm         VARCHAR,
    product_width_cm          VARCHAR,
    ingested_at               TIMESTAMP_NTZ,
    source_filename           VARCHAR,
    source_row_number         NUMBER,
    batch_id                  VARCHAR,
    batch_seq                 NUMBER
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.SELLERS (
    seller_id              VARCHAR,
    seller_zip_code_prefix VARCHAR,
    seller_city            VARCHAR,
    seller_state           VARCHAR,
    ingested_at            TIMESTAMP_NTZ,
    source_filename        VARCHAR,
    source_row_number      NUMBER,
    batch_id               VARCHAR,
    batch_seq              NUMBER
);
