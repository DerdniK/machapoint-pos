create or replace function fn_auditoria_shifts()
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
        insert into public.bitacora_shift (
            shiftid, cashierid, opening_amount, status, opened_at, closed_at, 
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.shiftid, NEW.cashierid, NEW.opening_amount, NEW.status, NEW.opened_at, NEW.closed_at, 
            'A', v_operador, now()
        );
        return NEW;

    elsif (TG_OP = 'UPDATE') then
        insert into public.bitacora_shift (
            shiftid, cashierid, opening_amount, status, opened_at, closed_at, 
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.shiftid, NEW.cashierid, NEW.opening_amount, NEW.status, NEW.opened_at, NEW.closed_at, 
            'C', v_operador, now()
        );
        return NEW;
    end if;

    return null;
end;
$$;
