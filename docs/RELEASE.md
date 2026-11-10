# Aion Endless Run 0.12.0 · Dört ayaklı kurt ve sabit süzülen baykuş

- Kurt Shift/mobil depar sırasında dört ayak üzerinde koşar; normal koşu korunur.
- Kurt normalde ileri atılarak ısırır ve sıradaki saldırıda pençe savurur. Önde üç tırnak izi görünür. Depar sırasında ayrı bir sıçrayarak ısırma animasyonu vardır; Shift’i saldırı ortasında bırakmak pozu değiştirmez.
- Baykuş süzülürken yüz ve gövde sağa sola sıçramaz. Hafif kanat ucu hareketleri sürer. Rüzgâra girip çıkarken aynı süzülme dizisi kullanılır.
- Baykuş yerde kanatlarını sırayla öne savurur; havadayken açık kanat ve toplanmış ayaklarla gagasını ileri uzatır.
- Yeni kareler gerçek yakın gözden hizalanır. Altın tüy/gaga veya uzak gözü yanlışlıkla merkez seçme sorunu düzeltildi. İki özgün PNG, 64 çizilmiş poz. Aion ve koyunun beğenilen çizimleri korunur.

Dokuz kaynak/sahne dizisinde 1.975 kontrol, 55 yerel/canlı/PWA akış yürütmesi ve bütün native işler geçti. Native CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42926160897 . Dokuz paket ve iki bütünlük dosyası yayımlandı; paket özetleri, aynı imzalı APK ve indirilen Mac arşivi doğrulandı. Kayıtlar docs/evidence-v012 içindedir. Önceki boss, gamepad, dil, sürü ve çevrimdışı özellikleri korunur.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.12.0-windows-x64-Setup.exe` | `AionEndlessRun-0.12.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.12.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.12.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.12.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 12’dir.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0–0.11.0 sürümleri korunmuştur.
