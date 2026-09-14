create or replace function fn_auditoria_users()
returns trigger
language plpgsql
security definer
as $$
DECLARE
    v_operador UUID;
BEGIN
    v_operador := auth.uid();

    IF v_operador IS NULL THEN
        BEGIN
            v_operador := NULLIF(current_setting('app.current_user_id', true), '')::UUID;
        EXCEPTION WHEN OTHERS THEN
            v_operador := NULL;
        END;
    END IF;

    IF v_operador IS NULL THEN
        IF (TG_OP = 'DELETE') THEN
            v_operador := OLD.userid;
        ELSE
            v_operador := NEW.userid;
        END IF;
    END IF;

    if (TG_OP = 'INSERT') then
        insert into public.bitacora_users (
            userid, username, firstname, lastname, roleid, 
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.userid, NEW.username, NEW.firstname, NEW.lastname, NEW.roleid, 
            'A', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'UPDATE') then
        insert into public.bitacora_users (
            userid, username, firstname, lastname, roleid, 
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.userid, NEW.username, NEW.firstname, NEW.lastname, NEW.roleid, 
            'C', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'DELETE') then
        insert into public.bitacora_users (
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
$$;
