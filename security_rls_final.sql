-- ============================================================
-- SEGURIDAD FINAL: Supabase Auth + RLS
-- Torneo de Futbol - Monteria
--
-- Ejecuta este archivo en Supabase SQL Editor despues de crear
-- las tablas base. Este script reemplaza las politicas publicas
-- antiguas por reglas basadas en auth.uid().
-- ============================================================

-- 1. Normalizar perfil de usuarios y roles.
ALTER TABLE public.usuarios
  ALTER COLUMN password DROP NOT NULL,
  ALTER COLUMN password SET DEFAULT '',
  ADD COLUMN IF NOT EXISTS municipio TEXT;

ALTER TABLE public.usuarios
  DROP CONSTRAINT IF EXISTS usuarios_rol_check;

UPDATE public.usuarios
SET rol = 'team'
WHERE rol = 'equipo';

ALTER TABLE public.usuarios
  ALTER COLUMN rol SET DEFAULT 'team',
  ADD CONSTRAINT usuarios_rol_check CHECK (rol IN ('admin', 'team'));

-- 2. Trigger: cada usuario de Supabase Auth crea/actualiza su perfil publico.
-- Los registros nuevos siempre entran como team; los admins se asignan manualmente.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.usuarios (id, email, nombre, rol, municipio, password)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'nombre', 'Usuario'),
    'team',
    COALESCE(new.raw_user_meta_data->>'municipio', 'No definido'),
    ''
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    nombre = EXCLUDED.nombre,
    rol = public.usuarios.rol,
    municipio = EXCLUDED.municipio;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Helpers SECURITY DEFINER para evitar recursion en politicas.
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT rol FROM public.usuarios WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(public.current_user_role() = 'admin', false)
$$;

CREATE OR REPLACE FUNCTION public.owns_team(team_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.equipos
    WHERE id = team_uuid
      AND usuario_id = auth.uid()
  )
$$;

-- 4. Activar RLS.
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jugadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eventos_partido ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF to_regclass('public.notificaciones') IS NOT NULL THEN
    ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- 5. Limpiar politicas antiguas conocidas.
DROP POLICY IF EXISTS "public_read_users" ON public.usuarios;
DROP POLICY IF EXISTS "public_insert_users" ON public.usuarios;
DROP POLICY IF EXISTS "public_update_users" ON public.usuarios;
DROP POLICY IF EXISTS "public_delete_users" ON public.usuarios;
DROP POLICY IF EXISTS "allow_read_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "allow_insert_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "allow_update_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "all_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "seguro_read_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "seguro_insert_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "seguro_update_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "seguro_delete_usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "Trigger puede insertar usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_select_self_admin" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_self_admin" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_delete_admin" ON public.usuarios;

DROP POLICY IF EXISTS "public_read_equipos" ON public.equipos;
DROP POLICY IF EXISTS "public_insert_equipos" ON public.equipos;
DROP POLICY IF EXISTS "public_update_equipos" ON public.equipos;
DROP POLICY IF EXISTS "public_delete_equipos" ON public.equipos;
DROP POLICY IF EXISTS "seguro_read_equipos" ON public.equipos;
DROP POLICY IF EXISTS "seguro_insert_equipos" ON public.equipos;
DROP POLICY IF EXISTS "seguro_update_equipos" ON public.equipos;
DROP POLICY IF EXISTS "seguro_delete_equipos" ON public.equipos;
DROP POLICY IF EXISTS "all_equipos" ON public.equipos;
DROP POLICY IF EXISTS "Lectura publica de equipos" ON public.equipos;
DROP POLICY IF EXISTS "Lectura pública de equipos" ON public.equipos;
DROP POLICY IF EXISTS "Equipos editables por dueño o admin" ON public.equipos;
DROP POLICY IF EXISTS "equipos_select_public" ON public.equipos;
DROP POLICY IF EXISTS "equipos_insert_owner_admin" ON public.equipos;
DROP POLICY IF EXISTS "equipos_update_owner_admin" ON public.equipos;
DROP POLICY IF EXISTS "equipos_delete_admin" ON public.equipos;

