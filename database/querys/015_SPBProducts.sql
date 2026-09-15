create or replace function sp_b_delete_product(p_productid integer)

returns boolean
language plpgsql
security definer
as $$
begin

    delete from products
    where productid = p_productid;

    return found;
end;
$$;