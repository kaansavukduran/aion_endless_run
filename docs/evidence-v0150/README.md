# 0.15.0 verification

The JSON file records executed source/scene suites and browser sessions, including each tested web build. Earlier runner/gamepad sessions used the same gameplay code before the last language-popup-only correction; the eleven-language sessions include that correction. Original hero PNG SHA-256 comparisons are retained separately.

Real browser actions cover all eleven languages in portrait and landscape, settings/start/pause/return, saved override and unsupported-locale fallback, actual touch on the lower list option, stable four-character animation, double jump/glide/sprint, touch strike/roll/cancel/multitouch/rotation, three boss victories and standard virtual Xbox/PlayStation mappings. No writable game hooks are used by these drivers. Controlled source fixtures separately verify combat geometry, one-hit rewards, power expiry, range boundaries, six-biome cycling and monotonic boss return over five milestones.

Translations have not received native-speaker editorial review. Browser mobile viewports and virtual Gamepad API devices are not physical phones or controllers. The local Android build is signed by the existing stable key; emulator testing is performed by the existing GitHub Actions job because this execution host's ADB cannot create its default directory in the read-only home.

See [implementation and retained behavior](../../docs/UPGRADE-0.15.0.md). Further completed loader, route, native and live verification is appended below before delivery.

## Completed additional verification

Normal unseeded input runs reached all six biomes, encountered six enemy types, earned XP, used RB lightning and collected all three new buffs. The final boss driver recorded all three victory-return travel curves, verified frozen normal distance and the 100 XP reward, and passed 37 controller/boss checks. PWA migration from public 0.14.1 to 0.15.0 passed 11 checks including offline record preservation and a subsequent update. Chromium and Firefox loader suites each passed 19 checks.

The repaired Android native job passed seven real input/layout checks offline on API30: https://github.com/kaansavukduran/aion_endless_run/actions/runs/43313385100 . The screenshots here are its actual emulator captures. Four Python tests cover long UTF-8 diagnostic chunks, incomplete records, corruption and order. The package-version contract prevents the initially observed stale 0.14.1 Linux/Windows names. Documentation evidence is now excluded from Godot resource imports; gameplay has no res://docs dependencies. Desktop imports have a 300-second process timeout.

## Final delivery

[Final delivery report](DELIVERY.md). All nine 0.15.0 packages are public; tag workflow 43314959959 passed every required source/native/release job. Downloaded APK signature/hash and macOS ZIP CRC/universal CPUs were independently checked. Live production Firefox passed six additional checks; total browser checks: 223.
