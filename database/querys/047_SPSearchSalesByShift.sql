create or replace function sp_search_sales_by_shift(p_shiftid int)
RETURNS TABLE (
  saleid INT,
  shiftid INT,
  cashier_username VARCHAR,
  total NUMERIC,
  status VARCHAR,
  created_at timestamptz,
  payment_method VARCHAR,
  amount_given NUMERIC,
  change_given NUMERIC,
  items JSONB
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.saleid,
    v.shiftid,
    v.cashier_username,
    v.total,
    v.status,
    v.created_at,
    v.payment_method,
    v.amount_given,
    v.change_given,
    v.items
  FROM vista_sales v
  WHERE v.shiftid = p_shiftid;
END;
$$;
