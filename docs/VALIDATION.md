# Verification

This file records evidence, not a promise of identical behavior on every device.

## Automated game tests

Godot 4.6.3, actual main scene and deterministic physics: **39 checks passed**. Grounded jump, double-jump rejection, pause freezing time/distance/height, fire/ice collisions, genuine pickups and obstacle clears without double awards, a long generated run through both biomes, retry counters, Space/Esc at the real scene entry, character selection, pause/resume preservation, on-screen language switching, disk persistence of best/character/settings, gameplay with sound/animation disabled.

The test uses a separate local data directory. It does not infer successful device installation from a source import or archive creation.

## Exported UI

`tests/browser_e2e.py`: **12 Chromium checks passed** against the actual Godot Web export. Real Space start/jump, Esc pause, frozen score, visible character selection, resume preserving the run, pointer jump, immediate Turkish/English switch without leaving settings, offline play through a real collision and result screen, preferences retained after reload, no uncaught browser errors. Desktop 1152×648 and phone 390×844 / 844×390 screenshots were inspected. Portrait shows a rotation hint; the native mobile game requests landscape orientation.

Screenshots in `docs/evidence/` are runtime captures, not generated mockups. The offline result capture uses the selected owl and shows its ash state. Source tests separately validate both collision types for all characters and both biomes during a long run.

## Native packages

Linux x64 embedded executable started successfully with the native engine in headless mode. Android release APK was produced locally and verified by `apksigner` (v2 and v3 signatures; RSA 3072, one signer). `aapt` confirms package `com.kaansavukduran.aionendlessrun`, version 0.1.0 / code 1, ARM64/x86_64 and no INTERNET permission. This is APK structure/signature verification, not a physical phone installation test.

macOS CI produced the universal application and DMG and started its native executable in headless mode on an Apple Silicon runner. Development ad-hoc signing is used; there is no Developer ID or notarization. Windows and Linux installer/portable results are recorded after the final CI run. Interactive UI verification here is the Web export; headless native startup alone does not prove GPU rendering, sound or touch behavior on a particular device.

Physical Windows/macOS/Android interaction and iPhone installation have not been tested. iOS App Store/TestFlight installation and macOS Developer ID/notarization require the owner's Apple distribution setup.
