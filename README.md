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

> **Nota:** En este repositorio suele existir `js/config.js` versionado para que el despliegue funcione sin paso de build. Si el repo es público, evita incluir secretos que no deban exponerse; la clave **anon** de Supabase está pensada para el cliente, pero conviene no publicar claves de servicio ni credenciales privadas.

## Vista pública del torneo

La página **`torneo-publico.html`** muestra fixture y tabla de posiciones **sin iniciar sesión** (solo lectura), para compartir el enlace.

Para que cargue datos con el cliente anónimo de Supabase, el proyecto debe permitir **lectura pública** (rol `anon`) al menos en las tablas que usa la vista:

- `equipos` — `SELECT` para listar nombres, escudos, grupos, etc.
- `partidos` — `SELECT` para fechas, horas, resultados y relaciones con equipos.

Ejemplo de políticas (ajusta nombres y reglas a tu modelo; revisa si quieres ocultar correos en otra vista):

```sql
-- Permitir a cualquiera ver equipos y partidos (solo lectura)
create policy "Torneo público lee equipos"
  on equipos for select
  to anon
  using (true);

create policy "Torneo público lee partidos"
  on partidos for select
  to anon
  using (true);
```

Si no aplicas políticas similares, la página mostrará un aviso y tablas vacías.

## Recordatorios en panel

En **admin** (`dashboard.html`) y **equipo** (`team-panel.html`) aparece un aviso cuando hay un partido **pendiente programado para mañana** (fecha del partido = día siguiente al actual en el reloj del navegador). El usuario puede **ocultar** el aviso hasta el día siguiente (se guarda en `localStorage`). No se envían correos automáticos desde el servidor; para EmailJS masivo haría falta un backend o trabajo manual.

## Despliegue en Vercel y Render

El mismo código puede publicarse en **Vercel** y en **Render** (sitio estático). Recomendación práctica:

- Elige **un** sitio como “oficial” para enlaces y pruebas (menos confusión con cookies y orígenes).
- Mantén **la misma cadena de CSP** y las cabeceras de seguridad en **`vercel.json`** y **`render.yaml`** cuando cambies proveedores o CDN.
- En **`vercel.json`** existen cabeceras **CORS** (`Access-Control-Allow-Origin`, etc.) fijadas al dominio de Vercel; en **Render** no se repiten: la app se sirve todo desde el mismo origen y no suele hacer falta CORS para HTML/CSS/JS. Si en el futuro necesitas CORS en Render, configúralo en el panel de Render o amplía `render.yaml` con el origen correcto.

En Render, el blueprint **`render.yaml`** define rutas (por ejemplo reescrituras de `.sql` / `.md` a `404.html`) y cabeceras. Tras cambiar el archivo, vuelve a desplegar el servicio estático para que aplique.

## Política de seguridad (CSP)

La política **Content-Security-Policy** la envían los servidores en cabeceras HTTP (no en `<meta>` en las páginas). Debe coincidir entre:

- **`vercel.json`** → `headers` → `Content-Security-Policy`
- **`render.yaml`** → `headers` → misma cabecera en `path: /*`
- **`.htaccess`** (solo si sirves el proyecto con Apache) → `Header set Content-Security-Policy`

Si añades un nuevo dominio de API o CDN, actualiza **los tres** sitios anteriores para que la cadena sea idéntica.

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
| `vercel.json` | Cabeceras de seguridad, CSP y caché (Vercel) |
| `render.yaml` | Mismo esquema de cabeceras y caché (Render estático) |
| `torneo-publico.html` | Fixture y tabla pública (solo lectura) |
| `js/public-view.js` | Lógica de la vista pública |
| `js/reminders.js` | Aviso “partido mañana” en paneles |

## Licencia y uso

Uso del proyecto según lo acuerdes con los mantenedores del torneo.
