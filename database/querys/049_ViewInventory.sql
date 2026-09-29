create or replace view vista_inventory as
select
  inventoryid,
  productid,
  stock,
  updated_at
from inventory
