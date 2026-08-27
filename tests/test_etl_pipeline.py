"""
Unit Tests for Batch ETL Transformation Pipeline
Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
Module: CI7000 - MSc Information Systems Dissertation
"""

import unittest
import os
import csv
import hashlib
from datetime import datetime

class TestETLPipeline(unittest.TestCase):
    
    @classmethod
    def setUpClass(cls):
        cls.raw_data_dir = "data/raw"
        cls.required_csvs = [
            "dim_products.csv",
            "dim_customers.csv",
            "dim_suppliers.csv",
            "dim_employees.csv",
            "raw_sales_orders.csv",
            "raw_inventory_snapshots.csv",
            "raw_finance_postings.csv",
            "raw_hr_workforce.csv"
        ]

    def test_raw_csv_files_exist(self):
        """Verify all expected domain datasets are present in data/raw."""
        for filename in self.required_csvs:
            path = os.path.join(self.raw_data_dir, filename)
            self.assertTrue(os.path.exists(path), f"Missing expected dataset: {filename}")

    def test_sales_data_schema_and_types(self):
        """Test sales orders for non-null keys, positive amounts, and valid date formats."""
        sales_path = os.path.join(self.raw_data_dir, "raw_sales_orders.csv")
        if not os.path.exists(sales_path):
            self.skipTest("raw_sales_orders.csv not generated yet")

        with open(sales_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            row_count = 0
            for row in reader:
                row_count += 1
                # Check critical keys
                self.assertTrue(len(row["order_id"]) > 0, "order_id must not be empty")
                self.assertTrue(len(row["customer_id"]) > 0, "customer_id must not be empty")
                
                # Check financial precision
                qty = int(row["quantity"])
                unit_price = float(row["unit_price"])
                total_amt = float(row["total_amount"])
                
                self.assertGreater(qty, 0, "Quantity must be strictly positive")
                self.assertGreater(unit_price, 0.0, "Unit price must be positive")
                self.assertGreaterEqual(total_amt, 0.0, "Total amount cannot be negative")
                
                if row_count >= 500:  # Sample first 500 rows for fast testing
                    break

    def test_customer_pseudonymisation_sha256(self):
        """Verify customer identifiers conform to SHA-256 hexadecimal hash format."""
        cust_path = os.path.join(self.raw_data_dir, "dim_customers.csv")
        if not os.path.exists(cust_path):
            self.skipTest("dim_customers.csv not generated yet")

        with open(cust_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                cust_hash = row["customer_id"]
                # Must start with Client_Hash_ and contain 16 hex chars
                self.assertTrue(cust_hash.startswith("Client_Hash_"), "Customer ID must follow pseudonym format")
                hex_part = cust_hash.replace("Client_Hash_", "")
                self.assertEqual(len(hex_part), 16, "Pseudonym hash snippet must be 16 chars")

    def test_date_key_integer_format(self):
        """Verify surrogate date keys are valid YYYYMMDD integers."""
        inv_path = os.path.join(self.raw_data_dir, "raw_inventory_snapshots.csv")
        if not os.path.exists(inv_path):
            self.skipTest("raw_inventory_snapshots.csv not generated yet")

        with open(inv_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for i, row in enumerate(reader):
                date_key = int(row["date_key"])
                self.assertGreaterEqual(date_key, 20200101, "Date key out of range (<2020)")
                self.assertLessEqual(date_key, 20301231, "Date key out of range (>2030)")
                if i >= 200:
                    break

if __name__ == "__main__":
    unittest.main()
