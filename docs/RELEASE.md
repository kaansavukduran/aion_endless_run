# Aion Endless Run 0.14.0

AIONIA v1.4 uygulaması: varsayılan koyu tema ve sistem/sans yazı, saklanan açık/koyu/sistem seçimi, pixel alternatifi ve büyütülmüş metin; sıcak, keskin çerçeveli kompakt arayüz. Uzun karakter adı ve karakter seçimi başlığı gerçek karta sığar. %200 metinde gerekli menü kaydırması korunur.

Kullanıcının seçtiği bölünmüş telefon kontrolleri: solda Zıpla, sağda Vur/Takla; boss'ta Vur yerinde Ateş et. Depar erişilebilir; eski sağ küme alternatif. Portre/yatay ve çoklu dokunma korunur. Kol eylemleri yeniden atanabilir; ölü bölge ve isteğe bağlı, varsayılan kapalı titreşim; güncel tuş yardımı ve kesilince duraklama.

Siyah Fragaria açılışı gerçek ilerlemeye bağlı on segmentli çubukla web ve native sahnede. Çilek kutlaması arka planda büyük FRAGARIA ve sekiz mevcut kutlama kimliği kullanır; ödül vermez. Kahraman çizimleri değiştirilmez. Firefox PCK doğrulama, eski worker güncellemesi ve çevrimdışı kayıtlar korunur; son atomik ayar taşımasından sonra açık FS senkronizasyonu istenir.

Kaynak doğrulaması: 2.539 sahne/model kontrolü, 184 gerçek tarayıcı kontrolü ve 5 paket sözleşme testi. [Kapsam ve NOT TESTED alanları](AIONIA-QA.md). Paket makbuzu gerçek native CI sonuçlarına bağlanır; testten önce yayın başarılı denmez.

## İndirme / platform

[0.14.0 sürümü](https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.14.0) bütün doğrulamalar bitince Windows kurulum/portable, Linux deb/AppImage/portable, macOS universal DMG/portable, sabit anahtarla imzalı Android APK ve web offline arşivini birlikte sunar. Önceki sürümler korunur. `SHA256SUMS` ve `BUILD-RECEIPT.json` dosya boyutu, özet, kaynak commit ve CI bağlantısını taşır.

Android uygulama kimliği ve imza korunur, versionCode 15'tir. macOS paketleri yalnız ad-hoc imzalıdır; Developer ID/noter yok. Windows Authenticode yok. iPhone için web/PWA hedefi vardır; yerel iOS/App Store/TestFlight için sahibin Apple imzası gerekir. Fiziksel Poco/Xbox/PS/iPhone ve ekran okuyucu testi bu ortamda yapılmadı.
