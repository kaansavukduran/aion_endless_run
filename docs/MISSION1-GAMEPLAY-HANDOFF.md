# Mission 1 · Oynanış geliştirme devri

Bu belge Mission 1 oynanış çalışmasının tek devir defteridir. [M1-DELIVERY.md](M1-DELIVERY.md) tarihsel teslim kaydıdır; bu çalışmanın güncel durumu buradadır. Mission 2 geliştirmesi kullanıcı Mission 1'i kabul edene kadar başlamaz; Mission 1 sonucu oyuncuyu Mission 2'ye göndermez.

## Başlangıç ve kaynaklar

- Başlangıç: `main` 24fb2850e9eaa7274415f9fa8342956be48411ca (0.29.0, Godot 4.6.3/GDScript). Dal: `ccr-bb237833-janqhg`; her tur PR ile `main`'e alınır.
- Okunan Drive belgeleri (21 Kasım 2026, Google Drive bağlayıcısı): `01_Bolum_Incelemesi.md` (MS3 Mission 1), `04_Bolum_Ritmi_Rotalar_ve_Hikaye.md`, `baslangic_backlog.csv`. Diğer klasör belgeleri listelendi, bu turda tam okunmadı. Canlı AIONIA standardı ve regresyon kaydı bu turda okunmadı; repo içi `AIONIA_STANDARD.md` (son okuma v1.7) ve `.agents/skills/*` sözleşmeleri uygulandı.
- Repo talimatları: `AGENTS.md` yok. `.agents/skills/unslop` ve `fragaria-unslop` (proje sözleşmesi, regresyon kapıları) okundu.

## Faz 0 · Teşhis (kod ve çalışan oyun)

| Soru | Gözlem | Kaynak |
| --- | --- | --- |
| Oyuncu nerede "sağa bas + ateş"e geçiyor? | Ana rotalar 28–30 bin piksel. Platform her 650 px, kapı her 1000 px, sandık her 780 px, meyve her 220 px mekanik aralıkla diziliyor. Alt rotalar 8 adet aynı kalıp beşli düşman grubuyla `lerpf` ile eşit aralıklı dolduruluyor. | `campaign_world.gd` `load_section`, `campaign_content.gd` `populate` |
| Rota değişince eylem değişiyor mu? | 0.29.0'da iki ayrım birebir aynı geometriydi (aynı 3 rampa, aynı alt kanal, aynı 12 meyve, 2 nöbetçi). Seçim yalnızca çıkışa hangi yükseklikte varıldığına bağlıydı; yol boyunca eylem değişmiyordu. | `campaign_routes.gd` (0.29.0) |
| Hangi işaret yapay? | Ayrımda yukarı/aşağı ok tabelaları vardı; dünyadan okunan bir giriş yoktu. | `draw_landmarks` (0.29.0) |
| Arayüz sürtünmesi | Ana menü: "Oyna" ana eylem; Sonsuz/Nasıl oynanır?/Kahramanlar/Ayarlar ikincil. HUD tek şeritte skor, can, bomba, silah ve bekçiler gösteriyor; ayrıntılı inceleme sonraki turda. | Ekran görüntüsü, 0.29.0 |

Öncelik sırası: (1) fiziksel ayrımlar, (2) alt rotalarda elle tasarlanmış karşılaşma ritmi ve sıkıştırma, (3) düşman hazırlık/toparlanma okunurluğu, (4) Kök Motoru evreleri, (5) HUD ve sonuç ekranı.

## Tur günlüğü

### 0.30.0 · Doğal ve farklı iki yol ayrımı

- **Ayrım 1 · Fener Kavşağı (`fork_one`)**: Alt kanal, iskele binasının altındaki gerçek tavanlı bakım geçidinden geçer. Ayakta duran gövde (74 px) ve araç (132 px) geçemez; çömelmiş gövde (40 px) tavanın altına sığar. Geçitte Aşağı bırakılsa da kahraman tavana gömülmez, çömelik kalır. Tavan altında zıplama reddedilir, çıkışta kendiliğinden doğrulur. Binanın çatısı katıdır: üst güverteden Aşağı+Zıpla ile geçide düşülmez. Bina iki yönden de mermi geçirmez. Geçidin içinde ışık çizgisi gibi meyveler, çıkışında bomba ikmali vardır. Ayakta ağza dayanan oyuncuya bir kez "Alçak geçit · sürünmek için eğil (S/↓)" ipucu görünür. Üst yol basamaklardan tırmanmadır.
- **Ayrım 2 · Asma Geçit (`fork_two`)**: Farklı fikir. Alt kök kanalı kökle kilitli bir kapakla kapalıdır; kilit mekanizması (4 vuruş) kırılınca kapak zemini açılır ve +1 kalkan verir. Açılan kapak kalıcı kimlikle (`fork_two:root_lock`) kontrol noktasında açık kalır. Kapalı avlu, üst güvertenin altındaki çitte biter, rota seçmez. Üst hizmet yolu farklı aralıklı basamaklardan oluşur; orta açıklık basıldıktan 2,4 s sonra çöker ve oyuncuyu çukura değil avluya düşürür. Avludan kapak yolu her zaman açık kalır; bölüm kilitlenmez.
- Ok tabelaları kaldırıldı; girişler bina/geçit ve kapak/kilit ile okunur. Rota yardım metni güncellendi.
- Kurallar: `scripts/campaign_routes.gd` sabitleri (`PIER`, `CRAWL_CEILING`, `STAND_HEIGHT`, `CROUCH_HEIGHT`, `MOUNTED_HEIGHT`, `SERVICE_WALKWAYS`, `SERVICE_BRIDGE_SECONDS`, `HATCH_*`). Çizim aynı dikdörtgenleri kullanan geçici şekillerdir.

