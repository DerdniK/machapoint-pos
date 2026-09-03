create or replace view vista_users as
select 
    u.userid,
    u.username,
    u.firstname,
    u.lastname,
    u.roleid,
    r.rolename,
    u.created_at
from users u
left join roles r on u.roleid = r.roleid;