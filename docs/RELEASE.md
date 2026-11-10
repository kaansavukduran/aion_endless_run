# Aion Endless Run 0.8.0 · Dört biyom ve robot kovalamacası

- **Boyut ve piksel taşması:** Bütün kahraman kareleri ayrı, saydam paylı dokulara alınır; komşu atlas karesi örneklenmez. Normal koşu/depar/zıplama/saldırı/silah pozlarında baş/kulak oranı ortak referanstır. Yatay pozun toplam yüksekliğine göre karakter büyütme kaldırılır. Mantar devliği kasıtlıdır, küçük koyunlar %72 kalır.
- **Bataklık ve şehir:** Çöl/kar döngüsüne Sisli Bataklık ve Bakır Şehir, ayrı manzara/ışık/ön plan ayrıntıları ve yumuşak geçişler eklendi.
- **Parkur:** Gerçek çukurlar ve düşme/kurtarma hareketi; sandık, kütük, yol bariyeri, kaya, menfez, fıçı; alçak kök ve boru geçitleri. Güvenli karşılaşma aralığı korunur.
- **Seyrek ateş bitkisi:** Uyarılı ağız animasyonu, gerçek ateş topu, yumruk ve üstüne basmayla yenilme. İlk fırsat 26–42 saniyelik koşudan sonra; sonraki uzun aralıklar rastgele, dolu hatlarda doğum ertelenir.
- **Her 10 seviyede boss:** Sarılma → enerji tabancasının verilmesi → özgün Kül Muhafızı robotunu kovalama. Sağ tık/F/mobil Ateş et/RB basılı atış; üç savaş canı ve azalan boss can barı. Alçak atışa zıpla, yüksek atışın altından takla at. Normal engeller/eşyalar/cüceler/bitkiler arenadan temizlenir. Zaferden sonra güç süreleri korunarak normal koşuya güvenli dönüş.
- **84 yeni çizilmiş kare:** Silahlı kahramanlar, robot/bitki/mermi/silah ve yeni parkur. Kaynak PNG’ler değiştirilmedi; asıl satır aralıkları ve siluetler kayıtlı.
- **Korunanlar:** TR/EN/CS, başlangıçta karakter seçimi, çevrimdışı kayıt ve güncelleme, yatay mobil çoklu dokunma, dönüşümlü tek basış saldırıları, gerçek takla, seviye kutlamaları, nadir mantar, rüzgâr ve gecikmeli sürü.

541 kaynak/sahne kontrolü ve 152 yerel/canlı/PWA akış yürütmesi geçti. Native paket doğrulaması: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42898132230 .

Doğrulama kapsamı ve gerçek kayıtlar [docs/VALIDATION.md](https://github.com/kaansavukduran/aion_endless_run/blob/main/docs/VALIDATION.md) içindedir. Önceki sürümler korunur. Paket kimliklerini `BUILD-RECEIPT.json` ve `SHA256SUMS` tanımlar.

## İndir ve aç

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.8.0-windows-x64-Setup.exe` | `AionEndlessRun-0.8.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.8.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.8.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.8.0-android-arm64-x64.apk` | APK normal yoldan kurulur |
| iPhone | Apple hesabı, imzalama ve TestFlight/App Store dağıtımı bekliyor | Yerel portable iPhone paketi yok |

Windows'ta Setup dosyasını aç veya ZIP'i tamamen çıkartıp EXE'yi aç. Linux AppImage'e çalıştırma izni ver ya da DEB'i kur. Mac DMG'deki uygulamayı Applications'a taşı. Android APK, önceki sürümle aynı uygulama kimliği ve imza anahtarını kullanır; versionCode 8'dır.

Oyun ve varlıklar çevrimdışıdır. Web sürümünde ilk tam yükleme internet ister; önbellekleme sonrası çevrimdışı açılabilir. `SHA256SUMS` ve `BUILD-RECEIPT.json` gerçek paketleri tanımlar.

Windows Authenticode ve macOS Developer ID/noter onayı yoktur. macOS geliştirme amaçlı ad-hoc imzalıdır; Gatekeeper açılışı engelleyebilir. Fiziksel cihaz kapsamı ve gerçek test kayıtları `docs/VALIDATION.md` içindedir. Önceki 0.1.0–0.7.0 sürümleri korunmuştur.
