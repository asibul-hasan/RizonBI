# 📖 RizonDW Technical Data Dictionary

**Author:** S M HOSNEY ARAFAT RIZON (Student ID: K2554665)  
**Module:** CI7000 - MSc Information Systems Dissertation  
**Supervisor:** Dr. Islam Choudhury  
**Database:** Aiven Cloud PostgreSQL 17 (`rizondw`)

---

## 1. Conformed Dimension Tables

### `dim_date`
*Primary Key:* `date_key` (INTEGER, `YYYYMMDD`)  
*Granularity:* Single calendar day (2020-01-01 to 2030-12-31, 4,018 total rows).

| Column Name | Data Type | Nullable | Description |
| :--- | :--- | :---: | :--- |
| `date_key` | INT | NO | Surrogate key (e.g. `20240115`) |
| `full_date` | DATE | NO | Standard SQL date (`2024-01-15`) |
| `day_of_week` | INT | NO | 1 (Sunday) to 7 (Saturday) |
| `day_name` | VARCHAR(15) | NO | Monday, Tuesday, etc. |
| `day_of_month` | INT | NO | 1 to 31 |
| `month_number`| INT | NO | 1 to 12 |
| `month_name` | VARCHAR(15) | NO | January, February, etc. |
| `quarter` | INT | NO | 1 to 4 |
| `year` | INT | NO | 2020 to 2030 |
| `is_weekend` | INT | NO | 1 for Saturday/Sunday, 0 for weekday |

---

### `dim_customer`
*Primary Key:* `customer_sk` (SERIAL INT)  
*GDPR Classification:* Pseudonymised (Article 25 / 32).

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `customer_sk` | SERIAL | Surrogate primary key |
| `customer_id` | INT | Source operational ID (Unique) |
| `customer_code`| VARCHAR(50)| Business customer identifier (`CUST-00001`) |
| `pseudonymised_name` | VARCHAR(100) | Salted SHA-256 pseudonym (`Client_Hash_fc1ba68a594010f2`) |
| `pseudonymised_email` | VARCHAR(100) | Salted SHA-256 pseudonym (`usr_d820b1c724e25df1@anon.sme`) |
| `region` | VARCHAR(50) | London, Manchester, Birmingham, Leeds, Glasgow, Bristol |
| `customer_tier` | VARCHAR(20) | Platinum, Gold, Silver, Standard |

---

## 2. Core Fact Tables

### `fact_sales`
*Primary Key:* `sale_id` (SERIAL)  
*Granularity:* One record per line item in a customer sales transaction (30,000 production rows).

| Column Name | Data Type | Foreign Key / Reference |
| :--- | :--- | :--- |
| `sale_id` | SERIAL | Primary key |
| `order_id` | VARCHAR(50) | Degenerate order transaction ID |
| `date_key` | INT | `dim_date.date_key` |
| `customer_sk` | INT | `dim_customer.customer_sk` |
| `product_sk` | INT | `dim_product.product_sk` |
| `quantity` | INT | Ordered item quantity ($>0$) |
| `unit_price` | NUMERIC(12, 2)| Selling price per item |
| `gross_amount`| NUMERIC(12, 2)| Total gross value ($quantity \times unit\_price$) |
| `discount_amount` | NUMERIC(12, 2) | Discount applied |
| `net_amount` | NUMERIC(12, 2)| Net billed revenue |
| `cost_amount` | NUMERIC(12, 2)| Cost of goods sold ($quantity \times unit\_cost$) |
| `margin_amount` | NUMERIC(12, 2) | Gross margin ($net\_amount - cost\_amount$) |
| `region` | VARCHAR(50) | Geographical sales region |
| `channel` | VARCHAR(50) | E-Commerce Web, Mobile App, Direct B2B, Retail Partner |
| `status` | VARCHAR(20) | Completed, Shipped, Pending, Cancelled |

---

### `fact_financial_transactions`
*Primary Key:* `transaction_id` (SERIAL)  
*Granularity:* General Ledger accounting postings (10,000 rows).

| Column Name | Data Type | Foreign Key / Reference |
| :--- | :--- | :--- |
| `transaction_id` | SERIAL | Primary key |
| `posting_reference` | VARCHAR(50) | Journal entry reference |
| `date_key` | INT | `dim_date.date_key` |
| `account_sk` | INT | `dim_account.account_sk` |
| `debit_amount` | NUMERIC(14, 2) | Debit posting value |
| `credit_amount` | NUMERIC(14, 2) | Credit posting value |
| `net_posting_amount` | NUMERIC(14, 2) | Net posting ($debit - credit$) |
