-- ==============================================================================
-- POSTGRESQL 16/17 DATA LOADER & DIMENSIONAL POPULATION SCRIPT
-- Project: Scalable Data Warehouse for Real-Time BI (CI7000)
-- Author: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
-- Supervisor: Dr. Islam Choudhury
-- ==============================================================================

-- 1. POPULATE CONFORMED DATE DIMENSION (2020 - 2030)
-- ==============================================================================
INSERT INTO dim_date (date_key, full_date, day_of_week, day_name, day_of_month, month_number, month_name, quarter, year, is_weekend)
SELECT 
    TO_CHAR(d, 'YYYYMMDD')::INT AS date_key,
    d::DATE AS full_date,
    EXTRACT(ISODOW FROM d)::INT AS day_of_week,
    TO_CHAR(d, 'Day') AS day_name,
    EXTRACT(DAY FROM d)::INT AS day_of_month,
    EXTRACT(MONTH FROM d)::INT AS month_number,
    TO_CHAR(d, 'Month') AS month_name,
    EXTRACT(QUARTER FROM d)::INT AS quarter,
    EXTRACT(YEAR FROM d)::INT AS year,
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN 1 ELSE 0 END AS is_weekend
FROM GENERATE_SERIES('2020-01-01'::DATE, '2030-12-31'::DATE, '1 day'::INTERVAL) d
ON CONFLICT (date_key) DO NOTHING;

-- 2. POPULATE CHART OF ACCOUNTS DIMENSION
-- ==============================================================================
INSERT INTO dim_account (account_code, account_name, account_type) VALUES
('REV-100', 'Operating Revenue', 'Revenue'),
('REV-200', 'Services Revenue', 'Revenue'),
('COGS-100', 'Direct Material Costs', 'COGS'),
('COGS-200', 'Third-Party Infrastructure', 'COGS'),
('OPEX-100', 'Salaries & Payroll', 'Expense'),
('OPEX-200', 'Office Lease & Utilities', 'Expense'),
('OPEX-300', 'Marketing & Advertising', 'Expense'),
('OPEX-400', 'Software Subscriptions & Cloud', 'Expense'),
('TAX-100', 'Corporate & VAT Tax', 'Tax')
ON CONFLICT (account_code) DO NOTHING;

-- 3. SQL AUTOMATED DATA QUALITY AUDIT FUNCTION
-- ==============================================================================
CREATE OR REPLACE FUNCTION fn_audit_data_quality() 
RETURNS TABLE(test_name TEXT, status TEXT, actual_count BIGINT, expected_count BIGINT) AS $$
BEGIN
    -- Test 1: Customer ID uniqueness
    RETURN QUERY SELECT 
        'dim_customer_unique_id'::TEXT,
        CASE WHEN (COUNT(customer_id) - COUNT(DISTINCT customer_id)) = 0 THEN 'PASSED'::TEXT ELSE 'FAILED'::TEXT END,
        (COUNT(customer_id) - COUNT(DISTINCT customer_id)),
        0::BIGINT
    FROM dim_customer;

    -- Test 2: Product Positive Unit Price
    RETURN QUERY SELECT 
        'dim_product_positive_price'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASSED'::TEXT ELSE 'FAILED'::TEXT END,
        COUNT(*),
        0::BIGINT
    FROM dim_product WHERE unit_price <= 0;

    -- Test 3: Fact Sales Non-Null Customer Key
    RETURN QUERY SELECT 
        'fact_sales_non_null_fk'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASSED'::TEXT ELSE 'FAILED'::TEXT END,
        COUNT(*),
        0::BIGINT
    FROM fact_sales WHERE customer_sk IS NULL OR product_sk IS NULL;

    -- Test 4: Fact Sales Non-Negative Revenue
    RETURN QUERY SELECT 
        'fact_sales_valid_revenue'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASSED'::TEXT ELSE 'FAILED'::TEXT END,
        COUNT(*),
        0::BIGINT
    FROM fact_sales WHERE net_amount < 0;

    -- Test 5: Inventory Stock Valid Range
    RETURN QUERY SELECT 
        'fact_inventory_valid_stock'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASSED'::TEXT ELSE 'FAILED'::TEXT END,
        COUNT(*),
        0::BIGINT
    FROM fact_inventory WHERE stock_on_hand < 0;
END;
$$ LANGUAGE plpgsql;

-- 4. MATERIALIZED AGGREGATIONS FOR ACCELERATED OLAP SERVING (<50ms)
-- ==============================================================================
-- Developer note: Unique index on (year, month_number, category, region) enables
-- non-blocking 'REFRESH MATERIALIZED VIEW CONCURRENTLY' for zero-downtime serving.
CREATE MATERIALIZED VIEW IF NOT EXISTS mat_monthly_sales_summary AS
SELECT 
    d.year,
    d.quarter,
    d.month_number,
    d.month_name,
    p.category,
    s.region,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.gross_amount) AS total_gross_revenue,
    SUM(s.net_amount) AS total_net_revenue,
    SUM(s.margin_amount) AS total_gross_margin
FROM fact_sales s
JOIN dim_date d ON s.date_key = d.date_key
JOIN dim_product p ON s.product_sk = p.product_sk
WHERE s.status != 'Cancelled'
GROUP BY d.year, d.quarter, d.month_number, d.month_name, p.category, s.region;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mat_monthly_sales ON mat_monthly_sales_summary(year, month_number, category, region);
