---
title: Rizon Enterprise BI Data Warehouse
emoji: 📊
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# Scalable Data Warehouse for Real-Time Business Intelligence and Decision Support

**Author:** S M HOSNEY ARAFAT RIZON (Student ID: K2554665)  
**Programme:** MSc Information Systems  
**Module:** Project Dissertation (CI7000)  
**Supervisor:** Dr. Islam Choudhury  
**Institution:** Kingston University London  

---

## 🎯 Executive Summary
This project provides a complete, scalable, and reproducible **Real-Time Data Warehouse and Business Intelligence (BI)** reference architecture specifically designed for Small and Medium Enterprises (SMEs).

Grounded in **Design Science Research (DSR)** and **Kimball Dimensional Modeling**, the platform features:
- **Multi-Domain Star Schemas:** Sales & Commercial, Inventory & Supply Chain, General Ledger Finance, and GDPR-Compliant HR Workforce.
- **Sub-Second Analytical Serving Layer:** Empirical query response time with overall 95th-percentile (P95) latency of **$15.63\text{ ms}$** (SLA target: $<500\text{ ms}$).
- **Real-Time Streaming Ingestion:** Low-latency event streaming achieving an average latency of **$73.1\text{ ms}$** (SLA target: $<2{,}000\text{ ms}$).
- **Automated Data Quality & Rejection Logging:** Built-in automated assertion suite enforcing a **$99.92\%$ row acceptance rate** (SLA target: $>99\%$).
- **Multi-Departmental BI Dashboard Portal:** Interactive decision support dashboards with Role-Based Access Control (RBAC) and Row-Level Security (RLS).
- **GDPR Privacy by Design (Articles 25 & 32):** Cryptographic SHA-256 pseudonymisation for customer identifiers and departmental aggregation for workforce privacy.

---

## 📁 Repository Structure

```
c:/pridesys/apps/rizon/
├── plan.md                                # Implementation plan and requirements map
├── README.md                              # This documentation manual
├── runner.js                              # Zero-dependency end-to-end execution engine
├── requirements.txt                       # Python dependencies
├── Dockerfile                             # Container build definition for BI tier
├── docker-compose.yml                     # Multi-container enterprise stack (Postgres, Kafka, BI)
├── warehouse/
│   └── schema.sql                         # Complete PostgreSQL / SQLite DDL schema & views
├── data_generator/
│   └── generator.py                       # Python synthetic batch & streaming generator
├── etl/
│   └── pipeline.py                        # Automated ELT pipeline with data quality assertions
├── streaming/
│   ├── producer.py                        # Streaming event producer with throughput benchmark
│   └── consumer.py                        # Streaming consumer with latency tracking
├── dashboard/
│   ├── index.html                         # Standalone interactive modern BI web portal
│   └── app.py                             # Multi-page Streamlit BI application
├── benchmarks/
│   ├── run_benchmark.py                   # Python automated latency benchmark runner
│   ├── benchmark_report.json              # Empirical benchmark results in JSON
│   └── benchmark_report.md                # Markdown evaluation report for Chapter 6
├── data/
│   ├── raw/                               # Raw synthetic CSV datasets (Sales, Inv, Fin, HR)
│   └── processed/                         # Processed and streaming buffer files
└── dissertation/                          # Full Academic Dissertation Chapters (CI7000)
    ├── 01_introduction.md                 # Chapter 1: Introduction & Background
    ├── 02_literature_review.md            # Chapter 2: Literature Review
    ├── 03_methodology.md                  # Chapter 3: Research Methodology (DSR)
    ├── 04_system_architecture_design.md   # Chapter 4: Architecture & Dimensional Design
    ├── 05_implementation_engineering.md  # Chapter 5: Implementation Details
    ├── 06_evaluation_results.md           # Chapter 6: Evaluation & Benchmarks
    ├── 07_discussion_reflection.md        # Chapter 7: Discussion & Reflection
    ├── 08_conclusion_future_work.md       # Chapter 8: Conclusion & Future Work
    └── references.md                      # Academic References (Harvard Style)
```

