create or replace view vista_user_w_password as
select
  userid,
  username,
  password
from users
