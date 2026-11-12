# AIONIA v1.4 · 0.14.0 doğrulaması

Godot 4.6.3, 2549 kaynak/sahne kontrolü; 190 gerçek tarayıcı kontrolü; 6 web paket sözleşme testi. Yerel web derlemesi `9bb15b0a19e43f88`. Chromium ve gerçek masaüstü Gecko kullanıldı; telefon/tablet viewportları ve dokunma emüle edildi. Fiziksel Poco/Xbox/PS cihazı veya ekran okuyucu denendiği iddia edilmez.

Kaynak/sahne sonuçları `source/`, normal girdi ve salt okunur gözlemle alınan tarayıcı sonuçları `browser/`, gerçek görüntüler `screenshots/`. Kol cihazı Gamepad API düzeyinde sanaldır; dünya durumu değiştirilmez. Boss otomasyonu normal sanal kol girdilerini tarayıcı karesi içinde zamanlar. Birbirinden bağımsız dokunma vakaları gerçek menüden yeni koşu başlatır; kayıt/protokol beklemesinin doğal bir engele çarpmayı giriş arızası gibi göstermesi önlenir.

`asset-integrity.json`: 40 oyun PNG'sinin tümü taban commit ile byte düzeyinde aynı. İlk 03fd1f4 referansından beri korunan anatomik hizalama/pafta kayıtları regresyon testlerindedir. Yeni kahraman çizimi yoktur. Sistem fontunun Web fallback'i gerçek ölçümde Open Sans SemiBold'dur; Pixelify logosu ayrı kalır.

Aktarım/senkronizasyon notu: hızlı ayar değişimi sonrası bazı eski IndexedDB anlık görüntüleri gözlendi. Mevcut ConfigFile/IndexedDB akışı yanında sürümlü küçük localStorage kurtarma kopyası, son ayarı eşzamanlı korur; daha yeni revizyon yüklenir, rekorlar/progress birleştirilir. Anında yeniden yükleme altı viewportta doğrulandı. Son atomik `save.tmp → save.cfg` adımından sonra ayrıca resmi `JavaScriptBridge.force_fs_sync()` çağrılır. Motor kaynağında bu çağrı, devam eden aktarım bitince ele alınan `idb_needs_sync` bayrağını işaretler. Gerçek dosya/yenileme testi uygulanır; tek başına bunun tarayıcının tüm kapanış zamanlamalarını garanti ettiği söylenmez.

Kaynak commit'i hazırlık anında native CI ve yayın henüz çalışmamıştır. Bu çıktılar için sürümün `BUILD-RECEIPT.json` dosyası, GitHub Actions ve son Drive teslim raporu yetkilidir. iOS native imzası, macOS Developer ID/noter ve Windows Authenticode bu çalışmada sağlanmadı.

İlk GitHub CI add2d59 üzerinde Çekçe koyun adının taşmasını yakaladı. Düzeltme, gerçek sahne ağacındaki Label ölçümünü ve iki alternatif sistem fontu regresyonunu kullanır. Bu ilk başarısız deneme saklanır; başarı gibi etiketlenmez. Browser sonuçlarında her süitin gerçek export kimliği ayrıca kayıtlıdır; kontrol/animasyon süitlerinin ilgili kodu son yerleşim/kayıt düzeltmesinde değişmedi.
