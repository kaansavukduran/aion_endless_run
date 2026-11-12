(() => {
  'use strict';
  const BUILD = '__BUILD__';
  const ASSETS = __ASSETS__;
  const CACHE = 'aion-offline-' + BUILD;
  const PACK_PATH = '/aion.pck';
  const lang = (navigator.language || 'en').toLowerCase().split(/[-_]/)[0];
  const words = {
    tr: ['Oyun indiriliyor…','Oyun hazırlanıyor…','Oyun dosyası tam yüklenemedi. Bağlantını kontrol edip yeniden deneyebilirsin.','Yeniden dene','Güncel sürümü aç'],
    en: ['Downloading the game…','Preparing the game…','The game file could not be loaded completely. Check your connection and try again.','Try again','Open current version'],
    cs: ['Stahování hry…','Příprava hry…','Herní soubor se nepodařilo načíst celý. Zkontrolujte připojení a zkuste to znovu.','Zkusit znovu','Otevřít aktuální verzi']
  }[['tr','en','cs'].includes(lang) ? lang : 'en'];
  const state = {phase:'waiting',attempts:0,error:''};
  function stamp(phase, error = '') {
    state.phase = phase; state.error = error;
    if (['verifying','starting'].includes(phase)) {
      document.getElementById('status-progress')?.removeAttribute('value');
      const percent=document.getElementById('aion-loading-percent'); if(percent)percent.textContent='…';
    }
    document.documentElement.dataset.bootState = phase;
    document.documentElement.dataset.bootAttempts = String(state.attempts);
    if (error) document.documentElement.dataset.bootError = error;
  }
  function notice(text) {
    const node = document.getElementById('status-notice');
    if (node) {node.textContent = text; node.style.display = 'block'; node.setAttribute('role','status');}
  }
  async function forgetBadPack(url) {
    if (!('caches' in window)) return;
    try {
      for (const key of await caches.keys()) {
        if (key.startsWith('aion-offline-') || key.startsWith('Aion Endless Run-sw-cache-')) {
          await (await caches.open(key)).delete(url, {ignoreSearch:true});
        }
      }
    } catch (_) {} // Storage restrictions must not block an online game.
  }
  async function rememberPack(url, buffer, expected) {
    if (!('caches' in window)) return;
    try {
      await (await caches.open(CACHE)).put(url, new Response(buffer, {headers:{
        'Content-Type':'application/octet-stream','Content-Length':String(expected.bytes),
        'X-Aion-Verified':expected.sha256
      }}));
    } catch (error) { console.info('Aion offline storage unavailable:',error.name); }
  }
  async function loadPack(url, expected, progress) {
    let last;
    for (let attempt = 0; attempt < 3; attempt++) {
      state.attempts++; stamp('downloading'); notice(words[0]);
      try {
        const response = await fetch(url, {cache:attempt ? 'reload':'default'});
        if (response.status !== 200 || /text\/html|application\/json/i.test(response.headers.get('Content-Type') || '')) {
          throw new Error('pack-response:'+response.status);
        }
        // A fixed-size buffer avoids accepting a successful but partial response.
        let buffer;
        if (response.body?.getReader) {
          const reader = response.body.getReader();
          const bytes = new Uint8Array(expected.bytes);
          let size = 0;
          try {
            while (true) {
              const part = await reader.read();
              if (part.done) break;
              if (size + part.value.byteLength > bytes.byteLength) throw new Error('pack-too-large');
              bytes.set(part.value,size); size += part.value.byteLength;
              progress?.(size,expected.bytes);
              const output=document.getElementById('aion-loading-percent');
              if(output)output.textContent=Math.floor(size/expected.bytes*100)+'%';
            }
          } catch (error) { await reader.cancel().catch(() => {}); throw error; }
          if (size !== expected.bytes) throw new Error('pack-incomplete:'+size);
          buffer = bytes.buffer;
        } else { buffer = await response.arrayBuffer(); }
        stamp('verifying'); notice(words[1]);
        const header = new Uint8Array(buffer,0,Math.min(4,buffer.byteLength));
        if (buffer.byteLength !== expected.bytes || header.join(',') !== '71,68,80,67') throw new Error('pack-invalid-header-or-size');
        const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',buffer)),n=>n.toString(16).padStart(2,'0')).join('');
        if (hash !== expected.sha256) throw new Error('pack-integrity');
        await rememberPack(url,buffer,expected);
        return buffer;
      } catch (error) {
        last = error;
        console.warn('Aion pack retry',attempt+1,error.message);
        await forgetBadPack(url);
      }
    }
    throw last;
  }
  async function repairLatest() {
    try {
      const response = await fetch('./aion-latest.json?check='+Date.now(),{cache:'no-store'});
      if (!response.ok) return false;
      const latest = await response.json();
      if (!/^[a-f0-9]{16}$/.test(latest.build) || latest.build === BUILD || new URL(location.href).searchParams.has('aion-recovery')) return false;
      const url = new URL('./',location.href);
      url.searchParams.set('build',latest.build); url.searchParams.set('aion-recovery','1');
      stamp('recovering'); location.replace(url.href); return true;
    } catch (_) { return false; }
  }
  let handlingFailure = false;
  async function failure(error) {
    if (handlingFailure) return;
    if (state.phase === 'ready' || state.phase === 'recovering') return;
    handlingFailure = true;
    stamp('failed',String(error?.message || error));
    console.error('Aion startup:',state.error);
    if (await repairLatest()) return;
    const output=document.getElementById('aion-loading-percent'); if(output)output.textContent='';
    const overlay = document.getElementById('status');
    if (overlay) overlay.style.visibility = 'visible';
    const bar = document.getElementById('status-progress');
    if (bar) bar.style.display = 'none';
    notice(words[2]);
    const node = document.getElementById('status-notice');
    if (!node || document.getElementById('aion-retry')) return;
    for (const [id,label,fresh] of [['aion-retry',words[3],false],['aion-current',words[4],true]]) {
      const button = document.createElement('button'); button.id=id; button.textContent=label;
      Object.assign(button.style,{margin:'12px 6px',padding:'12px 18px',borderRadius:'0',border:'2px solid #edc88f',background:'#b65c77',color:'#fff1d5',font:'20px AionPixel, monospace',cursor:'pointer'});
      button.onclick = () => {
        const url = new URL('./',location.href);
        if (!fresh) url.searchParams.set('build',BUILD);
        url.searchParams.set('retry',String(Date.now())); location.replace(url.href);
      };
      node.appendChild(button);
    }
  }
  async function start(engine, config, options) {
    const url = new URL(config.executable+'.pck',location.href).href;
    const expected = ASSETS[config.executable+'.pck'];
    let pack = await loadPack(url,expected,options.onProgress);
    const original = engine.preloadFile;
    // Network URL and virtual filesystem path are deliberately separate.
    // Always preload the verified bytes, never download the PCK a second time.
    engine.preloadFile = function(file,path) {
      return file === PACK_PATH ? original.call(this,pack,PACK_PATH) : original.call(this,file,path);
    };
    stamp('starting'); notice(words[1]);
    try {
      const result = await engine.startGame({...options,onProgress:()=>{},mainPack:PACK_PATH});
      stamp('ready');
      const url = new URL(location.href); url.searchParams.delete('aion-recovery'); url.searchParams.delete('retry'); history.replaceState(null,'',url);
      window.dispatchEvent(new Event('aion-game-started'));
      return result;
    } finally { engine.preloadFile = original; pack = null; }
  }
  window.AION_BOOT = {start,failure,get state(){return {...state};}};
  addEventListener('error',event => {
    if (state.phase !== 'ready' && ((event.target?.tagName === 'SCRIPT') || /Engine is not defined/.test(event.message || ''))) failure(new Error('engine-script-unavailable'));
  },true);
})();
