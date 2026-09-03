ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

ALTER TABLE users ADD CONSTRAINT users_username_key UNIQUE (username);

ALTER TABLE users ALTER COLUMN roleid SET DEFAULT 1;

ALTER TABLE users ALTER COLUMN username type varchar;
ALTER TABLE users ALTER COLUMN firstname type varchar;
ALTER TABLE users ALTER COLUMN lastname type varchar;
