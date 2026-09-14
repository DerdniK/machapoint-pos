create or replace function sp_view_products(
    p_productid integer default null
)
returns setof vista_products
language plpgsql
security definer
as $$
begin
    if p_productid is null then
        return query select * from vista_products;
    else
        return query select * from vista_products where productid = p_productid;
    end if;
end;
$$;