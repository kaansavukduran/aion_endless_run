# 0.15.0 verification

The JSON file records executed source/scene suites and browser sessions, including each tested web build. Earlier runner/gamepad sessions used the same gameplay code before the last language-popup-only correction; the eleven-language sessions include that correction. Original hero PNG SHA-256 comparisons are retained separately.

Real browser actions cover all eleven languages in portrait and landscape, settings/start/pause/return, saved override and unsupported-locale fallback, actual touch on the lower list option, stable four-character animation, double jump/glide/sprint, touch strike/roll/cancel/multitouch/rotation, three boss victories and standard virtual Xbox/PlayStation mappings. No writable game hooks are used by these drivers. Controlled source fixtures separately verify combat geometry, one-hit rewards, power expiry, range boundaries, six-biome cycling and monotonic boss return over five milestones.

Translations have not received native-speaker editorial review. Browser mobile viewports and virtual Gamepad API devices are not physical phones or controllers. The local Android build is signed by the existing stable key; emulator testing is performed by the existing GitHub Actions job because this execution host's ADB cannot create its default directory in the read-only home.

See [implementation and retained behavior](../../docs/UPGRADE-0.15.0.md). Further completed loader, route, native and live verification is appended below before delivery.
