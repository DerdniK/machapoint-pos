CREATE OR REPLACE FUNCTION sp_close_shift_z_cut(
    p_shiftid INT,
    p_cashierid uuid,
    p_actual_cash NUMERIC(12, 2),
    p_notes TEXT DEFAULT NULL
) 
RETURNS INT AS $$
DECLARE
    v_shift_status VARCHAR(20);
    v_opened_at TIMESTAMP WITH TIME ZONE;
    v_opening_cash NUMERIC(12, 2);
    
    v_total_sales NUMERIC(12, 2);
    v_total_sales_count INT;
    v_first_sale_id INT;
    v_last_sale_id INT;
    
    v_expected_cash_sales NUMERIC(12, 2);
    v_expected_card NUMERIC(12, 2);
    v_expected_transfer NUMERIC(12, 2);
    v_total_expected_cash NUMERIC(12, 2);
    
    v_cash_difference NUMERIC(12, 2);
    v_z_cut_id INT;
BEGIN
    SELECT status, opened_at, opening_amount 
    INTO v_shift_status, v_opened_at, v_opening_cash
    FROM shifts
    WHERE shiftid = p_shiftid;

    IF v_shift_status IS NULL OR v_shift_status != 'OPEN' THEN
        RAISE EXCEPTION 'El turno % no existe o ya ha sido cerrado.', p_shiftid;
    END IF;

    SELECT 
        COALESCE(SUM(total), 0.00),
        COUNT(saleid),
        MIN(saleid),
        MAX(saleid)
    INTO 
        v_total_sales,
        v_total_sales_count,
        v_first_sale_id,
        v_last_sale_id
    FROM sales
    WHERE shiftid = p_shiftid AND status = 'COMPLETED';

    SELECT COALESCE(SUM(sp.amount), 0.00) INTO v_expected_cash_sales
    FROM salepayments sp
    JOIN sales s ON sp.saleid = s.saleid
    WHERE s.shiftid = p_shiftid AND s.status = 'COMPLETED' AND sp.payment_method = 'CASH';

    SELECT COALESCE(SUM(sp.amount), 0.00) INTO v_expected_card
    FROM salepayments sp
    JOIN sales s ON sp.saleid = s.saleid
    WHERE s.shiftid = p_shiftid AND s.status = 'COMPLETED' AND sp.payment_method IN ('CREDIT_CARD', 'DEBIT_CARD');

    SELECT COALESCE(SUM(sp.amount), 0.00) INTO v_expected_transfer
    FROM salepayments sp
    JOIN sales s ON sp.saleid = s.saleid
    WHERE s.shiftid = p_shiftid AND s.status = 'COMPLETED' AND sp.payment_method = 'TRANSFER';

    v_total_expected_cash := v_opening_cash + v_expected_cash_sales;
    v_cash_difference := p_actual_cash - v_total_expected_cash;

    INSERT INTO z_cuts (
        shiftid,
        cashierid,
        opened_at,
        closed_at,
        firstsaleid,
        lastsaleid,
        opening_cash,
        total_sales,
        total_sales_count,
        expected_cash,
        expected_card,
        expected_transfer,
        actual_cash,
        cash_difference,
        notes
    )
    VALUES (
        p_shiftid,
        p_cashierid,
        v_opened_at,
        CURRENT_TIMESTAMP,
        v_first_sale_id,
        v_last_sale_id,
        v_opening_cash,
        v_total_sales,
        v_total_sales_count,
        v_total_expected_cash,
        v_expected_card,
        v_expected_transfer,
        p_actual_cash,
        v_cash_difference,
        p_notes
    )
    RETURNING zcutid INTO v_z_cut_id;

    UPDATE shifts
    SET status = 'CLOSED',
        closed_at = CURRENT_TIMESTAMP
    WHERE shiftid = p_shiftid;

    RETURN v_z_cut_id;
END;
$$ LANGUAGE plpgsql;