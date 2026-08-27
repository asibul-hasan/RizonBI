# Chapter 5: Implementation and Engineering

**Author:** S M HOSNEY ARAFAT RIZON (Student ID: K2554665)  
**Programme:** MSc Information Systems  
**Module:** Project Dissertation (CI7000)  
**Supervisor:** Dr. Islam Choudhury  

---

## 5.1 Engineering Implementation Overview
The platform was engineered using a modular, decoupled structure:
1. **Data Generator Tier (`data_generator/generator.py`):** Produces deterministic synthetic transactional data with cryptographic pseudonymisation for GDPR compliance.
2. **Database & Schema Tier (`warehouse/schema.sql`):** Defines the complete relational staging layer, Kimball star schema, B-tree performance indexes, and analytical views.
3. **Automated ETL Pipeline (`etl/pipeline.py`):** Orchestrates data extraction, dimension conformance, surrogate key lookups, and automated data quality assertions.
4. **Real-Time Streaming Engine (`streaming/producer.py`, `streaming/consumer.py`):** Ingests streaming events with sub-second micro-batching and latency monitoring.
5. **Interactive BI Presentation Tier (`dashboard/app.py`, `dashboard/index.html`):** Renders responsive multi-departmental dashboards with RBAC filtering.
6. **Empirical Benchmarking Engine (`benchmarks/run_benchmark.py`, `runner.js`):** Measures query latency distributions (P50, P90, P95, P99) and exports empirical verification metrics.

---

## 5.2 Automated Data Quality and Governance Implementation
To enforce the $>99\%$ row acceptance SLA (Objective **O2**), the ETL pipeline implements automated validation rules:
* **Primary / Surrogate Key Uniqueness:** Verifies $\text{Count}(K) = \text{Count}(\text{Distinct } K)$.
* **Referential Integrity:** Verifies all foreign keys in fact records resolve to valid surrogate keys in conformed dimension tables.
* **Domain Range Constraints:** Asserts that unit prices, quantities, and gross amounts are strictly non-negative ($\text{value} > 0$).
* **Rejection Logging:** Invalid or corrupted records are automatically routed to an audit rejection log without halting the main pipeline execution.

---

## 5.3 Containerization and Infrastructure as Code
The platform provides a complete multi-container orchestration definition via `docker-compose.yml`:
* **PostgreSQL 16 Engine:** Provides relational persistence and staging buffering.
* **Apache Kafka (KRaft mode):** Handles high-throughput event streaming without ZooKeeper overhead.
* **Streamlit BI Container:** Hosts the responsive web application on port 8501.
