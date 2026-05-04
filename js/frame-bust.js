/**
 * Anti–clickjacking: si la página está en un iframe, redirige al top.
 * Si no, quita la clase que oculta el body hasta este script (ver css/frame-bust.css).
 */
(function () {
  'use strict';
  if (self !== top) {
    top.location = self.location;
    return;
  }
  var b = document.getElementById('antiClickjackBody');
  if (b) b.classList.remove('frame-bust-pending');
})();