DROP POLICY IF EXISTS "public_read_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "public_insert_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "public_update_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "public_delete_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "seguro_read_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "seguro_insert_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "seguro_delete_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "all_jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "Lectura publica de jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "Lectura pública de jugadores" ON public.jugadores;
DROP POLICY IF EXISTS "Jugadores editables por dueño de equipo o admin" ON public.jugadores;
DROP POLICY IF EXISTS "jugadores_select_public" ON public.jugadores;
DROP POLICY IF EXISTS "jugadores_select_authenticated" ON public.jugadores;
DROP POLICY IF EXISTS "jugadores_insert_owner_admin" ON public.jugadores;
DROP POLICY IF EXISTS "jugadores_update_owner_admin" ON public.jugadores;
DROP POLICY IF EXISTS "jugadores_delete_owner_admin" ON public.jugadores;

DROP POLICY IF EXISTS "public_read_partidos" ON public.partidos;
DROP POLICY IF EXISTS "public_insert_partidos" ON public.partidos;
DROP POLICY IF EXISTS "public_update_partidos" ON public.partidos;
DROP POLICY IF EXISTS "public_delete_partidos" ON public.partidos;
DROP POLICY IF EXISTS "seguro_read_partidos" ON public.partidos;
DROP POLICY IF EXISTS "seguro_insert_partidos" ON public.partidos;
DROP POLICY IF EXISTS "seguro_update_partidos" ON public.partidos;
DROP POLICY IF EXISTS "seguro_delete_partidos" ON public.partidos;
DROP POLICY IF EXISTS "all_partidos" ON public.partidos;
DROP POLICY IF EXISTS "Lectura publica de partidos" ON public.partidos;
DROP POLICY IF EXISTS "Lectura pública de partidos" ON public.partidos;
DROP POLICY IF EXISTS "Solo admin gestiona partidos" ON public.partidos;
DROP POLICY IF EXISTS "partidos_select_public" ON public.partidos;
DROP POLICY IF EXISTS "partidos_insert_admin" ON public.partidos;
DROP POLICY IF EXISTS "partidos_update_admin" ON public.partidos;
DROP POLICY IF EXISTS "partidos_delete_admin" ON public.partidos;

DROP POLICY IF EXISTS "public_all_eventos" ON public.eventos_partido;
DROP POLICY IF EXISTS "seguro_all_eventos" ON public.eventos_partido;
DROP POLICY IF EXISTS "all_eventos" ON public.eventos_partido;
DROP POLICY IF EXISTS "all_eventos_partido" ON public.eventos_partido;
DROP POLICY IF EXISTS "Lectura publica de eventos" ON public.eventos_partido;
DROP POLICY IF EXISTS "Lectura pública de eventos" ON public.eventos_partido;
DROP POLICY IF EXISTS "Solo admin gestiona eventos" ON public.eventos_partido;
DROP POLICY IF EXISTS "eventos_select_public" ON public.eventos_partido;
DROP POLICY IF EXISTS "eventos_select_authenticated" ON public.eventos_partido;
DROP POLICY IF EXISTS "eventos_insert_admin" ON public.eventos_partido;
DROP POLICY IF EXISTS "eventos_update_admin" ON public.eventos_partido;
DROP POLICY IF EXISTS "eventos_delete_admin" ON public.eventos_partido;

DO $$
BEGIN
  IF to_regclass('public.notificaciones') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Equipos ven sus propias notificaciones" ON public.notificaciones;
    DROP POLICY IF EXISTS "public_all_notificaciones" ON public.notificaciones;
    DROP POLICY IF EXISTS "all_notificaciones" ON public.notificaciones;
    DROP POLICY IF EXISTS "notificaciones_select_destinatario_admin" ON public.notificaciones;
    DROP POLICY IF EXISTS "notificaciones_insert_admin" ON public.notificaciones;
    DROP POLICY IF EXISTS "notificaciones_update_destinatario_admin" ON public.notificaciones;
    DROP POLICY IF EXISTS "notificaciones_delete_admin" ON public.notificaciones;
  END IF;