---

## 🚀 Quickstart: Run the Platform with PostgreSQL

### Option A: Aiven Cloud PostgreSQL Ingestion (Automated)
Run the automated deployment script to connect to your live Aiven Cloud database (`rizondw`), deploy the schemas, load all 4 domain datasets, and execute automated data quality tests:

**Using PowerShell:**
```powershell
.\etl\deploy_to_aiven.ps1
```

**Using Python:**
```bash
python etl/load_postgres.py
```

### Option B: Execute SQL Directly on Aiven Cloud via `psql`
```bash
# Set connection URI
$AIVEN_URI="postgres://avnadmin:YOUR_PASSWORD@aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com:12656/rizondw?sslmode=require"

# 1. Apply Schema & Views
psql $AIVEN_URI -f warehouse/schema.sql

# 2. Populate Date Dimensions & Data Quality Function
psql $AIVEN_URI -f warehouse/load_postgres.sql

# 3. Run Analytical Performance Benchmarks (EXPLAIN ANALYZE)
psql $AIVEN_URI -f benchmarks/benchmark_queries.sql
```

### Option C: Deploy to Hugging Face Spaces (via GitHub & Docker)
You can host this live BI Data Warehouse platform 24/7 on **Hugging Face Spaces for FREE**:

1. **Push this repository to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: MSc CI7000 Data Warehouse BI Portal"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   git push -u origin main
   ```
2. **Create a Hugging Face Space**:
   * Go to [huggingface.co/new-space](https://huggingface.co/new-space).
   * **Space Name:** `rizon-bi-datawarehouse`
   * **License:** `MIT`
   * **SDK:** Select **Docker** (Blank / from GitHub repo).
   * **Visibility:** Public (or Private).
3. **Configure Database Secret (Environment Variable)**:
   * In your Hugging Face Space **Settings** $\rightarrow$ **Variables and secrets** $\rightarrow$ **New secret**:
     * **Name:** `DATABASE_URL`
     * **Value:** `postgres://avnadmin:YOUR_PASSWORD@aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com:12656/rizondw?sslmode=require`
4. **Build & Launch**:
   * Hugging Face will automatically build the `Dockerfile`, install `postgresql-client`, expose port `7860`, and serve the live dashboard at `https://huggingface.co/spaces/YOUR_USERNAME/rizon-bi-datawarehouse`!

---

### Option D: Local Interactive BI Dashboard
Open [`dashboard/index.html`](file:///c:/pridesys/apps/rizon/dashboard/index.html) directly in any web browser or visit [`http://localhost:3000`](http://localhost:3000) when running `node server.js`.
```bash
pip install -r requirements.txt
streamlit run dashboard/app.py
```

---

## 📊 Empirical Benchmark Results & SLA Verification

| Research Objective | Stated SLA Target | Empirical System Measurement | Evaluation Status |
| :--- | :--- | :--- | :---: |
| **O2: Batch ETL Quality** | Process $\ge 500{,}000$ rows with $>99\%$ acceptance | **99.92% Row Acceptance Rate** | **✅ PASSED** |
| **O3: Streaming Latency** | Throughput $\ge 10{,}000$ msg/s, Latency $<2{,}000$ ms | **P95 Latency: 143.0 ms** (Avg: 73.1 ms) | **✅ PASSED** |
| **O4: Analytical Query SLA** | 95th Percentile Query Latency $< 500$ ms | **Overall P95: 15.63 ms** | **✅ PASSED** |
| **O5: Multi-Domain BI Views** | Multi-domain interactive decision support | **6 Interactive BI Views** with RBAC | **✅ PASSED** |

---

## 🎓 Academic Dissertation Deliverable (Module CI7000)
The complete academic dissertation write-up conforming to the Kingston University MSc Information Systems specifications is organized across the 8 dedicated chapters in the [`dissertation/`](file:///c:/pridesys/apps/rizon/dissertation/) directory.
