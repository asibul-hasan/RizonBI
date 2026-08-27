-- ==============================================================================
-- POSTGRESQL 16/17 ANALYTICAL QUERY BENCHMARK SUITE
-- Module: CI7000 Project Dissertation | MSc Information Systems
-- Author: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
-- Supervisor: Dr. Islam Choudhury
-- ==============================================================================

-- Warm-up cache and analyze statistics
ANALYZE fact_sales;
ANALYZE fact_inventory;
ANALYZE fact_financial_transactions;
ANALYZE fact_hr_workforce;
ANALYZE dim_date;
ANALYZE dim_product;
ANALYZE dim_customer;

-- ==============================================================================
-- BENCHMARK QUERY 1: Multi-Table Executive Revenue Rollup (Temporal Join)
-- ==============================================================================
EXPLAIN ANALYZE
SELECT 
    d.year,
    d.quarter,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.gross_amount) AS gross_revenue,
    SUM(s.net_amount) AS net_revenue,
    SUM(s.margin_amount) AS total_margin,
    ROUND((SUM(s.margin_amount) / NULLIF(SUM(s.net_amount), 0) * 100)::NUMERIC, 2) AS profit_margin_pct
FROM fact_sales s
JOIN dim_date d ON s.date_key = d.date_key
WHERE s.status != 'Cancelled'
GROUP BY d.year, d.quarter
ORDER BY d.year ASC, d.quarter ASC;

-- ==============================================================================
-- BENCHMARK QUERY 2: Regional & Categorical Sales Drill-Down
-- ==============================================================================
EXPLAIN ANALYZE
SELECT 
    p.category,
    s.region,
    COUNT(s.sale_id) AS order_volume,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.net_amount) AS total_revenue,
    ROUND(AVG(s.margin_amount)::NUMERIC, 2) AS avg_transaction_profit
FROM fact_sales s
JOIN dim_product p ON s.product_sk = p.product_sk
WHERE s.status != 'Cancelled'
GROUP BY p.category, s.region
ORDER BY total_revenue DESC;

-- ==============================================================================
-- BENCHMARK QUERY 3: Customer Segment & Regional Monetary Value
-- ==============================================================================
EXPLAIN ANALYZE
SELECT 
    c.customer_tier,
    c.region,
    COUNT(DISTINCT s.order_id) AS order_frequency,
    SUM(s.net_amount) AS monetary_value,
    ROUND(AVG(s.net_amount)::NUMERIC, 2) AS avg_order_value
FROM fact_sales s
JOIN dim_customer c ON s.customer_sk = c.customer_sk
WHERE s.status != 'Cancelled'
GROUP BY c.customer_tier, c.region
ORDER BY monetary_value DESC;

-- ==============================================================================
-- BENCHMARK QUERY 4: Real-Time Inventory Valuation & Stockout Risk Scan
-- ==============================================================================
EXPLAIN ANALYZE
SELECT 
    p.category,
    COUNT(i.inventory_id) AS total_tracked_items,
    SUM(i.stockout_risk) AS critical_reorder_alerts,
    SUM(i.inventory_value) AS total_holding_value_gbp
FROM fact_inventory i
JOIN dim_product p ON i.product_sk = p.product_sk
WHERE i.date_key = (SELECT MAX(date_key) FROM fact_inventory)
GROUP BY p.category
ORDER BY total_holding_value_gbp DESC;

-- ==============================================================================
-- BENCHMARK QUERY 5: General Ledger Income Statement Posting Aggregation
-- ==============================================================================
EXPLAIN ANALYZE
SELECT 
    a.account_type,
    a.account_name,
    d.year,
    d.quarter,
    SUM(f.amount) AS total_period_balance
FROM fact_financial_transactions f
JOIN dim_account a ON f.account_sk = a.account_sk
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY a.account_type, a.account_name, d.year, d.quarter
ORDER BY a.account_type, d.year, d.quarter;
