create or replace trigger trg_inventory_after_insert
after insert on inventory
for each row
execute function fn_auditoria_inventory();

create or replace trigger trg_inventory_before_update
before update on inventory
for each row
execute function fn_auditoria_inventory();

create or replace trigger trg_inventory_before_delete
before delete on inventory
for each row
execute function fn_auditoria_inventory();