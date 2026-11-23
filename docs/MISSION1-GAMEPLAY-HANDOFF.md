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


## Sol 6.2 · 0.50.0 · Altı kahramanlı teknik aday (doğrulama sürüyor)

23 Kasım 2026, Europe/Istanbul. Teknik aday ile kullanıcı kabulü ayrıdır; kullanıcı oyunu oynayıp açıkça onaylamadı. Mission 2 geliştirilmez. Bu bölüm önceki kayıtları değiştirmeden devam eder. PR #10'daki 0.49 ara aday hiçbir zaman main/Pages'e yayımlanmadı. Onun doğrulanmış düzeltmeleri korunarak aynı PR altı kahramanlı 0.50 adayına ilerletiliyor; 0.49 yayımlanmış önceki sürüm olarak sunulmaz. main/Pages henüz bu kayıtla başarılı ilan edilmez.

### Uygulanan kararlar ve gerçek nedenler

- Eski dört kahramanın kimliği/sırası ve kaynak PNG'leri korunur. Mission 1 kadrosu `aion,sheep,rabbit,eren,armadillo,frog`; Ömer ve Melun iki kullanımlık yardımcı rollerde kalır. Klasik Sonsuz modu özgün dört kahramanla ayrıdır; yeni ikisi sessizce Aion'a çevrilmez. Ana Enter/Space görünür ana eylem olan Mission 1'e gider.
- Geri adım, ileri klibin ters oynatılması değildir. Ortak yüz-X ve gerçek zemin köküyle yeni bağımsız çizimler kullanılır; fizik konumu kare hizasını gizlemek için oynatılmaz. S ile yerde eğilmek artık masaüstü fare nişanını ele geçirmez. Aynı gerçek sahne/girdide eski koşulu geri koyan kontrollü karşılaştırma dört hatayı yakaladı; düzelmiş sahne 108 kontrolü geçti.
- Sınır/kapı tarafından engellenen hareketin amaçlanan hızı sıfır değilken alınan yol sıfır kalıyordu; bu, tutulan bir yürüme karesi üretiyordu. Altı kahramanda aynı sınır örneği önce 6 FAIL, gerçek çözümlenmiş hızı kullanınca 6 PASS. Bu artık fiziksel hızdır; çizimi sabitleyen bir konum telafisi değildir.
- Armadillo: eğil + E/Y/bağlamsal dokunma; hazırlık, kilitli yönde kabuk hücumu, tek temas hasarı, fren ve toparlanma. Kurbağa: aynı eylemle hareket eden ağza bağlı, sonlu menzilli, ilk temasta dönen dil. Yakındaki araç/silah değişimi öncelikli; Shift/LB depar ve üç ana dokunma eylemi korunur. Şarjlı tavşanlar ve Aion çift sıçraması korunur.
- El bombası: tek simülasyon sahibi, `.16` saniyede tek tüketim/bırakma, `.42` saniyelik beden hareketi; gerçek yüzey sekmesi ve süreli patlama. Aynı opak tutuş pikseli/merkez ofseti elde ve uçuşta kullanılır. Elde/uçuşta nesne boyutu aynıdır; açık takip elinde tabanca görünmez. Duraklatma zamanı dondurur; odak/hasar/ölüm harcanmamış eylemi iptal eder. Yeniden deneme geçici bombaları ve bekleme süresini temizler.
- Etkin saldırıdan sonra başlayan toparlanma görünür ve vurulabilir. Mimic ilk karede 73px sıçrıyordu; gerçek süreye bağlı eğriyle 10ms'de yaklaşık 5px yükselir. Burrow hazırlık/hücum/toparlanma bitene kadar yüzeyde kalır. Boss ışın uyarısı sıfırı geçtiğinde bir kez ateşlenir; önce büyük adımda kaybolabiliyordu. Kritik işaretler dumanın üstünde, duman kademeli saydamdır.
- Dar geçidin 55px açıklığı değiştirilmedi. Eski dört kahramanın baş/solungaç/kulak/halesini gerçekten alçaltan ayrı tünel pozları vardır; yeni ikisinin özgün alçak pozları kullanılır. Hasar/ölüm sırasında dar tavanda alçak mevcut çizim uyarlamaları açıkça kaydedilir; bunlar yeni çizilmiş ölüm animasyonu diye sunulmaz.
- Özgün fener korusu açılışı Drive-By Wire'ın sabit referanslarıyla kompozisyon/ışık açısından karşılaştırıldı. Ana menü düzeni korunur. Yeni eldeki tabanca varyantı, 28px'te karmaşık pickup detaylarının renk yığınına dönüşmesini düzeltir; cyan basınç ucu/pirinç çerçeve/kahverengi kabza kimliği, özgün pickup PNG ve diğer on silah korunur. İskele evi mevcut kaliteli piksel ahşap parçalarıyla çizilir; yalnız `draw_pier` değişir, çatı/alt yüzey/rota çarpışmaları aynı kalır.

### Birleşik ilerleme ve kalite tablosu

