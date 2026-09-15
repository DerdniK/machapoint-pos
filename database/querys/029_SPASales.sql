create or replace function sp_process_sale (
  p_shiftid INT,
  p_cashierid uuid,
  p_total NUMERIC(12, 2),
  p_items JSONB, -- Estructura: [{"product_id": 15, "unit_price": 50.00, "quantity": 2}, ...]
  p_paymentmethod VARCHAR(30),
  p_amountgiven NUMERIC(12, 2) default null,
  p_changegiven NUMERIC(12, 2) default null,
  p_transactionreference VARCHAR(100) default null
) RETURNS INT as $$
DECLARE
    v_shiftstatus VARCHAR(20);
    v_newsaleid INT;
    item RECORD;
    v_currentstock INT;
BEGIN
    SELECT status INTO v_shiftstatus
    FROM shifts
    WHERE shiftid = p_shiftid;

    IF v_shiftstatus IS NULL OR v_shiftstatus != 'OPEN' THEN
        RAISE EXCEPTION 'El turno % no existe o no se encuentra activo.', p_shiftid;
    END IF;

    INSERT INTO sales (shiftid, cashierid, total, status)
    VALUES (p_shiftid, p_cashierid, p_total, 'COMPLETED')
    RETURNING saleid INTO v_newsaleid;

    FOR item IN 
        SELECT 
            x AS raw_json,
            (COALESCE(x->>'ProductId', x->>'productId', x->>'product_id'))::INT AS productid,
            (COALESCE(x->>'Unit_price', x->>'unit_price', x->>'UnitPrice', x->>'unitPrice'))::NUMERIC(12, 2) AS unit_price,
            (COALESCE(x->>'Quantity', x->>'quantity'))::INT AS quantity
        FROM jsonb_array_elements(p_items) AS x
    LOOP
        IF item.productid IS NULL THEN
            RAISE EXCEPTION 'JSON inválido. Elemento recibido: % | JSON completo: %', 
                item.raw_json::text, 
                p_items::text;
        END IF;

        SELECT stock INTO v_currentstock
        FROM inventory
        WHERE productid = item.productid
        FOR UPDATE;

        IF v_currentstock IS NULL THEN
            RAISE EXCEPTION 'El producto ID % no existe registrado en la tabla de inventario.', item.productid;
        ELSIF v_currentstock < item.quantity THEN
            RAISE EXCEPTION 'Stock insuficiente para el producto ID %. Disponible: %, Solicitado: %', 
                item.productid, v_currentstock, item.quantity;
        END IF;

        INSERT INTO sale_items (saleid, productid, unit_price, quantity, subtotal)
        VALUES (
            v_newsaleid, 
            item.productid, 
            item.unit_price, 
            item.quantity, 
            (item.unit_price * item.quantity)
        );

        UPDATE inventory
        SET stock = stock - item.quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE productid = item.productid;
    END LOOP;

    INSERT INTO salepayments (
        saleid, 
        payment_method, 
        amount, 
        amount_given, 
        change_given, 
        transaction_reference
    )
    VALUES (
        v_newsaleid, 
        p_paymentmethod, 
        p_total, 
        p_amountgiven, 
        p_changegiven, 
        p_transactionreference
    );

    RETURN v_newsaleid;
END;
$$ LANGUAGE plpgsql;