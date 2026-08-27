# Chapter 1: Introduction and Research Background

**Author:** S M HOSNEY ARAFAT RIZON (Student ID: K2554665)  
**Programme:** MSc Information Systems  
**Module:** Project Dissertation (CI7000)  
**Supervisor:** Dr. Islam Choudhury  
**Institution:** Kingston University London  

---

## 1.1 Motivation and Industrial Context
In the modern digital economy, data-driven decision-making has emerged as an indispensable competitive differentiator. Empirical research conducted by the McKinsey Global Institute (2021) establishes that organizations leveraging deep analytical capabilities are 23 times more likely to acquire customers and six times more likely to retain them relative to their non-analytical counterparts. Despite the proliferation of modern data infrastructure, Small and Medium Enterprises (SMEs) face disproportionate operational hurdles when attempting to transition from batch-oriented reporting paradigms to low-latency, real-time analytical ecosystems.

Many SMEs continue to rely on fragmented spreadsheets and manual export routines. These methods are inherently vulnerable to human error, exhibit poor horizontal scalability, and cannot provide the sub-minute analytical insights required to navigate dynamic, volatile market conditions. While cloud computing and open-source data engineering tools have theoretically democratized data warehousing, integrating disparate source systems, enforcing automated data quality, maintaining sub-second query latency, and ensuring strict General Data Protection Regulation (GDPR) compliance remain major engineering challenges under constrained operational budgets.

---

## 1.2 Research Problem Statement
Enterprise data generation is experiencing exponential growth, transitioning from periodic transactional batches to continuous, high-velocity event streams. However, contemporary data warehouse reference architectures are predominantly optimized for large enterprises with substantial capital and engineering resources.

The core research problem investigated in this dissertation is:
> *How can an open-source, cloud-ready Data Warehouse architecture be designed and implemented to provide real-time Business Intelligence (BI) and sub-second decision support for SMEs without incurring prohibitive licensing costs or operational complexity?*

---

## 1.3 Stakeholders and Practical Benefits
The artifacts and empirical findings produced in this research directly benefit several key stakeholder groups:
1. **Operational Managers & Business Analysts:** Gain access to real-time, interactive Key Performance Indicator (KPI) dashboards that eliminate information asymmetry across sales, inventory, finance, and human resources.
2. **Data Engineers & IT Administrators:** Benefit from a containerized, Infrastructure-as-Code (IaC) deployment pipeline that automates data validation, minimizes manual intervention, and enforces version-controlled transformations.
3. **Executive Leadership:** Receive consolidated, cross-departmental executive views supporting agile strategic planning and predictive resource allocation.
4. **Academic & Research Community:** Acquire an open, reproducible reference architecture grounded in Design Science Research (DSR) that integrates streaming ingestion, Kimball dimensional modeling, and GDPR privacy-by-design principles.

---

## 1.4 Project Aims and SMART Objectives

### Overall Aim
To design, implement, and empirically evaluate a scalable, open-source data warehouse architecture capable of ingesting, transforming, validating, and serving real-time business intelligence data for SME decision support.

### SMART Research Objectives
* **O1 — Requirements Analysis & Dimensional Modeling:** Elicit functional and non-functional requirements from four representative SME business domains (Sales, Inventory, Finance, HR) and construct a validated Kimball Star Schema.
* **O2 — Automated Ingestion & Quality Assurance:** Implement an automated ELT/ETL pipeline capable of processing batch transactions with an automated data quality framework enforcing a **$>99\%$ row acceptance rate**.
* **O3 — Real-Time Streaming Integration:** Deploy an event streaming topology capable of sustaining throughput ($\ge 10{,}000\text{ msgs/s}$) with an end-to-end ingestion latency **$< 2\text{ seconds}$**.
* **O4 — High-Performance OLAP Serving Layer:** Configure a columnar OLAP analytical layer serving complex multidimensional queries with a 95th-percentile (P95) response time **$< 500\text{ ms}$**.
* **O5 — Interactive Multi-Domain BI Dashboards:** Deliver interactive, responsive BI dashboards with role-based access control (RBAC) and row-level security (RLS).
* **O6 — Empirical Benchmarking & Security Evaluation:** Conduct rigorous performance benchmarking, SLA validation, and GDPR compliance audits.
* **O7 — Academic Dissertation Synthesis:** Document the theoretical framework, design decisions, empirical results, and critical reflection in a structured dissertation conforming to Kingston University CI7000 standards.

---

## 1.5 Structure of the Dissertation
The remainder of this dissertation is organized as follows:
* **Chapter 2 (Literature Review):** Critically examines data warehouse paradigms (Kimball vs. Inmon), streaming architectures (Lambda vs. Kappa), columnar OLAP engines, BI tools, and data governance.
* **Chapter 3 (Methodology):** Outlines the Design Science Research (DSR) methodology, experimental setups, and ethical considerations.
* **Chapter 4 (System Architecture & Design):** Details the conceptual, logical, and physical data models, streaming topologies, and security mechanisms.
* **Chapter 5 (Implementation & Engineering):** Documents the end-to-end technical implementation across all platform tiers.
* **Chapter 6 (Evaluation & Results):** Analyzes empirical benchmarks, query latency percentiles, throughput metrics, and SLA compliance.
* **Chapter 7 (Discussion & Reflection):** Critically discusses architectural trade-offs, cost-benefit implications for SMEs, and system limitations.
* **Chapter 8 (Conclusion & Future Work):** Summarizes research contributions, practical recommendations, and future research trajectories.
