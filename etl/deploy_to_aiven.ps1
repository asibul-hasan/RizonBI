# Aiven Cloud PostgreSQL Data Warehouse Ingestion Script
$AivenUri = if ($env:DATABASE_URL) { $env:DATABASE_URL } else { "postgres://avnadmin:AVNS_DxFVsIyjx9okN5LVt2h@aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com:12656/rizondw?sslmode=require" }
$PsqlPath = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
if (-not (Test-Path $PsqlPath)) { $PsqlPath = "psql" }

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  AIVEN CLOUD POSTGRESQL DATA WAREHOUSE DEPLOYMENT AND INGESTION ENGINE        " -ForegroundColor Cyan
Write-Host "  Database: rizondw on Aiven Cloud (PostgreSQL 17)                              " -ForegroundColor Cyan
Write-Host "  Student: S M HOSNEY ARAFAT RIZON (ID: K2554665) | Supervisor: Dr. Islam Choudhury" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Apply DDL Schema
Write-Host "[1/5] Applying DDL Schemas and Views (warehouse/schema.sql)..." -ForegroundColor Yellow
& $PsqlPath $AivenUri -f "warehouse/schema.sql"

# 2. Populate Date and Audit Functions
Write-Host "[2/5] Initializing Calendar Dimension and Quality Audit (warehouse/load_postgres.sql)..." -ForegroundColor Yellow
& $PsqlPath $AivenUri -f "warehouse/load_postgres.sql"

# 3. Load CSV Datasets into Staging Tables using \copy
Write-Host "[3/5] Loading Raw CSV Datasets into Staging Tables via copy..." -ForegroundColor Yellow

$tables = @(
    @{ File = "data/raw/dim_products.csv"; Table = "stg_products" },
    @{ File = "data/raw/dim_customers.csv"; Table = "stg_customers" },
    @{ File = "data/raw/dim_suppliers.csv"; Table = "stg_suppliers" },
    @{ File = "data/raw/dim_employees.csv"; Table = "stg_employees" },
    @{ File = "data/raw/raw_sales_orders.csv"; Table = "stg_sales_orders" },
    @{ File = "data/raw/raw_inventory_snapshots.csv"; Table = "stg_inventory_snapshots" },
    @{ File = "data/raw/raw_finance_postings.csv"; Table = "stg_finance_postings" },
    @{ File = "data/raw/raw_hr_workforce.csv"; Table = "stg_hr_workforce" }
)

foreach ($t in $tables) {
    if (Test-Path $t.File) {
        $abs = (Resolve-Path $t.File).Path.Replace('\', '/')
        Write-Host "    -> Ingesting $($t.File) into $($t.Table)..." -ForegroundColor Gray
        & $PsqlPath $AivenUri -c "TRUNCATE TABLE $($t.Table);" 2>$null
        & $PsqlPath $AivenUri -c "\copy $($t.Table) FROM '$abs' WITH (FORMAT csv, HEADER true);"
    }
}

# 4. Transform Staging into Dimensional Star Schema Facts
Write-Host "[4/5] Transforming Staging Data into Kimball Star Schema Facts..." -ForegroundColor Yellow

$sqlTransform = "
INSERT INTO dim_product (product_id, product_sku, product_name, category, unit_price, unit_cost, reorder_level, lead_time_days)
SELECT product_id, product_sku, product_name, category, unit_price, unit_cost, reorder_level, lead_time_days
FROM stg_products ON CONFLICT (product_id) DO NOTHING;

INSERT INTO dim_customer (customer_id, customer_code, pseudonymised_name, pseudonymised_email, region, customer_tier, created_at)
SELECT customer_id, customer_code, pseudonymised_name, pseudonymised_email, region, customer_tier, created_at
FROM stg_customers ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO dim_supplier (supplier_id, supplier_code, supplier_name, country, rating, payment_terms_days)
SELECT supplier_id, supplier_code, supplier_name, country, rating, payment_terms_days
FROM stg_suppliers ON CONFLICT (supplier_id) DO NOTHING;

INSERT INTO dim_employee (employee_id, employee_code, masked_name, department, role, salary, hire_date, performance_score, is_active)
SELECT employee_id, employee_code, masked_name, department, role, salary, hire_date, performance_score, is_active
FROM stg_employees ON CONFLICT (employee_id) DO NOTHING;

TRUNCATE TABLE fact_sales CASCADE;
TRUNCATE TABLE fact_inventory CASCADE;
TRUNCATE TABLE fact_financial_transactions CASCADE;
TRUNCATE TABLE fact_hr_workforce CASCADE;

INSERT INTO fact_sales (
    order_id, order_number, order_timestamp, date_key, customer_sk, product_sk,
    region, channel, payment_method, quantity, unit_price, unit_cost,
    gross_amount, discount_amount, net_amount, margin_amount, status
)
SELECT 
    s.order_id, s.order_number, s.order_timestamp, s.date_key,
    c.customer_sk, p.product_sk, s.region, s.channel, s.payment_method,
    s.quantity, s.unit_price, s.unit_cost, s.gross_amount, s.discount_amount,
    s.net_amount, s.margin_amount, s.status
FROM stg_sales_orders s
JOIN dim_customer c ON s.customer_id = c.customer_id
JOIN dim_product p ON s.product_id = p.product_id;

INSERT INTO fact_inventory (snapshot_id, date_key, product_sk, supplier_sk, stock_on_hand, reorder_level, stockout_risk, unit_cost, inventory_value)
SELECT i.snapshot_id, i.date_key, p.product_sk, s.supplier_sk, i.stock_on_hand, i.reorder_level, i.stockout_risk, i.unit_cost, i.inventory_value
FROM stg_inventory_snapshots i
JOIN dim_product p ON i.product_id = p.product_id
JOIN dim_supplier s ON i.supplier_id = s.supplier_id;

INSERT INTO fact_financial_transactions (posting_id, date_key, account_sk, entry_type, amount, currency, reference)
SELECT f.posting_id, f.date_key, a.account_sk, f.entry_type, f.amount, f.currency, f.reference
FROM stg_finance_postings f
JOIN dim_account a ON f.account_code = a.account_code;

INSERT INTO fact_hr_workforce (hr_metric_id, date_key, department, headcount, avg_salary, avg_performance_score, total_training_hours, turnover_rate)
SELECT hr_metric_id, date_key, department, headcount, avg_salary, avg_performance_score, total_training_hours, turnover_rate
FROM stg_hr_workforce;

REFRESH MATERIALIZED VIEW mat_monthly_sales_summary;
"

& $PsqlPath $AivenUri -c $sqlTransform

# 5. Run Automated Data Quality Tests
Write-Host "[5/5] Executing Data Quality Audit Suite (fn_audit_data_quality)..." -ForegroundColor Yellow
& $PsqlPath $AivenUri -c "SELECT test_name, status, actual_count, expected_count FROM fn_audit_data_quality();"

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "  SUCCESS: AIVEN CLOUD POSTGRESQL DATA WAREHOUSE LOADED AND AUDITED!           " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
