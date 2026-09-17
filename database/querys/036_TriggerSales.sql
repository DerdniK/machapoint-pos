create or replace trigger trg_sales_after_insert
after insert on sales
for each row
execute function fn_auditoria_sales();