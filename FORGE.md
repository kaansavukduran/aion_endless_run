# Forge · Aion Endless Run

Yetkili kaynak: https://github.com/kaansavukduran/aion_endless_run · `main`.

Yeni bağımsız Godot 4.6.3 oyunu. FireAxolotl kaynaklarına değişiklik yapılmadı. Kaynak PNG'ler değiştirilmeden alındı ve provenance kayıtları korundu. Aion 6×8 koşu paftası gerçek karelerini kullanır. 0.2.0 için wolf/sheep/owl kimliklerinden yeni sağa bakan 6×6 koşu/zıplama/süzülme paftası üretildi. Orijinal paftalar korunur; yeni PNG değiştirilmeden çizilir, hücre taban çizgileri kayıtlıdır.

Ana akış: Space/sol tık/dokunma zıplama, Esc duraklatma; karakter seçimi, ayarlar, gerçek skor ve kristaller, kalıcı rekor/tercihler, ateş/buz sonlanması, iki biyom, gündüz/gece. Ses yerel sentezlenir. Ağ çağrısı/telemetri yok.

`tests/test_game.gd`: 84 anlamlı fizik ve gerçek sahne/menü/kayıt kontrolü. Son platform ve görsel doğrulama: `docs/VALIDATION.md`. Release kapsamı: `docs/RELEASE.md`. Paketleme: `.github/workflows/build.yml`, `packaging/`, `docs/BUILD.md`. Özel anahtarları kaynağa veya arşive ekleme.

Öncelikli sonraki işler: fiziksel dokunmatik cihaz deneyimi, Apple Developer ID/noter onayı ve iOS TestFlight kurulumu. Kaynak projenin iOS hedefinin varlığı iPhone'da kurulabilir paket üretildiği anlamına gelmez. Mevcut ilk beta paketlerini ve etiketlerini koru.

İlk teslim 0.1.0 beta: Windows NSIS+ZIP, Linux DEB+AppImage+tar.gz, macOS universal DMG+ZIP, Android release APK ve ek Web arşivi. 40 kaynak/gerçek sahne kontrolü ve 12 gerçek tarayıcı kontrolü. Native Android emülatör testi ANGLE/SwiftShader ile ekran içeriğini ve offline başlangıç/Space/Esc akışını denetler; eski GLES çeviricisinin boş ekranı başarısız kabul edilir. Windows ve Linux kurulumdan sonra da açılır; macOS native ilk açılışı CI’da geçti.

Android release imza anahtarı `/workspace/work/signing` özel derleme alanındadır, kaynakta veya Release içinde değildir. GitHub secrets yazma denemesi 403 döndürdü. İleriki imzalı güncellemeler için aynı anahtarın güvenli saklanması ve sahibinin GitHub Actions secret ayarını tamamlaması gerekir; `docs/BUILD.md` izlenir. iOS App Store/TestFlight ve macOS Developer ID/noter onayı tamamlanmadı.

0.1.0 için doğrulanmış oyun kodu: `c36b105`. Tam başarılı CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42825770482 . Sonraki yalnızca belge/ekran görüntüsü kaydı oyun kaynaklarını değiştirmez. Release içindeki BUILD-RECEIPT.json ile SHA256SUMS gerçek yüklenen dosyaları tanımlar.

## 0.2.0 geliştirmesi

Aion çift zıplar. Baykuş tek zıplar; Space/dokunma basılıyken düşüşte süzülür ve bırakınca normal düşer. Koyun aralıklı görünen arkadaşları temasla toplar; toplam en fazla 3 koyun, her koyun 1 can. Kurt Shift veya karakter üzerine basılı tutularak 1.55 kat hızlanır; ikinci dokunma parmağıyla aynı anda zıplanır. Tüm basılı kontroller duraklatma, odak kaybı ve karakter seçiminde temizlenir.

Yerelde 84 kaynak/sahne kontrolü, 12 temel web akışı ve 12 yeni yetenek/touch akışı geçti. Ekran görüntüleri `docs/evidence-v02/` içinde kaydedilir. Vercel kaynak derlemesi hem hazır Godot hem sıfırdan resmi indirmeyle doğrulandı. Kullanıcının Vercel adresi: https://aionendlessrun.vercel.app/ . Bu adresin 0.2.0 yayını yeni main gönderiminden sonra ayrıca doğrulanır. Native CI ve 0.2.0 Release teslimi tamamlanınca son kayıt eklenir; 0.1.0 korunur.

## 0.2.0 teslim sonucu

Oyun kodu `3af5c07`; paket/native CI https://github.com/kaansavukduran/aion_endless_run/actions/runs/42842185612 tamamen başarılı. Sonraki değişiklikler test zamanlaması/belgelerdir. Android tutma sırasında görüntü alma kontrolü https://github.com/kaansavukduran/aion_endless_run/actions/runs/42844605684 ile tekrar geçti; yeni baykuş karesi native ekranda açıldı.

Yayın: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.2.0 . Yayımlama işi: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42845252854 . 9 paket + BUILD-RECEIPT.json + SHA256SUMS yüklendi; Android imzası ve yayımlanan dosya SHA-256 değeri doğrulandı. 0.1.0 etiketi ve 11 varlığı korundu. APK geçici olarak aynı GitHub deposunun release-assets/v0.2.0 dalından Actions’a aktarıldı; yayımdan sonra bu geçici dal silindi. İmza anahtarı aktarılmadı.

