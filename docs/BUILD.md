# Reproducible packaging

Engine and export templates: official Godot 4.6.3 standard build, verified against upstream SHA-512 by `packaging/setup_godot.py` in CI. Project is GDScript and GL Compatibility; no .NET runtime needed.

Windows and Linux exports embed the PCK in the executable; macOS keeps it inside the application bundle. Windows: NSIS per-user installer (no admin elevation) and ZIP. Linux: AppImage, DEB and tar.gz. macOS: universal app ZIP and DMG on a macOS runner. macOS Developer ID and notarization are not configured; packages use development ad-hoc signing only. Windows Authenticode is not configured.

Android uses the stock release template, stable package ID `com.kaansavukduran.aionendlessrun`, ARM64 and x86_64. No network permission. CI signing requires repository Actions secrets `AION_ANDROID_KEYSTORE_B64` and `AION_ANDROID_KEY_PASSWORD`; alias is `aionrelease`. The initial key was created outside the repository in the private build workspace; the current GitHub integration cannot write repository secrets (HTTP 403). The first APK is built locally. To enable later CI Android builds, the owner must configure these two secrets and the repository variable `AION_ANDROID_SIGNING_READY=true`. Back up the original key securely; do not replace the key for an update. Increment `version/code` and `version/name` for each later release. Do not commit the keystore or `.godot/export_credentials.cfg`.

The iOS preset is a source export target. A macOS/Xcode environment, Apple Developer team, provisioning profiles, distribution certificate and App Store Connect/TestFlight record are required before an installable signed iPhone app can be delivered. iOS is not silently described as covered by the APK or a desktop archive.

Local export:

```sh
mkdir -p build/linux build/windows build/macos build/web build/android build/ios
godot --headless --editor --import --quit
godot --headless --export-release Linux
godot --headless --export-release Windows
godot --headless --export-release macOS
godot --headless --export-release Web
```

For Android set `JAVA_HOME`, `ANDROID_HOME`, `AION_KEYSTORE`, `AION_KEY_ALIAS`, `AION_KEY_PASSWORD`, run `python3 packaging/android_config.py`, then `godot --headless --export-release Android`. Build-tools 35.0.0, Android platform 35 and platform-tools are required. Credentials are not printed.

The web archive is an additional preview, not a substitute for native packages. Serve it over localhost/HTTPS, e.g. `python3 -m http.server 8000 --directory build/web`, then open `http://localhost:8000`. Its service worker can cache the game after the first complete load. Native games work offline immediately after installation/extraction.
