create or replace function fn_auditoria_sales()
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
        insert into public.bitacora_sales (
            saleid, shiftid, cashierid, total, status, created_at,accion, hecho_por, fecha_hora
        )
        values (
            NEW.saleid, NEW.shiftid, NEW.cashierid, NEW.total, NEW.status,NEW.created_at, 
            'A', v_operador, now()
        );
        return NEW;
    end if;
    return null;
end;
$$;
