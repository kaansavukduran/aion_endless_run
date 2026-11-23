(() => {
  'use strict';
  const BUILD = '__BUILD__';
  const VERSION = '__VERSION__';
  window.AION_BUILD = {build: BUILD, version: VERSION};
  const url = new URL(location.href);
  url.searchParams.set('build', BUILD);
  history.replaceState(null, '', url);
  if (!('serviceWorker' in navigator)) return;
  function uiLanguage() {
    const code = (document.getElementById('canvas')?.getAttribute('lang') || navigator.language || 'en').toLowerCase().split(/[-_]/)[0];
    return ['tr','en','cs'].includes(code) ? code : 'en';
  }
  const words = {
    tr: ['Yeni sürüm hazır · Güncelle', 'Kaydediliyor…', 'Güncelleme bekliyor · Tekrar dene'],
    en: ['New version ready · Update', 'Saving…', 'Update pending · Try again'],
    cs: ['Nová verze je připravena · Aktualizovat', 'Ukládání…', 'Aktualizace čeká · Zkusit znovu']
  };
  let offer;
  let button;
  let saving = false;
  let retry = false;
  let verification = 0;

  async function isPublished(candidate) {
    const manifest = new URL('./aion-latest.json', location.href);
    manifest.searchParams.set('check', String(Date.now()));
    const response = await fetch(manifest, {cache:'no-store', signal:AbortSignal.timeout(5000)});
    if (!response.ok) return false;
    const latest = await response.json();
    return latest.build === candidate.build && latest.version === candidate.version &&
      candidate.worker === navigator.serviceWorker.controller;
  }

  function renderOffer() {
    if (!offer && !button) return;
    if (!button) {
      button = document.createElement('button');
      button.id = 'aion-update';
      button.type = 'button';
      button.setAttribute('aria-live', 'polite');
      Object.assign(button.style, {
        position:'fixed', bottom:'max(16px, env(safe-area-inset-bottom))',
        right:'max(16px, env(safe-area-inset-right))', zIndex:'100',
        background:'#312534', color:'#fff1d5', border:'2px solid #edc88f',
        padding:'12px 16px', minHeight:'44px', font:'bold 14px system-ui', cursor:'pointer'
      });
      button.addEventListener('click', applyUpdate);
      document.body.appendChild(button);
      const canvas = document.getElementById('canvas');
      if (canvas) new MutationObserver(renderOffer).observe(canvas, {attributes:true, attributeFilter:['lang']});
    }
    button.hidden = !offer && !saving;
    button.disabled = saving;
    button.textContent = saving ? words[uiLanguage()][1] :
      retry ? words[uiLanguage()][2] : offer ? words[uiLanguage()][0] + ' v' + offer.version : '';
  }

  async function applyUpdate() {
    if (!offer || saving) return;
    saving = true;
    retry = false;
    renderOffer();
    try {
      if (window.aionSaveForUpdate?.() === false) throw new Error('Game progress could not be saved');
      // Allow Godot's background IDBFS flush to finish before navigation.
      await new Promise(resolve => setTimeout(resolve, 2200));
      const candidate = offer;
      if (!candidate || !await isPublished(candidate)) throw new Error('Update no longer ready');
      const target = new URL(location.href);
      target.searchParams.set('build', candidate.build);
      location.replace(target.href);
      return;
    } catch (error) {
      console.info('Aion update postponed:', error.message);
    }
    saving = false;
    retry = true;
    renderOffer();
  }

  async function checkOffer(data, worker) {
    if (!worker || worker !== navigator.serviceWorker.controller ||
        !/^[a-f0-9]{16}$/.test(data.build) || data.build === BUILD) return;
    const ticket = ++verification;
    const candidate = {build:data.build, version:data.version, worker};
    try {
      const published = await isPublished(candidate);
      if (ticket !== verification) return;
      offer = published ? candidate : null;
      retry = false;
      renderOffer();
    } catch (_) {
      // Keep a previously verified offer available for retry after reconnect.
    }
  }
  navigator.serviceWorker.addEventListener('message', event => {
    if (event.data?.type === 'aion-client-query') {
      event.source?.postMessage({type:'aion-client',build:BUILD});
      return;
    }
    if (event.data?.type === 'aion-version') checkOffer(event.data, event.source);
  });
  const registerOffline = () => navigator.serviceWorker.register('./index.service.worker.js', {updateViaCache:'none'}).then(registration => {
    if (!registration) return; // Browsers/privacy tools may disable worker installation.
    const check = () => {
      registration.update().catch(() => {}); // Offline is an expected condition.
      navigator.serviceWorker.controller?.postMessage({type:'aion-version'});
    };
    navigator.serviceWorker.addEventListener('controllerchange', check);
    addEventListener('online', check);
    document.addEventListener('visibilitychange', () => {if (!document.hidden) check();});
    setInterval(check, 60000);
    check();
  }).catch(error => console.info('Aion offline cache unavailable:', error.message));
  // Avoid simultaneous engine loading and a second full mobile cache download.
  if (window.AION_BOOT?.state.phase === 'ready') registerOffline();
  else addEventListener('aion-game-started',registerOffline,{once:true});
})();
