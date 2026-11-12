# AIONIA v1.4 · 0.14.1 doğrulaması

Godot 4.6.3, 2879 kaynak/sahne kontrolü; 207 gerçek tarayıcı kontrolü; 6 web paket sözleşme testi. Yerel web derlemesi `8ed8d7dd9c646fee`. Chromium ve gerçek masaüstü Gecko kullanıldı; telefon/tablet viewportları ve dokunma emüle edildi. Fiziksel Poco/Xbox/PS cihazı veya ekran okuyucu denendiği iddia edilmez.

Kaynak/sahne sonuçları `source/`, normal girdi ve salt okunur gözlemle alınan tarayıcı sonuçları `browser/`, gerçek görüntüler `screenshots/`. Kol cihazı Gamepad API düzeyinde sanaldır; dünya durumu değiştirilmez. Boss otomasyonu normal sanal kol girdilerini tarayıcı karesi içinde zamanlar. Birbirinden bağımsız dokunma vakaları gerçek menüden yeni koşu başlatır; kayıt/protokol beklemesinin doğal bir engele çarpmayı giriş arızası gibi göstermesi önlenir.

`asset-integrity.json`: 40 oyun PNG'sinin tümü taban commit ile byte düzeyinde aynı. İlk 03fd1f4 referansından beri korunan anatomik hizalama/pafta kayıtları regresyon testlerindedir. Yeni kahraman çizimi yoktur. Sistem fontunun Web fallback'i gerçek ölçümde Open Sans SemiBold'dur; Pixelify logosu ayrı kalır.

Aktarım/senkronizasyon notu: hızlı ayar değişimi sonrası bazı eski IndexedDB anlık görüntüleri gözlendi. Son atomik `save.tmp → save.cfg` adımından sonra resmi `JavaScriptBridge.force_fs_sync()` çağrılır. Motor kaynağında bu çağrı, devam eden aktarım bitince ele alınan `idb_needs_sync` bayrağını işaretler. Gerçek dosya/yenileme testi uygulanır; tek başına bunun tarayıcının tüm kapanış zamanlamalarını garanti ettiği söylenmez.

Kaynak commit'i hazırlık anında native CI ve yayın henüz çalışmamıştır. Bu çıktılar için sürümün `BUILD-RECEIPT.json` dosyası, GitHub Actions ve son Drive teslim raporu yetkilidir. iOS native imzası, macOS Developer ID/noter ve Windows Authenticode bu çalışmada sağlanmadı.

0.14.1’de gerçek 0.14.0 Android PNG’sindeki Settings/karakter başlığı çakışması giderildi. Sistem fontuyla kartlar büyüdüğünde önizleme alanı yer açar; başlık metni gerçek genişlik verildikten sonra şekillenir. Aksi halde sıfır genişlikten kalan 1.181 birimlik eski Label yüksekliği görülebiliyordu. DejaVu Sans/Liberation Sans ile yatay, 9:16, 3:4 ve dar masaüstü kaynak kontrolleri geçer. Sekiz gerçek tarayıcı ekran durumu ve native TR/EN/CS görüntüleri ektedir. Native API30 testinde 7 kontrol geçti; fiziksel cihaz testi değildir. `native-provenance.json` gerçek commit ve CI/artifact bağlantısıdır.

ConfigFile/IndexedDB korunur; sürümlü küçük localStorage kurtarma kopyası hızlı yenilemede son seçimi korur. Yerel 207 tarayıcı kontrolü, 6 paketleme sözleşmesi ve 2.879 kaynak/sahne kontrolü gerçektir. Görsel/oyun PNG’lerinin 40’ı değişmedi. Hareket test sürücüsü hızlı aşağı kaydırmayı tek CDP gesture komutuyla üretir, kısa geçişleri pasif gözlemle yakalar ve iki parmak koordinatlarını ilk basıştan önce çözer. Protokol gecikmesi oyunda dokunma arızası gibi sunulmaz.
