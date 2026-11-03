-- Run after loading and a successful dbt build.
USE ROLE OLIST_TRANSFORM;
USE SECONDARY ROLES NONE;
USE WAREHOUSE OLIST_WH;

-- RAW counts include historical versions.
SELECT 'customers' AS source_table, COUNT(*) AS raw_rows
FROM OLIST.RAW.CUSTOMERS
UNION ALL
SELECT 'orders', COUNT(*) FROM OLIST.RAW.ORDERS
UNION ALL
SELECT 'order_items', COUNT(*) FROM OLIST.RAW.ORDER_ITEMS
UNION ALL
SELECT 'products', COUNT(*) FROM OLIST.RAW.PRODUCTS
UNION ALL
SELECT 'sellers', COUNT(*) FROM OLIST.RAW.SELLERS;

-- Fact counts and unique business keys must match.
SELECT
    'orders' AS fact_table,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS unique_keys
FROM OLIST.CORE.FCT_ORDERS
UNION ALL
SELECT
    'order_items',
    COUNT(*),
    COUNT(DISTINCT order_id, order_item_id)
FROM OLIST.CORE.FCT_ORDER_ITEMS;

-- Preserve the invalid inputs and later corrections in RAW.
SELECT order_id, order_status, batch_id, batch_seq, source_filename
FROM OLIST.RAW.ORDERS
WHERE order_id = '8cbdb3ca13f635b864d4073a96387d2a'
ORDER BY batch_seq;

-- Final simulated version: canceled, FALSE, NULL, batch sequence 6.
SELECT order_id, order_status, is_delivered, is_late, batch_id, batch_seq
FROM OLIST.CORE.FCT_ORDERS
WHERE order_id = '8cbdb3ca13f635b864d4073a96387d2a';

-- Overall delivery percentage uses totals, not averaged percentages.
SELECT
    SUM(delivered_orders) AS delivered_orders,
    SUM(measurable_orders) AS measurable_orders,
    SUM(late_orders) AS late_orders,
    SUM(missing_delivery_dates) AS missing_delivery_dates,
    ROUND(
        100.0 * SUM(late_orders)
        / NULLIF(SUM(measurable_orders), 0),
        2
    ) AS late_order_percentage
FROM OLIST.MARTS.DELIVERY_PERFORMANCE;

SELECT * FROM OLIST.MARTS.REPEAT_CUSTOMERS;
