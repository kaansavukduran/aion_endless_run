# Aion Endless Run 0.10.0 · Sürü, üç boss ve gamepad menüleri

- Küçük koyunlar boss sırasında kaybolmaz; kovalamaca mesafesi üzerinden zıplama/taklayı gecikmeli izler, koşuya dönüşte iz geçmişi korunur.
- Üç özgün boss tasarımı, tasarım başına üç saldırı ve yarı canda hızlanan ikinci aşama. Kül Muhafızı, Fırtına Vatozu, Kök Motoru normal koşuda 10/20/30 seviyelerde döner. Yön uyarıları ve salvoda güvenli tek kaçış hattı vardır.
- Ana menüde Boss antrenmanı: seçili karakterle istediğin boss’u dene; rekor ve seviye ilerlemesi korunur. Koyunda iki küçük arkadaş bulunur.
- Silahla koşu ve atışın hazırlık/parlama/geri tepme/toparlanması ayrı 12 karelik döngüler. Koyun iki ön toynağıyla tutar. Mermi ölçülmüş namludan parlama anında çıkar; normal ölüm silah pozuyla örtülmez.
- Xbox / standart PlayStation gamepad menülerinde D-pad/sol çubuk gezinir, A/Cross veya X/Square seçer, B/Circle geri döner. Yeniden Oyna, Ana Menü, Ayarlar ve duraklatma seçimleri düzeltildi. RT/R2 ateş desteği ve bağlantı kesilince kontrol temizleme/duraklatma eklendi.
- Kutlama karakteri koşu yolunun arkasındaki yükseltilmiş zeminde, yakın nesnelerin arkasında ve paralaksla geçilir; derinlik için saydamlık kullanılmaz. Sarılma öne gelir.
- Engelde sarsılıp düşme ve düşmanda yüzüstü kapanma, her kahramana ayrı 12 kare. Ateş, buz ve çukur animasyonları korunur.
- 3 yeni orijinal PNG / 300 çizilmiş kare. Önceki tüm sürümler, üç dil, çevrimdışı kayıt/güncelleme ve en az 30 saniyelik seviye temposu korunur.

Yedi kaynak/sahne dizisinde 1.344 kontrol ve 91 yerel/canlı/PWA akış yürütmesi geçti. Native CI başarılı: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42913367815 . Sanal standart Xbox/PS4/PS5 eşlemeleriyle gerçek menüler ve üç antrenman savaşı doğrulandı; fiziksel kol donanımıyla test iddiası yoktur. Kapsam ve özgün kayıtlar `docs/VALIDATION.md` / `docs/evidence-v010/` içindedir.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.10.0-windows-x64-Setup.exe` | `AionEndlessRun-0.10.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.10.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.10.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.10.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 10'dır.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0–0.9.0 sürümleri korunmuştur.
