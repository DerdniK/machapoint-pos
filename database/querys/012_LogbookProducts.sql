create table bitacora_products(
    id serial primary key,
    productid int,
    name varchar,
    sku varchar,
    typeid int4,
    price numeric (5,2),
    accion varchar(10),     -- 'A' (Alta), 'B' (Baja), 'C' (Cambio)
    hecho_por uuid,
    fecha_hora timestamp default now()
);

alter table bitacora_products
add column imageurl varchar;