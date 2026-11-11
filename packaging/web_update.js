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
    tr: ['Yeni sürüm hazır · Güncelle', 'Kaydediliyor…'],
    en: ['New version ready · Update', 'Saving…'],
    cs: ['Nová verze je připravena · Aktualizovat', 'Ukládání…']
  };
  function showUpdate(data) {
    if (!data || data.type !== 'aion-version' || data.build === BUILD) return;
    const show = () => {
      if (document.getElementById('aion-update')) return;
      const button = document.createElement('button');
      button.id = 'aion-update';
      button.textContent = words[uiLanguage()][0] + ' v' + data.version;
      Object.assign(button.style, {position:'fixed', bottom:'16px', right:'16px', zIndex:'100', background:'#b1eddb', color:'#102b30', border:'2px solid #e0fff0', borderRadius:'10px', padding:'14px 18px', font:'bold 14px sans-serif', cursor:'pointer'});
      button.onclick = () => {
        button.disabled = true;
        button.textContent = words[uiLanguage()][1];
        if (typeof window.aionSaveForUpdate === 'function') window.aionSaveForUpdate();
        // Godot automatically flushes its IDBFS persistence once a second.
        setTimeout(() => { location.href = './?build=' + encodeURIComponent(data.build); }, 2200);
      };
      document.body.appendChild(button);
      const canvas = document.getElementById('canvas');
      if (canvas) new MutationObserver(() => {
        if (!button.disabled) button.textContent = words[uiLanguage()][0] + ' v' + data.version;
      }).observe(canvas, {attributes:true, attributeFilter:['lang']});
    };
    if (document.body) show(); else addEventListener('DOMContentLoaded', show, {once:true});
  }
  navigator.serviceWorker.addEventListener('message', event => {
    if (event.data?.type === 'aion-client-query') {
      event.source?.postMessage({type:'aion-client',build:BUILD});
      return;
    }
    showUpdate(event.data);
  });
  const registerOffline = () => navigator.serviceWorker.register('./index.service.worker.js', {updateViaCache:'none'}).then(registration => {
    if (!registration) return; // Browsers/privacy tools may disable worker installation.
    const check = () => {
      registration.update().catch(() => {}); // Offline is an expected condition.
      if (registration.active) registration.active.postMessage({type:'aion-version'});
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
