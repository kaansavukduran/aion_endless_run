# Aion Endless Run 0.6.0 · Üç dil, başlangıçta seçim, tutarlı boyutlar

- **TR / EN / CS açılır menü:** Türkçe, İngilizce ve tam Çekçe arayüz. İlk açılış tarayıcı/cihazın ana dilini kullanır; `tr`, `en`, `cs` dışındaki dillerde İngilizce açılır. Oyuncu değiştirdiğinde tercihi kaydedilir. Otomatik ilk seçim bir sonraki cihaz dilini gereksiz yere kilitlemez; eski geçerli tercihler korunur.
- **İstenen isimler:** Türkçe Aion, Baykuş Ömer, Melun Bilge Kurt, Kutsanmış Cahil Koyun. İngilizce Aion, Omar the Owl, Accursed Wise Wolf, Blessed Ignorant Sheep. Çekçe Aion, Sova Omar, Prokletý moudrý vlk, Požehnaná nevědomá ovečka.
- **Başlangıçta görünür seçim:** Dört karakter kartı koşudan önce görünür. Koşu ve duraklatma sırasında karakter değişimi arayüzden ve oyun işlevinden engellenir; yeni seçim için ana menüye dönülür.
- **Tutarlı animasyon ölçeği:** Koşu, zıplama, iniş, süzülme, yükselen hava ve depar aynı normal yüksekliği korur. Paftaların opak sınırları kare bazında kaydedilir; orijinal PNG'ler korunur. Lider koyun normal, arkasındaki koyunlar %72 boyuttadır. Eğilme alçalır; yalnızca mantar gücü büyütür.
- **Önceki macera korunur:** Dört saldırı, karga, düşmana basıp sekme, alçak dal, dev mantar/cüce dalgaları, yedi güç, değişken karşılaşmalar/tempo, hava/şimşek, gecikmeli sürü, çift zıplama, yükselen hava ve kurt deparı. Space zıpla, sol tık/J vur, aşağı/S/Ctrl eğil, Shift kurt deparı, Esc duraklat. Yatay telefon ve bağımsız çoklu dokunma sürer.

207 kaynak/sahne ve 93 yerel tarayıcı/PWA kontrolü başarılı. Gerçek tarayıcı, güncelleme ve native paket doğrulaması `docs/VALIDATION.md` içinde kaydedilir.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.6.0-windows-x64-Setup.exe` | `AionEndlessRun-0.6.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.6.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.6.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.6.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 6'dır.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0, 0.2.0, 0.3.0, 0.4.0 ve 0.5.0 sürümleri korunmuştur.
