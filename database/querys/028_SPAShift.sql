--- Insert opening of the shift

CREATE OR REPLACE FUNCTION sp_open_shift(
    p_cashierid uuid,
    p_opening_amount NUMERIC(12, 2)
) 
RETURNS INT AS $$
DECLARE
    v_active_shift_id INT;
    v_new_shift_id INT;
BEGIN
    SELECT shiftid INTO v_active_shift_id
    FROM shifts
    WHERE cashierid = p_cashierid AND status = 'OPEN'
    LIMIT 1;

    IF v_active_shift_id IS NOT NULL THEN
        RAISE EXCEPTION 'El cajero ya tiene un turno abierto (ID Turno: %). Debe cerrarlo antes de abrir uno nuevo.', v_active_shift_id;
    END IF;

    INSERT INTO shifts (cashierid, opening_amount, status)
    VALUES (p_cashierid, p_opening_amount, 'OPEN')
    RETURNING shiftid INTO v_new_shift_id;

    RETURN v_new_shift_id;
END;
$$ LANGUAGE plpgsql;