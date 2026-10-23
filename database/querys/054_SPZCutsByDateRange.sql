CREATE OR REPLACE FUNCTION sp_zcuts_by_date_range(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    zcutid INT,
    shiftid INT,
    cashierid UUID,
    opened_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    firstsaleid INT,
    lastsaleid INT,
    opening_cash NUMERIC(12, 2),
    total_sales NUMERIC(12, 2),
    total_sales_count INT,
    expected_cash NUMERIC(12, 2),
    expected_card NUMERIC(12, 2),
    expected_transfer NUMERIC(12, 2),
    actual_cash NUMERIC(12, 2),
    cash_difference NUMERIC(12, 2),
    notes TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        z.zcutid,
        z.shiftid,
        z.cashierid,
        z.opened_at,
        z.closed_at,
        z.firstsaleid,
        z.lastsaleid,
        z.opening_cash,
        z.total_sales,
        z.total_sales_count,
        z.expected_cash,
        z.expected_card,
        z.expected_transfer,
        z.actual_cash,
        z.cash_difference,
        z.notes
    FROM z_cuts z
    
    WHERE z.closed_at >= start_date::TIMESTAMPTZ
      AND z.closed_at < (end_date + INTERVAL '1 day')::TIMESTAMPTZ
    ORDER BY z.closed_at DESC;
END;
$$;

CREATE INDEX idx_zcuts_openedat on z_cuts (closed_at);
CREaTE INDEX idx_zcuts_closedat on z_cuts (opened_at);