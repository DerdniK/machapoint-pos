create or replace trigger trg_zcuts_after_insert
after insert on z_cuts
for each row
execute function fn_auditoria_zcut();