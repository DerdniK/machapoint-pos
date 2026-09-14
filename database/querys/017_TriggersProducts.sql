create trigger trg_products_after_insert
after insert on public.products
for each row execute function public.fn_auditoria_products();

create trigger trg_products_before_update
before update on public.products
for each row execute function public.fn_auditoria_products();

create trigger trg_products_before_delete
before delete on public.products
for each row execute function public.fn_auditoria_products();