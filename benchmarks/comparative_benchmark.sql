-- ==============================================================================
-- POSTGRESQL COMPARATIVE PERFORMANCE BENCHMARK EXPERIMENT
-- Module: CI7000 Project Dissertation | MSc Information Systems
-- Author: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
-- Supervisor: Dr. Islam Choudhury
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- EXPERIMENT 1: Executive Monthly Revenue Rollup
-- ------------------------------------------------------------------------------

-- Tier 1: Baseline Unindexed Staging Query (Full Table Scan)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    EXTRACT(YEAR FROM s.order_timestamp) AS year,
    EXTRACT(MONTH FROM s.order_timestamp) AS month,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.net_amount) AS total_revenue,
    SUM(s.margin_amount) AS total_margin
FROM stg_sales_orders s
WHERE s.status != 'Cancelled'
GROUP BY year, month
ORDER BY year, month;

-- Tier 2: Optimized Kimball Star Schema (Indexed Temporal Join)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    d.year,
    d.month_number,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.net_amount) AS total_revenue,
    SUM(s.margin_amount) AS total_margin
FROM fact_sales s
JOIN dim_date d ON s.date_key = d.date_key
WHERE s.status != 'Cancelled'
GROUP BY d.year, d.month_number
ORDER BY d.year, d.month_number;

-- Tier 3: Pre-aggregated Materialized View
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    year,
    month_number,
    SUM(total_orders) AS total_orders,
    SUM(total_net_revenue) AS total_revenue,
    SUM(total_gross_margin) AS total_margin
FROM mat_monthly_sales_summary
GROUP BY year, month_number
ORDER BY year, month_number;

-- ------------------------------------------------------------------------------
-- EXPERIMENT 2: Regional & Categorical Sales Performance
-- ------------------------------------------------------------------------------

-- Tier 1: Unindexed Normalized Staging Join
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.category,
    s.region,
    COUNT(s.order_id) AS order_volume,
    SUM(s.quantity) AS total_units,
    SUM(s.net_amount) AS total_revenue
FROM stg_sales_orders s
JOIN stg_products p ON s.product_id = p.product_id
WHERE s.status != 'Cancelled'
GROUP BY p.category, s.region
ORDER BY total_revenue DESC;

-- Tier 2: Kimball Star Schema with Dimension Surrogate Key Join
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.category,
    s.region,
    COUNT(s.sale_id) AS order_volume,
    SUM(s.quantity) AS total_units,
    SUM(s.net_amount) AS total_revenue
FROM fact_sales s
JOIN dim_product p ON s.product_sk = p.product_sk
WHERE s.status != 'Cancelled'
GROUP BY p.category, s.region
ORDER BY total_revenue DESC;

-- Tier 3: Materialized View Rollup
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    category,
    region,
    SUM(total_orders) AS order_volume,
    SUM(total_units_sold) AS total_units,
    SUM(total_net_revenue) AS total_revenue
FROM mat_monthly_sales_summary
GROUP BY category, region
ORDER BY total_revenue DESC;
