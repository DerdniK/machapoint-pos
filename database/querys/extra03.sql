SELECT 
    schemaname,
    relname AS table_name,
    n_live_tup AS estimated_rows,
    seq_scan,
    idx_scan,
    ROUND(100.0 * idx_scan / NULLIF(seq_scan + idx_scan, 0), 2) AS index_usage_percent
FROM 
    pg_stat_user_tables
WHERE 
    n_live_tup > 0
ORDER BY 
    seq_scan DESC;