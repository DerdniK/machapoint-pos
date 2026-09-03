create or replace function sp_a_insert_user(
    p_username varchar,
    p_password text,
    p_firstname varchar,
    p_lastname varchar,
    p_roleid int4
)

returns uuid
language plpgsql
security definer
as $$
declare
    v_userid uuid;
begin
    
    insert into users (username, password, firstname, lastname, roleid)
    values (p_username, p_password, p_firstname, p_lastname, p_roleid)
    returning userid into v_userid;

    return v_userid;
end;
$$;