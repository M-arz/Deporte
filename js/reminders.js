/**
 * Recordatorios de partidos: aviso en panel el día anterior (fecha del partido = mañana).
 * Sin envío masivo de correo (evita abusos desde el cliente); el organizador puede contactar equipos aparte.
 */
(function (global) {
  'use strict';

  function ymdLocal(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + day;
  }

  function tomorrowYmd() {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    return ymdLocal(d);
  }

  function matchDateYmd(m) {
    if (!m || !m.fecha) return '';
    return String(m.fecha).slice(0, 10);
  }

  function isPending(m) {
    return m.estado === 'pendiente';
  }

  function findTomorrowMatches(matches, teamId) {
    const t = tomorrowYmd();
    return (matches || []).filter(function (m) {
      if (!isPending(m)) return false;
      if (matchDateYmd(m) !== t) return false;
      if (!teamId) return true;
      return m.equipo_local_id === teamId || m.equipo_visit_id === teamId;
    });
  }

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatTime(h) {
    return h ? String(h).slice(0, 5) : '—';
  }

  function dismissKey() {
    return 'torneo_reminder_dismiss_' + tomorrowYmd();
  }

  function renderList(matches) {
    if (!matches.length) return '';
    return (
      '<ul class="match-reminder-list">' +
      matches.map(function (m) {
        var home = (m.equipo_local && m.equipo_local.nombre) || 'Local';
        var away = (m.equipo_visit && m.equipo_visit.nombre) || 'Visitante';
        return (
          '<li><strong>' + esc(home) + '</strong> vs <strong>' + esc(away) + '</strong> · ' +
          esc(formatTime(m.hora)) + '</li>'
        );
      }).join('') +
      '</ul>'
    );
  }

  function injectBanner(host, matches, teamId, title, introHtml) {
    if (!host) return;
    host.innerHTML = '';
    var list = findTomorrowMatches(matches, teamId);
    if (!list.length) return;
    try {
      if (localStorage.getItem(dismissKey()) === '1') return;
    } catch (e) { /* private mode */ }

    var box = document.createElement('div');
    box.className = 'match-reminder-banner';
    box.setAttribute('role', 'status');
    box.setAttribute('aria-live', 'polite');
    box.innerHTML =
      '<div class="match-reminder-inner">' +
      '<div class="match-reminder-title">' + esc(title) + '</div>' +
      introHtml +
      renderList(list) +
      '<button type="button" class="btn-reminder-dismiss">Ocultar hasta mañana</button>' +
      '</div>';
    host.appendChild(box);
    box.querySelector('.btn-reminder-dismiss').addEventListener('click', function () {
      try {
        localStorage.setItem(dismissKey(), '1');
      } catch (e) { /* ignore */ }
      box.remove();
    });
  }

  function renderAdminBanner(host, matches) {
    injectBanner(
      host,
      matches,
      null,
      'Partidos mañana',
      '<p class="match-reminder-p">Recordatorio para el cuerpo organizador: hay partidos <strong>programados para mañana</strong> (fecha en el sistema).</p>'
    );
  }

  function renderTeamBanner(host, matches, teamId) {
    if (!teamId) return;
    injectBanner(
      host,
      matches,
      teamId,
      'Tu equipo juega mañana',
      '<p class="match-reminder-p">Tenéis un partido <strong>mañana</strong>. Revisad hora y lugar con la organización.</p>'
    );
  }

  global.MatchReminders = {
    findTomorrowMatches: findTomorrowMatches,
    renderAdminBanner: renderAdminBanner,
    renderTeamBanner: renderTeamBanner
  };
})(typeof window !== 'undefined' ? window : this);
