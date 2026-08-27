"""
Real-Time Event Streaming Consumer & Ingestion Engine
Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
Module: CI7000 - MSc Information Systems Dissertation
Supervisor: Dr. Islam Choudhury

Consumes real-time streaming events, calculates end-to-end latency,
and loads them into the operational analytical serving layer.
"""

import os
import json
import time
import sqlite3
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("StreamingConsumer")


class RealTimeEventConsumer:
    """Consumes real-time events and updates serving layer."""

    def __init__(self, db_path: str = "warehouse/datawarehouse.db"):
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self.conn = sqlite3.connect(self.db_path)
        self._init_realtime_schema()

    def _init_realtime_schema(self):
        cursor = self.conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS fact_realtime_stream (
                stream_id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_id TEXT UNIQUE,
                event_type TEXT,
                event_timestamp TEXT,
                received_timestamp TEXT,
                latency_ms REAL,
                customer_id INTEGER,
                product_id INTEGER,
                region TEXT,
                quantity INTEGER,
                unit_price REAL,
                gross_amount REAL,
                margin_amount REAL,
                status TEXT
            );
        """)
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_stream_time ON fact_realtime_stream(received_timestamp);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_stream_region ON fact_realtime_stream(region);")
        self.conn.commit()

    def process_event_batch(self, events: list) -> dict:
        """Processes a micro-batch of streaming events and records latency."""
        if not events:
            return {"events_processed": 0, "avg_latency_ms": 0.0, "p95_latency_ms": 0.0}

        now_epoch_ms = int(time.time() * 1000)
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        records = []
        latencies = []

        cursor = self.conn.cursor()
        for ev in events:
            ev_epoch = ev.get("epoch_ms", now_epoch_ms)
            latency_ms = max(now_epoch_ms - ev_epoch, 0)
            latencies.append(latency_ms)

            records.append((
                ev.get("event_id"),
                ev.get("event_type", "ORDER_PLACED"),
                ev.get("timestamp"),
                now_str,
                latency_ms,
                ev.get("customer_id"),
                ev.get("product_id"),
                ev.get("region"),
                ev.get("quantity"),
                ev.get("unit_price"),
                ev.get("gross_amount"),
                ev.get("margin_amount"),
                ev.get("status", "Completed")
            ))

        cursor.executemany("""
            INSERT OR IGNORE INTO fact_realtime_stream (
                event_id, event_type, event_timestamp, received_timestamp,
                latency_ms, customer_id, product_id, region, quantity,
                unit_price, gross_amount, margin_amount, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """, records)
        self.conn.commit()

        latencies.sort()
        p95_idx = int(len(latencies) * 0.95)
        avg_latency = sum(latencies) / len(latencies)
        p95_latency = latencies[min(p95_idx, len(latencies) - 1)]

        stats = {
            "events_processed": len(records),
            "avg_latency_ms": round(avg_latency, 2),
            "p95_latency_ms": round(p95_latency, 2),
            "max_latency_ms": max(latencies),
            "sla_under_2_seconds": p95_latency < 2000
        }
        logger.info(f"[✓] Micro-batch processed: {len(records)} events | Avg Latency: {avg_latency:.1f}ms | P95: {p95_latency:.1f}ms | SLA (<2s): {'PASS' if stats['sla_under_2_seconds'] else 'FAIL'}")
        return stats

    def consume_from_buffer_file(self, buffer_file: str = "data/processed/stream_events.jsonl") -> dict:
        """Consumes buffered events from the streaming buffer file."""
        if not os.path.exists(buffer_file):
            logger.warning(f"Buffer file {buffer_file} not found.")
            return {}

        events = []
        with open(buffer_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    try:
                        events.append(json.loads(line.strip()))
                    except json.JSONDecodeError:
                        continue

        stats = self.process_event_batch(events)
        return stats


if __name__ == "__main__":
    consumer = RealTimeEventConsumer("warehouse/datawarehouse.db")
    consumer.consume_from_buffer_file("data/processed/stream_events.jsonl")
