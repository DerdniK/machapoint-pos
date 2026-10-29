
CREATE SCHEMA IF NOT EXISTS pgrst_no_exposed_schemas;

ALTER ROLE authenticator SET pgrst.db_schemas = 'pgrst_no_exposed_schemas';

NOTIFY pgrst;