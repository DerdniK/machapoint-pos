create table bitacora_users (
    bitacora_id serial primary key,
    userid uuid,
    username varchar,
    firstname varchar,
    lastname varchar,
    roleid int4,
    accion varchar(10),     -- 'A' (Alta), 'B' (Baja), 'C' (Cambio)
    hecho_por uuid,
    fecha_hora timestamp default now()
);