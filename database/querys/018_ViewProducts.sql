create or replace view vista_products as 
select
  p.productid,
  p.name,
  p.sku,
  p.price,
  p.imageurl,
  p.typeid,
  t.typename
from products p
left join product_types t on p.typeid = t.typeid;
  