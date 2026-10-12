CREATE INDEX idx_sales_created_at ON sales (created_at);

CREATE OR REPLACE FUNCTION sp_sales_by_date_range(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    saleid INT,
    shiftid INT,
    cashierid UUID,
    total NUMERIC,
    status VARCHAR,
    created_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.saleid,
        s.shiftid,
        s.cashierid,
        s.total,
        s.status,
        s.created_at
    FROM sales s
    WHERE s.created_at >= start_date::TIMESTAMPTZ
      AND s.created_at < (end_date + INTERVAL '1 day')::TIMESTAMPTZ;
END;
$$;