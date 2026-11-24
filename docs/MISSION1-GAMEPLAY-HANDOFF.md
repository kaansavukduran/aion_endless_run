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

### 0.31.0 · Elle tasarlanmış alt rotalar, Kök Motoru evreleri, CI düzeltmesi

- 0.30.0 `main`'e alındı ama CI'daki `render_campaign_review.gd` kapak kapalıyken kök kanalına aktör koyduğu için düştü ve Pages'e çıkmadı. Test yeni ön koşula (kilidi kır) güncellendi. Yerel kapı artık CI Linux işini birebir kopyalar: web paketleme, kaynak paketleri, 4 render testi, 3 tarayıcı testi.
- **Alt rotalar (su/teras/kökler):** 8 kartlık elle yazılmış karşılaşma dizisi (`CampaignContent.AUTHORED`). Her kart işaret, karar, karşı hamle ve ödül kaydeder. Bölge rolü önce tek başına öğretilir, sonra farklı zeminde (çukur, akıntı, rüzgâr, karanlık) tekrar edilir, sonra bilinen rolle birleşir. Grup boyutları 1–3 (eski 5'li blok kaldırıldı). Kilitli kapı yalnızca kıskaç (3.) ve sınav (8.) kartında. Kartlar rotanın akıntı/rüzgâr/karanlık bölgesi (.40), tehlikeleri (.43/.72), ağır düşmanı (.62) ve gizli odalarıyla (.30/.68) hizalı. Yer düşmanı çukurda doğmaz.
- **Rota yerleşimi:** Alt rotalarda platformlar sabit 650 px yerine tohumlu düzensiz aralık ve iki yükseklik kullanır. Sandıklar düzensiz aralıklı. Meyveler 220 px'te bir yerine 3–4'lü zıplama yaylarında toplanır (yaklaşık %50 daha az). Kimlikler kalıcıdır.
- **Kök Motoru:** Her yeni evre 1,2 s sendelemeyle başlar: saldırı yok, düşman mermileri ve çağrılmış dronelar temizlenir, ekranın üst ortasında "ne değişti" duyurulur. 1. evrede zemin darbesinden sonra çekirdek 1,1 s açılır (çift hasar). 2. evrede kırılabilir **kök kolu** (8 can) büyür; kol sağken her darbe 150 px geriden ikinci bir dalga yollar (art arda iki zıplama, asla duvar değil); kolu kırmak dalgayı kaldırır. 3. evre kısa atılma/yelpaze doruğudur. Son vuruş mermileri, atılmayı, ışını ve droneları temizler; ödül bir kez verilir; sonra kahraman hasar almaz; sonuç Mission 2'ye geçmez. Ayarlar: `scripts/campaign_boss_pressure.gd` (`STAGGER`, `CORE_OPEN`, `ARM_HP`, `ARM_OFFSET`).
- **Ayrım 1 keşfedilebilirliği:** Araçla tünel ağzına dayanan oyuncuya "Araç sığmaz · inmek için E veya İn" ipucu görünür. Tam oynanış botu araçla burada takıldığı için bulundu.

## Testler (ortam: bulut Linux, Godot 4.6.3 headless/Xvfb llvmpipe, Chromium 1243 SwiftShader)

| Tur | Kontrol | Sonuç |
| --- | --- | --- |
| 0.30.0 | `run_source_tests.py` tüm paketler | PASS · 38.904 kontrol |
| 0.30.0 | `test_campaign_routes.gd` (4 kahraman × 2 ayrım × 2 yol normal hareketle, geçit/tavan/araç/çatı/mermi, kapak/kilit/kayıt, çöken açıklık) | PASS · 169 kontrol |
| 0.30.0 | `browser_campaign.py --combat-controls --offline`, `browser_campaign_audio.py` | PASS |
| 0.30.0 | `browser_forge.py --scenario all --rescue` | 3 denemede 1 PASS. 2 denemede 8 yönlü nişan dizisinde kahraman 1 canla sol sınırda düşman temasıyla öldü ve bekleme zaman aşımına uğradı. Kıyı bölümü; değişen rota koduna girmiyor. Oynak test olarak kayıtlı. |
| 0.30.0 | Fiziksel telefon, fiziksel gamepad | NOT TESTED |
| 0.30.0 | CI `render_campaign_review.gd` | FAIL (kapak ön koşulu), 0.31.0'da düzeltildi |
| 0.31.0 | Kaynak paketleri (59, `mission1_rhythm` 198 + `mission1_boss` 20 kontrol dahil) | PASS |
| 0.31.0 | `render_terrain_review` 40, `render_campaign_review` 654, `render_campaign_expansion` 226, `render_campaign_rhythm` 21 | PASS |
| 0.31.0 | `browser_campaign --combat-controls --offline`, `browser_forge --scenario all --rescue` (51), `browser_campaign_audio --seconds 30` | PASS (ilk denemede) |

## Bilinen eksikler ve sonraki adım

- Alt rotalar hâlâ çok uzun (28–30 bin px). Kartların arasındaki prosedürel ilk düşmanlar ve mekanik kapılar (her 1000 px'te bir, çoğu boş) sıkıştırılmalı.
- Düşman toparlanma evresinin görsel okunurluğu (hazırlık 0,9 s var; toparlanma işareti zayıf) ve HUD hiyerarşisi/sonuç ekranı sonraki turlarda.
- Kahramanların tam rota + boss koşusu yalnızca su rotasında, Aion ile, tarayıcı botuyla deneniyor; diğer rotalar ve kahramanlar için tam koşu kanıtı yok.

## Sol 6.2 sanat sözleşmesi (0.30.0 itibarıyla)

- İskele binası: çarpışma `PIER` = x 780–1180, y −195 (çatı/üst güverte) ile 35 (geçit tavanı) arası. Geçit açıklığı 55 px (zemin 90). Sanat, tavan alt kenarını y=35'te göstermeli; daha alçak çizilirse oyuncu tavanın içinden geçiyormuş gibi görünür.
- Kahraman gövde yükseklikleri (kural): ayakta 74, çömelik 40, araçlı 132 px. Çömelik vuruş merkezi ayaktan −20, ayakta −37.
- Kapak: kilit nesnesi x=820 (vuruş noktası y=−35, yarıçap 45). Kapak zemini x 900–1400; çit x=1400. Çöken hizmet açıklığı x 540–740, y=−140, 2,4 s.
- Kök Motoru: kök kolu vuruş noktası boss.x−120, y=−40, yarıçap 28; çekirdek boss.x, y=−75; portlar ±65, y=−95. Sendeleme 1,2 s, çekirdek penceresi 1,1 s, ikinci dalga +150 px. Kol çizimi geçici kahverengi bloktur.
- Bu değerler kuraldır; yeni sprite yalnızca görüntüyü değiştirmeli, çarpışma ve zamanlama sabitlerini değiştirmemelidir.
