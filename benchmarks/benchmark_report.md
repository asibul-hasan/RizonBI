# Empirical Evaluation and Benchmark Report
**Author:** S M HOSNEY ARAFAT RIZON (ID: K2554665)  
**Programme:** MSc Information Systems | **Module:** Project Dissertation CI7000  
**Supervisor:** Dr. Islam Choudhury  
**Date of Evaluation:** Mon Aug 24 2026  

---

## 1. Executive Summary & SLA Verification Matrix

| SMART Objective | Performance SLA Target | Empirical System Result | Verification Status |
| :--- | :--- | :--- | :--- |
| **O2: Batch ETL Quality** | Process $\ge 500,000$ rows with $>99\%$ acceptance | **99.92% Row Acceptance Rate** | **✅ PASSED** |
| **O3: Streaming Latency** | Throughput $\ge 10,000$ msg/s, Latency $<2,000$ ms | **140.0 ms P95 Latency** | **✅ PASSED** |
| **O4: Analytical Query SLA** | 95th Percentile Query Response $<500$ ms | **22.42 ms Overall P95** | **✅ PASSED** |
| **O5: BI Decision Support** | Multi-domain Interactive Dashboards | **6 Multi-Domain BI Views** | **✅ PASSED** |

---

## 2. Analytical Query Latency Benchmarks (ms)

| Benchmark Query Name | Average (ms) | Median / P50 (ms) | P95 SLA (ms) | Target (<500ms) |
| :--- | :---: | :---: | :---: | :---: |
| `Q1_Executive_Revenue_Rollup` | 18.21 ms | 17.9 ms | 29.19 ms | ✅ **PASS** |
| `Q2_Regional_Category_DrillDown` | 17.19 ms | 16.66 ms | 19.55 ms | ✅ **PASS** |
| `Q3_Inventory_Stockout_Risk_Scan` | 0.11 ms | 0.09 ms | 0.15 ms | ✅ **PASS** |
| `Q4_Finance_Income_Statement` | 1.62 ms | 1.59 ms | 2.23 ms | ✅ **PASS** |

---

## 3. Data Governance & GDPR Article 25/32 Compliance
- **Pseudonymisation:** All customer names and emails were cryptographically hashed using SHA-256 with a unique enterprise salt.
- **PII Minimisation:** HR records were aggregated into monthly departmental workforce summaries, preventing individual employee surveillance.
- **Row-Level Security (RLS):** Role-based isolation ensures departmental access controls in the BI presentation layer.
