# Aion Endless Run 0.1.0 · İlk oynanabilir beta

FireAxolotl'daki sevimli Aion koşusu artık bağımsız bir oyun. Firefox/eklenti veya hesap gerekmez; oyunun kendisi çevrimdışı çalışır.

- Space, tıklama veya dokunma ile zıpla. Esc ile duraklat ve kaldığın yerden devam et.
- Orijinal Aion koşu, zıplama, donma, ateş ve kül kareleri.
- Aion, Baykuş Ömer, Accursed Wise Wolf ve Blessed Ignorant Sheep. Arkadaşlar mevcut paftalardan piksel görünümüyle çizilir; aynı hız ve çarpışma kuralları.
- Katmanlı piksel manzaralar, Kehribar Çölü/Ayaz Vadisi ve gündüz/gece döngüsü.
- Mesafe, engel ve kristal puanları; cihazda saklanan rekor ve tercihler.
- Türkçe/English, kapatılabilir ses ve dekoratif animasyon.

## İndirme ve kurulum

Bu Release'ın **Assets** bölümündeki dosyalardan seç:

| Cihaz | Kurulum | Taşınabilir |
| --- | --- | --- |
| Windows x64 | `AionEndlessRun-0.1.0-windows-x64-Setup.exe` | `AionEndlessRun-0.1.0-windows-x64-portable.zip` |
| Linux x64 | `AionEndlessRun-0.1.0-linux-x64.deb` | `.AppImage` veya `-portable.tar.gz` |
| macOS Intel / Apple Silicon | `AionEndlessRun-0.1.0-macos-universal.dmg` | `-macos-universal-portable.zip` |
| Android ARM64 / x64 | `AionEndlessRun-0.1.0-android-arm64-x64.apk` | APK kurulur; masaüstü portable biçimi uygulanmaz |
| iPhone | Apple imzası ve App Store/TestFlight dağıtımı bekliyor | Yerel iPhone portable paketi yok |

Windows kurulum dosyasına çift tıkla. Portable ZIP'i tamamen çıkart ve EXE'yi aç. Linux AppImage için dosyaya çalıştırma izni ver; DEB'i paket yöneticisiyle kur. macOS DMG içindeki uygulamayı Applications'a taşı veya ZIP'i çıkart. APK'yı Android'de açıp sistemin kurulum adımlarını izle. İlk ekranda **Koşuya başla** düğmesini görmelisin.

**Sınırlar:** Windows paketi Authenticode, macOS paketi Developer ID imzasına sahip değil. macOS Developer ID/notarization tamamlanmadığı için Gatekeeper uygulamayı engelleyebilir. Android paket imzası bütünlük ve güncelleme kimliği içindir, Play Store yayını değildir. iPhone için Apple Developer hesabı, Xcode imzası ve TestFlight/App Store süreci henüz yok. Fiziksel Android, Windows ve macOS cihaz testlerinin kapsamı `docs/VALIDATION.md` içinde ayrıca belirtilir.

Kaynak kodu bu etiketin GitHub kaynak arşividir. `SHA256SUMS` indirilen varlıkları karşılaştırmak içindir. İlk beta olduğu için kararlı sürüm olarak sunulmaz; sonraki sürümler önceki Release dosyalarını koruyacaktır.
