create or replace function fn_auditoria_products()
returns trigger
language plpgsql
security definer
as $$
DECLARE
    v_operador UUID;
BEGIN
    -- 1. Intentar obtener el usuario autenticado
    v_operador := auth.uid();

    -- 2. Si es nulo, buscar variable de aplicación
    IF v_operador IS NULL THEN
        BEGIN
            v_operador := NULLIF(current_setting('app.current_user_id', true), '')::UUID;
        EXCEPTION WHEN OTHERS THEN
            v_operador := NULL;
        END;
    END IF;

    if (TG_OP = 'INSERT') then
        insert into bitacora_products (
            productid, name, sku, typeid, price, imageurl,
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.productid, NEW.name, NEW.sku, NEW.typeid, NEW.price, NEW.imageurl,
            'A', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'UPDATE') then
        insert into bitacora_products (
            productid, name, sku, typeid, price, imageurl,
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.productid, NEW.name, NEW.sku, NEW.typeid, NEW.price, NEW.imageurl,
            'C', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'DELETE') then
        insert into bitacora_products (
            productid, name, sku, typeid, price,imageurl,
            accion, hecho_por, fecha_hora
        )
        values (
            OLD.productid, OLD.name, OLD.sku, OLD.typeid, OLD.price, OLD.imageurl,
            'B', v_operador, now()
        );
        return OLD;
    end if;

    return null;
end;
$$;
