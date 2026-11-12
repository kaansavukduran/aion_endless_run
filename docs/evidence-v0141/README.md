# AIONIA v1.4 · 0.14.1 doğrulaması

Godot 4.6.3, 2691 kaynak/sahne kontrolü; 199 gerçek tarayıcı kontrolü; 6 web paket sözleşme testi. Yerel web derlemesi `208ceac62cc20d3e`. Chromium ve gerçek masaüstü Gecko kullanıldı; telefon/tablet viewportları ve dokunma emüle edildi. Fiziksel Poco/Xbox/PS cihazı veya ekran okuyucu denendiği iddia edilmez.

Kaynak/sahne sonuçları `source/`, normal girdi ve salt okunur gözlemle alınan tarayıcı sonuçları `browser/`, gerçek görüntüler `screenshots/`. Kol cihazı Gamepad API düzeyinde sanaldır; dünya durumu değiştirilmez. Boss otomasyonu normal sanal kol girdilerini tarayıcı karesi içinde zamanlar. Birbirinden bağımsız dokunma vakaları gerçek menüden yeni koşu başlatır; kayıt/protokol beklemesinin doğal bir engele çarpmayı giriş arızası gibi göstermesi önlenir.

`asset-integrity.json`: 40 oyun PNG'sinin tümü taban commit ile byte düzeyinde aynı. İlk 03fd1f4 referansından beri korunan anatomik hizalama/pafta kayıtları regresyon testlerindedir. Yeni kahraman çizimi yoktur. Sistem fontunun Web fallback'i gerçek ölçümde Open Sans SemiBold'dur; Pixelify logosu ayrı kalır.

Aktarım/senkronizasyon notu: hızlı ayar değişimi sonrası bazı eski IndexedDB anlık görüntüleri gözlendi. Son atomik `save.tmp → save.cfg` adımından sonra resmi `JavaScriptBridge.force_fs_sync()` çağrılır. Motor kaynağında bu çağrı, devam eden aktarım bitince ele alınan `idb_needs_sync` bayrağını işaretler. Gerçek dosya/yenileme testi uygulanır; tek başına bunun tarayıcının tüm kapanış zamanlamalarını garanti ettiği söylenmez.

Kaynak commit'i hazırlık anında native CI ve yayın henüz çalışmamıştır. Bu çıktılar için sürümün `BUILD-RECEIPT.json` dosyası, GitHub Actions ve son Drive teslim raporu yetkilidir. iOS native imzası, macOS Developer ID/noter ve Windows Authenticode bu çalışmada sağlanmadı.

0.14.1 gerçek Android 0.14.0 görüntüsündeki ana menü çakışmasını düzeltir; `portrait-16x9-main.png` yeni 450×800 durumudur. 1440×2560, üç dil ve iki metin ölçeği kaynak matrisine eklendi. Native emülatör testi aynı panel/karakter başlığı bölgelerinin ayrılığını da gerçek logdan denetler; bu kaynak anında yeni CI sonucu henüz yoktur.

ConfigFile/IndexedDB korunur. Küçük, sürümlü `AionStorage` localStorage kurtarma kopyası atomik dosya kaydıyla birlikte son seçimi senkron tutar. Yedi ekranda hemen yenileme, eski PWA göçü ve bozuk/engellenmiş yardımcı depolama sözleşmesi gerçekten denendi. Henüz bitmemiş IDB aktarımının tüm iç motor zamanlamasının kesin tek nedeni kanıtlandığı iddia edilmez.

Tekrar doğrulamada ağır eşzamanlı yazılım GPU yükünde kısa zıplama anını kaçıran sürücü gözlemi görüldü. İki parmak koordinatları ilk basıştan önce alınır, eşzamanlı gerçek havada/zıpla-basılı/saldır durumunu pasif MutationObserver kaydeder. Menü ve PWA testleri ayrıca sıralı koşuda geçti; bu bekleme/gözlem düzeltmeleri oyun eylemlerini değiştirmez.
