create or replace function sp_c_update_product(
    p_productid integer,
    p_name text default null,
    p_sku text default null,
    p_typeid integer default null,
    p_price numeric default null,
    p_imageurl text default null
)

returns boolean
language plpgsql
security definer
as $$
begin
update products
    set 
        name     = coalesce(p_name, name),
        sku      = coalesce(p_sku, sku),
        typeid   = coalesce(p_typeid, typeid),
        price    = coalesce(p_price, price),
        imageurl = coalesce(p_imageurl, imageurl)
    where productid = p_productid;

    return found;
end;
$$;