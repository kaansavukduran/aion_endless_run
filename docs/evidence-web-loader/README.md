# Web loader revision 2 (game 0.12.0)

The owner reported a native Godot “Couldn't load project data at path /” / missing-PCK dialog on Poco X7, Firefox. An actual Chromium mobile-viewport run reproduces that exact native dialog when the PCK request receives HTTP 200 HTML. This proves the unvalidated-response failure path, not the exact packet received by the owner's phone.

The loader checks status, complete byte count, GDPC magic and SHA-256 before engine startup. It retries up to three times and deletes only a corrupt PCK cache entry, never IndexedDB. Verified bytes use the fixed virtual /aion.pck path, independent of fingerprinted download URLs. Persistent failure gives localized Retry/current-version buttons. A stale page referencing removed engine files can recover once using the latest manifest.

Offline installation starts after the game loads, validates files sequentially and reuses the boot-verified pack. Activation probes modern clients; a missing build query alone no longer forces a Firefox navigation during reload. Unknown modern clients retain their prior cache. Genuine legacy Godot installations still migrate. Existing score, preferences and the explicit save-before-update button are preserved.

`tests/browser_loader.py` passes 14 real-browser checks in each of Chromium and Firefox: stale-shell recovery without a loop, HTML/short/full-size corrupt/206 responses, absence of native missing-pack alerts, real game startup and touch input in landscape/portrait, localized retry, no engine allocation for invalid packs, real CacheStorage poison repair, actual IndexedDB score retention and real offline reload. These use actual HTTP responses, Godot WASM/PCK, browser storage and normal UI inputs, without game setters. Five stdlib packaging contracts verify manifest/file hashes, the engine wrapper boundary, worker HTML integrity, deferred worker registration and explicit failure for an unexpected engine template.

Firefox runs headed on Xvfb/Mesa because headless Firefox here has no WebGL2. Its Android user agent, touch input, DPR2 and mobile viewports exercise Gecko and the phone layout; this is not a physical Poco X7 test. No owner-device test is claimed. Native binaries, version0.12.0, game code and sprite art remain unchanged.

Reproduce (with Godot export templates and Playwright browsers installed):

```sh
python3 tests/test_web_packaging.py
python3 packaging/build_web.py
python3 tests/browser_loader.py --evidence /tmp/aion-chromium
DISPLAY=:99 python3 tests/browser_loader.py --browser firefox --evidence /tmp/aion-firefox
python3 tests/browser_upgrade.py --legacy /path/to/AionEndlessRun-0.12.0-web-offline.tar.gz --current build/web --evidence /tmp/aion-upgrade
```

The released 0.12.0 offline archive also passes 11 real PWA migration checks into loader2 with the same game version and a different build identity. This retains the selected owl, English preference and earned score, reloads the new export offline and tests a subsequent save-before-update transition. Publication and live verification follow after the production deployment is ready.
