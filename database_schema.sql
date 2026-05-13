-- ============================================================
-- ESQUEMA DE BASE DE DATOS
-- Torneo de Futbol - Monteria
--
-- Ejecuta este SQL en Supabase SQL Editor para crear las tablas.
-- Luego ejecuta security_rls_final.sql para instalar Auth + RLS.
-- ============================================================

-- 1. USUARIOS (perfiles publicos vinculados a auth.users)
CREATE TABLE IF NOT EXISTS public.usuarios (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT UNIQUE NOT NULL,
  password    TEXT DEFAULT '',
  nombre      TEXT NOT NULL,
  rol         TEXT NOT NULL DEFAULT 'team' CHECK (rol IN ('admin','team')),
  municipio   TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. EQUIPOS
CREATE TABLE IF NOT EXISTS public.equipos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT UNIQUE NOT NULL,
  email       TEXT UNIQUE NOT NULL,
  municipio   TEXT NOT NULL DEFAULT 'Monteria',
  escudo      TEXT,
  grupo       TEXT DEFAULT 'Unico',
  usuario_id  UUID REFERENCES public.usuarios(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 3. PARTIDOS
CREATE TABLE IF NOT EXISTS public.partidos (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipo_local_id  UUID NOT NULL REFERENCES public.equipos(id) ON DELETE CASCADE,
  equipo_visit_id  UUID NOT NULL REFERENCES public.equipos(id) ON DELETE CASCADE,
  fecha            DATE NOT NULL,
  hora             TIME NOT NULL,
  fase             TEXT DEFAULT 'Clasificacion General',
  goles_local      INT,
  goles_visit      INT,
  estado           TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','finalizado')),
  created_at       TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT equipos_distintos CHECK (equipo_local_id <> equipo_visit_id)
);

-- 4. JUGADORES
CREATE TABLE IF NOT EXISTS public.jugadores (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipo_id       UUID NOT NULL REFERENCES public.equipos(id) ON DELETE CASCADE,
  nombre          TEXT NOT NULL,
  documento       TEXT NOT NULL,
  posicion        TEXT NOT NULL CHECK (posicion IN ('Portero','Defensa','Mediocampista','Delantero')),
  dorsal          INT NOT NULL CHECK (dorsal BETWEEN 1 AND 999),
  fecha_nac       DATE,
  foto            TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (equipo_id, dorsal),
  UNIQUE (equipo_id, documento)
);

-- 5. EVENTOS DE PARTIDO (goles y tarjetas por jugador)
CREATE TABLE IF NOT EXISTS public.eventos_partido (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partido_id  UUID NOT NULL REFERENCES public.partidos(id) ON DELETE CASCADE,
  jugador_id  UUID NOT NULL REFERENCES public.jugadores(id) ON DELETE CASCADE,
  equipo_id   UUID NOT NULL REFERENCES public.equipos(id) ON DELETE CASCADE,
  tipo        TEXT NOT NULL CHECK (tipo IN ('gol','amarilla','roja')),
  cantidad    INT NOT NULL DEFAULT 1 CHECK (cantidad >= 0),
  pagada      BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (partido_id, jugador_id, tipo)
);

-- 6. NOTIFICACIONES (opcional, usada por panel de equipo)
CREATE TABLE IF NOT EXISTS public.notificaciones (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipo_id   UUID NOT NULL REFERENCES public.equipos(id) ON DELETE CASCADE,
  titulo      TEXT NOT NULL,
  mensaje     TEXT NOT NULL,
  leida       BOOLEAN DEFAULT false,
  creado_en   TIMESTAMPTZ DEFAULT now()
);

-- 7. Activar RLS sin politicas publicas permisivas.
-- Ejecuta security_rls_final.sql inmediatamente despues.
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jugadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eventos_partido ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;
