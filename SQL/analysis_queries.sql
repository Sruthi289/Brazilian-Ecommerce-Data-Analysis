-- ============================================================
-- BRAZILIAN E-COMMERCE DATA ANALYSIS
-- SQL Analysis Queries
-- Database: PostgreSQL
-- ============================================================


-- ============================================================
-- 1. DATASET EXPLORATION
-- ============================================================

-- Count records in each table
SELECT COUNT(*) FROM orders;

SELECT COUNT(*) FROM order_items;

SELECT COUNT(*) FROM products;

SELECT COUNT(*) FROM payments;

SELECT COUNT(*) FROM customers;

SELECT COUNT(*) FROM sellers;

SELECT COUNT(*) FROM geolocation;

SELECT COUNT(*) FROM reviews;

-- List tables in the public schema
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================
-- 2. SALES AND REVENUE ANALYSIS
-- ============================================================

-- Total payment value for delivered orders
SELECT
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM payments
WHERE order_id IN (
    SELECT order_id
    FROM orders
    WHERE order_status = 'delivered'
);

-- Average payment value per delivered order
SELECT
    ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2)
        AS average_payment_per_order
FROM payments
WHERE order_id IN (
    SELECT order_id
    FROM orders
    WHERE order_status = 'delivered'
);

-- Monthly revenue from delivered orders
SELECT
    o.purchase_year,
    o.purchase_month,
    o.purchase_month_name,
    ROUND(SUM(p.payment_value), 2) AS monthly_revenue
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.purchase_year,
    o.purchase_month,
    o.purchase_month_name
ORDER BY
    o.purchase_year,
    o.purchase_month;


-- ============================================================
-- 3. PRODUCT ANALYSIS
-- ============================================================

-- Top 10 product categories by sales
SELECT
    p.product_category_name,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_sales DESC
LIMIT 10;


-- ============================================================
-- 4. CUSTOMER ANALYSIS
-- ============================================================

-- Top 10 customer states by number of delivered orders
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;


-- ============================================================
-- 5. SELLER ANALYSIS
-- ============================================================

-- Top 10 sellers by sales
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS product_sales,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY total_sales DESC
LIMIT 10;


-- ============================================================
-- 6. PAYMENT ANALYSIS
-- ============================================================

-- Payment records, total payment value, and average payment by type
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- ============================================================
-- 7. ORDER ANALYSIS
-- ============================================================

-- Total number of delivered orders
SELECT
    COUNT(*) AS total_delivered_orders
FROM orders
WHERE order_status = 'delivered';

-- Order counts by status
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Monthly order volume
SELECT
    purchase_year,
    purchase_month,
    purchase_month_name,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    purchase_year,
    purchase_month,
    purchase_month_name
ORDER BY
    purchase_year,
    purchase_month;


-- ============================================================
-- 8. DELIVERY PERFORMANCE ANALYSIS
-- ============================================================

-- Average actual delivery time and average delivery delay
SELECT
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(delivery_delay_days), 2) AS avg_delay_days
FROM orders
WHERE order_status = 'delivered';

-- Distribution of delivered orders by delivery status
SELECT
    CASE
        WHEN delivery_delay_days < 0 THEN 'Early'
        WHEN delivery_delay_days = 0 THEN 'On Time'
        WHEN delivery_delay_days > 0 THEN 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders
WHERE order_status = 'delivered'
  AND delivery_delay_days IS NOT NULL
GROUP BY
    CASE
        WHEN delivery_delay_days < 0 THEN 'Early'
        WHEN delivery_delay_days = 0 THEN 'On Time'
        WHEN delivery_delay_days > 0 THEN 'Late'
    END
ORDER BY total_orders DESC;


-- ============================================================
-- 9. CUSTOMER REVIEW ANALYSIS
-- ============================================================

-- Review counts and percentage by review score
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 10. DATA INTEGRITY CHECKS
-- ============================================================

-- Check for order items without a matching order
SELECT
    COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for payment records without a matching order
SELECT
    COUNT(*) AS orphan_payment_records
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for order items without a matching product
SELECT
    COUNT(*) AS orphan_product_records
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check for order items without a matching seller
SELECT
    COUNT(*) AS orphan_seller_records
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Check for orders without a matching customer
SELECT
    COUNT(*) AS orphan_customer_records
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check for reviews without a matching order
SELECT
    COUNT(*) AS orphan_review_records
FROM reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
