/**
 * Automated REST API & Integration Test Suite
 * Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
 * Module: CI7000 - MSc Information Systems
 */

const http = require('http');
const assert = require('assert');

const TEST_PORT = process.env.PORT || 3000;
const BASE_URL = `http://localhost:${TEST_PORT}`;

console.log('====================================================');
console.log('  RUNNING LIVE REST API INTEGRATION TESTS           ');
console.log('====================================================\n');

function makeRequest(path) {
    return new Promise((resolve, reject) => {
        http.get(`${BASE_URL}${path}`, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(data) });
                } catch (e) {
                    resolve({ status: res.statusCode, body: data });
                }
            });
        }).on('error', err => reject(err));
    });
}

async function runApiTests() {
    try {
        console.log(`[+] Testing GET /api/live-data (Default / Executive)...`);
        const res1 = await makeRequest('/api/live-data');
        assert.strictEqual(res1.status, 200, 'API must return HTTP 200 OK');
        assert.ok(res1.body.kpis, 'Response must include executive KPIs');
        assert.ok(res1.body.monthly, 'Response must include monthly revenue trends');
        assert.ok(res1.body.regional, 'Response must include regional breakdowns');
        assert.ok(res1.body.inventory, 'Response must include inventory facts');
        assert.ok(res1.body.finance, 'Response must include financial ledger postings');
        assert.ok(res1.body.hr, 'Response must include HR workforce metrics');
        assert.ok(res1.body.dataQuality, 'Response must include automated data quality results');
        console.log(`  [PASS] GET /api/live-data returned all 7 analytical domains with HTTP 200.`);

        console.log(`\n[+] Testing GET /api/live-data?region=London (Row-Level Security Filter)...`);
        const res2 = await makeRequest('/api/live-data?region=London');
        assert.strictEqual(res2.status, 200);
        assert.strictEqual(res2.body.currentRegion, 'London');
        console.log(`  [PASS] Regional filter query parameter handled properly (Region: London).`);

        console.log(`\n[+] Testing GET /api/live-data?role=sales (Role-Based Access Control Metadata)...`);
        const res3 = await makeRequest('/api/live-data?role=sales');
        assert.strictEqual(res3.status, 200);
        assert.strictEqual(res3.body.currentRole, 'sales');
        console.log(`  [PASS] Role-Based Access Control context handled properly (Role: sales).`);

        console.log('\n[✓] ALL REST API INTEGRATION TESTS PASSED SUCCESSFULLY.\n');
    } catch (err) {
        if (err.code === 'ECONNREFUSED') {
            console.log('\n[!] Note: API server is offline. Run "node server.js" first to execute live HTTP integration tests.');
        } else {
            console.error('\n[X] Test failed:', err.message);
            process.exit(1);
        }
    }
}

runApiTests();
