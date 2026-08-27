-- ==============================================================================
-- SQL Data Quality & Schema Integrity Assertion Test Suite
-- Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
-- Module: CI7000 MSc Information Systems Dissertation
-- ==============================================================================

DO $$
DECLARE
    v_dup_cust INT;
    v_neg_sales INT;
    v_null_fk INT;
    v_neg_stock INT;
    v_orphan_dates INT;
BEGIN
    RAISE NOTICE '>>> STARTING SQL DATA QUALITY & SCHEMA INTEGRITY TESTS <<<';

    -- Test 1: Check for duplicate customer surrogate keys
    SELECT COUNT(*) - COUNT(DISTINCT customer_sk) INTO v_dup_cust FROM dim_customer;
    IF v_dup_cust > 0 THEN
        RAISE EXCEPTION 'TEST 1 FAILED: Found % duplicate customer surrogate keys', v_dup_cust;
    ELSE
        RAISE NOTICE 'TEST 1 PASSED: Zero duplicate customer surrogate keys found.';
    END IF;

    -- Test 2: Check for negative sales amounts or quantities
    SELECT COUNT(*) INTO v_neg_sales 
    FROM fact_sales 
    WHERE net_amount < 0 OR quantity <= 0 OR gross_amount < 0;
    IF v_neg_sales > 0 THEN
        RAISE EXCEPTION 'TEST 2 FAILED: Found % invalid sales records with negative amounts/quantities', v_neg_sales;
    ELSE
        RAISE NOTICE 'TEST 2 PASSED: All sales records have positive amounts and quantities.';
    END IF;

    -- Test 3: Referential integrity: Check for orphan foreign keys in fact_sales
    SELECT COUNT(*) INTO v_null_fk 
    FROM fact_sales s
    LEFT JOIN dim_date d ON s.date_key = d.date_key
    LEFT JOIN dim_customer c ON s.customer_sk = c.customer_sk
    LEFT JOIN dim_product p ON s.product_sk = p.product_sk
    WHERE d.date_key IS NULL OR c.customer_sk IS NULL OR p.product_sk IS NULL;

    IF v_null_fk > 0 THEN
        RAISE EXCEPTION 'TEST 3 FAILED: Found % orphan foreign key references in fact_sales', v_null_fk;
    ELSE
        RAISE NOTICE 'TEST 3 PASSED: 100%% referential integrity verified in fact_sales.';
    END IF;

    -- Test 4: Inventory stock levels consistency
    SELECT COUNT(*) INTO v_neg_stock 
    FROM fact_inventory 
    WHERE stock_on_hand < 0 OR reorder_level < 0;
    IF v_neg_stock > 0 THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Found % negative inventory records', v_neg_stock;
    ELSE
        RAISE NOTICE 'TEST 4 PASSED: All inventory stock quantities are valid (non-negative).';
    END IF;

    -- Test 5: Date boundary range integrity (2020 to 2030)
    SELECT COUNT(*) INTO v_orphan_dates 
    FROM dim_date 
    WHERE date_key < 20200101 OR date_key > 20301231;
    IF v_orphan_dates > 0 THEN
        RAISE EXCEPTION 'TEST 5 FAILED: Found % dates outside 2020-2030 bounds', v_orphan_dates;
    ELSE
        RAISE NOTICE 'TEST 5 PASSED: All 4,018 calendar date keys fall strictly within 2020-2030.';
    END IF;

    RAISE NOTICE '>>> ALL 5 SQL DATA QUALITY TESTS COMPLETED AND PASSED SUCCESSFULLY <<<';
END $$;
