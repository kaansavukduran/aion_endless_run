# Aion Endless Run 0.9.0 · Akıcı hareket, yavaş seviye temposu

- Her seviye için **en az 30 saniye aktif normal koşu ve 12.000 yeni mesafe**. İki koşul birlikte gerekir. Duraklama/sarılma/boss süresi sayılmaz; biriken puan hızlı seviye zinciri yaratmaz.
- Anime kutlaması arka planda dünya ile sağdan sola geçer ve beş saniyede biter. Sekiz farklı yetişkin karakter sola bakar. Her 10 seviyede sağdan yaklaşan sarılma ve silah verme korunur.
- **10 yeni orijinal PNG, 997 gerçek çizilmiş kare.** Kahramanların ana hareketleri 12, düşman/robot dizileri 11 kare. Takla, donma/ateş/kül, eşyalar ve kutlamalar da zenginleştirildi. Kare sayıları kayıttan okunur; kaynak PNG’ler değişmeden korunur. Her karakter paftasında ortak ölçek, her karede ayrı saydam paylı doku.
- Baykuş havada gagasıyla, yerde dönüşümlü kanatla vurur. Kurt silahlı pozlarında da kendi mor/kremsi kürkünü taşır; önlük/gömlek yok.
- Ters U kemerler kaldırıldı. Yerdeki dört biyom hız şeridi 3,5 saniye %18 hız verir. Havada iki karga iplerle gerçek boru/tahta taşır; altından takla at veya havadan vurarak kır.
- Önceki dört biyom, çevrimdışı çalışma/kayıt/güncelleme, üç dil, nadir mantar, boss kovalamacası, hava olayları, rüzgâr ve gecikmeli sürü korunur.

1.200 kaynak/sahne kontrolü ve 96 yerel/canlı/PWA akış yürütmesi geçti. Tam başarılı native paket CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42907853628 . Dokuz paket ve iki doğrulama dosyası yayımlandı; sunucu SHA-256/boyutları, aynı imzalı APK ve indirilen universal Mac ZIP doğrulandı. Kapsam, sınırlamalar ve gerçek kayıtlar `docs/VALIDATION.md` / `docs/evidence-v09/` içindedir. Önceki sürümler korunur.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.9.0-windows-x64-Setup.exe` | `AionEndlessRun-0.9.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.9.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.9.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.9.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 9'dır.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0–0.8.0 sürümleri korunmuştur.
