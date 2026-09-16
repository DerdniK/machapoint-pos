CREATE TABLE shifts (
    shiftid SERIAL PRIMARY KEY,
    cashierid uuid NOT NULL REFERENCES users(userid),
    opening_amount NUMERIC(12, 2) NOT NULL CHECK (opening_amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'CLOSED'
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE
);