## Testler (ortam: bulut Linux, Godot 4.6.3 headless/Xvfb llvmpipe, Chromium 1243 SwiftShader)

| Tur | Kontrol | Sonuç |
| --- | --- | --- |
| 0.30.0 | `run_source_tests.py` tüm paketler | PASS · 38.904 kontrol |
| 0.30.0 | `test_campaign_routes.gd` (4 kahraman × 2 ayrım × 2 yol normal hareketle, geçit/tavan/araç/çatı/mermi, kapak/kilit/kayıt, çöken açıklık) | PASS · 169 kontrol |
| 0.30.0 | `browser_campaign.py --combat-controls --offline`, `browser_campaign_audio.py` | PASS |
| 0.30.0 | `browser_forge.py --scenario all --rescue` | 3 denemede 1 PASS. 2 denemede 8 yönlü nişan dizisinde kahraman 1 canla sol sınırda düşman temasıyla öldü ve bekleme zaman aşımına uğradı. Kıyı bölümü; değişen rota koduna girmiyor. Oynak test olarak kayıtlı. |
| 0.30.0 | Fiziksel telefon, fiziksel gamepad | NOT TESTED |

## Bilinen eksikler ve sonraki adım

- Alt rotalar (su 30.000, teras 28.000, kökler 29.000 px) hâlâ eşit aralıklı beşli gruplarla dolu. Sonraki tur: her rota için elle yazılmış, rol öğreten karşılaşma listesi; sıkıştırma; rotaya özgü hareket problemi (su akıntısı, teras rüzgârı, kök karanlığı) ile bağlantı.
- Kök Motoru evreleri, HUD hiyerarşisi ve sonuç ekranı henüz bu çalışmada değişmedi.

## Sol 6.2 sanat sözleşmesi (0.30.0 itibarıyla)

- İskele binası: çarpışma `PIER` = x 780–1180, y −195 (çatı/üst güverte) ile 35 (geçit tavanı) arası. Geçit açıklığı 55 px (zemin 90). Sanat, tavan alt kenarını y=35'te göstermeli; daha alçak çizilirse oyuncu tavanın içinden geçiyormuş gibi görünür.
- Kahraman gövde yükseklikleri (kural): ayakta 74, çömelik 40, araçlı 132 px. Çömelik vuruş merkezi ayaktan −20, ayakta −37.
- Kapak: kilit nesnesi x=820 (vuruş noktası y=−35, yarıçap 45). Kapak zemini x 900–1400; çit x=1400. Çöken hizmet açıklığı x 540–740, y=−140, 2,4 s.
- Bu değerler kuraldır; yeni sprite yalnızca görüntüyü değiştirmeli, çarpışma ve zamanlama sabitlerini değiştirmemelidir.

## Sol 6.2 · 23 Kasım 2026 (Europe/Istanbul) · 0.49.0 ara entegrasyon doğrulaması

Bu tur altı kahramanlı Mission 1 kabul adayı değildir. Ara sürümde mevcut Aion, Kutsanmış, Ayça ve Eren korunur; Armadillo ve Kurbağa ile yeni geri yürüme ve bomba sanatı sonraki entegrasyonda doğrulanacaktır. Kullanıcı kabulü bekliyor. Mission 2 kapsam dışıdır.

