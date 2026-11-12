#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
version=0.13.1
binary=build/linux/AionEndlessRun.x86_64
chmod +x "$binary"
cp LICENSE THIRD_PARTY_NOTICES.md README.md build/linux/
tar -czf "build/AionEndlessRun-${version}-linux-x64-portable.tar.gz" -C build/linux .
appdir=build/AionEndlessRun.AppDir
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/icons/hicolor/scalable/apps"
cp "$binary" "$appdir/usr/bin/AionEndlessRun"
cp assets/icon.svg "$appdir/aionendlessrun.svg"
cp assets/icon.svg "$appdir/usr/share/icons/hicolor/scalable/apps/aionendlessrun.svg"
cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/usr/bin/AionEndlessRun" "$@"
EOF
chmod +x "$appdir/AppRun"
cat > "$appdir/aionendlessrun.desktop" <<'EOF'
[Desktop Entry]
Name=Aion Endless Run
Comment=An offline pixel adventure
Exec=AionEndlessRun
Icon=aionendlessrun
Type=Application
Categories=Game;ArcadeGame;
Terminal=false
EOF
if command -v appimagetool >/dev/null 2>&1; then
  ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 appimagetool "$appdir" "build/AionEndlessRun-${version}-linux-x64.AppImage"
fi
deb=build/deb
mkdir -p "$deb/DEBIAN" "$deb/usr/games" "$deb/usr/share/applications" "$deb/usr/share/icons/hicolor/scalable/apps" "$deb/usr/share/doc/aion-endless-run"
cp "$binary" "$deb/usr/games/AionEndlessRun"
cp "$appdir/aionendlessrun.desktop" "$deb/usr/share/applications/"
cp assets/icon.svg "$deb/usr/share/icons/hicolor/scalable/apps/aionendlessrun.svg"
cp LICENSE THIRD_PARTY_NOTICES.md "$deb/usr/share/doc/aion-endless-run/"
cat > "$deb/DEBIAN/control" <<EOF
Package: aion-endless-run
Version: $version
Architecture: amd64
Maintainer: Kaan Savukduran
Section: games
Priority: optional
Depends: libc6 (>= 2.31), libx11-6, libxcursor1, libxinerama1, libxi6, libxrandr2, libgl1, libasound2 | libasound2t64, libpulse0
Description: Offline Aion pixel-art endless runner
 Space to jump, Esc to pause. Fire, ice, and four friends.
EOF
dpkg-deb --root-owner-group --build "$deb" "build/AionEndlessRun-${version}-linux-x64.deb"
