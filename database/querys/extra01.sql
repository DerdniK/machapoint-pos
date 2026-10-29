SELECT 
    p.proname AS nombre_funcion,
    pg_catalog.pg_get_function_identity_arguments(p.oid) AS argumentos
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'sp_close_shift_z_cut';