END $$;

-- 5.1 Limpieza defensiva: borrar cualquier politica restante en estas tablas.
-- Esto elimina politicas con nombres no previstos como all_equipos, all_partidos, etc.
DO $$
DECLARE
  policy_record record;
BEGIN
  FOR policy_record IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('usuarios', 'equipos', 'jugadores', 'partidos', 'eventos_partido', 'notificaciones')
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      policy_record.policyname,
      policy_record.schemaname,
      policy_record.tablename
    );
  END LOOP;
END $$;

-- 6. Politicas finales.
CREATE POLICY "usuarios_select_self_admin"
  ON public.usuarios FOR SELECT
  USING (id = auth.uid() OR public.is_admin());

CREATE POLICY "usuarios_update_self_admin"
  ON public.usuarios FOR UPDATE
  USING (id = auth.uid() OR public.is_admin())
  WITH CHECK (id = auth.uid() OR public.is_admin());

CREATE POLICY "usuarios_delete_admin"
  ON public.usuarios FOR DELETE
  USING (public.is_admin());

CREATE POLICY "equipos_select_public"
  ON public.equipos FOR SELECT
  USING (true);

CREATE POLICY "equipos_insert_owner_admin"
  ON public.equipos FOR INSERT
  WITH CHECK (usuario_id = auth.uid() OR public.is_admin());

CREATE POLICY "equipos_update_owner_admin"
  ON public.equipos FOR UPDATE
  USING (usuario_id = auth.uid() OR public.is_admin())
  WITH CHECK (usuario_id = auth.uid() OR public.is_admin());

CREATE POLICY "equipos_delete_admin"
  ON public.equipos FOR DELETE
  USING (public.is_admin());

CREATE POLICY "jugadores_select_authenticated"
  ON public.jugadores FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "jugadores_insert_owner_admin"
  ON public.jugadores FOR INSERT
  WITH CHECK (public.owns_team(equipo_id) OR public.is_admin());

CREATE POLICY "jugadores_update_owner_admin"
  ON public.jugadores FOR UPDATE
  USING (public.owns_team(equipo_id) OR public.is_admin())
  WITH CHECK (public.owns_team(equipo_id) OR public.is_admin());

CREATE POLICY "jugadores_delete_owner_admin"
  ON public.jugadores FOR DELETE
  USING (public.owns_team(equipo_id) OR public.is_admin());

CREATE POLICY "partidos_select_public"
  ON public.partidos FOR SELECT
  USING (true);

CREATE POLICY "partidos_insert_admin"
  ON public.partidos FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "partidos_update_admin"
  ON public.partidos FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "partidos_delete_admin"
  ON public.partidos FOR DELETE
  USING (public.is_admin());

CREATE POLICY "eventos_select_authenticated"
  ON public.eventos_partido FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "eventos_insert_admin"
  ON public.eventos_partido FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "eventos_update_admin"
  ON public.eventos_partido FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "eventos_delete_admin"
  ON public.eventos_partido FOR DELETE
  USING (public.is_admin());

DO $$
BEGIN
  IF to_regclass('public.notificaciones') IS NOT NULL THEN
    CREATE POLICY "notificaciones_select_destinatario_admin"
      ON public.notificaciones FOR SELECT
      USING (public.is_admin() OR public.owns_team(equipo_id));

    CREATE POLICY "notificaciones_insert_admin"
      ON public.notificaciones FOR INSERT
      WITH CHECK (public.is_admin());

    CREATE POLICY "notificaciones_update_destinatario_admin"
      ON public.notificaciones FOR UPDATE
      USING (public.is_admin() OR public.owns_team(equipo_id))
      WITH CHECK (public.is_admin() OR public.owns_team(equipo_id));

    CREATE POLICY "notificaciones_delete_admin"
      ON public.notificaciones FOR DELETE
      USING (public.is_admin());
  END IF;
END $$;

-- 7. Resumen de verificacion.
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('usuarios', 'equipos', 'jugadores', 'partidos', 'eventos_partido', 'notificaciones')
ORDER BY tablename, policyname;
