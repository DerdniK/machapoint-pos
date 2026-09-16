Create or replace view vista_sales as
SELECT
  s.saleid,
  s.shiftid,
  u.username as cashier_username,
  s.total,
  s.status,
  s.created_at,

  sp.payment_method,
  sp.amount_given,
  sp.change_given,
  
  jsonb_agg(
      jsonb_build_object(
          'sale_item_id', si.saleitemid,
          'product_id', p.productid,
          'sku', p.sku,
          'product_name', p.name,
          'unit_price', si.unit_price,
          'quantity', si.quantity,
          'subtotal', si.subtotal
      )
  ) AS items

FROM sales s
JOIN users u ON s.cashierid = u.userid
LEFT JOIN salepayments sp ON s.saleid = sp.saleid
JOIN sale_items si ON s.saleid = si.saleid
JOIN products p ON si.productid = p.productid
GROUP BY 
    s.saleid, 
    s.shiftid, 
    u.username, 
    s.created_at, 
    s.status, 
    s.total, 
    sp.payment_method, 
    sp.amount_given, 
    sp.change_given;