- Kaynak: `main` `466492fac40eb4760456738a648eb36f3f2a61c7` (0.30.0) üzerine özgün Neon 0.48 yamasının 28 dosyası, ardından düşman evreleri ve karakter seçimi düzeltmeleri. Canlı AIONIA v1.7, ilgili v1.1 regresyon kaydı ve güncel referans dizini bu oturumda yetkili Drive bağlayıcısıyla okundu. Özel belgelerin tam metinleri depoya eklenmedi.
- Başlangıç yayın ayrımı: GitHub Actions `44913207727`, 0.30.0 Linux render adımında `Rendered junction actor has real collision support: fork_two` ile başarısızdı. Son başarılı Pages işi `44902975788`, `24fb2850e9eaa7274415f9fa8342956be48411ca` kaynaklıydı. 22 Kasım başlangıç canlı `build.json`: 0.29.0, `56d6256c05dff7a1`. Bu eski yayın yeni adayın doğrulaması sayılmaz.
- İlk yerel web çıktısı: Godot 4.6.3, tek iş parçacığı, `packaging/build_web.py`; 0.49.0, build `31309b2d2e4a89f6`. Bu çıktı rota kanıtının kimliğini korumak için `http://127.0.0.1:8798` üzerinde saklandı. Son küçük düşman düzeltmelerinden sonraki nihai yerel çıktı: `a053514fb2ad2016`, `http://127.0.0.1:8799`. Bunlar yayımlanmış adres değildir.

| Kontrol | Durum ve kanıt |
| --- | --- |
| İlk 61 motor paketi | 59 PASS; `campaign` içinde iki eski doğrudan-platform meyve koşulu FAIL; `campaign_selection_flow` 19/19 gözlendiği halde sonuç satırı biçimi nedeniyle çalıştırıcı FAIL. Özgün günlükler korundu. |
| Meyve erişimi düzeltmesi | PASS, `campaign` 419/419. Yeni test, boşluğun üstündeki meyveyi keyfî mesafe eşiğiyle kabul etmek yerine destek yüzeyinden gerçek zıplama fiziğiyle `taken[id]` oluştuğunu sınar. Bu yalıtılmış geometri testi tam normal oyun kanıtı değildir. |
| Seçim testi sonuç satırı | PASS, düzeltilmiş `campaign_selection_flow` 19/19. Önceki yanlış FAIL silinmedi. |
| Son yerel gerçek renderer | PASS, Godot 4.6.3 / Linux X11: 657/657 kontrol (`049-render.log`). Bu görsel/motor kontrolü normal oyuncu rotasının yerine geçmez. |
| İngilizce normal ön yüz | PASS, Chromium/SwiftShader, Linux, 1280×720; 26 kontrol. Dört kahramanın gerçek seçim/onayı, yardım ileri/geri, açılışı yeniden oynat/atla, 393×873 ve 873×393 yön değişimi, kayıt yazmayan Attract, Sonsuz başlat/duraklat/ana menü. Yakalanan Godot/tarayıcı script hatası yok. |
| İlk normal su rotası denemesi | FAIL, 210 saniye sonunda `fork_one` x=764, y=48, araçta. Bot araçtan inmeden alçak geçide basıyordu; görünen araç ve gerçek tavan çarpışması doğru biçimde geçişi engelledi. Bu kayıt ürün kusuru diye sınıflandırılmadı. İlk hata görüntüsü, gözlemi ve performans oturumu korundu. |
| Düzeltilmiş normal su rotası | PASS, ilk `31309b2d2e4a89f6` çıktısı: 348,49 saniye, sıfır ölüm. Shore → quay → gerçek çömelerek iskele geçidi → water → relay → üç evreli boss → zafer/sonuç → kalıcı tamamlanma → ana menü. Gerçek E silah değişimi ve `crawled_under_pier` gözlendi. Godot/tarayıcı script hatası yok. Rota düğmesi, konum/zafer yazımı, düşman temizleme veya dokunulmazlık kullanılmadı. |
| Normal teras rotası | PASS, ilk `31309b2d2e4a89f6` çıktısı: iki fiziksel üst geçit → canopy → terrace → relay → boss → sonuç/kayıt/ana menü. İki gerçek ölüm ve checkpoint tekrarları günlükte korundu. Gerçek E ile heavy → disc değişimi gözlendi; script hatası yok. |
| Normal kök rotası | PASS, nihai `a053514fb2ad2016`, Kutsanmış: gerçek seçim/onay → üst ilk ayrım → canopy → atışla açılan kök kilidi/alt ikinci ayrım → roots → relay → boss/sonuç/kayıt/ana menü. Sıfır ölüm. Gerçek bıçak/mermi kurtarmaları, teşekkür sırasında uzaktan ödül verilmemesi, fiziksel çanta hediyesi, temasla tek seferlik alma ve kalıcı `awarded`/`taken` kayıtları doğrulandı; script hatası yok. |
| Beş ardışık gerçek Retry | PASS, teras denemesinin başında normal duraklat → checkpoint Retry; 10 doğrulama. Her denemede kahraman/bölüm ve `awarded`/`taken` durumu korundu, düğüm sayısı 24 kaldı. Gözlenen süre 1,32–1,82 saniye. |
| Gerçek WebAudio yaşam döngüsü | PASS, nihai `a053514fb2ad2016` üzerinde 35 gözlem, yaklaşık 54 saniye. Gerçek paused → playing → paused girişlerinde `music_starts=1` kaldı, uzun örnek başlatma çoğalması gözlenmedi, yakalanan tarayıcı hatası yok. Bu kontrol işitme/ses kalitesi değerlendirmesi değildir. |
| Linux Firefox 153.0 | PASS, nihai `a053514fb2ad2016`, gerçek Gecko/X11 yazılım render ortamı. Normal menüden başlatma, hareket/ateş/bomba, dokunma, dikey/yatay, duraklat/devam, çevrimdışı yeniden yükleme ve gerçek Continue kayıt koruma; script hatası yok. Chromium'a özgü CDP çoklu dokunma bu kontrolde iddia edilmedi. İlk iki giriş, oyun URL'sinden önce yerel “Profile Missing” nedeniyle BLOCKED idi; yazılabilir TMPDIR yanında XDG_CONFIG_HOME/DATA_HOME/CACHE_HOME kullanılarak ortam düzeltildi, HOME değiştirilmedi. İlk kayıtlar ve bir test-metadata TypeError düzeltmesi ayrı korundu. |
| Nihai yerel build smoke | PASS: `a053514fb2ad2016`, yeni profil, gerçek hareket/ateş/bomba, dokunma/çoklu dokunma/iptal, yön değiştirme, Shift/RMB ve sentetik Xbox sprint/duraklat/devam/ateş/zıpla/bomba. Çevrimdışı tekrar açılış ve gerçek Continue checkpoint/skoru korudu. Script hatası yok. Sentetik gamepad fiziksel donanım kanıtı değildir. |
| Fiziksel cihazlar | NOT TESTED: gerçek telefon/tablet, fiziksel Xbox/gamepad, macOS/Safari ve Windows/Edge. Tarayıcı boyutlandırması fiziksel cihaz testi sayılmadı. |
| Yayın | NOT VERIFIED: bu ara kayıtta 0.49.0 için yeni main/Pages yayını doğrulanmadı. |

