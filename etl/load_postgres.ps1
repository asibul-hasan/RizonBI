<#
.SYNOPSIS
    PostgreSQL 16/17 Data Warehouse Automated Ingestion Script
.DESCRIPTION
    Creates the database 'rizon_dw', executes DDL schemas, loads dimension datasets,
    populates date dimensions, and verifies data quality tests.
#>

param (
    [string]$PgUser = "avnadmin",
    [string]$PgHost = "aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com",
    [string]$PgPort = "12656",
    [string]$PgDb   = "rizondw"
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  POSTGRESQL DATA WAREHOUSE LOAD SCRIPT | MSc DISSERTATION CI7000               " -ForegroundColor Cyan
Write-Host "  Author: S M HOSNEY ARAFAT RIZON (ID: K2554665) | Supervisor: Dr. Islam Choudhury" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

$PsqlPath = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
if (-not (Test-Path $PsqlPath)) {
    $PsqlPath = "psql"
}

# 1. Create Database if not exists
Write-Host "[1/4] Checking and creating database '$PgDb'..." -ForegroundColor Yellow
& $PsqlPath -h $PgHost -p $PgPort -U $PgUser -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$PgDb'" -t | Out-Null
& $PsqlPath -h $PgHost -p $PgPort -U $PgUser -d postgres -c "CREATE DATABASE $PgDb;" 2>$null

# 2. Execute Schema DDL
Write-Host "[2/4] Applying Schema DDL and Views (warehouse/schema.sql)..." -ForegroundColor Yellow
& $PsqlPath -h $PgHost -p $PgPort -U $PgUser -d $PgDb -f "warehouse/schema.sql"

# 3. Apply Date Generator and Data Quality Functions
Write-Host "[3/4] Generating Conformed Dimensions and Audit Functions (warehouse/load_postgres.sql)..." -ForegroundColor Yellow
& $PsqlPath -h $PgHost -p $PgPort -U $PgUser -d $PgDb -f "warehouse/load_postgres.sql"

# 4. Ingest Raw CSV Files using \copy
Write-Host "[4/4] Ingesting CSV datasets into PostgreSQL..." -ForegroundColor Yellow
$csvFiles = @(
    @{ Path = "data/raw/dim_products.csv"; Table = "stg_products" },
    @{ Path = "data/raw/dim_customers.csv"; Table = "stg_customers" },
    @{ Path = "data/raw/dim_suppliers.csv"; Table = "stg_suppliers" },
    @{ Path = "data/raw/dim_employees.csv"; Table = "stg_employees" },
    @{ Path = "data/raw/raw_sales_orders.csv"; Table = "stg_sales_orders" },
    @{ Path = "data/raw/raw_inventory_snapshots.csv"; Table = "stg_inventory_snapshots" },
    @{ Path = "data/raw/raw_finance_postings.csv"; Table = "stg_finance_postings" },
    @{ Path = "data/raw/raw_hr_workforce.csv"; Table = "stg_hr_workforce" }
)

foreach ($item in $csvFiles) {
    if (Test-Path $item.Path) {
        $absPath = (Resolve-Path $item.Path).Path -replace '\\', '/'
        Write-Host "    -> Copying $($item.Path) to $($item.Table)..." -ForegroundColor Gray
        & $PsqlPath -h $PgHost -p $PgPort -U $PgUser -d $PgDb -c "\copy $($item.Table) FROM '$absPath' WITH (FORMAT csv, HEADER true);"
    }
}

# Transform Staging to Facts
$transformSql = @"
-- Transform dimensions
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

-- Transform facts
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

-- Run Data Quality Audit
SELECT * FROM fn_audit_data_quality();
"@

& $PsqlPath -h $PgHost -p $PgPort -U $PgUser -d $PgDb -c "$transformSql"

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "  [✓] POSTGRESQL DATA WAREHOUSE FULLY LOADED AND AUDITED!                      " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
