create or replace function fn_auditoria_zcut()
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
        insert into public.bitacora_z_cuts (
            zcutid, shiftid,cashierid, opened_at, closed_at, firstsaleid,lastsaleid,opening_cash,total_sales, total_sales_count,expected_cash,expected_card,expected_transfer,actual_cash, cash_difference,notes,
            accion, hecho_por, fecha_hora
        )
        values (
            NEW.zcutid, NEW.shiftid,NEW.cashierid, NEW.opened_at, NEW.closed_at, NEW.firstsaleid,NEW.lastsaleid,NEW.opening_cash,NEW.total_sales, NEW.total_sales_count,NEW.expected_cash,NEW.expected_card,NEW.expected_transfer,NEW.actual_cash, NEW.cash_difference,NEW.notes, 
            'A', v_operador, now()
        );
        return NEW;
    end if;
    return null;
end;
$$;
