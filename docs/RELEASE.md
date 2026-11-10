# Aion Endless Run 0.4.0 · Yeni animasyonlar ve web güncellemeleri

Bu sürüm, sürü zıplamasını ve rüzgârı oynanışa bağlar. Yeni 18 karelik ek pafta; kurdun daha belirgin deparını, baykuşun yükselen hava kanat çırpışını ve koyunun esneyen zıplama/yumuşak inişini içerir. Önceki koşu, donma ve kül paftaları korunur.

- **Sıralı sürü:** Space önce öndeki koyunu zıplatır. İkinci koyun öndekinin zıpladığı noktaya geldiğinde, üçüncü de onu izleyerek zıplar. Gecikme gerçek koşu mesafesine bağlıdır; hız değişince de aynı yol korunur. Duraklatma hepsinin konumunu korur.
- **Hareketli depar rüzgârı:** Sabit üç çizginin yerine değişen uzunluk, kıvrım ve saydamlıkla geriye akan rüzgâr izleri vardır. Deparın yeni adım ve kuyruk kareleri de hareket eder.
- **Yükselen hava:** Aralıklı beliren, yukarı akan işaretlerle görünen rüzgâr bölgeleri vardır. Baykuş tek zıplamasından sonra basılı tutarak süzülürken akıma girerse biraz yükselir ve yeni kanat vuruşu animasyonu oynar. Bırakınca normal düşüşe döner; rüzgâr ikinci zıplama vermez, yükselme sınırlıdır.

Web ve indirilebilir paketler v0.4.0'dır. Önceki çevrimdışı önbellekten güncelleme ve kayıt koruma sürer. Açık 0.3 oyununda yeni sürüm düğmesi belirir; düğme önce duraklatıp kaydeder, ardından yeni sürümü açar.

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
| Windows x64 | `AionEndlessRun-0.4.0-windows-x64-Setup.exe` | `AionEndlessRun-0.4.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.4.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.4.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.4.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 4'dir.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0, 0.2.0 ve 0.3.0 sürümleri korunmuştur.
