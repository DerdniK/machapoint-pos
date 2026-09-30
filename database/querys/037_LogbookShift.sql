create table bitacora_shift (
  bitacora_id serial primary key,
  shiftid int,
  cashierid uuid,
  opening_amount numeric,
  status text,
  opened_at timestamp,
  closed_at timestamp,
  accion varchar(10),
  hecho_por uuid,
  fecha_hora timestamp default now()
);
