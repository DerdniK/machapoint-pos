CREATE TABLE z_cuts (
    zcutid SERIAL PRIMARY KEY,
    shiftid INT NOT NULL UNIQUE REFERENCES shifts(shiftid),
    cashierid uuid NOT NULL REFERENCES users(userid),
    
    opened_at TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    firstsaleid INT REFERENCES sales(saleid),
    lastsaleid INT REFERENCES sales(saleid),
    
    opening_cash NUMERIC(12, 2) NOT NULL,
    total_sales NUMERIC(12, 2) NOT NULL,      -- Suma total vendida en el turno
    total_sales_count INT NOT NULL DEFAULT 0, -- Cantidad de ventas realizadas
    
    expected_cash NUMERIC(12, 2) NOT NULL,
    expected_card NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    expected_transfer NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    
    actual_cash NUMERIC(12, 2) NOT NULL,
    cash_difference NUMERIC(12, 2) NOT NULL, -- (actual_cash - expected_cash)
    
    notes TEXT
);