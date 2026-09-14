alter table users
alter column UserID set default gen_random_uuid();

alter table users
alter column created_at set default current_timestamp ;