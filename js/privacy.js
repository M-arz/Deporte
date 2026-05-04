/**
 * privacidad.html — botón volver sin handlers inline (CSP sin unsafe-inline).
 */
document.addEventListener('DOMContentLoaded', function () {
  var btn = document.querySelector('.back-btn-container .btn-back');
  if (!btn) return;
  btn.addEventListener('click', function () {
    if (window.history.length <= 1 || window.opener != null) {
      window.close();
    }
    setTimeout(function () {
      window.location.href = 'index.html';
    }, 200);
  });
});
