/**
 * config.example.js — Plantilla de configuración
 * ─────────────────────────────────────────────────
 * 1. Copia este archivo como `js/config.js`
 * 2. Rellena URL y anon key de Supabase (Dashboard → Settings → API)
 * 3. Si usas EmailJS en el login, rellena también las tres constantes de EmailJS
 *
 * La clave anónima de Supabase está pensada para usarse en cliente; no expongas
 * la service_role. Las claves de EmailJS son públicas por diseño, pero conviene
 * no compartirlas en repositorios públicos sin control.
 */

const SUPABASE_URL  = 'https://TU-PROYECTO.supabase.co';
const SUPABASE_ANON = 'TU_SUPABASE_ANON_KEY';

const EMAILJS_PUBLIC_KEY   = 'TU_EMAILJS_PUBLIC_KEY';
const EMAILJS_SERVICE_ID   = 'TU_EMAILJS_SERVICE_ID';
const EMAILJS_TEMPLATE_ID  = 'TU_EMAILJS_TEMPLATE_ID';
