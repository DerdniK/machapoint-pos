CREATE table Product_types (
  typeid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  typename TEXT UNIQUE NOT NULL
);

CREATE TABLE Products (
  ProductID int generated always as identity primary key,
  name varchar(20),
  sku varchar(20),
  typeid int ,
  price numeric(5,2),
  constraint RoleFK foreign key (typeid) references Product_types(typeid)
);

Alter table products add imageurl varchar(100);

insert into product_types(typename) values ('posters'),('pines'),('stickers'),('postales');

/*generic  database records-to be changed*/
insert into products (name,sku,typeid,price)
values
('Vintage Poster', 'PST-VTG-001', 1, 80.00),
('Metal Pin', 'PIN-MTL-002', 2, 50.20),
('Sticker Pack', 'STK-PCK-003', 3, 100.00),
('Holiday Postal Card', 'PC-HLD-004', 4, 30.00),
('Art Poster', 'PST-ART-005', 1, 60.00);

alter table products alter column name type varchar;
alter table products alter column sku type varchar;