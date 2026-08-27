# Chapter 7: Discussion, Economic Analysis, and Critical Reflection

**Author:** S M HOSNEY ARAFAT RIZON (Student ID: K2554665)  
**Programme:** MSc Information Systems  
**Module:** Project Dissertation (CI7000)  
**Supervisor:** Dr. Islam Choudhury  

---

## 7.1 Interpretation of Empirical Findings in Relation to Literature

### 7.1.1 Dimensional Modeling vs. Normalized Architectures
The empirical findings from Chapter 6 validate the foundational assertions of Kimball and Ross (2013). By transforming raw staging data into a conformed star schema with pre-computed integer surrogate keys (`dim_date`, `dim_product`, `dim_customer`), query latency decreased by **$2.3\times$ to $50\times$** compared to normalized, on-the-fly timestamp extractions. Pre-aggregated materialized views (`mat_monthly_sales_summary`) further accelerated execution by **up to $79.7\times$**, reducing buffer memory consumption from 653 shared hits to just 16 hits.

### 7.1.2 Real-Time Event Streaming & Ingestion Latency
The sustained throughput ($\ge 10{,}000\text{ msgs/s}$) with an average ingestion latency of **$73.5\text{ ms}$** supports Kreps' (2014) principles regarding the viability of streaming primitives for operational BI. This disproves the traditional assumption that sub-second operational BI requires complex dual-codebase Lambda architectures (Marz & Warren, 2015).

---

## 7.2 Total Cost of Ownership (TCO) & SME Economic Analysis

A central research objective was demonstrating that enterprise-quality analytical decision support can be achieved without prohibitive licensing fees.

| Cost Component | Commercial Enterprise Stack (Snowflake + Power BI Premium + Fivetran) | Proposed Open-Source Stack (PostgreSQL 17 + Docker + Open BI) | Annual SME Cost Savings |
| :--- | :--- | :--- | :---: |
| **Data Warehouse Engine** | Snowflake Standard ($2.00 / credit): ~£7,200/year | Managed PostgreSQL (Aiven / AWS RDS): ~£720/year | **£6,480 (90% Savings)** |
| **BI Tool Licensing** | Power BI Premium ($20/user/mo for 25 users): £6,000/year | Open-Source BI Portal (Streamlit / Web): £0/year | **£6,000 (100% Savings)** |
| **ETL & Data Pipeline** | Fivetran / Stitch ($500/month): £6,000/year | Automated Python / dbt pipeline: £0/year | **£6,000 (100% Savings)** |
| **Total Annual Estimated TCO** | **~£19,200 / year** | **~£720 / year** | **~£18,480 / year (96.2% Reduction)** |

For Small and Medium Enterprises with constrained IT budgets, a **$96.2\%$ cost reduction** removes the financial barrier to adopting advanced real-time decision support systems.

---

## 7.3 Formal GDPR Data Protection Impact Assessment (DPIA)

In accordance with **Article 35 of the General Data Protection Regulation (GDPR, EU 2016/679)**, a systematic Data Protection Impact Assessment was conducted across the platform lifecycle:

| DPIA Assessment Stage | Identified Privacy Risk | Legal Basis / GDPR Article | Implemented Architectural Control | Residual Risk Level |
| :--- | :--- | :--- | :--- | :---: |
| **Data Ingestion** | Ingestion of direct customer identifiers (Names, Emails) | Art. 5(1)(c) — Data Minimisation | Cryptographic SHA-256 pseudonymisation with dynamic enterprise salt (`Client_Hash_...`) | **LOW** |
| **Workforce Reporting** | Employee surveillance via individual HR performance tracking | Art. 5(1)(b) — Purpose Limitation | Departmental aggregate rollup (`fact_hr_workforce`); suppression of individual staff identities | **LOW** |
| **Multi-Tenant Access** | Unauthorized cross-departmental data leakage | Art. 32 — Security of Processing | Role-Based Access Control (RBAC) & Row-Level Security (RLS) enforcement | **VERY LOW** |
| **Data Subject Rights** | Inability to process Right to be Forgotten requests | Art. 17 — Right to Erasure | Automated anonymisation stored procedure: `UPDATE dim_customer SET pseudonymised_name = 'ANONYMISED' WHERE customer_id = :id;` | **VERY LOW** |
| **Data in Transit / Rest** | Unencrypted interception over public networks | Art. 32(1)(a) — Cryptographic Encryption | TLS 1.3 encryption in transit (`sslmode=require`) and AES-256 storage volume encryption | **VERY LOW** |

---

## 7.4 Critical Evaluation of System Limitations
While the system successfully achieved all stated objectives, the following constraints should be acknowledged:
1. **Single-Node vs. Massively Parallel Processing (MPP):** For SME workloads ($<100\text{M}$ rows), single-node PostgreSQL with B-tree indexing and materialized views delivers sub-second response times. However, organizations operating at petabyte scales with billions of events would require distributed MPP engines (e.g., Apache Druid or ClickHouse clusters).
2. **Streaming Producer Simulation:** While the event generator deterministically replicates realistic multi-channel e-commerce patterns, production enterprise deployments require live Change Data Capture (CDC) connectors (e.g., Debezium) integrated with transactional ERP backends.
3. **Automated Cache Invalidation:** The current materialized views require periodic `REFRESH MATERIALIZED VIEW` commands; future iterations could incorporate incremental view maintenance extensions (pg_ivm).
