# Chapter 8: Conclusion and Future Work

**Author:** S M HOSNEY ARAFAT RIZON (Student ID: K2554665)  
**Programme:** MSc Information Systems  
**Module:** Project Dissertation (CI7000)  
**Supervisor:** Dr. Islam Choudhury  

---

## 8.1 Summary of Contributions
This dissertation successfully addressed the real-time business intelligence and data warehousing challenges faced by Small and Medium Enterprises (SMEs). The key contributions include:
1. **Reference Architecture:** Designed and implemented a scalable, open-source data warehouse architecture integrating streaming ingestion, Kimball dimensional modeling, automated data quality testing, and interactive BI dashboards.
2. **Empirical Validation:** Demonstrated that all analytical queries execute well within the **$<500\text{ ms}$ SLA target** (overall P95: $15.63\text{ ms}$) and real-time event streaming operates with **$<150\text{ ms}$ end-to-end latency** (SLA: $<2{,}000\text{ ms}$).
3. **Data Quality & Privacy-by-Design:** Enforced a **$99.92\%$ row acceptance rate** and implemented GDPR Article 25/32 compliant pseudonymisation and aggregation controls.
4. **Reproducible Open Artifact:** Provided a containerized, zero-dependency codebase with automated execution scripts and documentation.

---

## 8.2 Fulfillment of SMART Objectives

| Objective | Target Criteria | Outcome | Assessment |
| :--- | :--- | :--- | :---: |
| **O1** | Requirements & Dimensional Modeling across 4 domains | Complete Star Schema DDL (`schema.sql`) | **Met** |
| **O2** | Automated ETL with $>99\%$ row acceptance rate | Automated ETL with 99.92% acceptance rate | **Met** |
| **O3** | Streaming ingestion throughput & $<2\text{s}$ latency | P95 Latency 143.0 ms | **Met** |
| **O4** | OLAP query serving with P95 latency $<500\text{ms}$ | P95 Latency 15.63 ms | **Met** |
| **O5** | Multi-domain interactive BI dashboards with RBAC | 6 Responsive BI views with RBAC | **Met** |
| **O6** | Performance benchmarking & GDPR audit | Complete benchmark report & GDPR analysis | **Met** |
| **O7** | Complete academic dissertation document | Full 8-chapter dissertation structured to CI7000 | **Met** |

---

## 8.3 Recommendations for SME Practitioners
1. **Adopt Conformed Dimensional Modeling:** Prioritize Kimball star schemas to minimize query complexity and accelerate BI response times.
2. **Implement Automated Ingestion Testing:** Enforce data quality assertions early in the ELT pipeline to prevent dirty data propagation.
3. **Embed Privacy by Design:** Apply cryptographic pseudonymisation at the ingestion stage to ensure GDPR accountability.

---

## 8.4 Future Research Directions
1. **AI / LLM Natural Language Query Interfaces:** Integrating Retrieval-Augmented Generation (RAG) and Text-to-SQL agents allowing non-technical managers to query the dimensional warehouse using natural language.
2. **Predictive Analytics & Machine Learning Integration:** Incorporating time-series forecasting models (e.g., Prophet, ARIMA) directly into the BI layer for automated inventory reorder predictions and sales forecasting.
3. **Automated Anomaly Detection on Event Streams:** Applying unsupervised machine learning models to streaming Kafka topics for real-time financial fraud detection and supply chain disruption warnings.
