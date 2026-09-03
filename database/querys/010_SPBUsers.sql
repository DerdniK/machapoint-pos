create or replace function sp_b_delete_user(p_userid uuid)

returns boolean
language plpgsql
security definer
as $$
begin
    delete from users
    where userid = p_userid;

    return found;
end;
$$;