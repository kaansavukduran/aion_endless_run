'use strict';
const BUILD = '__BUILD__';
const VERSION = '__VERSION__';
const CACHE = 'aion-offline-' + BUILD;
const FILES = __FILES__;
const INFO = __FILE_INFO__;
const versionMessage = {type:'aion-version',build:BUILD,version:VERSION};
const modernClients = new Map();
async function verifiedResponse(response, expected) {
  if (response.status !== 200) throw new Error('Incomplete offline response: '+response.status);
  const buffer = await response.arrayBuffer();
  if (buffer.byteLength !== expected.bytes) throw new Error('Incomplete offline file');
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',buffer)),n=>n.toString(16).padStart(2,'0')).join('');
  if (hash !== expected.sha256) throw new Error('Offline integrity mismatch');
  const headers = new Headers(response.headers);
  headers.delete('Content-Encoding'); headers.delete('Transfer-Encoding');
  headers.set('Content-Length',String(buffer.byteLength)); headers.set('X-Aion-Verified',hash);
  return new Response(buffer,{headers});
}
self.addEventListener('install',event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // Sequential validation bounds peak memory and reuses the boot-verified PCK.
    for (const path of FILES) {
      const existing = await cache.match(path);
      if (existing?.headers.get('X-Aion-Verified') === INFO[path].sha256 && Number(existing.headers.get('Content-Length')) === INFO[path].bytes) continue;
      await cache.put(path,await verifiedResponse(await fetch(new Request(path,{cache:'reload'})),INFO[path]));
    }
    await self.skipWaiting();
  })());
});
self.addEventListener('activate',event => {
  event.waitUntil((async () => {
    await self.clients.claim();
    const keep = new Set([CACHE]);
    const keys = await caches.keys();
    const windows = await self.clients.matchAll({type:'window'});
    for (const client of windows) client.postMessage({type:'aion-client-query'});
    await new Promise(resolve => setTimeout(resolve,500));
    const priorModern = keys.some(key=>key.startsWith('aion-offline-') && key!==CACHE);
    const priorLegacy = keys.some(key=>key.startsWith('Aion Endless Run-sw-cache-'));
    let legacyOpen = false;
    let unknownModern = false;
    for (const client of windows) {
      const url = new URL(client.url);
      const build = modernClients.get(client.id) || url.searchParams.get('build');
      // Firefox can still report the pre-history URL during activation/reload.
      // Only an actual legacy Godot cache justifies a forced navigation.
      if (!build && priorLegacy && !priorModern) {
        legacyOpen = true;
        url.searchParams.set('build',BUILD); client.navigate(url.href).catch(() => {});
      } else {
        if (build) keep.add('aion-offline-'+build);
        else unknownModern = true;
        client.postMessage(versionMessage);
      }
    }
    for (const key of await caches.keys()) {
      if (key.startsWith('aion-offline-') && !unknownModern && !keep.has(key)) await caches.delete(key);
      if (!legacyOpen && key.startsWith('Aion Endless Run-sw-cache-')) await caches.delete(key);
    }
  })());
});
self.addEventListener('message',event => {
  if (event.data?.type === 'aion-client' && event.source && /^[a-f0-9]{16}$/.test(event.data.build || '')) modernClients.set(event.source.id,event.data.build);
  if (event.data?.type === 'aion-version' && event.source) event.source.postMessage(versionMessage);
});
self.addEventListener('fetch',event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  if (request.mode === 'navigate' || url.pathname.endsWith('/aion-latest.json')) {
    event.respondWith((async () => {
      try { const response = await fetch(request,{cache:'no-cache'}); if (response.ok) return response; } catch (_) {}
      return (await caches.open(CACHE)).match(request.mode === 'navigate' ? 'index.html':'aion-latest.json');
    })());
    return;
  }
  event.respondWith((async () => {
    if (request.cache === 'reload' || request.cache === 'no-store') return fetch(request);
    const current = await (await caches.open(CACHE)).match(request,{ignoreSearch:true});
    if (current) return current;
    // An older, still-open game may need its own deferred audio/engine files.
    const oldBuild = url.pathname.match(/aion-([a-f0-9]{16})\./)?.[1];
    if (oldBuild) {
      const old = await (await caches.open('aion-offline-'+oldBuild)).match(request,{ignoreSearch:true});
      if (old) return old;
    }
    return fetch(request);
  })());
});
