create sequence "public"."bitacora_users_bitacora_id_seq";


  create table "public"."bitacora_users" (
    "bitacora_id" integer not null default nextval('public.bitacora_users_bitacora_id_seq'::regclass),
    "userid" uuid,
    "username" character varying,
    "firstname" character varying,
    "lastname" character varying,
    "roleid" integer,
    "accion" character varying(10),
    "hecho_por" uuid,
    "fecha_hora" timestamp without time zone default now()
      );


alter table "public"."users" alter column "userid" set default gen_random_uuid();

alter sequence "public"."bitacora_users_bitacora_id_seq" owned by "public"."bitacora_users"."bitacora_id";

CREATE UNIQUE INDEX bitacora_users_pkey ON public.bitacora_users USING btree (bitacora_id);

alter table "public"."bitacora_users" add constraint "bitacora_users_pkey" PRIMARY KEY using index "bitacora_users_pkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.fn_auditoria_users()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    v_operador uuid;
begin
    -- Capturamos el usuario actualmente autenticado en Supabase Auth
    v_operador := auth.uid();

    if (TG_OP = 'INSERT') then
        insert into bitacora_users (
            userid, username, firstname, lastname, roleid, 
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.userid, NEW.username, NEW.firstname, NEW.lastname, NEW.roleid, 
            'A', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'UPDATE') then
        insert into bitacora_users (
            userid, username, firstname, lastname, roleid, 
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.userid, NEW.username, NEW.firstname, NEW.lastname, NEW.roleid, 
            'C', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'DELETE') then
        insert into bitacora_users (
            userid, username, firstname, lastname, roleid, 
            accion, hecho_por, fecha_hora
        )
        values (
            OLD.userid, OLD.username, OLD.firstname, OLD.lastname, OLD.roleid, 
            'B', v_operador, now()
        );
        return OLD;
    end if;

    return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.sp_a_insert_user(p_username character varying, p_password text, p_firstname character varying, p_lastname character varying, p_roleid integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    v_userid uuid;
begin
    insert into users (username, password, firstname, lastname, roleid)
    values (p_username, p_password, p_firstname, p_lastname, p_roleid)
    returning userid into v_userid;

    return v_userid;
end;
$function$
;

create or replace view "public"."vista_users" as  SELECT u.userid,
    u.username,
    u.firstname,
    u.lastname,
    u.roleid,
    r.rolename,
    u.created_at
   FROM (public.users u
     LEFT JOIN public.roles r ON ((u.roleid = r.roleid)));


grant delete on table "public"."bitacora_users" to "anon";

grant insert on table "public"."bitacora_users" to "anon";

grant references on table "public"."bitacora_users" to "anon";

grant select on table "public"."bitacora_users" to "anon";

grant trigger on table "public"."bitacora_users" to "anon";

grant truncate on table "public"."bitacora_users" to "anon";

grant update on table "public"."bitacora_users" to "anon";

grant delete on table "public"."bitacora_users" to "authenticated";

grant insert on table "public"."bitacora_users" to "authenticated";

grant references on table "public"."bitacora_users" to "authenticated";

grant select on table "public"."bitacora_users" to "authenticated";

grant trigger on table "public"."bitacora_users" to "authenticated";

grant truncate on table "public"."bitacora_users" to "authenticated";

grant update on table "public"."bitacora_users" to "authenticated";

grant delete on table "public"."bitacora_users" to "service_role";

grant insert on table "public"."bitacora_users" to "service_role";

grant references on table "public"."bitacora_users" to "service_role";

grant select on table "public"."bitacora_users" to "service_role";

grant trigger on table "public"."bitacora_users" to "service_role";

grant truncate on table "public"."bitacora_users" to "service_role";

grant update on table "public"."bitacora_users" to "service_role";

CREATE TRIGGER trg_users_after_insert AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_users();

CREATE TRIGGER trg_users_before_delete BEFORE DELETE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_users();

CREATE TRIGGER trg_users_before_update BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_users();


