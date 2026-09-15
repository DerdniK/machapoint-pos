create or replace function sp_c_update_user(
    p_userid uuid,
    p_username varchar default null,
    p_password text default null,
    p_firstname varchar default null,
    p_lastname varchar default null,
    p_roleid int4 default null
)

returns boolean
language plpgsql
security definer
as $$
declare
    v_updated boolean;
begin

update users
    set 
        username  = coalesce(p_username, username),
        password  = coalesce(p_password, password),
        firstname = coalesce(p_firstname, firstname),
        lastname  = coalesce(p_lastname, lastname),
        roleid    = coalesce(p_roleid, roleid)
    where userid = p_userid;

    -- Returns true if a row was updated, false if user was not found
    return found;
end;
$$;