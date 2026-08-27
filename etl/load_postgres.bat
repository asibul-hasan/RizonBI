@echo off
REM PostgreSQL 16/17 Data Warehouse Ingestion Batch Script
REM Author: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
REM Module: CI7000 Project Dissertation

set PGHOST=localhost
set PGPORT=5432
set PGUSER=postgres
set PGDATABASE=rizon_dw

echo ================================================================================
echo   POSTGRESQL DATA WAREHOUSE LOAD SCRIPT - CI7000 MSc DISSERTATION
echo ================================================================================

set PSQL="C:\Program Files\PostgreSQL\17\bin\psql.exe"
if not exist %PSQL% set PSQL=psql

echo [1/3] Creating Database %PGDATABASE%...
%PSQL% -U %PGUSER% -h %PGHOST% -p %PGPORT% -d postgres -c "CREATE DATABASE %PGDATABASE%;" 2>nul

echo [2/3] Executing Schema DDL and Ingestion Scripts...
%PSQL% -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -f "warehouse/schema.sql"
%PSQL% -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -f "warehouse/load_postgres.sql"

echo [3/3] Running Python ETL Loader (or execute load_postgres.ps1)...
python etl/load_postgres.py

echo ================================================================================
echo   [OK] PostgreSQL Ingestion Complete.
echo ================================================================================
pause