| Alan | Üretilen / gerekli | Oyuna bağlanan | Gerçek kontrol | Açık kapı |
| --- | --- | --- | --- | --- |
| Neon + GitHub | 28/28 özgün dosya doğrulandı | 0.49 entegrasyon + 0.50 çalışma dalı | Import, tüm kaynak ve export | PR/main/Pages son durumunu aşağıda güncelle |
| Altılı geri yürüme | 6/6, ayrı ileri/geri/alçak çizimler | Gerçek hareket ve nişan seçicisi | 65 paketlik sabit tur 50.462 PASS; son dar düzeltmeler ayrıca | Son normal tarayıcı matrisi sürüyor |
| Armadillo | Kabuk hücumu ve özgün klipler | Seçim, E/Y/dokunma, kayıt/sonuç | 740 yeni kahraman kontrolü; normal görev aşağıda | Son yayın adresinde doğrulama |
| Kurbağa | Ağız/dil/temas/geri çekilme | Seçim, E/Y/dokunma, kayıt/sonuç | 740 kontrol; normal görev sürüyor | Normal boss/sonuç ve canlı doğrulama |
| Altılı kadro | 6/6 | Seçim, yardım, önizleme, tek başlatma, devam | 108 seçim; 1720 sunum; 2739 ölçek/yerleşim | Normal tarayıcı matrisi / fiziksel cihaz |
| El bombası | Hazırlık/bırakma/uçuş/sekme/7 efekt evresi/ses | Tek eylem, gerçek hasar | 346 davranış; 216 kontrollü sahne karesi; tünelde 72 tutuş karesi | Normal tarayıcı ses/girdi son kapısı |
| Diğer animasyonlar | Özgün kaynak envanteri korunur | 13 düşman rolü, 3 boss evresi; mevcut NPC zinciri | 82 döngü; 93 kontrollü rol/evre gözlemi | Kullanıcı okunurluk ve sanat kabulü |
| Başlangıç/seçim | Yeni özgün açılış, 6 kart | Gerçek ekran/olaylar | Native öncesi/sonrası, TR/EN, 200% | Kullanıcı sanat kabulü |
| HUD/akış | Mevcut dar şerit ve onaylı joystick/üç eylem korunur | Gerçek oyun/geri dönüş/yardım | 977 UI; 42 bağlamsal eylem | Fiziksel telefon/gamepad |
| Mission 1 yolları | Üç yaprak ve iki fiziksel ayrım | Su/teras/kökler + röle/büyük boss | 0.49 üçü normal girdilerle tamamlandı | 0.50 yeni ikisi ve son canlı görev |
| Ses/efekt/performans | Yeni özgün bomba sesleri, saydam duman | Gerçek olay/miks | Ayrı normal ses kaydı ve ham motor gözlemleri | Fiziksel referans cihaz bütçesi |
| Main/Pages | Yetkili mevcut zincir korunur | Başarılı main artifact'ı dışında yayın yok | İlk kırmızı CI kayıtları korunur | Son commit/iş/build/canlı sonuç bekliyor |

### Kanıtların sürüm ve yöntem sınırı

- Sabit 0.50 kaynak turu: **65 paket, 50.462 kontrol PASS**, kaynak klasörü `full-65-stable`. Bu turdan sonraki tabanca/tünelde ölüm ve engellenmiş hız düzeltmeleri dar ilgili paketlerle ayrıca kontrol edilir; son CI tam olarak yayımlanan commit'i tekrar sınar.
- Native GL/llvmpipe: altılı ana gövde/rota 961, genişletilmiş kurtarma 308, ritim 21 render kontrolü. Bunlar kurgulanmış sahne örnekleridir, normal görev tamamlama kanıtı değildir. Tünel matrisi 288 kare, özgün fiziksel ayak kökünü ve gerçek 55px tavanı kullanır. Yeni tabanca/eldeki nesne görseli normal oyun ölçeğinde karşılaştırıldı.
- İlk 0.50 yerel web `bec51444a31e3d2b`: Armadillo gerçek S+E ile ilk düşmana vurdu; sıradan tuşlarla su yolu, tüm bölüm geçişleri, boss/zafer/kayıt/ana menü 456,10 saniyede tamamlandı; bir gerçek ölüm/Retry vardı. Bu ilk hash yeni son tabanca/son iskele boyamasını içermez; bu görseller için kanıt diye kullanılmaz.
- Sonraki yerel web `95a71d4766f0fd6e`: yeni tabanca, çizim saati gözlemleri, bütün kahraman/oyun mekanikleri. Kurbağa'nın normal E saldırısı gerçek ilk düşmana temas etti; beş gerçek Pause→Retry 10 kontrolle kimlik ve tek ödülü korudu. Tam kökler görevi 335,57 saniyede bir gerçek ölüm ve checkpoint Retry ile boss/sonuç/kayıt/ana menüye ulaştı. Altılı normal girdi matrisi ayrıca sürüyor. Bu hash son 1px iskele boya dikişi düzeltmesinden öncedir; geometri aynıdır.
- İlk altılı tarayıcı matrisi: bir yardımcının geri sayfa gezinme hatası, ardından farklı kare zamanına ait `data.player` ile `pose.anchor`ı karşılaştırma hatası yakalandı. Örnek farkı tam bir `.05s × 235px/s = 11.75px` adımdı; gövde titreşimi diye sınıflandırılmadı. Hatalı kayıtlar korunur. Yeni test çizim saatini ve o anda zeminde olmayı eşler; normal hızdaki özgün video karelerini doldurmaz/yeniden zamanlamaz.
- Firefox 153 gerçek Linux/Gecko/X11 0.49 son export: 27 normal girdi/offline kontrolü PASS. Önceki iki `Profile Missing` yerel ortam sorunu ve test yardımcısının `browser.version()` hatası korunur; yazılabilir XDG dizinleri ve doğru özellik erişimiyle çözüldü. Chrome/Firefox masaüstü testi fiziksel Poco/iPhone testi değildir.
- Performans ölçümleri SwiftShader ve QA'nın 10Hz durum gözlemi/otomasyon maliyetini içerir. Motor process/physics sayaçları ve süre monitörleri, tarayıcı rAF/uzun görev ve JS heap ayrı sunulur. Yazılım renderer sonuçları üretim telefon FPS'i veya yüzde performans kazanımı diye yorumlanmaz.

