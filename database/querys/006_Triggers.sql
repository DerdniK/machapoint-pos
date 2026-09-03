
-- Trigger AFTER INSERT (SP_A)
create or replace trigger trg_users_after_insert
after insert on users
for each row
execute function fn_auditoria_users();

-- Trigger BEFORE UPDATE (SP_C)
create or replace trigger trg_users_before_update
before update on users
for each row
execute function fn_auditoria_users();

-- Trigger BEFORE DELETE (SP_B)
create or replace trigger trg_users_before_delete
before delete on users
for each row
execute function fn_auditoria_users();