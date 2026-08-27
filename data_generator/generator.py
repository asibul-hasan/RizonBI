"""
Synthetic Data Generator for SME Enterprise Data Warehouse & BI Platform
Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
Module: CI7000 - MSc Information Systems Dissertation
Supervisor: Dr. Islam Choudhury

Covers 4 Key Domains:
1. Sales & Orders
2. Inventory & Supply Chain
3. Finance & Accounting
4. Human Resources (GDPR Anonymised)
"""

import os
import csv
import json
import time
import uuid
import random
import hashlib
from datetime import datetime, timedelta

# Deterministic seed for academic reproducibility
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# GDPR Salt for pseudonymisation
GDPR_SALT = "msc_ci7000_gdpr_salt_2026"

# Domain Reference Lists
REGIONS = ["London", "Manchester", "Birmingham", "Leeds", "Glasgow", "Bristol", "Edinburgh"]
CHANNELS = ["E-Commerce Web", "Mobile App", "Direct B2B", "Retail Partner"]
PAYMENT_METHODS = ["Credit Card", "Bank Transfer", "Direct Debit", "Corporate Credit"]
ORDER_STATUSES = ["Completed", "Completed", "Completed", "Shipped", "Pending", "Cancelled"]

PRODUCT_CATEGORIES = {
    "Cloud Software": [
        ("SaaS Enterprise License", 1200.0, 150.0),
        ("SaaS Pro Seat", 450.0, 50.0),
        ("Analytics API Add-on", 300.0, 30.0),
        ("Cloud Storage Tier 1", 150.0, 20.0),
    ],
    "Hardware & Devices": [
        ("Edge IoT Gateway", 650.0, 380.0),
        ("Enterprise Router v4", 890.0, 520.0),
        ("Workstation Monitor 4K", 320.0, 190.0),
        ("Secure RFID Scanner", 210.0, 110.0),
    ],
    "Professional Services": [
        ("Data Migration Consultation", 2500.0, 800.0),
        ("BI Architecture Implementation", 4500.0, 1500.0),
        ("Annual Maintenance SLA", 1800.0, 400.0),
        ("Cybersecurity Audit", 3200.0, 1000.0),
    ],
    "Office & Infrastructure": [
        ("Ergonomic Desk Unit", 420.0, 210.0),
        ("Server Rack 42U", 1150.0, 680.0),
        ("UPS Backup Unit 3kVA", 780.0, 430.0),
        ("Network Patch Cable Box", 65.0, 25.0),
    ]
}

DEPARTMENTS = ["Sales & Marketing", "Engineering & IT", "Finance & Legal", "Operations & Supply", "Human Resources"]
JOB_ROLES = {
    "Sales & Marketing": [("Account Executive", 38000, 55000), ("Sales Director", 75000, 110000), ("Marketing Specialist", 32000, 48000)],
    "Engineering & IT": [("Data Engineer", 45000, 75000), ("Software Developer", 40000, 70000), ("DevOps Specialist", 50000, 85000), ("IT Support", 26000, 38000)],
    "Finance & Legal": [("Financial Analyst", 36000, 55000), ("Senior Accountant", 48000, 72000), ("Compliance Officer", 42000, 65000)],
    "Operations & Supply": [("Supply Chain Manager", 45000, 68000), ("Warehouse Lead", 28000, 40000), ("Logistics Coordinator", 26000, 37000)],
    "Human Resources": [("HR Generalist", 30000, 46000), ("Talent Partner", 35000, 52000), ("HR Director", 70000, 98000)]
}

GL_ACCOUNTS = [
    ("REV-100", "Operating Revenue", "Revenue"),
    ("REV-200", "Services Revenue", "Revenue"),
    ("COGS-100", "Direct Material Costs", "COGS"),
    ("COGS-200", "Third-Party Infrastructure", "COGS"),
    ("OPEX-100", "Salaries & Payroll", "Expense"),
    ("OPEX-200", "Office Lease & Utilities", "Expense"),
    ("OPEX-300", "Marketing & Advertising", "Expense"),
    ("OPEX-400", "Software Subscriptions & Cloud", "Expense"),
    ("TAX-100", "Corporate & VAT Tax", "Tax")
]


