CREATE TABLE sales (
    saleid SERIAL PRIMARY KEY,
    shiftid INT NOT NULL REFERENCES shifts(shiftid),
    cashierid uuid NOT NULL REFERENCES users(userid),
    total NUMERIC(12, 2) NOT NULL CHECK (total >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED', -- 'COMPLETED', 'CANCELLED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);