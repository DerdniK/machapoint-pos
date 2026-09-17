create or replace function fn_auditoria_inventory()
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

    if (TG_OP = 'INSERT') then
        insert into public.bitacora_inventory (
            inventoryid, productid, stock, updated_at,
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.inventoryid, NEW.productid, NEW.stock, NEW.updated_at, 
            'A', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'UPDATE') then
        insert into public.bitacora_inventory (
            inventoryid, productid, stock, updated_at,
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.inventoryid, NEW.productid, NEW.stock, NEW.updated_at,
            'C', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'DELETE') then
        insert into public.bitacora_inventory (
            inventoryid, productid, stock, updated_at,
            accion, hecho_por, fecha_hora
        )
        values (
            OLD.inventoryid, OLD.productid, OLD.stock, OLD.updated_at, 
            'B', v_operador, now()
        );
        return OLD;
    end if;

    return null;
end;
$$;