### Açık işler / sonraki ilk eylem

1. Normal altılı matrisin ve Kurbağa kökler/boss/sonuç akışının son hash üzerinde sonuçlarını işle. Gerçek bir ürün hatası çıkarsa aynı koşulla giderip ilgili regresyonu çalıştır.
2. 0.49 PR #10'un tarayıcı Forge son aşağı-sağ nişan hazırlığı sorununu gerçek paket izleriyle düzelt; Android aynı son turda PASS. CI gereklilikleri gevşetilmez.
3. 0.50 kaynağını güncel main ile koruyarak birleştir, tam başarılı CI artifact'ını Pages'e taşı ve canlı sürüm/build/karakter/hareket/ateş/yeniden deneme ile son normal Mission 1'i doğrula.
4. Gerçek telefon/tablet, fiziksel Xbox/PS ve Safari/Edge cihaz matrisi erişim bekler; otomasyonu gerçek cihaz veya kullanıcı sanat kabulü gibi sunma.


### Son davranış düzeltmeleri · 0.50 adayının dondurulması

- Gerçek normal tarayıcı girdisi, hareket ederken otomatik yakın yumruğun `idle_fire` seçtiğini gösterdi. Karakter ilerlerken ayaklar sabit kalıyordu. Bu gerçek kusur ölçüm hatası diye elenmedi: altı kahraman × yer/hava kontrollü karşılaştırma önce 12 FAIL, düzeltme sonrası 12 PASS. Her iki gövde sağlayıcısı, hareketli yakın saldırıda gerçek yürüyüş/geri adım/hava evresini korur. Yerinde yumruk ve bıçak kurtarmanın kendi saatleri korunur.
- Kurbağa'nın uzayan dili de hareketli bedeni sabit ayak karesine kilitliyordu. İleri/geri/alçak ileri/alçak geri/hava için 30 özgün açık-ağız karesi bağlandı; hazırlık ve toparlanmada normal yürüyüş kullanılır. Dilin fiziği, süreleri, menzili ve hasarı değişmedi. `frog_tongue_motion` 2873, yeni kahraman 829, sanat 2512 kontrol PASS; normal görevi bitirme kanıtı olarak sunulmadı.
- Gerçek `Game.toggle_pause` sırasında S bırakılması eğik gövdeyi doğrultuyor, bomba ve dilin sunumunu kaybettiriyordu. Geçici duraklama duruşu ve nişanı korunur, devamda girişler bırakılmış olarak kalır; kayda yeni alan eklenmedi. Bomba/duraklatma 566, bağlamsal eylem 42 ve UI 977 kontrol PASS. Odak kaybının mevcut iptal davranışı korunur.
- Son kaynak çalıştırıcısına `frog_tongue_motion` eklendi: tam aday artık 66 test grubu. Tam 66 grubun sonucu tamamlanmadan PASS yazılmaz. CI gerçek altılı render kapıları 961/308/21 ve terrain 40 olarak korunur.
- Normal tarayıcı kanıtı `bc7af24eda63831c`: Armadillo kökler 292,49 saniye / bir gerçek ölüm; teras 370,35 saniye / dört gerçek ölüm. Her iki koşu boss/sonuç/kayıt/ana menüye ulaştı. Bu hash son hareketli yumruk, duraklama sunumu ve Kurbağa dil yürüyüşü düzeltmelerinden öncedir; son animasyon kalitesinin kanıtı değildir.
- Tarayıcı Forge son aşağı-sağ nişan kontrolünde CDP tuş çağrıları yükseliş aralığını tüketiyordu. Zemin durumunu ve yön/eğilmeyi gerçek tuşlarla sıçramadan önce onaylayan hazırlık kullanıldı; havada/yükselişte/gerçek yeni mermi koşulları ve süre sınırı gevşetilmedi. Son 0.49 yerel paket üzerinde 26/26 normal yön/kurtarma kontrolü PASS. Android tutarlı aynı gözlem imleci düzeltmesi son CI'da PASS; fiziksel cihaz testi değildir.
