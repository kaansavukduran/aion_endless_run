# Mission 1 · Oynanış geliştirme devri

Bu belge Mission 1 oynanış çalışmasının tek devir defteridir. [M1-DELIVERY.md](M1-DELIVERY.md) tarihsel teslim kaydıdır; bu çalışmanın güncel durumu buradadır. Mission 2 geliştirmesi kullanıcı Mission 1'i kabul edene kadar başlamaz; Mission 1 sonucu oyuncuyu Mission 2'ye göndermez.

## Güncel durum · 23 Kasım 2026 · 0.50.0

Bu üst kayıt güncel durumdur; aşağıdaki 0.29/0.30/0.49 başlangıçları ve ara kırmızı kapılar tarihçedir. Kullanıcı görsel/oynanış kabulü bekliyor; teknik test sonucu kullanıcı kabulü değildir.

- Yetkili kaynak: `kaansavukduran/aion_endless_run`, Godot4.6.3. [PR10](https://github.com/kaansavukduran/aion_endless_run/pull/10) başı `e88bad79b9d4c70c8e84ece2ca15f4f3ec227394`; geçmiş korunarak main'e birleştirme commit'i `8167621180f4c9b5817e5f7e3a9cfbc637e97d43`. Çalışma başlangıcındaki gerçek main `466492f` korundu; eski prompt commit'ine dönülmedi.
- [Son PR CI45098562466](https://github.com/kaansavukduran/aion_endless_run/actions/runs/45098562466), deneme2: **SUCCESS**. Godot66/66 paket, **54.217 kontrol PASS**; Python web7/Android40/macOS3 PASS. [Makinece okunabilir son kaynak sonucu](evidence-sol62/source-results-0.50-final-ci.json) tam e88 kaynağını tanımlar. Önceki sonuç dosyaları kendi commit'lerinin kanıtı olarak korunur.
- Aynı kaynağın Windows/macOS/Linux paket işleri PASS; Linux gerçek render kapıları40/961/308/21, normal tarayıcı kontrolleri/offline, altılı seçim/nişan/kurtarma Forge akışı ve ses yaşam döngüsü PASS. Android'in ilk denemesi uygulama açılmadan Google Emulator indirmesinde bozuk ZIP ile durdu. Özgün hata saklandı; yalnız bu işin tekrarında gerçek emülatör/çevrimdışı/girdi testi PASS. Ürün veya test kapısı değiştirilmedi.
- Main için ayrı [CI45100627441](https://github.com/kaansavukduran/aion_endless_run/actions/runs/45100627441) **SUCCESS**; aynı66/54.217 kaynak kontrolü, masaüstü/Android/tarayıcı kapıları yeniden geçti. [Pages45102014529](https://github.com/kaansavukduran/aion_endless_run/actions/runs/45102014529) **SUCCESS**, tam `8167621` artifact'ını doğrulayıp yayımladı. Aşağıdaki gerçek canlı0.50.0 kabul koşuları ilk yayının **`abfb88139e9af7d3`** build'ine aittir; yerel son `a69aaa019e01382d` ve PR CI `2398c507556061b3` kimlikleri canlı kimlik diye kullanılmaz. Bu son belge/kanıt gönderimi ürün kodunu değiştirmez. Sonraki paketlemenin kimliği [canlı build.json](https://kaansavukduran.github.io/aion_endless_run/build.json) ve aynı commit'in başarılı Actions/Pages kaydıyla doğrulanır; bu dosyanın kendi commit kimliği kendine referansla uydurulmaz.
- Vercel commit durumu **failure / Account is blocked**. Bu hesap engeli giderilmiş veya Vercel güncellenmiş sayılmaz. Yetkili yayın hedefi mevcut [GitHub Pages oyunu](https://kaansavukduran.github.io/aion_endless_run/). Gerçek HTTP'den13 asset indirildi; boyut/SHA-256 manifest ile birebir, WASM MIME doğru. [Canlı bütünlük makbuzu](evidence-sol62/public-0.50-integrity.json); PCK199.168.144 bayt, SHA-256 `40d3157afe9fa8d61cef54b99c7a482ab840e0168a4b8d64a053c6ba13df1859`. Bu dosya kontrolü oyun içi kullanıcı akışı testi yerine geçmez.
- Tam okunan resmi AIONIA kaynağı **v1.7**; son metadata kontrolü aynı13 Kasım2026 kaynağını doğruladı. Neon26 betik+2 test28/28 özgün baytla doğrulandı, son Drive listesi aynı kaldı. Drive'a yükleme/yedek yapılmadı.
- Kanıt sınırlaması: gerçek Linux Firefox/Chromium, Android emülatörü, sanal gamepad ve kontrollü native render fiziksel Poco/iPhone/Xbox/PS/Safari/Edge testi değildir. Yazılım renderer kaydı60fps hedefini kanıtlamaz. Beş kişilik pilot ve kullanıcı sanat/oyun hissi onayı **NOT TESTED / bekliyor**.
- Teknik sınır: altı kahramanlı Mission1 adayı uygulandı ve aşağıdaki kaynak/normal oyun/yayın kapıları tamamlandı. Son belge/kanıt commit'inin standart main/Pages zincirini de izleyip son yanıtın yayın makbuzunda ayır. Sonraki ürün adımı kullanıcı Mission1'i oynayıp açıkça kabul etmeden Mission2 değildir; yalnız yeni kanıtlanan Mission1 kusurunu aynı akışla yeniden üret/düzelt. Fiziksel cihaz erişimi ve kullanıcı sanat/oyun hissi kabulü bekliyor.

### Canlı0.50 kullanıcı akışları

- **Ayça WATER PASS**: gerçek yayımlanmış canvas0.50.0/buildabfb, Chromium156,424,03 saniye,4 gerçek ölüm/kontrol noktası tekrarı,17 kontrol, yakalanan script/tarayıcı hatası0. Gerçek seçim/başlatma, shore→quay→fork_one alt iskele geçidinde çömelme→water→relay→arena, final boss/sonuç, tamamlanmış kalıcı kayıt ve ana menü. Salt gözlem CDP aynı oyun bağlamına bağlandı; konum/sağlık/RNG setters, dokunulmazlık veya düşman temizleme kullanılmadı. Ham kanıt `050-live-rabbit-water/`, gerçek video özgün zamanlıdır ve60fps kabulü değildir.
- **Eren TERRACE PASS**: aynı gerçek kamu build'i/canvas0.50,361,59 saniye,2 gerçek ölüm/kontrol noktası tekrarı,15 kontrol, script/tarayıcı hatası0. İki fiziksel üst ayrım→canopy→terrace→relay→arena, boss/sonuç/kalıcı tamamlanma/ana menü. Ham kanıt `050-live-eren-terrace/`. Bu iki canlı sonuç, tüm6×3 kombinasyonunun oynandığı iddiası değildir; yeni ikinin üçer yerel rotası ve eski kahramanların tam akışları yukarıdaki kesin build kapsamlarıyla ayrı tutulur. [Kompakt canlı sonuç makbuzu](evidence-sol62/live-0.50-results.json) iki görevi ve kayıt/tarayıcı kapsamını birlikte gösterir.
- **Eski0.29 profilinden0.50'ye güncelleme ve Continue/offline PASS**: orijinal ilk açılışta3 kontrol eski profil/karakter/kalıcı verinin yeni runtime'a geçtiğini doğruladı. Aynı profil korunarak nihai devam/çevrimdışı makbuzu10 kontrol ve0 uncaught hata ile tamamlandı. Ayça/Rabbit, shore, skor25, `taken` ve `awarded` içinde yalnız `shore:fruit:1:true` aynen kaldı. Online ve offline tek gerçek dokunuş; menü nesli1/briefing→2/playing gözlemlendikten sonra kesin eşitlikler kontrol edildi. Offline manifest gerçek `aion-offline-abfb88139e9af7d3` CacheStorage'dan okundu; yeni ağ cevabı gibi sunulmadı. Ham son kayıt `050-live-upgrade-complete/`.
- İlk güncelleme testinin4. kontrolü yalnız250ms bekleyip henüz briefing/time0 gözlemini okudu; kalıcı skor hâlâ25'ti. Aynı başarısızlığın hemen sonraki gerçek ekran görüntüsünde gameplay ve SCORE00025 zaten görünüyordu. Bu eski gözlem, veri kaybı kanıtı değildir. Test artık tek dokunuştan sonra en çok15s içinde gerçek menü/nesil onayını bekler;25 skor ve iki kimlik kümesinin kesin şartları gevşetilmez. İlk kırmızı makbuz `050-live-upgrade/` korunur.
- İkinci devam denemesi9 gerçek online/offline sonucu geçti, sonra QA dosya yazıcısı offline iken `no-store` ağ isteği yaparak durdu. Ürün hatası değildir; manifest kaynağı ağdan bağımsız, açık provenansla kaydedildi. İlk serializer hatası `050-live-upgrade-ack/` saklandı; tam test PASS'i yalnız son10/0 makbuzuna aittir. Kaydı hazırlarken normal oynama/kaydetme akışı kullanıldı; QA doğrudan oyun durumu/depolama değeri yazmadı veya silmedi.
- Kamu tarayıcı taşımaları OpenAI bulut TLS proxy'si içinden geçer. Chromium yalnız pinlenmiş proxy leaf SPKI kullanır; doğrudan üretim sertifika zinciri veya fiziksel telefon kabulü iddia edilmez.
- **Gerçek canlı Linux Firefox153 PASS**,10 açılış/offline Continue kontrolü, canvas0.50/buildabfb,0 hata. İlk deneme oyundan önce `SEC_ERROR_UNKNOWN_ISSUER` ile BLOCKED kaldı; `security.enterprise_roots.enabled` tek başına bu Linux ortamında yetmedi. Mevcut OpenAI proxy CA'sı hem issuer hem imza/CA niteliğiyle doğrulandı ve yalnız yeni geçici Firefox NSS test profiline eklendi. `ignore-TLS`, genel güven deposu veya kullanıcının tarayıcısı değiştirilmedi. `050-live-firefox-nss/` tam makbuzdur; ilk issuer engeli saklanır. Bu10 kontrol tam Firefox görevi veya Poco testi değildir; önceki33/9 yerel Gecko kapsamı ayrı kalır.
- Bütün son canlı tarayıcı süreçleri başarı koduyla kapandı; açık tarayıcı bağlamı0. Beş kişilik pilot, fiziksel telefon/tablet/kol, macOS Safari ve Windows Edge uygulanmadı. Video/FPS yazılım renderer sınırları değiştirilmedi. Kullanıcı kabulü bekliyor.

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


### Son sabit kaynak doğrulaması

`265cdba3b322340642d3f282d7a10748efb8f1c1` ürün ağacı: **66/66 gerçek motor paketi, 53.987 kontrol PASS**. Makinece okunabilir sonuç [source-results-0.50.json](evidence-sol62/source-results-0.50.json). İlk 66 turunun iki kaynak yükleme hatası, bu oturumda birleştirme yapılırken test çalıştırılmasından kaynaklandı; geçici çakışma işaretleri temizlendikten sonra tam tur yeniden çalıştırıldı. İlk günlükler korunur ve o tur başarılı sayılmaz.

Diğer iki ilk-tur hatası bağımsız gerçek nedene sahipti: Armadillo ve Kurbağa'nın alçak elinde aşağı çevrilen yeni tabanca namlusu zeminin yaklaşık 1,02/1,33 piksel altında kalıyordu; mevcut zemin koruması doğru biçimde yatay atış seçiyordu. Sekiz yön testi artık aşağı atışı geçerli hava bağlamında sınar; kesin yön ve 760px/s hız toleransı korunur. Yerdeki altı kahramanın ham namlu/zemin ilişkisi ve gerçek mermi-görünen namlu eşleşmesi ayrıca doğrulanır. Ürün kodu değiştirilmedi. Yön paketi 530/2 FAIL → 560/0; Forge paketi 653/2 → 657/0.

Son yerel web `a9b8f2321cba8a3d` (0.50.0): PCK 199.166.736 bayt, SHA-256 `be604765d93b8d607078f3133a2a6bb84b8d578f4c38d677c40a22391cf20b4f`; 556 ürün girdisinin özeti export öncesi/sonrası aynıdır. Bu hash son hareketli yumruk, duraklatma sunumu ve Kurbağa dil yürüyüşünü içerir. Kurbağa su yolu 303,08 saniye, bir gerçek ölüm/Retry, 16 kontrol ile tüm boss/sonuç/kayıt/ana menü akışını geçti. Normal ilk düşmana gerçek E dili temas etti; hazırlık/uzama/çekilme/toparlanma/bekleme/hazır evreleri kaydedildi. Kalan tarayıcı matrisi ve yayın doğrulaması aşağıdaki sonraki makbuzla kapatılır.


### 0.50 CI giriş denetimleri

PR #10 `265cdba` çalışması `45089990639`: kaynak 66 paket, Windows ve macOS paketleri PASS; Linux gerçek render kapıları 40/961/308/21 PASS. Android menü denetimi eski dört kahramanın tek sayfada bulunmasını beklediğinden FAIL; altılı kadro fiziksel sayfalarla gezilirken test artık tüm altı kimliği tam eşitlikle doğrular ve her sayfada emekli iki kimliği reddeder. Eren/Ayça seçimlerinde aynı gerçek sayfalama kullanılır; 40 Android yardımcı kontrolü PASS. Emülatörün yeni koşusu tamamlanmadan Android PASS sayılmaz.

Aynı CI'nın Linux tarayıcı kontrolü A tuşunu 35px yol alınınca bırakıyordu. Gerçek yerel motor karşılaştırması üç 50ms adımda 35,25px yol alındığını fakat nişanın henüz sağda (`x=+.219`) olduğunu, dördüncü adımda sola (`x=−.227`) geçtiğini gösterdi. Test, aynı 10 saniyelik sınır içinde gerçek yol ve yönü birlikte onayladıktan sonra tuşu bırakır; nihai yön şartı korunur. Yeni bomba denetimi de mühimmat tüketimini `.16s` bıraktıktan sonra `.42s` gövde toparlanmasını bekler; sıradaki gerçek yukarı mermisi gözlenmeden bağımsız açısal geçiş denemesine başlamaz. Başarısız özgün paketler korunur.

Altılı normal tarayıcı matrisinde atışın model anı, bağımsız çizimin gerçek zamanıyla eşlenir. Otomatik atış hareketten sonra oluşturulur ve aynı adımda mermi yaşı ilerler; önceki çizim karesine sabit hızlı geri tahmin uygulamak havada yanlış 21,78px fark üretiyordu. Özgün akışın tam zaman eşliğinde 13 atışı en fazla 0,0000428px farkla doğrulandı. Pasif 10Hz telemetrinin atladığı 11 doğum ayrı NOT_VERIFIED kalır; en yakın görüntü aranmaz, ara kare uydurulmaz, tolerans yükseltilmez. İlk iki kahramanın son normal akışı PASS; kalan dördü hâlâ deneniyor. Özgün video zamanlaması korunur; 60fps istenen yakalama gerçek 60fps başarısı diye sunulmaz.


### Altı kahraman ve tamamlanmış dokunma regresyonu

Son `a9b8f2321cba8a3d` normal klavye/fare matrisi **6/6 kahraman PASS**: 5857 başarılı koşul; 44 hareket grubunda tam atış doğum karesi pasif telemetride bulunmadığından açıkça NOT_VERIFIED (131 tekil doğum). [Altılı matris indeksi](evidence-sol62/six-hero-core-0.50.json) hangi gerçek atış/çizim eşlerinin gözlendiğini ayrı tutar. Altı kahramanın gerçek seçim/başlatma, iki yöne yürüyüş/geri adım/eğilme, duruşa dönüş, havada yeni mermi ve tek bomba akışı geçti. Armadillo'nun tüm hücum evreleri ve Kurbağa'nın gerçek geri yürüyüş sırasında ağız-bağlı dil hareketi de gözlendi. Video özgün zamanlıdır; ölçülen 5,46–10,44 kodlanmış fps, 60fps kabulü değildir.

`a9` tamamlanmış normal Chromium smoke 44, gerçek Linux Firefox 153 akışı 33 ve WebAudio yaşam döngüsü 3 kontrol PASS. Chromium çoklu dokunma/iptal, sanal Xbox ve offline Continue içerir; Firefox Linux Gecko'dur, fiziksel Poco/iPhone/Safari değildir. Bomba probe'u gerçek checkpoint Retry ile bağımsız hazırlanır; `.55s` bekleme süresi bırakma anından başlar. Eski sabit duvar zamanı beklemeleri yeni `.16s` bırakma/`.42s` hareketle geçerli hazırlık oluşturmuyordu. İlk başarısız denemeler korunur.

İlk ek çoklu dokunma denemesi ikinci parmağı bırakmadan sonuç bekledi; sonraki deneme CDP touchEnd listesini yanlış yorumlayıp birinci parmağı bıraktı. Bu iki başlangıç denemesi INVALID test kanıtıdır, ürün hatasını kanıtlamaz; ara sınıflandırma geri çekildi. Son bağımsız `context-fulltap-corrected-baseline` kaydı gerçek olayları doğruladı: ilk pointerdown (110,673), ikinci pointerdown ve pointerup düğme merkezinde (640,537), ilk parmak bırakılmadan tutuluyor. Eski `a9` üzerinde sonraki 1,0 simülasyon saniyesinde can3/eğilme/hazır düğme korunurken yetenek hiç başlamadı; hiçbir ön saldırı, dünya durumu yazımı veya düşman temizleme kullanılmadı. Yalnız bu düzeltilmiş tamamlanmış dokunma kaydı gerçek hata kanıtıdır.

Hedefli düzeltme yalnız `CampaignGame._input` bağlamsal dokunma yolundadır: görünür düğmenin gerçek dikdörtgeni, bağımsız parmak sahibi, tek etkinleşme, GUI öykünmesinden önce tüketme, bırakma/iptal ve odak kaybında temizleme. Beden, sanat, fizik, klavye/fare ve gamepad eşlemeleri değişmedi. Yatay/dikey doğrudan yönlendirme regresyonu önce 60 kontrolde 8 FAIL, sonra ek engelli/sürükleme durumlarıyla **64/64 PASS**; UI 977 ve bomba 566 da PASS. Bunlar motor yönlendirme testleridir; düzeltilmiş yeni web hash'inin gerçek dokunma doğrulaması ayrı kapıdır, henüz başarılı ilan edilmez.

PR `acfa4ad` / CI `45091387046`: kaynak, Windows, macOS ve Android emülatörü PASS. Emülatör altı sayfalı kahraman erişimini, TR/EN yerleşimini, gerçek Aion atış/zıplama, iki tavşanın şarjlı sıçraması, yön değiştirme ve gerçek iki parmak çömel/ateşi doğruladı. Linux aynı turda ikinci dokunmatik bombayı soğuma bitmeden gönderdiğinden FAIL; yeni helper gerçek bırakma saati ve bağımsız normal Retry hazırlığını kullanır. Bu CI başarısızlığı veya sonraki yayın tamamlanmış sayılmaz.

Eski canlı 0.29.0 `56d6256c05dff7a1` üzerinde normal UI ile gerçek test kaydı hazırlandı: Ayça/Rabbit, shore checkpoint, skor25, `taken`/`awarded` içinde tek `shore:fruit:1`, şema3. Gerçek eski service-worker/cache kapalı kalıcı profilde korunur; 0.50 yayımlandığında normal güncelleme ve Continue yoluyla sınanacaktır. Bulut TLS proxy'si için yalnız testte pinlenmiş SPKI taşıması kullanılır; doğrudan üretim sertifikası veya fiziksel cihaz kabulü iddia edilmez.


### Düzeltilmiş dokunma paketi ve son kontrol kapsamı

Yeni yerel paket **0.50.0 / `6cfb02012ffaa168`**: PCK199.167.072 bayt; SHA-256 `8d549684a541346c19fe6750386c567a516e24b726768a9a47a2c408d2f8214e`. Export öncesi/sonrası557 ürün girdisi aynı; `a9` ile karşılaştırınca PCK içindeki tek değişen oyun dosyası `campaign_game.gd` dokunma yönlendirmesidir. Sanat, gövde, fizik, kayıt biçimi ve diğer kontroller aynı kaldı.

- Düzeltilmiş gerçek dokunuşla Armadillo yatay dokunma/Y25, Kurbağa yatay tek dokunma/Y23, Armadillo393×873 dikey iki parmak20 kontrol: **68 PASS**, yakalanan script/tarayıcı hatası yok. Bırakılan noktanın bağlamsal düğme olduğu, ilk çubuk parmağının tutulduğu, tek yetenek/ek silah veya bomba çıkmaması ve temizlik doğrulandı. Önceki yanlış parmak denemeleri bu toplama katılmadı.
- `6cf` yeni profil gerçek normal tarayıcı akışı28 kontrol PASS: hareket/ateş, gerçek G ve tek dokunmatik bomba, iki yön, eşzamanlı hareket/zıplama ve iptal, offline yeniden yükleme ve Continue. Gamepad özel yetenek Y sanal aygıttır; fiziksel Xbox/PS testi değildir.
- GitHub CI `45094356685`, `978f4e2` kaynak işi: **66/66 paket, 54.068 kontrol PASS**, ayrıca40 Python Android yardımcı testi PASS. [CI kaynak sonuçları](evidence-sol62/source-results-0.50-ci.json). Linux font/yerleşim ortamındaki kontrol sayısı yerel53.987'den farklıdır; yeni bağlamsal suite64 kontrol, diğer UI paketleri gerçek ölçülen yerleşim sayısını kullanır. Sayı farkı test eksiltme değildir. Tam platform/yayın zincirinin sonucu henüz bu satırda başarılı ilan edilmez.

Geçerli son test komutu `browser_six_heroes.py --activation-only --inputs touch pad` yalnız gerçek menü girişi ve hedeflenen giriş etkinleşmesini sınar; ana altılı yürüyüş/nişan matrisinin yerine geçmez. `--viewport WIDTH HEIGHT` pozitif boyut doğrulamasıyla eklenmiştir. Baseline, kontrollü sahne, normal yerel oyun, CI, canlı yayın ve kullanıcı sanat kabulü ayrı tutulur. Kullanıcı kabulü bekler; Mission2 geliştirilmez.


### Son arayüz düzeltmesi ve yerel kapıların kapanması

`6cf` üzerinde CI'nın birebir normal komutu `browser_forge.py --scenario all --rescue` TR'de **55 kontrol PASS**: altı gerçek karakter seçimi, ana kart sayfalamasından Aion'a dönüş, açılış/yardım/Attract, iki yön, Sonsuz modu/kol menüsü, sekiz gerçek nişan yönü, çömel/ateş ve ilk kurtarmanın ipten kurtulma/yürüme/çanta/temasla tek ödül zinciri. EN +200% yazı boyutunda ayrı ön yüz34 kontrol PASS. CI978/9f'deki son Linux hatası, testin son Eren sayfasında Aion kartını aramasıydı; gerçek RosterPrevious/Next kullanımı ve yeni kart kimliklerinin motor onayı eklendi. Karakter seçimi kapsamı dörtten altıya çıkarıldı, kör Next döngüleri kaldırıldı. Hiçbir gizli kontrol JS ile açılmadı.

Görsel inceleme, EN200 Main kartında `Kutsanmış` adının son `ş` harfinin ayrı satıra düştüğünü doğruladı. Mevcut fontun tam ad genişliği ölçülür; sığmayan durumda kart/sayfa kapasitesi azalır. Yazı boyutu, ad ve font değiştirilmez. Seçili kart; dil, boyut, yön ve controller seçimi sırasında gerçek kapasiteye göre bulunur. Varsayılan100% işaretçili masaüstünün altılı/iki sütunlu düzeni korunur; dokunmatik dar ekranın mevcut sayfalaması korunur. Eski zorlanmış-dokunma testinin masaüstü altılı grid beklentisi yanlış hazırlıktı ve ilk kırmızı kayıt saklandı; gerçek masaüstü koşulunda koruma testi geçti.

Yerel native kontroller: charge/roll/paged UI **2908**, front presentation **1720**, campaign selection **108** PASS. İki geniş font ailesinde adlar gerçek istenen boyutta kontrol edildi. Yeni en son yerel paket **0.50.0 / `a69aaa019e01382d`**: PCK199.168.144 bayt, SHA-256 `b65c8809a05dde39fbecbc3f7f0b24b2bdebdb2332e35bc04ca0b64921d5139d`.557 ürün girdisi export öncesi/sonrası aynı; `6cf`e göre yalnız `game.gd` ve `pixel_interface.gd` değişti. Beden/sanat, fizik ve düzeltilmiş dokunma kodu aynıdır.

`a69` gerçek EN200 ön yüz34 kontrol PASS; ayrıca normal Settings200→Main gerçek RosterNext→SelectSheep hedefli görüntü4 kontrol PASS: Kutsanmış tek satırda, istenen2.0 yazı boyutu ve font aynıdır; kontroller sığar. Dokunmatik100% mevcut iki kart sayfası ayrı korundu, gerçek işaretçili masaüstü altılı grid native denetimle korundu. Yeni profil startup/offline gerçek Continue7 kontrol PASS. Önceki tam görev/gövde/giriş kanıtları kapsamı değiştirilmeden korunur; arayüz değişikliği için aynı görevler sahte yeni kanıt diye tekrarlanmadı.

Görev sonu kaynak tazelik kontrolü: Drive26 betik+2 testin kimlik/boyut/değiştirilme zamanı yine28/28 aynı, ek dosya yok; iki güncel devir belgesi21 Kasım tarihleriyle aynı. GitHub main hâlâ466492f. AIONIA resmî belge metadata'sı13 Kasım2026T00:29:34.975Z ile okunanv1.7 anlık kopyayla aynı. Bu metadata kontrolü yeni bir içerik okuması veya standart sürümü uydurma değildir. Drive'a yedek/yükleme yapıldığı iddia edilmez.

Sonraki kapı: bu son kaynak ağacının tam CI'sı, main birleştirmesi, başarılı main artifact'ının Pages'e taşınması, gerçek canlı0.50 açılışı, korunmuş0.29 kaydının normal güncellemesi ve canlı Ayça su/Eren teras görevleri. Başarılmayan bu uzak kapılara PASS yazılmaz. Kullanıcı sanat/oynanış kabulü ve fiziksel cihaz matrisi hâlâ ayrıdır; Mission2 yoktur.


### Son kaynak sayfalama regresyonu

CI45097856611 /71c1845 kaynak kapısında yalnız `unslop_quality` testi FAIL: büyük yazıdaki gerçek tek kartlı düzeni dolaşırken test sabit üç sayfa varsayıyordu. Oyun/pager sorunu değildir. Kontrol gerçek önceki/sonraki düğmeleriyle, en çok kahraman sayısı kadar sayfa dolaşır; altı benzersiz ve görünür/erişilebilir kart şartı aynıdır. Aynı eski `/2` varsayımı komşu Arcade roster testinde, üç adımlık sınır seçim akışında da kaldırıldı; üretim dosyası/PCK değişmedi.

Yerel odaklı tekrarlar: Unslop778, charge/roll/paged UI2896, seçim108; komşu Arcade roster893 ve seçim108 PASS. Kontrol sayıları gerçek görünür eylem/font ortamına bağlıdır; sabit toplam değer kalite ölçütü yapılmaz. Test sonu altı karakter kümesi ve bütün görünür kontrol sınırı şartları korunur. Önceki kırmızı günlük ve CI bağlantısı saklıdır. Tam son CI sonucu henüz PASS ilan edilmez.

### 0.51.0 · Aion ve Kutsanmış yeniden çizimi

Kullanıcı iki karakterin T pozuna ve karakter paftasına bağlı yeni oyun çizimleri istedi. Aion için A varyantındaki DNA kuyruğu ve bilim önlüğü, Kutsanmış için v02 paftasındaki hale, krem yün ve iki ayaklı duruş kullanıldı. On özgün atlasın 204 karesi seçim, Mission 1 giriş ve sonuç geçişi, hareket/nişan, dar geçit, bomba, yakın vuruş, ip kesme, hasar ve düşüşe bağlandı. Ayça, Eren, Armadillo ve Kurbağa çizimleri korunur. Güncel kayıt ve kaynaklar [karakter sanat notunda](M1-HERO-ART.md). Farklı piksel estetiğinin kullanıcı kabulü açık kalır.

Armadillo yerle gerçekten temas ederek kabuğunda ilerlediğinde zeminden kısa taş parçaları çıkar. Havada ve ilk kapanışta yeni parça oluşmaz. Azaltılmış hareket seçeneği bu görsel katmanı kapatır. Eski yükleyici kontrolleri artık gerçek StartRun ve PauseRun eylemleri ile gerçek skorun kayıt altına alınmasını bekler.

- [Üç yolun normal giriş kayıtları](evidence-sol62/hero-routes-0.50.json), Armadillo ve Kurbağa ile su, teras ve kök yollarını gerçek boss sonucu ve kayıt dahil ayrı ayrı doğruluyor. Yerel 0.50 yapılarının kimlikleri her satırda belirtilir.
- Önceki canlı 0.50.0 `e51e7e7247abd731` üzerinde Kutsanmış ile kök rotası normal klavye/fare girdileriyle tamamlandı. 16 kontrol, bir gerçek ölüm ve aynı bölümden yeniden deneme, yaklaşık 450 duvar saati saniyesi, gerçek boss sonucu ve ana menü. Böylece 0.50 ailesinde su, teras ve kök rotalarının her biri için canlı tam görev kanıtı var. Kahraman/rota kombinasyonlarının tamamı oynatılmadı.
- Ara 0.51.0 `af1eb6b600424b6c` web paketinde normal klavye/fare Aion 817 ve Kutsanmış 804 kontrol PASS. Gerçek menü seçimi, iki yön ve geri adım, zıplarken ateş, silah namlusu, zemin hizası ve bomba doğrulandı. Hareketsiz oyun durumu enjekte edilmedi. Ağır bulut tarayıcı kaydı 60 kare/s hedefinin altında; ölçülen kayıt kareleri artırılmadı. 393×873 Armadillo dokunma/sanal gamepad 24 kontrol PASS; fiziksel kol testi değildir.
- Temas kareleri eklenmiş 0.51.0 yerel paket `8f39e1813e64181c` üretildi. PCK 200.319.816 bayt, SHA-256 `4acd8a8beb2ef87d664e904446110c915f5d9894476a2e1d29cee238f2e02beb`. Son hedefli motor testleri 4.216 kontrol PASS (gövde 2.798, sunum 504, Mission 1 davranış 66, yeni kahramanlar 848). Yeni yakın vuruş ve ip kesme, gerçek hasar/kurtarma anında kare 3'e ulaşıyor. On kullanılmayan eski hareket kaynağı ve iki eğilme atlası Git geçmişi ve kaynak ağacında korunur, paketlere alınmaz.
- 0.51 yayını bu kayıt yazılırken başlatma aşamasında; en son doğrulanmış Pages 0.50.0. Vercel ayrı olarak `DEPLOYMENT_DISABLED` / Payment required döndürüyor. Sıradaki kapı son yerel tarayıcı sonuçları, PR CI, main CI, Pages ve yeni canlı açılış. Mission 2 kapsam dışında.

Son ürün commit’i `8983722`, tam kaynak kopyasından dışa aktarım `aae78e1c103f6763` (200.319.896 bayt, PCK SHA-256 `ed4fd6fd93c42a1b9449be673f4b051b3023cb8db39bffa9d8586243e05e3372`). Yakın vuruş hareket esnasında adımı korur. Hedefli testlerde 9.244 kontrol PASS. Render denetimindeki 12 ilk yanlış beklenti, iki kahramanın da eski ateş karesini kullandığını varsayıyordu. Aynı kaynak/satır/kare denetimi yeni yakın vuruşa bağlandı. Dağıtım [PR 11](https://github.com/kaansavukduran/aion_endless_run/pull/11) ve mevcut Actions kapısıyla ilerler.
