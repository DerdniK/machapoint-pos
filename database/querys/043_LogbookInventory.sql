create table bitacora_inventory(
  bitacora_id serial primary key,
  inventoryid int,
  productid int,
  stock int,
  updated_at timestamp,
  accion varchar(10),
  hecho_por uuid,
  fecha_hora timestamp default now()
);