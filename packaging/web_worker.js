'use strict';
const BUILD = '__BUILD__';
const VERSION = '__VERSION__';
const CACHE = 'aion-offline-' + BUILD;
const FILES = __FILES__;
const versionMessage = {type:'aion-version', build:BUILD, version:VERSION};
self.addEventListener('install', event => {
  // Only activate a complete new export. Interrupted downloads leave the old
  // offline game available, without ever mixing two engine/PCK versions.
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    await cache.addAll(FILES.map(path => new Request(path, {cache:'reload'})));
    await self.skipWaiting();
  })());
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    await self.clients.claim();
    for (const client of await self.clients.matchAll({type:'window'})) {
      const url = new URL(client.url);
      if (!url.searchParams.has('build')) {
        // Old Godot HTML has no update listener. One migration navigation is
        // necessary to escape its cache-first shell; IndexedDB stays intact.
        url.searchParams.set('build', BUILD);
        client.navigate(url.href).catch(() => {});
      } else {
        client.postMessage(versionMessage);
      }
    }
    for (const key of await caches.keys()) {
      if ((key.startsWith('Aion Endless Run-sw-cache-') || key.startsWith('aion-offline-')) && key !== CACHE) await caches.delete(key);
    }
  })());
});
self.addEventListener('message', event => {
  if (event.data?.type === 'aion-version' && event.source) event.source.postMessage(versionMessage);
});
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;
  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      try {const response = await fetch(request, {cache:'no-cache'}); if (response.ok) return response;} catch (_) {}
      return (await caches.open(CACHE)).match('index.html');
    })());
    return;
  }
  // Immutable engine filenames are pinned to the same content build as HTML.
  // Unknown/new files go to network so an older worker cannot serve stale bytes.
  event.respondWith((async () => {
    const cached = await (await caches.open(CACHE)).match(request, {ignoreSearch:true});
    return cached || fetch(request);
  })());
});
