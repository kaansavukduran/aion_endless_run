# Aion Endless Run 0.11.0 · Özgün tasarımlar, tutarlı animasyon

- Dört ana karakter orijinal model paftalarına göre yeniden çizildi. Aion’un mavi gözleri, pembe dallanan dış solungaçları, beyaz önlüğü ve DNA kuyruğu; kurdun kıyafetsiz gri/mor kürkü ve lanet izi; koyunun altın halesi; baykuşun kahverengi tüyleri korunur.
- Aion tek elle yumruk atar, küçük mavi yumruk parlaması vardır. Enerji topu pozu kaldırıldı. Baykuş kanat/gaga, koyun kafa/çifte, kurt ısırık/kafa saldırıları kullanır.
- Koşu, zıplama, saldırı ve tabanca pozları yüz hizası üzerinden yerleştirilir; karakter başına ortak ölçek korunur. Yedi ve sekiz poz içeren satırlar gerçek sınırlarıyla ayrı okunur; komşu kare parçaları yalıtılır.
- Sağa ilerleyen takla, sekiz ayrı sıkı kapanmış pozla saat yönünde döner; merkezi zemine göre sabittir.
- Hareket, kamera/şimşek, ses ve kutlamalar ilk açılışta açık. Açık/Kapalı yazıları eklendi. Oyuncunun kaydettiği kapalı tercihler güncellemede zorla açılmaz.
- Beş yeni orijinal PNG / toplam 449 çizilmiş poz. Kalite için zorla kare çoğaltma yok. Bosslar, gecikmeli koyun sürüsü, gamepad menüleri, üç dil ve çevrimdışı özellikler korunur.

Sekiz kaynak/sahne dizisinde 1.773 kontrol geçti. Tarayıcı, native paket ve yayın doğrulama kayıtları tamamlandıkça docs/evidence-v011 içine eklenir. Fiziksel kol ve Apple sahibi imzalama kapsamı önceki sürümle aynıdır.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.11.0-windows-x64-Setup.exe` | `AionEndlessRun-0.11.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.11.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.11.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.11.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 11'dır.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0–0.10.0 sürümleri korunmuştur.
