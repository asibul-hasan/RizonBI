/**
 * Live PostgreSQL-Connected Server & BI API
 * Author: S M HOSNEY ARAFAT RIZON (ID: K2554665)
 * Module: CI7000 - MSc Information Systems Dissertation
 * Supervisor: Dr. Islam Choudhury
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const PORT = parseInt(process.env.PORT || "7860", 10);
const PUBLIC_DIR = path.join(__dirname, 'dashboard');

const AIVEN_URI = process.env.DATABASE_URL || "postgres://avnadmin:YOUR_PASSWORD@aidlydbpg-aidlly23-infoaidtech.a.aivencloud.com:12656/rizondw?sslmode=require";
const PSQL_PATH = process.env.PSQL_PATH || (process.platform === 'win32' ? "C:\\Program Files\\PostgreSQL\\17\\bin\\psql.exe" : "psql");

function fetchLiveUnifiedData(region = 'ALL') {
    return new Promise((resolve, reject) => {
        const regFilter = region !== 'ALL' ? `AND region = '${region}'` : '';
        const regFilterSales = region !== 'ALL' ? `AND s.region = '${region}'` : '';

        const sql = `
        SELECT json_build_object(
            'kpis', (
                SELECT json_build_object(
                    'total_revenue', COALESCE(ROUND(SUM(net_amount)::NUMERIC, 2), 0),
                    'gross_revenue', COALESCE(ROUND(SUM(gross_amount)::NUMERIC, 2), 0),
                    'total_margin', COALESCE(ROUND(SUM(margin_amount)::NUMERIC, 2), 0),
                    'total_orders', COUNT(DISTINCT order_id),
                    'active_clients', COUNT(DISTINCT customer_sk),
                    'margin_pct', COALESCE(ROUND((SUM(margin_amount) / NULLIF(SUM(net_amount), 0) * 100)::NUMERIC, 1), 0)
                ) FROM fact_sales WHERE status != 'Cancelled' ${regFilter}
            ),
            'monthly', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        d.year || '-' || LPAD(d.month_number::TEXT, 2, '0') AS month_period,
                        p.category,
                        ROUND(SUM(s.net_amount)::NUMERIC, 2) AS revenue,
                        ROUND(SUM(s.margin_amount)::NUMERIC, 2) AS margin
                    FROM fact_sales s
                    JOIN dim_date d ON s.date_key = d.date_key
                    JOIN dim_product p ON s.product_sk = p.product_sk
                    WHERE s.status != 'Cancelled' ${regFilterSales}
                    GROUP BY month_period, p.category
                    ORDER BY month_period ASC
                ) t
            ),
            'regional', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        region,
                        COUNT(sale_id) AS total_sales,
                        ROUND(SUM(net_amount)::NUMERIC, 2) AS revenue,
                        ROUND(SUM(margin_amount)::NUMERIC, 2) AS margin,
                        ROUND((SUM(margin_amount) / NULLIF(SUM(net_amount), 0) * 100)::NUMERIC, 1) AS margin_pct
                    FROM fact_sales
                    WHERE status != 'Cancelled'
                    GROUP BY region
                    ORDER BY revenue DESC
                ) t
            ),
            'channels', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        channel,
                        payment_method,
                        ROUND(SUM(net_amount)::NUMERIC, 2) AS revenue
                    FROM fact_sales
                    WHERE status != 'Cancelled' ${regFilter}
                    GROUP BY channel, payment_method
                ) t
            ),
            'topProducts', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        p.product_sku,
                        p.product_name,
                        p.category,
                        SUM(s.quantity) AS units_sold,
                        ROUND(SUM(s.net_amount)::NUMERIC, 2) AS total_revenue,
                        ROUND(SUM(s.margin_amount)::NUMERIC, 2) AS total_profit
                    FROM fact_sales s
                    JOIN dim_product p ON s.product_sk = p.product_sk
                    WHERE s.status != 'Cancelled' ${regFilterSales}
                    GROUP BY p.product_sku, p.product_name, p.category
                    ORDER BY total_revenue DESC
                    LIMIT 10
                ) t
            ),
            'inventory', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        p.product_name,
                        p.category,
                        sup.supplier_name,
                        i.stock_on_hand,
                        i.reorder_level,
                        i.stockout_risk,
                        ROUND(i.inventory_value::NUMERIC, 2) AS inventory_value
                    FROM fact_inventory i
                    JOIN dim_product p ON i.product_sk = p.product_sk
                    JOIN dim_supplier sup ON i.supplier_sk = sup.supplier_sk
                    WHERE i.date_key = (SELECT MAX(date_key) FROM fact_inventory)
                    ORDER BY i.stockout_risk DESC, i.stock_on_hand ASC
                ) t
            ),
            'finance', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        a.account_type,
                        a.account_name,
                        ROUND(SUM(f.amount)::NUMERIC, 2) AS total_amount
                    FROM fact_financial_transactions f
                    JOIN dim_account a ON f.account_sk = a.account_sk
                    GROUP BY a.account_type, a.account_name
                    ORDER BY a.account_type, total_amount DESC
                ) t
            ),
            'hr', (
                SELECT json_agg(t) FROM (
                    SELECT 
                        department,
                        ROUND(AVG(headcount)::NUMERIC, 0) AS avg_headcount,
                        ROUND(AVG(avg_salary)::NUMERIC, 2) AS average_salary,
                        ROUND(AVG(avg_performance_score)::NUMERIC, 1) AS average_performance,
                        ROUND(SUM(total_training_hours)::NUMERIC, 1) AS total_training,
                        ROUND((AVG(turnover_rate) * 100)::NUMERIC, 2) AS turnover_pct
                    FROM fact_hr_workforce
                    GROUP BY department
                ) t
            ),
            'dataQuality', (
                SELECT json_agg(t) FROM (
                    SELECT test_name, status, actual_count, expected_count FROM fn_audit_data_quality()
                ) t
            )
        );`;

        execFile(PSQL_PATH, [AIVEN_URI, '-t', '-A', '-c', sql], { maxBuffer: 1024 * 1024 * 10 }, (err, stdout, stderr) => {
            if (err) {
                console.error("PostgreSQL Query Error:", stderr || err.message);
                return reject(err);
            }
            try {
                const cleaned = stdout.trim();
                const parsed = JSON.parse(cleaned);
                resolve(parsed || {});
            } catch (pErr) {
                console.error("JSON parse error:", pErr);
                reject(pErr);
            }
        });
    });
}

const MIME_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml'
};

const server = http.createServer(async (req, res) => {
    const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
    const pathname = parsedUrl.pathname;

    if (pathname === '/api/live-data') {
        const role = parsedUrl.searchParams.get('role') || 'exec';
        const region = parsedUrl.searchParams.get('region') || 'ALL';

        try {
            const data = await fetchLiveUnifiedData(region);
            data.currentRole = role;
            data.currentRegion = region;
            data.source = "Aiven Cloud PostgreSQL 17.11 (rizondw)";
            data.timestamp = new Date().toISOString();

            res.writeHead(200, {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            });
            res.end(JSON.stringify(data));
        } catch (err) {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: err.message }));
        }
        return;
    }

    let reqPath = pathname === '/' ? '/index.html' : pathname;
    
    // Support direct presentation routing
    if (pathname.startsWith('/presentation')) {
        const presPath = path.join(__dirname, pathname);
        if (fs.existsSync(presPath)) {
            const ext = path.extname(presPath).toLowerCase();
            res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'text/html; charset=utf-8' });
            fs.createReadStream(presPath).pipe(res);
            return;
        }
    }

    const filePath = path.join(PUBLIC_DIR, reqPath);

    if (!filePath.startsWith(PUBLIC_DIR)) {
        res.writeHead(403, { 'Content-Type': 'text/plain' });
        res.end('403 Forbidden');
        return;
    }

    fs.readFile(filePath, (err, data) => {
        if (err) {
            fs.readFile(path.join(PUBLIC_DIR, 'index.html'), (err2, fallback) => {
                if (err2) {
                    res.writeHead(404, { 'Content-Type': 'text/plain' });
                    res.end('404 Not Found');
                } else {
                    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
                    res.end(fallback);
                }
            });
            return;
        }

        const ext = path.extname(filePath).toLowerCase();
        res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
        res.end(data);
    });
});

// Kill previous listeners and start server
function startServer(portToUse) {
    const srv = server.listen(portToUse, '0.0.0.0', () => {
        console.log("================================================================================");
        console.log(`  LIVE POSTGRESQL BI DASHBOARD API & WEB SERVER RUNNING ON PORT ${portToUse}    `);
        console.log(`  URL: http://localhost:${portToUse}                                            `);
        console.log(`  Database: Aiven Cloud PostgreSQL 17 (rizondw)                                `);
        console.log("================================================================================");
    });

    srv.on('error', (e) => {
        if (e.code === 'EADDRINUSE') {
            console.log(`Port ${portToUse} is in use, retrying on port ${portToUse + 1}...`);
            setTimeout(() => startServer(portToUse + 1), 300);
        } else {
            console.error("Server error:", e);
        }
    });
}

startServer(PORT);
