# Aion Endless Run 0.7.0 · Takla, seviye ve kutlama

- **Yeni gerçek animasyonlar:** 164 çizilmiş kare. Aion iki yumruk, baykuş sağ/sol kanat, kurt ısırık/kafa, koyun kafa/çifte hareketlerini sırayla kullanır. Her tıklama/basış bir saldırıdır; basılı tutma otomatik vuruş yapmaz. Saldırı kareleri komşu piksel taşmasını önlemek için ayrı kaydedilir.
- **Yassılmadan takla:** Dört karakterin yuvarlanma döngüleri, en az 0,68 saniyelik hareket ve basılı tutarak devam. Küçük koyunlar aynı yolu geriden takip eder. Dört çizilmiş üst engel: ağaç, buz, rün ve mantar kemeri.
- **Seviye ve anime kutlaması:** Her 900 mesafe bir seviye. Saçı/kıyafeti farklı sekiz yetişkin piksel karakter, dört değişen efekt. Her 10. seviyede yere iniş sonrası 1 saniye sarılma; dünya/düşman/güç saatleri durur, kalpler ve kısa korumayla devam eder. Kutlamalar kapatılabilir; seviye rekoru kaydedilir.
- **Daha nadir mantar:** Varsayılan uygun eşya fırsatı başına %2; ilk 20 saniyede yok, mantarlar arası en az 45 saniye. Ayarda %0–100. Devlikte düzensiz cüce kalabalıkları; 4. seviyeden sonra mantarsız seyrek cüce. Devlik bittiğinde dalga temizliği ve koruma. Yumuşak renk/kamera şiddeti ayrı ayarlanır; hızlı tam ekran flaş yok.
- **Rüzgâr çeşitliliği:** Baykuş rastgele yukarı, ileri veya çapraz akımları yakalar; ileri rüzgâr gerçek hız artışı sağlar. Karakter boyutları normal hareketlerde tutarlı kalır.
- **Korunanlar:** TR/EN/CS otomatik dil ve kayıtlı seçim, başlangıçta dört karakter, koşu sırasında seçim kilidi, çevrimdışı çalışma, yatay mobil çoklu dokunma, karga, düşmana basma, yedi güç, hava/şimşek, iki biyom, gecikmeli sürü, çift zıplama ve kurt deparı.

316 kaynak/sahne kontrolü ve toplam 133 yerel/canlı/PWA akış yürütmesi geçti. Windows kurulum/portable, Linux DEB/AppImage/portable, Mac universal ve çevrimdışı Android emülatör kontrolleri başarılı: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42890445749 .

Doğrulama kapsamı ve gerçek test kayıtları [docs/VALIDATION.md](https://github.com/kaansavukduran/aion_endless_run/blob/main/docs/VALIDATION.md) içindedir. Paketleri `BUILD-RECEIPT.json` ve `SHA256SUMS` tanımlar; önceki sürümler korunur.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.7.0-windows-x64-Setup.exe` | `AionEndlessRun-0.7.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.7.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.7.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.7.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 7'dır.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0, 0.2.0, 0.3.0, 0.4.0 0.5.0 ve 0.6.0 sürümleri korunmuştur.
