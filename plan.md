# Implementation Plan: Scalable Real-Time Data Warehouse for Business Intelligence

**Student:** S M HOSNEY ARAFAT RIZON (ID: K2554665)  
**Programme:** MSc Information Systems | **Module:** Project Dissertation CI7000  
**Supervisor:** Dr. Islam Choudhury  

---

## Objective
Build a straightforward, scalable, and fully functional Data Warehouse and Real-Time Business Intelligence prototype meeting all SMART objectives of the dissertation proposal without over-engineering.

---

## Step-by-Step Execution Plan

### Step 1: Environment & Infrastructure Configuration
- Create project directory structure.
- Define `docker-compose.yml` for the complete enterprise stack (PostgreSQL 16, Apache Kafka, Apache Superset / BI, Apache Airflow / Orchestration).
- Define Python dependencies (`requirements.txt`) including `faker`, `psycopg2-binary`, `duckdb`, `pandas`, `streamlit`, `plotly`, `pytest`.

### Step 2: Synthetic Data Generator (Batch & Streaming)
- Create `data_generator/generator.py`:
  - Generates realistic SME dataset covering 4 domains: **Sales**, **Inventory**, **Finance**, and **HR**.
  - Supports deterministic generation of batch data (CSV/JSON/SQL).
  - Supports streaming event generation with configurable throughput for Kafka / real-time ingestion.

### Step 3: Dimensional Data Warehouse Schemas (PostgreSQL & DuckDB)
- Create `warehouse/schema.sql`:
  - **Staging Schema:** `stg_sales`, `stg_inventory`, `stg_finance`, `stg_hr`.
  - **Star Schema Dimensions:** `dim_date`, `dim_customer` (GDPR pseudonymised), `dim_product`, `dim_supplier`, `dim_employee` (masked PII), `dim_account`.
  - **Star Schema Facts:** `fact_sales`, `fact_inventory`, `fact_financial_transactions`, `fact_hr_workforce`.
  - Views for business KPIs and GDPR compliance (data masking & right to erasure).

### Step 4: Robust & Simple ETL / ELT Pipeline
- Create `etl/pipeline.py`:
  - Automated extraction from raw/staging sources.
  - Data cleaning, surrogate key lookup, and dimensional transformations.
  - Built-in data quality checks (null checks, referential integrity, acceptance rate >99%).
  - Detailed execution logging and error handling.

### Step 5: Real-Time Event Streaming & Ingestion Layer
- Create `streaming/producer.py` and `streaming/consumer.py`:
  - Simulates high-throughput event streaming (Sales, Stock movements).
  - Micro-batch and real-time ingestion into the analytics serving layer.
  - Latency measurement (< 2 seconds end-to-end).

### Step 6: Interactive Business Intelligence Dashboard
- Create `dashboard/app.py` (Streamlit-based responsive BI web application + Superset connector):
  - **Executive Overview Dashboard**: High-level cross-departmental KPIs.
  - **Sales & Customer Analytics Dashboard**: Revenue, regional trends, top products.
  - **Inventory & Supply Chain Dashboard**: Stock levels, stockout alerts, reorder levels.
  - **Finance & Accounting Dashboard**: P&L, cash flow, expense breakdowns.
  - **HR & Workforce Dashboard**: Headcount, retention, training (GDPR anonymised aggregate).
  - **System Health & Pipeline Latency Dashboard**: Real-time ETL latency, data quality rates.
  - Role-Based Access Control (RBAC) simulation.

### Step 7: Automated Benchmarking & Performance Evaluation Suite
- Create `benchmarks/run_benchmark.py`:
  - Query latency benchmarks (P50, P90, P95, P99) comparing standard relational queries vs. optimized columnar OLAP queries.
  - Throughput benchmarks for streaming and batch ETL.
  - Generates benchmark report and charts for Chapter 6 of the dissertation.

### Step 8: Academic Dissertation Structure & Documentation
- Scaffold complete dissertation chapters in `dissertation/`:
  - `01_introduction.md`
  - `02_literature_review.md`
  - `03_methodology.md`
  - `04_system_architecture_design.md`
  - `05_implementation_engineering.md`
  - `06_evaluation_results.md`
  - `07_discussion_reflection.md`
  - `08_conclusion_future_work.md`
  - `references.md`
- Provide `README.md` with 1-click run instructions.
