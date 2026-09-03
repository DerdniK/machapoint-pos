create or replace function sp_view_users(
    p_userid uuid default null
)
returns setof vista_users
language plpgsql
security definer
as $$
begin
    if p_userid is null then
        return query select * from vista_users;
    else
        return query select * from vista_users where userid = p_userid;
    end if;
end;
$$;