create or replace function sp_search_product(
  p_name text
)
returns table(
  ProductID INT,
    name VARCHAR,
    sku VARCHAR,
    typeid INT,
    price NUMERIC,
    imageurl VARCHAR
) 
language plpgsql
AS $$
begin
    return query
    SELECT 
        p.productID, 
        p.name, 
        p.sku, 
        p.typeid, 
        p.price, 
        p.imageurl
    FROM products p
    WHERE p.name ILIKE '%' || p_name || '%';
END;
$$;