CREATE VIEW vista_z_cuts AS
SELECT 
    z.zcutid,
    z.shiftid,
    u.username AS cashier_username,
    z.opened_at,
    z.closed_at,
    z.opening_cash,
    z.total_sales,
    z.total_sales_count,
    z.expected_cash,
    z.actual_cash,
    z.cash_difference,
    CASE 
        WHEN z.cash_difference < 0 THEN 'FALTANTE'
        WHEN z.cash_difference > 0 THEN 'SOBRANTE'
        ELSE 'EXACTO'
    END AS audit_status,
    z.notes
FROM z_cuts z
JOIN users u ON z.cashierid = u.userid;