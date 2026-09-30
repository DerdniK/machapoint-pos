create table bitacora_sales (
  bitacora_id serial primary key,
  saleid int,
  shiftid int,
  cashierid uuid,
  total numeric,
  status text,
  created_at timestamp,
  hecho_por uuid,
  fecha_hora timestamp default now()
);

ALTER TABLE bitacora_sales add column accion varchar(10);