def pseudonymise_text(raw_text: str) -> str:
    """GDPR Article 32 & 25 compliant SHA-256 pseudonymisation with cryptographic salt."""
    salted = f"{raw_text}_{GDPR_SALT}".encode("utf-8")
    return hashlib.sha256(salted).hexdigest()[:16]


class SMEDataGenerator:
    """High-performance synthetic generator for batch and streaming data pipelines."""

    def __init__(self, start_date: datetime = None, end_date: datetime = None):
        self.end_date = end_date or datetime.now()
        self.start_date = start_date or (self.end_date - timedelta(days=365 * 2))
        self.products = self._init_products()
        self.customers = self._init_customers(count=500)
        self.employees = self._init_employees(count=120)
        self.suppliers = self._init_suppliers(count=35)

    def _init_products(self):
        products = []
        p_id = 1
        for category, items in PRODUCT_CATEGORIES.items():
            for name, price, cost in items:
                products.append({
                    "product_id": p_id,
                    "product_sku": f"SKU-{category[:3].upper()}-{p_id:04d}",
                    "product_name": name,
                    "category": category,
                    "unit_price": price,
                    "unit_cost": cost,
                    "reorder_level": random.randint(15, 50),
                    "lead_time_days": random.randint(3, 14)
                })
                p_id += 1
        return products

    def _init_customers(self, count=500):
        customers = []
        for i in range(1, count + 1):
            raw_name = f"Enterprise_Client_{i:04d}"
            raw_email = f"client{i:04d}@domain-corp.co.uk"
            customers.append({
                "customer_id": i,
                "customer_code": f"CUST-{i:05d}",
                "pseudonymised_name": f"Client_Hash_{pseudonymise_text(raw_name)}",
                "pseudonymised_email": f"usr_{pseudonymise_text(raw_email)}@anon.sme",
                "region": random.choice(REGIONS),
                "customer_tier": random.choices(["Standard", "Silver", "Gold", "Platinum"], weights=[50, 30, 15, 5])[0],
                "created_at": (self.start_date + timedelta(days=random.randint(0, 300))).strftime("%Y-%m-%d %H:%M:%S")
            })
        return customers

    def _init_employees(self, count=120):
        employees = []
        for i in range(1, count + 1):
            dept = random.choice(DEPARTMENTS)
            role, min_sal, max_sal = random.choice(JOB_ROLES[dept])
            raw_emp_name = f"Employee_{i:03d}"
            employees.append({
                "employee_id": i,
                "employee_code": f"EMP-{i:04d}",
                "masked_name": f"Staff_{pseudonymise_text(raw_emp_name)}",
                "department": dept,
                "role": role,
                "salary": round(random.uniform(min_sal, max_sal), 2),
                "hire_date": (self.start_date + timedelta(days=random.randint(0, 500))).strftime("%Y-%m-%d"),
                "performance_score": round(random.uniform(3.0, 5.0), 1),
                "is_active": 1 if random.random() > 0.08 else 0
            })
        return employees

    def _init_suppliers(self, count=35):
        suppliers = []
        for i in range(1, count + 1):
            suppliers.append({
                "supplier_id": i,
                "supplier_code": f"SUP-{i:03d}",
                "supplier_name": f"Supplier Partner {i:02d} Ltd",
                "country": random.choice(["United Kingdom", "Germany", "Netherlands", "Ireland", "France"]),
                "rating": round(random.uniform(3.8, 5.0), 1),
                "payment_terms_days": random.choice([15, 30, 45, 60])
            })
        return suppliers

    def generate_sales_batch(self, num_orders: int = 50000) -> list:
        """Generates realistic sales transactions with line-item detail."""
        sales_records = []
        total_time_span = int((self.end_date - self.start_date).total_seconds())

        for order_id in range(1, num_orders + 1):
            rand_sec = random.randint(0, total_time_span)
            order_dt = self.start_date + timedelta(seconds=rand_sec)
            customer = random.choice(self.customers)
            product = random.choice(self.products)
            quantity = random.choices([1, 2, 3, 5, 10, 20], weights=[45, 25, 15, 8, 5, 2])[0]
            discount_pct = random.choices([0.0, 0.05, 0.10, 0.15, 0.20], weights=[60, 20, 10, 7, 3])[0]
            
            gross_amount = round(product["unit_price"] * quantity, 2)
            discount_amount = round(gross_amount * discount_pct, 2)
            net_amount = round(gross_amount - discount_amount, 2)
            cost_amount = round(product["unit_cost"] * quantity, 2)
            margin_amount = round(net_amount - cost_amount, 2)
            status = random.choice(ORDER_STATUSES)

            sales_records.append({
                "order_id": order_id,
                "order_number": f"ORD-{order_dt.year}-{order_id:07d}",
                "order_timestamp": order_dt.strftime("%Y-%m-%d %H:%M:%S"),
                "date_key": int(order_dt.strftime("%Y%m%d")),
                "customer_id": customer["customer_id"],
                "product_id": product["product_id"],
                "region": customer["region"],
                "channel": random.choice(CHANNELS),
                "payment_method": random.choice(PAYMENT_METHODS),
                "quantity": quantity,
                "unit_price": product["unit_price"],
                "unit_cost": product["unit_cost"],
                "gross_amount": gross_amount,
                "discount_amount": discount_amount,
                "net_amount": net_amount,
                "margin_amount": margin_amount,
                "status": status
            })
        return sales_records

    def generate_inventory_snapshots(self, days: int = 180) -> list:
        """Generates daily stock levels and inventory movements."""
        inventory_records = []
        curr_dt = self.end_date - timedelta(days=days)
        record_id = 1

        for day in range(days):
            curr_date_str = curr_dt.strftime("%Y-%m-%d")
            date_key = int(curr_dt.strftime("%Y%m%d"))
            for prod in self.products:
                stock_on_hand = random.randint(10, 200)
                reorder_level = prod["reorder_level"]
                stockout_risk = 1 if stock_on_hand <= reorder_level else 0
                supplier = random.choice(self.suppliers)
                inventory_value = round(stock_on_hand * prod["unit_cost"], 2)

                inventory_records.append({
                    "snapshot_id": record_id,
                    "date": curr_date_str,
                    "date_key": date_key,
                    "product_id": prod["product_id"],
                    "supplier_id": supplier["supplier_id"],
                    "stock_on_hand": stock_on_hand,
                    "reorder_level": reorder_level,
                    "stockout_risk": stockout_risk,
                    "unit_cost": prod["unit_cost"],
                    "inventory_value": inventory_value
                })
                record_id += 1
            curr_dt += timedelta(days=1)
        return inventory_records

    def generate_financial_postings(self, num_records: int = 10000) -> list:
        """Generates general ledger journal entries and postings."""
        finance_records = []
        total_time_span = int((self.end_date - self.start_date).total_seconds())

        for entry_id in range(1, num_records + 1):
            rand_sec = random.randint(0, total_time_span)
            entry_dt = self.start_date + timedelta(seconds=rand_sec)
            acc_code, acc_name, acc_type = random.choice(GL_ACCOUNTS)
            
            if acc_type == "Revenue":
                amount = round(random.uniform(500, 15000), 2)
                entry_type = "Credit"
            elif acc_type == "COGS":
                amount = round(random.uniform(200, 8000), 2)
                entry_type = "Debit"
            elif acc_type == "Expense":
                amount = round(random.uniform(100, 5000), 2)
                entry_type = "Debit"
            else:
                amount = round(random.uniform(50, 2000), 2)
                entry_type = "Debit"

            finance_records.append({
                "posting_id": entry_id,
                "posting_date": entry_dt.strftime("%Y-%m-%d"),
                "date_key": int(entry_dt.strftime("%Y%m%d")),
                "account_code": acc_code,
                "account_name": acc_name,
                "account_type": acc_type,
                "entry_type": entry_type,
                "amount": amount,
                "currency": "GBP",
                "reference": f"GL-{entry_dt.year}-{entry_id:06d}"
            })
        return finance_records

    def generate_hr_metrics(self) -> list:
        """Generates monthly workforce snapshots and training records."""
        hr_records = []
        record_id = 1
        curr_dt = self.start_date

        while curr_dt <= self.end_date:
            month_str = curr_dt.strftime("%Y-%m")
            date_key = int(curr_dt.strftime("%Y%m%d"))
            for dept in DEPARTMENTS:
                dept_emps = [e for e in self.employees if e["department"] == dept and e["is_active"] == 1]
                headcount = len(dept_emps)
                # Developer note: Safeguard against zero-headcount division for newly formed departments
                avg_salary = round(sum(e["salary"] for e in dept_emps) / max(headcount, 1), 2)
                avg_perf = round(sum(e["performance_score"] for e in dept_emps) / max(headcount, 1), 2)
                training_hours = round(random.uniform(15, 60) * headcount, 1)
                turnover_rate = round(random.uniform(0.01, 0.05), 3)

                hr_records.append({
                    "hr_metric_id": record_id,
                    "month": month_str,
                    "date_key": date_key,
                    "department": dept,
                    "headcount": headcount,
                    "avg_salary": avg_salary,
                    "avg_performance_score": avg_perf,
                    "total_training_hours": training_hours,
                    "turnover_rate": turnover_rate
                })
                record_id += 1
            
            # Month transition handling: rollover year on December to avoid invalid 13th month
            next_month = curr_dt.month + 1 if curr_dt.month < 12 else 1
            next_year = curr_dt.year if curr_dt.month < 12 else curr_dt.year + 1
            curr_dt = curr_dt.replace(year=next_year, month=next_month, day=1)

        return hr_records

    def export_all_to_csv(self, output_dir: str = "data/raw", sales_count: int = 50000):
        """Exports all 4 domain datasets and dimension tables to CSV files."""
        os.makedirs(output_dir, exist_ok=True)
        print(f"[+] Generating synthetic SME datasets (Sales: {sales_count} rows)...")

        datasets = {
            "dim_products.csv": self.products,
            "dim_customers.csv": self.customers,
            "dim_employees.csv": self.employees,
            "dim_suppliers.csv": self.suppliers,
            "raw_sales_orders.csv": self.generate_sales_batch(num_orders=sales_count),
            "raw_inventory_snapshots.csv": self.generate_inventory_snapshots(days=180),
            "raw_finance_postings.csv": self.generate_financial_postings(num_records=10000),
            "raw_hr_workforce.csv": self.generate_hr_metrics()
        }

        for filename, data in datasets.items():
            filepath = os.path.join(output_dir, filename)
            if not data:
                continue
            keys = data[0].keys()
            with open(filepath, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=keys)
                writer.writeheader()
                writer.writerows(data)
            print(f"    -> Exported {len(data)} rows to {filepath}")

        print("[✓] All raw synthetic datasets generated successfully.")

    def stream_sales_events(self, events_per_second: int = 50, duration_seconds: int = 10):
        """Yields continuous real-time sales event stream for Kafka / stream ingestion."""
        end_time = time.time() + duration_seconds
        event_counter = 1
        sleep_interval = 1.0 / max(events_per_second, 1)

        while time.time() < end_time:
            now = datetime.now()
            cust = random.choice(self.customers)
            prod = random.choice(self.products)
            qty = random.choices([1, 2, 3, 5], weights=[60, 25, 10, 5])[0]
            gross = round(prod["unit_price"] * qty, 2)
            cost = round(prod["unit_cost"] * qty, 2)

            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "ORDER_CREATED",
                "timestamp": now.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3],
                "epoch_ms": int(now.timestamp() * 1000),
                "customer_id": cust["customer_id"],
                "product_id": prod["product_id"],
                "region": cust["region"],
                "quantity": qty,
                "unit_price": prod["unit_price"],
                "gross_amount": gross,
                "margin_amount": round(gross - cost, 2),
                "status": "Completed"
            }
            yield event
            event_counter += 1
            time.sleep(sleep_interval)


if __name__ == "__main__":
    generator = SMEDataGenerator()
    generator.export_all_to_csv("data/raw", sales_count=25000)