Vercel: https://aionendlessrun.vercel.app/ . 84 kaynak/sahne + 24 yerel gerçek tarayıcı kontrolü geçti. Canlı kaynaklardan da 12 temel ve 12 yetenek kontrolü geçti. Bu bulut ortamında Chromium sistem proxy CA’sını tanımadığı için canlı test trafiği sistem CA’sıyla TLS doğrulayan bir sürücüden geçirildi; worklet modülleri aynı doğrulanmış içerikten yüklendi. Canlı PWA service-worker önbellek kurulumu bu sürücüde doğrulanmadı; native çevrimdışı test ve webin yüklenmiş halde çevrimdışı oynanması ayrıdır.

## 0.3.0 animasyon ve web güncelleme düzeltmesi

Kullanıcı portable sürümü doğru, Vercel görünümünü eski buldu. Önceki doğrulama eski bir tarayıcı profilinin cache-first Godot servis çalışanından yükseltmesini kapsamıyordu. Üç karakter için ayrı 48 karelik Aion tarzı koşu/zıplama/donma/ateş/kül/yetenek/iniş paftaları eklendi. Dosyalar orijinal çıktı olarak korundu; bölge ve zemin metadata ile hizalanır. Kurtta depar, baykuşta süzülme ayrı animasyon kullanır; koşu mesafeye bağlandı. Tüm önceki yetenekler korundu.

Web motoru ve PCK aynı içerik kimliğine ait dosya adlarını kullanır. Sabit eski worker URL’si yeni atomik çevrimdışı önbelleği kurar, skipWaiting/claim ile eski kabuktan bir kez geçer. Kullanıcı IndexedDB kaydı silinmez. Sonraki güncellemeler aktif koşuyu bölmeden düğme gösterir; tıklanınca pause/save ve IDBFS flush sonrasında açılır. HUD ve canvas sürüm numarası verir. 96 Godot + 35 gerçek browser/PWA kontrolü geçti. 0.1.0’dan aynı origin üzerinde çevrimdışı önbellek, kayıt koruması, 0.3'e geçiş ve sonraki düğmeli güncelleme gerçek worker ile doğrulandı. Paketler/yayın için CI sonuçları ayrıca kaydedilir.

## 0.3.0 tamamlanan teslim

Oyun/paketleme kodu `7183dc8`. Native CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42851228198 tamamen başarılı (Windows kurulum/portable, Linux DEB/AppImage/portable, macOS universal app/DMG, Android çevrimdışı emülatör). Yayın: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.3.0 . Yayımlama işi: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42852589885 . 9 paket ve 2 doğrulama dosyası yayımlandı; GitHub asset digest/size değerleri receipt ile, yayımlanan APK da yerel imzalı dosyayla eşleşiyor. Android uygulama kimliği ve sertifikası aynı, versionCode 3. Geçici APK aktarım dalı yayın doğrulaması sonrası kaldırıldı. Eski sürümler korundu.

Canlı Vercel adresinde 12 temel + 12 yetenek/touch kontrolü geçti. Gerçek yayımlanan worker/engine/PCK dosyaları TLS doğrulamasıyla indirildi; 0.1.0 ve 0.2.0 eski arşivlerinden ayrı ayrı aynı yerel origin üzerinde yükseltme testlerinin 11'er kontrolü geçti. Hiçbir worker unregister/IndexedDB temizliği yapılmadı; kayıtlar korundu, güncel sürüm offline yeniden açıldı. Sonraki sürüm düğmesi açık koşuyu kesmeden belirdi; tıklama pause/save sonrasında açtı. Bulut Chromium proxy CA kısıtı nedeniyle bu gerçek-worker testi üretim dosyalarının yerel aynasında yapıldı; doğrudan canlı kontrollerde TLS doğrulayan yönlendirme sürücüsü kullanıldı. Native Android ekranında v0.3.0 yeni koşan baykuş görüldü; gerçek fiziksel cihaz/iOS imza durumu için yeni iddia yok.

## 0.4.0 sıralı sürü ve rüzgâr

Kullanıcı ikinci ve üçüncü koyunun öndekinin zıpladığı dünya noktasına geldiğinde sırayla zıplamasını, kurdun sabit üç hız çizgisinin hareketli rüzgâra dönüşmesini ve baykuşun aralıklı havada yükselen rüzgâr yakalamasını istedi. Sürü artık liderin kısa mesafe/poz geçmişini 64 ve 128 piksel geriden örnekler; hız bağımsız uzamsal zamanlama, farklı uçuş/iniş kareleri, pause/reset koruması vardır. Bellek geçmişi sınırlıdır. Kurt rüzgârı 12 bağımsız eğri/fade fazıyla akar. Baykuş görünür, geçen akımlarda basılı tutarak gerçekten yükselir; sınırlı yükseklik, bırakma ve sonlu uçuş korunur. Yeni 18 karelik ek orijinal pafta depar/kuyruk, yükselen hava kanatları, koyun esneme ve yumuşak inişini sağlar. Eski donma/kül paftaları korunur. 121 kaynak/sahne kontrolü geçti. Yayın/native sonuçları tamamlanınca ayrıca kaydedilir.
