"""
PostgreSQL Automated Data Warehouse Loader & ETL Script
Author: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
Module: CI7000 - MSc Information Systems Dissertation
Supervisor: Dr. Islam Choudhury

Loads raw CSV datasets into PostgreSQL 16/17, builds dimensional model,
resolves surrogate keys, and executes automated data quality audits.
"""

import os
import csv
import sys
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("PostgresETL")

# Connection Configuration (Aiven Managed PostgreSQL)
AIVEN_URI = os.getenv(
    "DATABASE_URL",
    "postgres://avnadmin:AVNS_DxFVsIyjx9okN5LVt2h@aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com:12656/rizondw?sslmode=require"
)
PG_HOST = os.getenv("PGHOST", "aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com")
PG_PORT = os.getenv("PGPORT", "12656")
PG_DATABASE = os.getenv("PGDATABASE", "rizondw")
PG_USER = os.getenv("PGUSER", "avnadmin")
PG_PASSWORD = os.getenv("PGPASSWORD", "AVNS_DxFVsIyjx9okN5LVt2h")


def get_postgres_connection():
    """Attempts to connect using psycopg2 or psycopg3."""
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            dbname=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        return conn
    except ImportError:
        try:
            import psycopg
            conn = psycopg.connect(
                f"host={PG_HOST} port={PG_PORT} dbname={PG_DATABASE} user={PG_USER} password={PG_PASSWORD}"
            )
            return conn
        except ImportError:
            logger.error("Neither psycopg2 nor psycopg is installed. Install via: pip install psycopg2-binary")
            return None
    except Exception as e:
        logger.error(f"Failed to connect to PostgreSQL: {e}")
        logger.info("Tip: Ensure database 'rizon_dw' exists: CREATE DATABASE rizon_dw;")
        return None


def execute_sql_file(conn, file_path):
    """Executes SQL statements from a file."""
    if not os.path.exists(file_path):
        logger.warning(f"File not found: {file_path}")
        return
    with open(file_path, "r", encoding="utf-8") as f:
        sql = f.read()
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
    logger.info(f"[✓] Executed {file_path}")


def load_csv_to_table(conn, csv_path, table_name, columns):
    """Loads CSV data into specified PostgreSQL table."""
    if not os.path.exists(csv_path):
        logger.warning(f"CSV file {csv_path} does not exist.")
        return 0

    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        records = [tuple(row[col] for col in columns) for row in reader]

    if not records:
        return 0

    cols_str = ", ".join(columns)
    placeholders = ", ".join(["%s"] * len(columns))
    insert_query = f"INSERT INTO {table_name} ({cols_str}) VALUES ({placeholders});"

    with conn.cursor() as cur:
        cur.executemany(insert_query, records)
    conn.commit()
    logger.info(f"    -> Inserted {len(records):,} rows into {table_name}")
    return len(records)


def run_full_postgres_etl():
    """Runs complete PostgreSQL ETL pipeline."""
    print("================================================================================")
    print("  POSTGRESQL DATA WAREHOUSE ETL & DATA QUALITY PIPELINE                         ")
    print(f"  Target Database: {PG_DATABASE} on {PG_HOST}:{PG_PORT} (User: {PG_USER})")
    print("================================================================================\n")

    conn = get_postgres_connection()
    if not conn:
        print("\n[!] Connection failed. Please check PostgreSQL credentials or create the database:")
        print(f"    psql -U {PG_USER} -c 'CREATE DATABASE {PG_DATABASE};'")
        sys.exit(1)

    try:
        # Step 1: Initialize Schema
        logger.info("[1/5] Initializing Staging, Dimensions, and Fact Tables in PostgreSQL...")
        execute_sql_file(conn, "warehouse/schema.sql")
        execute_sql_file(conn, "warehouse/load_postgres.sql")

        # Step 2: Load Dimensions
        logger.info("[2/5] Ingesting and Conforming Dimension Datasets...")
        load_csv_to_table(conn, "data/raw/dim_products.csv", "dim_product", 
                          ["product_id", "product_sku", "product_name", "category", "unit_price", "unit_cost", "reorder_level", "lead_time_days"])
        load_csv_to_table(conn, "data/raw/dim_customers.csv", "dim_customer", 
                          ["customer_id", "customer_code", "pseudonymised_name", "pseudonymised_email", "region", "customer_tier", "created_at"])
        load_csv_to_table(conn, "data/raw/dim_suppliers.csv", "dim_supplier", 
                          ["supplier_id", "supplier_code", "supplier_name", "country", "rating", "payment_terms_days"])
        load_csv_to_table(conn, "data/raw/dim_employees.csv", "dim_employee", 
                          ["employee_id", "employee_code", "masked_name", "department", "role", "salary", "hire_date", "performance_score", "is_active"])

        # Step 3: Load Facts
        logger.info("[3/5] Loading Fact Tables with Surrogate Key Resolution...")
        # Sales
        with conn.cursor() as cur:
            cur.execute("SELECT customer_id, customer_sk FROM dim_customer;")
            cust_map = dict(cur.fetchall())
            cur.execute("SELECT product_id, product_sk FROM dim_product;")
            prod_map = dict(cur.fetchall())

        sales_records = []
        with open("data/raw/raw_sales_orders.csv", "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                c_sk = cust_map.get(int(row["customer_id"]))
                p_sk = prod_map.get(int(row["product_id"]))
                if c_sk and p_sk:
                    sales_records.append((
                        int(row["order_id"]), row["order_number"], row["order_timestamp"],
                        int(row["date_key"]), c_sk, p_sk, row["region"], row["channel"],
                        row["payment_method"], int(row["quantity"]), float(row["unit_price"]),
                        float(row["unit_cost"]), float(row["gross_amount"]), float(row["discount_amount"]),
                        float(row["net_amount"]), float(row["margin_amount"]), row["status"]
                    ))

        with conn.cursor() as cur:
            cur.executemany("""
                INSERT INTO fact_sales (
                    order_id, order_number, order_timestamp, date_key, customer_sk, product_sk,
                    region, channel, payment_method, quantity, unit_price, unit_cost,
                    gross_amount, discount_amount, net_amount, margin_amount, status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
            """, sales_records)
        conn.commit()
        logger.info(f"    -> Inserted {len(sales_records):,} rows into fact_sales")

        # Step 4: Run Data Quality Suite
        logger.info("[4/5] Running Automated Data Quality Audit (fn_audit_data_quality)...")
        with conn.cursor() as cur:
            cur.execute("SELECT test_name, status, actual_count, expected_count FROM fn_audit_data_quality();")
            dq_rows = cur.fetchall()
            for t_name, status, act, exp in dq_rows:
                logger.info(f"    Test: {t_name:30s} | Status: {status} | Actual: {act} | Expected: {exp}")

        # Step 5: Refresh Materialized Views
        logger.info("[5/5] Refreshing Materialized OLAP Views for Sub-Second BI Querying...")
        with conn.cursor() as cur:
            cur.execute("REFRESH MATERIALIZED VIEW mat_monthly_sales_summary;")
        conn.commit()

        print("\n================================================================================")
        print("  [✓] POSTGRESQL DATA WAREHOUSE INGESTION COMPLETED SUCCESSFULLY!              ")
        print("================================================================================\n")

    finally:
        conn.close()


if __name__ == "__main__":
    run_full_postgres_etl()
