create or replace function sp_c_update_stock(
  p_productid integer,
  p_stock integer, 
  p_is_adjustment boolean default true --True para sumar, false para sobreescribir el valor del stock
)
returns boolean
language plpgsql
security definer
as $$
begin
  if p_is_adjustment then
    update inventory
    set stock = stock + p_stock,
      updated_at = NOW()
    where productid = p_productid;
  else
    update inventory
    set stock = p_stock,
      updated_at = NOW()
    where productid = p_productid;
  end if;

  return found;
end;
$$;