Performans kaydı oyun ve tarayıcı ölçümlerini ayırır: gerçek Godot process/physics kare sayaçları, QA `Performance.TIME_PROCESS` / `TIME_PHYSICS_PROCESS` gözlemleri, ayrı tarayıcı rAF/uzun görev örnekleri ve CDP heap bilgisi. 10 Hz monitör gözlemleri tüm motor karelerinin izi değildir. Web'de `MEMORY_STATIC` sıfır döndüğünde bellek sıfır diye sunulmaz, ölçüm kullanılamaz olarak kaydedilir. İlk deneme açılışı 12,66 saniyedir; iki eşzamanlı yazılım render bağlamında ölçülmüştür ve fiziksel cihaz performansı iddiası değildir. Önbellekli açılış, beş ardışık gerçek checkpoint Retry, rota geçişi ve boss örnekleri ayrıca tamamlanacak.

Modern Web Guidance: kurulu paket 1.0.1; kaynak HEAD `64a6d708f5a43f2cd3fde5d4d7db3905ba1bdf65`. `DISABLE_TELEMETRY=1` ile genel, hedefli sorgular kullanılarak `performance`, `interaction-paint-timing`, `progress`, `spatial-navigation`, `accessibility` okundu. Bu tur HTML/CSS/ürün JavaScript'i değiştirilmedi. Canvas içindeki sahne değişimi DOM soft-navigation veya içerik boyaması sayılmadı; browser rAF oyun FPS'i diye raporlanmadı. Mevcut Godot renderer, WASD ve onaylı dokunmatik düzen korundu; deneysel API açılmadı ve dış tarama yapılmadı.


Doğrulanmış kaynak anlık kopyası: [neon-import.json](evidence-sol62/neon-import.json). 26 betik ve 2 testin tamamı özgün baytlarıyla karşılaştırıldı; indirme sonrası iki Drive klasörünün kimlik, boyut ve değiştirilme tarihleri tekrar listelendi, değişiklik yoktu. Yama körlemesine mevcut dosyaların üstüne kopyalanmadı; temiz güncel temel üzerine uygulandı.

Bu entegrasyonda saldırı etkinliği ile toparlanma ardışık hale getirildi; toparlanma saldırı sırasında tüketilmez. Gerçek mini-boss mermisi testi önce iki hatayı yakaladı, düzeltmeden sonra 53/53 döngü kontrolü geçti. Kardeş ritim/genişleme/seçim testleriyle son odaklı tur 632/632 PASS. Gerçek Xvfb/llvmpipe CampaignGame renderi 657/657 PASS; önceki fork_two zemin desteği hatası yeni koşuda görülmedi. Web paketleme 7, Android paket sözleşmeleri 27 ve macOS DMG sözleşmeleri 3 test PASS; bunlar fiziksel cihaz veya kurulmuş paket testi değildir.
