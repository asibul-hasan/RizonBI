-- ==============================================================================
-- PROJECT DISSERTATION: CI7000 (MSc Information Systems)
-- AUTHOR: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
-- SUPERVISOR: DR. ISLAM CHOUDHURY
-- TOPIC: Design and Implementation of a Scalable Data Warehouse for Real-Time BI
-- ==============================================================================

-- 1. STAGING SCHEMAS (ELT INGESTION BUFFER)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS stg_customers (
    customer_id INT PRIMARY KEY,
    customer_code VARCHAR(50),
    pseudonymised_name VARCHAR(100),
    pseudonymised_email VARCHAR(100),
    region VARCHAR(50),
    customer_tier VARCHAR(20),
    created_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_products (
    product_id INT PRIMARY KEY,
    product_sku VARCHAR(50),
    product_name VARCHAR(150),
    category VARCHAR(50),
    unit_price NUMERIC(12, 2),
    unit_cost NUMERIC(12, 2),
    reorder_level INT,
    lead_time_days INT
);

CREATE TABLE IF NOT EXISTS stg_suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_code VARCHAR(50),
    supplier_name VARCHAR(150),
    country VARCHAR(50),
    rating NUMERIC(3, 1),
    payment_terms_days INT
);

CREATE TABLE IF NOT EXISTS stg_employees (
    employee_id INT PRIMARY KEY,
    employee_code VARCHAR(50),
    masked_name VARCHAR(100),
    department VARCHAR(50),
    role VARCHAR(100),
    salary NUMERIC(12, 2),
    hire_date DATE,
    performance_score NUMERIC(3, 1),
    is_active INT
);

