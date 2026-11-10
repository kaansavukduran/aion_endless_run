# Aion Endless Run 0.5.0 · Savaş, dev mantar ve değişen koşular

- **Saldırı ve üstüne basma:** Aion yumruk, baykuş kanat, koyun kafa, kurt ısırık saldırısı yapar. Space ile zıpla; sol tık/J/Vur ile hasar ver. Düşerken karga veya cücenin üstüne basarak sek, kombo puanı kazan.
- **Eğil:** Aşağı ok/S/Ctrl/Eğil basılıyken alçak dalların altından geç. Kargaların yüksek ve alçak uçuşları farklı kararlar ister.
- **Dev mantar:** 10 saniyeliğine büyü, küçük kırmızı şapkalı cüce dalgalarıyla savaş, engelleri parçala. Hafif renk/kamera hareketi ayrı ayardan kapatılır.
- **Yedi toplanabilir güç:** Mantar, zincir şimşeği, yavaşlatan zaman kumu, hızlandıran çizme, bir darbelik kalkan, kristal mıknatısı ve can yaprağı. Keşifler yerelde saklanır; geçici güçler yeni koşuda sıfırlanır.
- **Çeşitlilik:** Değişken aralıklar ve karışan karşılaşmalar, hızlanıp yavaşlayan tempo, yağmur/kar/kum/fırtına ve seyrek gök şimşeği. Kısa hedefler +100 puan verir.
- **102 yeni sprite karesi:** Dört saldırı ve eğilme, karga uçuş/dalış/yenilme, cüce koşu/saldırı/yenilme, animasyonlu eşya ve dal paftaları. Eski koşu/donma/kül animasyonları korunur.
- **Belirgin sıralı sürü:** Takipçiler 112 ve 224 piksel geriden aynı yolda zıplar; ilk hızda yaklaşık 0,35/0,70 saniye gecikme.
- **Telefon yatay:** Yön kilidi desteklenmediğinde döndürülen oyun alanı; aynı anda zıplama ve saldırı için bağımsız parmaklar.

Aion çift zıplaması, baykuş süzülmesi/yükselen hava, koyunun en fazla üç canı ve kurdun Shift/karaktere basılı tutma deparı korunur. Kumanda: A zıpla, X vur, B eğil, LB depar, Start duraklat. Esc duraklatır. Türkçe/English, çevrimdışı oyun, önceki kayıt ve web önbelleğinden güncelleme korunur. Araştırma ve tasarım kararları: `docs/GAME-DESIGN.md`.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.5.0-windows-x64-Setup.exe` | `AionEndlessRun-0.5.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.5.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.5.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.5.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 5'tir.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0, 0.2.0, 0.3.0 ve 0.4.0 sürümleri korunmuştur.
