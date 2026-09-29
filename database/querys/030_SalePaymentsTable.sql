CREATE TABLE salepayments (
    paymentid SERIAL PRIMARY KEY,
    saleid INT NOT NULL REFERENCES sales(saleid) ON DELETE CASCADE,
    payment_method VARCHAR(30) NOT NULL, -- 'CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'TRANSFER'
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    amount_given NUMERIC(12, 2), -- Solo efectivo
    change_given NUMERIC(12, 2), -- Cambio en efectivo
    transaction_reference VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);