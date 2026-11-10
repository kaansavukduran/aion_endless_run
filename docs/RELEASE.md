# Aion Endless Run 0.2.0 · Koşu arkadaşları ve karakter yetenekleri

Diğer karakterlerin bekleme kareleri yerine sağa bakan yeni piksel koşu paftası kullanılır. Wolf/koyun adımları ve baykuş kanatları kare kare değişir; zıplamada ayrı hava pozları vardır.

- **Aion:** Space veya dokunmayı bırakıp tekrar basarak havada bir kez daha zıpla. Yere inene kadar en fazla iki zıplama.
- **Baykuş Ömer:** Tek zıpla, Space/ekran dokunmasını basılı tutarak düşüşte süzül. Bırakınca normal düşüş. Süzülme yükseltmez ve sonsuz uçuş sağlamaz.
- **Blessed Ignorant Sheep:** Belirli mesafelerden sonra yerde beliren koyunları gerçekten temas ederek topla. Toplam en fazla üç koyun birlikte koşar. Her koyun bir can; çarpışma bir koyunu eksiltir, son koyunda koşu biter. Aynı temas arka arkaya iki can eksiltmez.
- **Accursed Wise Wolf:** Shift'e veya karakterin üstüne basılı tutarak hızlan. Bırakınca normal hız. Mobilde bir parmakla kurdu tutarken ikinci parmakla başka yere dokunup zıplayabilirsin. Kumandada X hızlandırır; A zıplatır/süzdürür.
- Duraklatma, odak kaybı ve karakter değiştirme basılı kontrolleri temizler. Rekorlar ve ayarlar korunur. Azaltılmış animasyonda da yetenekler çalışır.
- Vercel için kaynak koddan web derleme ayarı eklendi. Framework: Other; Build Command: `python3 packaging/build_web.py`; Output Directory: `build/web`. Kurulum anlatımı: `docs/VERCEL.md`.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.2.0-windows-x64-Setup.exe` | `AionEndlessRun-0.2.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.2.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.2.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.2.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 2'dir.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. 0.1.0 sürümü ve dosyaları korunmuştur.
