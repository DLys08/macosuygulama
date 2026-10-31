(function () {
  function chooseLocale(manual, country, languages) {
    if (manual === 'tr' || manual === 'en') return manual;
    if (typeof country === 'string' && /^[A-Z]{2}$/.test(country) && country !== 'XX') return country === 'TR' ? 'tr' : 'en';
    return (languages || []).some(function (lang) { return /^tr(?:-|$)/i.test(lang); }) ? 'tr' : 'en';
  }
  if (typeof module !== 'undefined') module.exports = { chooseLocale };
  if (typeof window === 'undefined') return;
  const key = 'alepdf-language';
  const query = new URLSearchParams(location.search).get('lang');
  let manual = query === 'tr' || query === 'en' ? query : null;
  try { if (manual) localStorage.setItem(key, manual); else manual = localStorage.getItem(key); } catch (_) {}
  if (query === 'tr' || query === 'en') history.replaceState(null, '', location.pathname + location.hash);
  function apply(country) {
    const selected = chooseLocale(manual, country, navigator.languages || [navigator.language]);
    const current = document.documentElement.lang;
    if (selected !== current) location.replace((selected === 'tr' ? '/tr/' : '/') + location.hash);
  }
  if (manual === 'tr' || manual === 'en') { apply(null); return; }
  const controller = new AbortController();
  const timeout = setTimeout(function () { controller.abort(); }, 1500);
  fetch('/api/locale', { cache: 'no-store', signal: controller.signal })
    .then(function (r) { if (!r.ok) throw new Error('Country unavailable'); return r.json(); })
    .then(function (data) { apply(data.country); })
    .catch(function () { apply(null); })
    .finally(function () { clearTimeout(timeout); });
})();
