# Aion Endless Run 0.3.0 · Koşu arkadaşları ve karakter yetenekleri

Baykuş, kurt ve koyunun her biri için Aion tarzında ayrı 48 karelik pafta: bekleme, altı gerçek koşu adımı, zıplama, donma, ateş/duman, türe özgü kül, özel yetenek ve iniş. Koşu kareleri mesafeyle ilerler; duraklatınca poz korunur. Baykuşta açık kanatlı süzülme, kurtta öne yatık depar döngüsü kullanılır.

Web'de eski oyunu tutan önbellek düzeltildi. Eski 0.1/0.2 servis çalışanı aynı adres üzerinden yeni sürüme geçer; rekor/ayarların IndexedDB kaydı silinmez. Yeni sürümlerde koşuyu bölmeyen bir **Yeni sürüm hazır · Güncelle** düğmesi vardır. Oyun dosyaları derlemeye özgü adlar taşır; yarım indirme eski çevrimdışı oyunu değiştirmez. HUD'da v0.3.0 görünür.

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
| Windows x64 | `AionEndlessRun-0.3.0-windows-x64-Setup.exe` | `AionEndlessRun-0.3.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.3.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.3.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.3.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 3'dir.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0 ve 0.2.0 sürümleri korunmuştur.
