# Torneo de Fútbol — Montería

Aplicación estática (HTML, CSS, JavaScript) para gestionar un torneo de fútbol: equipos, partidos y paneles de administración y de equipo. Los datos y la autenticación usan [Supabase](https://supabase.com/); el envío de correos en el flujo de login puede usar [EmailJS](https://www.emailjs.com/).

## Puesta en marcha

1. Clona el repositorio.
2. Copia la plantilla de configuración y edítala con tus credenciales:

   ```bash
   cp js/config.example.js js/config.js
   ```

3. Abre `js/config.js` y rellena al menos `SUPABASE_URL` y `SUPABASE_ANON`. Si usas EmailJS en la página de inicio de sesión, rellena también las tres constantes `EMAILJS_*`.
4. Sirve la carpeta del proyecto con cualquier servidor HTTP estático (por ejemplo la extensión “Live Server” del editor, o `npx serve .`).

> **Nota:** En este repositorio suele existir `js/config.js` versionado para que el despliegue en Vercel funcione sin paso de build. Si el repo es público, evita incluir secretos que no deban exponerse; la clave **anon** de Supabase está pensada para el cliente, pero conviene no publicar claves de servicio ni credenciales privadas.

## Política de seguridad (CSP)

La política **Content-Security-Policy** se define en un solo lugar para el despliegue en Vercel:

- Archivo: **`vercel.json`** → bloque `headers` → cabecera `Content-Security-Policy`.

Las páginas HTML **no** repiten la CSP en un `<meta http-equiv="...">`, para no duplicar ni chocar reglas.

Si sirves el sitio con **Apache** y `.htaccess`, la misma cadena de política está reflejada en la directiva `Header set Content-Security-Policy` de **`.htaccess`**; si cambias orígenes (nuevo CDN, otro proveedor de API), actualiza **ambos** archivos para que coincidan.

Resumen de la política actual:

- **Scripts:** solo mismo origen y `https://cdn.jsdelivr.net` (sin `unsafe-inline` en HTML).
- **Estilos:** mismo origen, `'unsafe-inline'` (necesario por estilos en plantillas dinámicas del panel), Google Fonts y CDN usados por el proyecto.
- **Conexiones:** Supabase (`https` y `wss`) y `https://api.emailjs.com`.

## Estructura relevante

| Ruta | Uso |
|------|-----|
| `js/config.js` | URL y claves (crear desde `config.example.js`) |
| `js/db.js` | Cliente Supabase y operaciones de datos |
| `js/frame-bust.js` | Protección frente a clickjacking (misma CSP estricta en scripts) |
| `vercel.json` | Cabeceras de seguridad y CSP |

## Licencia y uso

Uso del proyecto según lo acuerdes con los mantenedores del torneo.
