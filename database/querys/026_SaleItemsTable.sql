CREATE TABLE sale_items (
    saleitemid SERIAL PRIMARY KEY,
    saleid INT NOT NULL REFERENCES sales(saleid) ON DELETE CASCADE,
    productid INT NOT NULL REFERENCES products(productid) ON DELETE RESTRICT,
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0)
);