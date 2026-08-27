# ==============================================================================
# RIZONDW DEVELOPER AUTOMATION MAKEFILE
# MSc Information Systems CI7000 - Kingston University London
# Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
# ==============================================================================

.PHONY: help install test test-etl test-streaming test-api run docker-build docker-run

help:
	@echo "RizonDW Enterprise Data Warehouse & BI Platform Commands:"
	@echo "  make install        Install package dependencies"
	@echo "  make test           Run all automated unit and benchmark test suites"
	@echo "  make test-etl       Run batch ETL transformation tests"
	@echo "  make test-streaming Run real-time micro-batch latency benchmark"
	@echo "  make test-api       Run REST API integration tests"
	@echo "  make run            Start live BI web server on localhost:3000 / 7860"
	@echo "  make docker-build   Build production Docker container"
	@echo "  make docker-run     Run Docker container on port 7860"

install:
	npm install

test: test-etl test-streaming
	@echo "[✓] All core automated tests passed successfully."

test-etl:
	node tests/test_etl_pipeline.js

test-streaming:
	node tests/test_streaming_harness.js

test-api:
	node tests/test_api_endpoints.js

run:
	node server.js

docker-build:
	docker build -t rizondw:latest .

docker-run:
	docker run -p 7860:7860 -e DATABASE_URL="$$DATABASE_URL" rizondw:latest
