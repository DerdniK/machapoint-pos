CREATE INDEX idx_products_productid ON products (productid);

CREATE INDEX idx_users_userid ON users (userid);

CREATE INDEX idx_shifts_shiftid ON shifts (shiftid);

CREATE INDEX idx_products_name ON products (name);

CREATE INDEX idx_sales_created_at ON sales (created_at);

Create index idx_roles_roleid ON roles (roleid);

create index idx_product_types_typeid on product_types(typeid);

create index idx_inventory_productid on inventory (productid);

create index idx_sales_saleid on sales (saleid);

create index idx_salepayments on salepayments (paymentid);