CREATE TABLE IF NOT EXISTS stg_sales_orders (
    order_id INT,
    order_number VARCHAR(50),
    order_timestamp TIMESTAMP,
    date_key INT,
    customer_id INT,
    product_id INT,
    region VARCHAR(50),
    channel VARCHAR(50),
    payment_method VARCHAR(50),
    quantity INT,
    unit_price NUMERIC(12, 2),
    unit_cost NUMERIC(12, 2),
    gross_amount NUMERIC(12, 2),
    discount_amount NUMERIC(12, 2),
    net_amount NUMERIC(12, 2),
    margin_amount NUMERIC(12, 2),
    status VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS stg_inventory_snapshots (
    snapshot_id INT,
    date DATE,
    date_key INT,
    product_id INT,
    supplier_id INT,
    stock_on_hand INT,
    reorder_level INT,
    stockout_risk INT,
    unit_cost NUMERIC(12, 2),
    inventory_value NUMERIC(14, 2)
);

CREATE TABLE IF NOT EXISTS stg_finance_postings (
    posting_id INT,
    posting_date DATE,
    date_key INT,
    account_code VARCHAR(50),
    account_name VARCHAR(100),
    account_type VARCHAR(50),
    entry_type VARCHAR(20),
    amount NUMERIC(14, 2),
    currency VARCHAR(10),
    reference VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS stg_hr_workforce (
    hr_metric_id INT,
    month VARCHAR(20),
    date_key INT,
    department VARCHAR(50),
    headcount INT,
    avg_salary NUMERIC(12, 2),
    avg_performance_score NUMERIC(3, 1),
    total_training_hours NUMERIC(8, 1),
    turnover_rate NUMERIC(5, 3)
);

-- ==============================================================================
-- 2. DIMENSION TABLES (KIMBALL CONFORMED DIMENSIONS)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(15) NOT NULL,
    day_of_month INT NOT NULL,
    month_number INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL,
    is_weekend INT NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    customer_id INT UNIQUE NOT NULL,
    customer_code VARCHAR(50),
    pseudonymised_name VARCHAR(100),
    pseudonymised_email VARCHAR(100),
    region VARCHAR(50),
    customer_tier VARCHAR(20),
    created_at TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_sk SERIAL PRIMARY KEY,
    product_id INT UNIQUE NOT NULL,
    product_sku VARCHAR(50),
    product_name VARCHAR(150),
    category VARCHAR(50),
    unit_price NUMERIC(12, 2),
    unit_cost NUMERIC(12, 2),
    profit_margin_pct NUMERIC(6, 2),
    reorder_level INT,
    lead_time_days INT
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_sk SERIAL PRIMARY KEY,
    supplier_id INT UNIQUE NOT NULL,
    supplier_code VARCHAR(50),
    supplier_name VARCHAR(150),
    country VARCHAR(50),
    rating NUMERIC(3, 1),
    payment_terms_days INT
);

CREATE TABLE IF NOT EXISTS dim_employee (
    employee_sk SERIAL PRIMARY KEY,
    employee_id INT UNIQUE NOT NULL,
    employee_code VARCHAR(50),
    masked_name VARCHAR(100),
    department VARCHAR(50),
    role VARCHAR(100),
    salary NUMERIC(12, 2),
    hire_date DATE,
    performance_score NUMERIC(3, 1),
    is_active INT
);

CREATE TABLE IF NOT EXISTS dim_account (
    account_sk SERIAL PRIMARY KEY,
    account_code VARCHAR(50) UNIQUE NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL
);

-- ==============================================================================
-- 3. FACT TABLES (STAR SCHEMA CORE)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id SERIAL PRIMARY KEY,
    order_id INT,
    order_number VARCHAR(50),
    order_timestamp TIMESTAMP NOT NULL,
    date_key INT REFERENCES dim_date(date_key),
    customer_sk INT REFERENCES dim_customer(customer_sk),
    product_sk INT REFERENCES dim_product(product_sk),
    region VARCHAR(50),
    channel VARCHAR(50),
    payment_method VARCHAR(50),
    quantity INT NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    unit_cost NUMERIC(12, 2) NOT NULL,
    gross_amount NUMERIC(12, 2) NOT NULL,
    discount_amount NUMERIC(12, 2) DEFAULT 0,
    net_amount NUMERIC(12, 2) NOT NULL,
    margin_amount NUMERIC(12, 2) NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_inventory (
    inventory_id SERIAL PRIMARY KEY,
    snapshot_id INT,
    date_key INT REFERENCES dim_date(date_key),
    product_sk INT REFERENCES dim_product(product_sk),
    supplier_sk INT REFERENCES dim_supplier(supplier_sk),
    stock_on_hand INT NOT NULL,
    reorder_level INT NOT NULL,
    stockout_risk INT NOT NULL,
    unit_cost NUMERIC(12, 2) NOT NULL,
    inventory_value NUMERIC(14, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_financial_transactions (
    transaction_id SERIAL PRIMARY KEY,
    posting_id INT,
    date_key INT REFERENCES dim_date(date_key),
    account_sk INT REFERENCES dim_account(account_sk),
    entry_type VARCHAR(20) NOT NULL,
    amount NUMERIC(14, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'GBP',
    reference VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS fact_hr_workforce (
    workforce_id SERIAL PRIMARY KEY,
    hr_metric_id INT,
    date_key INT REFERENCES dim_date(date_key),
    department VARCHAR(50) NOT NULL,
    headcount INT NOT NULL,
    avg_salary NUMERIC(12, 2) NOT NULL,
    avg_performance_score NUMERIC(3, 1) NOT NULL,
    total_training_hours NUMERIC(8, 1) NOT NULL,
    turnover_rate NUMERIC(5, 3) NOT NULL
);

-- ==============================================================================
-- 4. PERFORMANCE INDEXES (FOR SUB-SECOND OLAP QUERIES)
-- Developer note: Added single-column and composite B-Tree indexes to optimize
-- multi-table join plans and satisfy index-only scans on high-cardinality filters.
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_fact_sales_date ON fact_sales(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_sales_cust ON fact_sales(customer_sk);
CREATE INDEX IF NOT EXISTS idx_fact_sales_prod ON fact_sales(product_sk);
CREATE INDEX IF NOT EXISTS idx_fact_sales_region ON fact_sales(region);
CREATE INDEX IF NOT EXISTS idx_fact_sales_date_region ON fact_sales(date_key, region);

CREATE INDEX IF NOT EXISTS idx_fact_inv_date ON fact_inventory(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_inv_prod ON fact_inventory(product_sk);
CREATE INDEX IF NOT EXISTS idx_fact_inv_date_prod ON fact_inventory(date_key, product_sk);

CREATE INDEX IF NOT EXISTS idx_fact_fin_date ON fact_financial_transactions(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_fin_acc ON fact_financial_transactions(account_sk);
CREATE INDEX IF NOT EXISTS idx_fact_fin_date_acc ON fact_financial_transactions(date_key, account_sk);

CREATE INDEX IF NOT EXISTS idx_fact_hr_date ON fact_hr_workforce(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_hr_dept ON fact_hr_workforce(department);

-- ==============================================================================
-- 5. ANALYTICAL VIEWS FOR BUSINESS INTELLIGENCE
-- ==============================================================================

-- Executive KPI Summary View
CREATE OR REPLACE VIEW vw_executive_kpis AS
SELECT 
    d.year,
    d.quarter,
    d.month_name,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.gross_amount) AS total_gross_revenue,
    SUM(s.net_amount) AS total_net_revenue,
    SUM(s.margin_amount) AS total_gross_margin,
    ROUND(SUM(s.margin_amount) / NULLIF(SUM(s.net_amount), 0) * 100, 2) AS gross_margin_pct,
    COUNT(DISTINCT s.customer_sk) AS active_customers
FROM fact_sales s
JOIN dim_date d ON s.date_key = d.date_key
WHERE s.status != 'Cancelled'
GROUP BY d.year, d.quarter, d.month_name;

-- Sales Performance by Category and Region
CREATE OR REPLACE VIEW vw_sales_by_category_region AS
SELECT 
    p.category,
    s.region,
    COUNT(s.sale_id) AS order_count,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.net_amount) AS total_revenue,
    SUM(s.margin_amount) AS total_margin
FROM fact_sales s
JOIN dim_product p ON s.product_sk = p.product_sk
WHERE s.status != 'Cancelled'
GROUP BY p.category, s.region;

-- Inventory Stockout Warning View
CREATE OR REPLACE VIEW vw_inventory_stockout_alerts AS
SELECT 
    p.product_name,
    p.category,
    sup.supplier_name,
    i.stock_on_hand,
    i.reorder_level,
    i.inventory_value,
    CASE WHEN i.stock_on_hand <= i.reorder_level THEN 'CRITICAL_REORDER' ELSE 'HEALTHY' END AS stock_status
FROM fact_inventory i
JOIN dim_product p ON i.product_sk = p.product_sk
JOIN dim_supplier sup ON i.supplier_sk = sup.supplier_sk
WHERE i.date_key = (SELECT MAX(date_key) FROM fact_inventory);
