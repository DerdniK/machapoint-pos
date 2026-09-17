create or replace trigger trg_shift_after_insert
after insert on shifts
for each row
execute function fn_auditoria_shifts();

create or replace trigger trg_shift_after_update
after update on shifts
for each row
execute function fn_auditoria_shifts();