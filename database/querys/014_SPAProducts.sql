create or replace function sp_a_insert_product(
    p_name text,
    p_sku text,
    p_precio double precision,
    p_typeid int,
    p_imageurl text default null
)

returns integer
language plpgsql
security definer
as $$
declare
    v_productid integer;
begin
    
    insert into products (name, sku, price, typeid,imageurl)
    values (p_name, p_sku, p_precio::numeric, p_typeid, p_imageurl)
    returning productid into v_productid;

    return v_productid;
end;
$$;