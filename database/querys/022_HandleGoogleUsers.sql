CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_firstname TEXT;
  v_lastname TEXT;
BEGIN
  v_firstname := COALESCE(
    NEW.raw_user_meta_data->>'given_name', 
    split_part(NEW.raw_user_meta_data->>'full_name', ' ', 1)
  );
  
  v_lastname  := COALESCE(
    NEW.raw_user_meta_data->>'family_name', 
    split_part(NEW.raw_user_meta_data->>'full_name', ' ', 2)
  );

  INSERT INTO public.users (
    userid,
    username,  -- Guardamos el email de Google directamente como username
    password,  -- Queda NULL para usuarios de Google OAuth
    firstname,
    lastname,
    roleid,    -- Toma el valor DEFAULT configurado
    created_at
  )
  VALUES (
    NEW.id,    -- Enlaza el UUID de auth.users con tu public.users.userid
    NEW.email,
    NULL,
    v_firstname,
    v_lastname,
    DEFAULT,
    NOW()
  )
  ON CONFLICT (userid) DO UPDATE SET
    username  = EXCLUDED.username,
    firstname = EXCLUDED.firstname,
    lastname  = EXCLUDED.lastname;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear el trigger que escucha los nuevos usuarios en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();