# Verification

## 0.2.0 character update

84 physics/main-scene checks passed, including double-jump limits and landing reset, finite hold/release glide, actual wolf movement speed, capped contact-based flock collection, one life per fire/ice contact, final-life death, held-input cancellation, independent two-finger controls, animation row/frame selection and visible followers. The existing 12 real Web flows and 12 additional real-input ability flows passed. Real ground pickups produced three visible sheep and a real obstacle removed one sheep while gameplay continued. Chromium touch events verified boost and jump together on an 844×390 view.

The Vercel web build was tested from a cold cache with official SHA-512-verified downloads, and with the installed engine. This is build verification; the actual public deployment and native packages are verified separately below.

## 0.1.0 original release history

This file records evidence, not a promise of identical behavior on every device.

## Automated game tests

Godot 4.6.3, actual main scene and deterministic physics: **40 checks passed**. Grounded jump, double-jump rejection, pause freezing time/distance/height, fire/ice collisions, genuine pickups and obstacle clears without double awards, a long generated run through both biomes, retry counters, Space/Esc at the real scene entry, character selection, pause/resume preservation, on-screen language switching, disk persistence of best/character/settings, gameplay with sound/animation disabled.

The test uses a separate local data directory. It does not infer successful device installation from a source import or archive creation.

## Exported UI

`tests/browser_e2e.py`: **12 Chromium checks passed** against the actual Godot Web export. Real Space start/jump, Esc pause, frozen score, visible character selection, resume preserving the run, pointer jump, immediate Turkish/English switch without leaving settings, offline play through a real collision and result screen, preferences retained after reload, no uncaught browser errors. Desktop 1152×648 and phone 390×844 / 844×390 screenshots were inspected. Portrait shows a rotation hint; the native mobile game requests landscape orientation.

Screenshots in `docs/evidence/` are runtime captures, not generated mockups. The offline result capture uses the selected owl and shows its ash state. Source tests separately validate both collision types for all characters and both biomes during a long run.

## Native packages

Linux x64 embedded executable started successfully with the native engine in headless mode. Android release APK was produced locally and verified by `apksigner` (v2 and v3 signatures; RSA 3072, one signer). `aapt` confirms package `com.kaansavukduran.aionendlessrun`, version 0.1.0 / code 1, ARM64/x86_64 and no INTERNET permission. The released APK has its own stable local signing identity. CI builds an otherwise equivalent test APK with a disposable test key, installs it in an Android API 30 x86_64 emulator, disables Wi-Fi/mobile data, launches the game, taps Start, sends Space/Esc and captures both the real menu and paused game. Screenshots are inspected and blank frames, shader linking errors, Java/GDScript exceptions and control-tree errors fail CI. ANGLE over SwiftShader is required on this headless runner; the legacy emulator GLES translator produced blank frames and was rejected. This remains an emulator test, not a physical phone test.

macOS CI produced the universal application and DMG and started its native executable in headless mode on an Apple Silicon runner. Development ad-hoc signing is used; there is no Developer ID or notarization. Windows x64: NSIS Setup and portable ZIP were produced; both the portable executable and the installed executable started successfully. Linux x64: DEB installed through APT and started; the portable binary and AppImage (extract-and-run mode) also started successfully. Evidence: [desktop install verification run](https://github.com/kaansavukduran/aion_endless_run/actions/runs/42823067265). Interactive UI verification here is the Web export; headless native startup alone does not prove GPU rendering, sound or touch behavior on a particular device.

Physical Windows/macOS/Android interaction and iPhone installation have not been tested. iOS App Store/TestFlight installation and macOS Developer ID/notarization require the owner's Apple distribution setup.

All four packaged PNGs were byte-compared against the donor; original SHA-256 values match. Official local export templates were verified against upstream SHA-512. Portable ZIP CRCs, tar archives and DEB metadata were checked after downloading the actual CI artifacts. Engine/font licenses are included in the native resource payloads.

A real exported play session reached Frost Valley, collected 11 crystals and scored 612 through keyboard jumps; the runtime image is `docs/evidence/09-snow-biome.png`. The final Android and desktop CI run is linked in the release build receipt.

Final complete CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42825770482 . Application source commit: `c36b105`. All test, Windows, Linux, macOS and Android emulator jobs passed. The release APK is signed locally with the original release key; the emulated CI test uses its disposable key.

## 0.2.0 final delivery

- Full native package/test CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42842185612 . All test, Windows installer/portable, Linux installed DEB/AppImage/portable, macOS app/DMG and Android emulator jobs passed. Application code: `3af5c07`.
- Android gesture-capture recheck: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42844605684 . The new owl airborne artwork rendered in the native app. Finite hold/release glide is separately verified in model and browser input tests. Physical devices remain untested.
- Release: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.2.0 . Nine packages and two verification files published. APK package identity and signing certificate match 0.1.0; versionCode is 2. Published APK SHA-256 matched the locally signed/verified APK.
- Public web: https://aionendlessrun.vercel.app/ . Vercel reports successful deployment. HTTP, WASM and audio-worklet JavaScript responses have correct status/MIME. Twelve base and twelve ability flows also passed against live content. The cloud Chromium trust store lacks the executor proxy CA, so those live requests used a forwarding test driver with normal system-CA TLS verification. The audio worklets used identical verified bytes through blob URLs because browser worklet requests bypass interception. Service workers were blocked only in that diagnostic driver; live PWA installation/cache reload and real-device audio are not claimed. Local exported web tests ran normally without this driver.
