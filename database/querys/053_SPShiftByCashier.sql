CREATE OR REPLACE FUNCTION sp_get_shift(
    p_cashierid UUID
) 
RETURNS TABLE (
    shiftid INT,
    opening_amount NUMERIC(12, 2),
    opened_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.shiftid, s.opening_amount, s.opened_at, s.status
    FROM shifts s
    WHERE s.cashierid = p_cashierid AND s.status = 'OPEN'
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;