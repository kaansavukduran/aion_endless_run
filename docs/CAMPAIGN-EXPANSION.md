# Mission 1 · 0.24.0 yerel genişleme

Durum: **yerel çalışma / TASLAK sanat ve içerik**. Başlangıç kaynağı `90055c5abf7e339c4cf30ad698f8c9f6383b59ae`, dal `feat/keeper-rescue`. Önceki canlı 0.23 sürümü bu görevde değiştirilmedi. Push, merge, GitHub Release ve Vercel/Pages yayını yapılmadı. Kullanıcının `writing-block.md` kapsamı uygulandı; belgeye gömülü rol ifadeleri yeni bir yetkilendirme veya dışa yayın izni sayılmadı.

Fragaria Unslop ile mevcut Godot 4.6.3 mimarisi üzerinde çalışıldı. Canlı AIONIA belgesi v1.7, regresyon belgesi v1.1 ve karakter referans dizini okundu. Bu, bütün standardın koşulsuz sertifikası değildir; özel belge içerikleri veya özel referans dosyaları bu kaynak ağacına kopyalanmadı.

## Gerçek kapsam

Ateş düğmesi yakındaki bağlı NPC için 0,6 saniyelik bıçak hareketine dönüşür. Temas 0,3 saniyede gerçekleşir; öncesinde bağlar çözülmez. Altı kahramanın ayrı çizimi vardır. Yürüme, mermi ve hasar mantığı bu hareket boyunca kesilmez diye varsayılmadı: kahramanın fizik X konumu ve yönü kısa kesme hareketinde sabitlenir. Fizik konumuna kare başına sahte düzeltme uygulanmaz. Bağ çözülünce NPC kalkar, teşekkür eder, gerçek silah/ikmal/puan verir ve yürüyerek ayrılır.

Sadece temas etmek, uzaktan ateş etmek veya bomba NPC kurtarmaz. Kafes bulunan örneklerde önce gerçek kafes mekanizması açılır; bağlı NPC yine taze Ateş basışıyla kurtarılır. Yakın düşman varsa yakın dövüş önceliklidir. Ödül ve kurtarma kimlikleri kayıtla korunur; tekrar denemeden puan veya ikmal üretilemez. Verilmiş özel silahın mühimmatı checkpoint yeniden denemesinde geri doldurulmaz; temel tabanca geri gelir.

## A · Bölüm envanteri

| Alan / rota | Sabit sahne ve karşılaşmalar | NPC | Mekanik / araç | Durum |
|---|---|---:|---|---|
| Kıyı / ortak | `shore`; 4 karşılaşma; ilk iki lamba | 3 | Lamba, kapı, ikmal, bekçiler | YENİ EKLENDİ; test kapsamı aşağıda |
| İskele / ortak | `quay`; 4 karşılaşma | 2 | Boşluk, üst platform, korunmuş Fener Kızağı | MEVCUT + GENİŞLETİLDİ |
| Dallar / üst yol | `canopy`; 2 karşılaşma; ikinci karar | 0 | Yüksek platformlar, bahçe atmosferi | MEVCUT + GENİŞLETİLDİ |
| Su / A | `water`: `moss_water`, `deep_channel`, `sunken_station`; `water:encounter:0..5` | 9 | Akıntı, elektrik / savak; Su Kabuğu; Akıntı Bekçisi | YENİ EKLENDİ |
| Bahçe / B | `terrace`: `hanging_gardens`, `wind_terraces`, `glass_greenhouse`; `terrace:encounter:0..5` | 10 | Hava akımı, sarmaşık / rüzgâr; Rüzgâr Kızağı; Teras Bekçisi | YENİ EKLENDİ |
| Kök / C | `roots`: `root_corridor`, `crystal_hollow`, `drill_chamber`; `roots:encounter:0..5` | 11 | Kaya, pençe / kristal; Kök Sondası; Sondaj Muhafızı | YENİ EKLENDİ |
| Röle / ortak | `relay`; 4 karşılaşma | 4 | Ağır devriye, röle ve imzasız bakım izi | YENİ EKLENDİ |
| Arena / ortak | `arena`; Kök Motoru, üç evre | 4 | 90 HP; çekirdek penceresi, ışın uyarısı, zemin dalgası, dronlar | GENİŞLETİLDİ |

Ana topoloji ve eski sahne kimlikleri korunur: A toplam 22, B 23, C 24 kurtarma fırsatı; bütün haritada 43 farklı sabit kimlik. Her yaprak rotada `:secret:0` ve `:secret:1` ayrı isteğe bağlı yükseltilmiş yan alanlardır; kapı, platform, NPC ve gerçek ödül içerirler. Bunlar dördüncü ana yol değildir. Belgede tarif edilen tam sualtı odaları ve yer altına inen bağımsız tünel sahneleri bu sürümde uygulanmış sayılmaz.

**Süre:** Alan başına ayrı hedef/ölçüm kaydı bu çalışmada tutulmadı (NOT MEASURED). Dosyadaki kıyı/iskele zaman çizgisi tasarım referansıdır; gerçekleşmiş değer olarak sunulmaz. 9–13 dakika bütün görev için tasarım hedefidir. Botun aktif model zamanı ve gerçek tarayıcı duvar saati test kayıtlarında ayrı tutulur. Altı kahramanın model koşuları bütün sırları toplamaz; bu değerler insan oynama süresi veya 9–13 dakika hedefinin başarı kanıtı değildir.

## Düşmanlar ve ödüller

| Sınıf | Kimlikler | Gerçek ayrım |
|---|---|---|
| Korunan 8 normal | `gnome`, `beetle`, `seed`, `crow`, `moth`, `drone`, `slime`, `wisp` | Eski hareket ve saldırılar |
| Su: 3 yeni normal | `leech`, `hopper`, `siphon` | Yapışma/yavaşlatma, sıçrama, lambayı söndürme/atış |
| Bahçe: 3 yeni normal | `kite`, `mirror`, `vine` | Hava fanı, hazırlık sırasında yansıtma, uyarılı yer süpürüşü |
| Kök: 3 yeni normal | `burrow`, `conductor`, `mimic` | Saklanma/çıkma, yakındakini güçlendirme, sandıktan atılma |
| Ayrı 4 ağır | `sweeper`, `glider`, `borer`, `patrol` | İki kırılabilir zırh + 8 gövde HP; farklı saldırı/hareket |
| Ayrı 3 mini boss | `current_guard`, `terrace_guard`, `drill_guard` | 12 HP; iki saldırı; çekirdek/zırh/platform penceresi |
| Ana boss | Kök Motoru | 90 HP / üç evre; son vuruştan sonra güvenli kısa yıkılış |

Normal düşman 1 HP ve 100 puandır; ağır, mini ve ana boss bu sayıya katılmaz. Normal vuruş/üstüne basma gerçekten hasar üretir. Saldırı menzilleri, hızları, fizik temas yarıçapları ve bölgesel listeler `campaign_content.gd`, `campaign_enemies.gd` ve `campaign_world.gd` içindedir. Bölüm geometrisi sabit, eski başlangıç düşmanlarının varyasyonu koşu tohumu ile tekrarlanabilirdir. Sınırsız rastgele spawn uygulanmadı.

NPC rolleri: bekçi, teknisyen, kurye, bahçıvan, gözlemci, arşivci. Teknisyen tamir/geçit, kurye kısa süreli takip ve gerçek destek atışı, arşivci isimsiz bakım ipucu sağlar. Gizli su/bahçe/kök NPC rolleri sırasıyla gözlemci/bahçıvan/arşivcidir. Yeni unvanlar ve makine adları TASLAK; kanon onayı iddia edilmez.

## Silah, destek, çevre ve araç

| Sistem | İşlevsel envanter |
|---|---|
| Temel silah | Sınırsız tabanca, 0,32 s; manuel reload yok |
| 10 özel silah | `heavy` hızlı fener, `scatter` üçlü saçma, `arc` delici, `beam` hızlı uzun delici ışın, `disc` iki sekme, `harpoon` uzun delici, `seeker` en çok üç hedef, `spore` kısa geniş fan, `trap` zemine bırakılan alan kapanı, `nova` tek alan patlaması |
| 8 destek | Can, kalkan, bomba, araç tamiri, 12 s hız, 12 s hasar, gizli oda ışığı, ödül mıknatısı |
| 12 çevre | İskele kırma, kapı, lamba, röle, açılan köprü, akıntı, hava akımı, kaya, sürpriz ikmal, gerçek NPC kafesi, savunma kulesi, bakım paneli |
| 4 sürülebilir tür | Korunan Fener Kızağı; dalabilen Su Kabuğu; süzülen Rüzgâr Kızağı; kayayı delen ve kısa menzilli güçlü atışlı Kök Sondası |

Hasar, mühimmat, aralık, mermi hızı, yaşam süresi ve delme değerleri `CampaignWeapons.SPECS` içindedir. Yeni silah başına yeni mobil tuş yoktur. Gerçek hız/güç/mıknatıs etkileri modelde sınanır; sadece ikonlar değildir. Kapan ve nova ana boss üzerinde de tetiklenir; nova ömrü sonunda bir kez patlar.

Yaşayan rota aracı Röle ve arenaya taşınır. Araçlar 4 HP, binme/inme, kendine özgü hareket/atış ve güvenli tahliye kullanır. Yeni üç araçta ayrı hareket/atış/hasar/yıkım çizimleri vardır; eski kızağa yeni bir yıkım paftası üretilmiş sayılmaz. Yıkılan araç onarım alınca kendiliğinden yeniden ortaya çıkmaz.

## B · Yeni sanat envanteri

| Atlas | Kullanım | Gruplar / gerçek kare | Kaynak boyutu | Kayıt |
|---|---|---:|---|---|
| `assets/campaign-rescue-heroes.png` | Altı kahraman: bıçak çıkar / kes / kapat | 6 / 36 | 1266×1243 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-rescue-npcs.png` | Sekiz mevcut anime tasarımı: bağlı / çözül / kalk / teşekkür / hediye / ayrıl | 8 / 64 | 1263×1246 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-water-enemies.png` | Üç su düşmanı × hareket / hazırlık / saldırı / yenilme | 12 / 72 | 1024×1536 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-garden-enemies.png` | Üç bahçe düşmanı × dört durum | 12 / 72 | 1199×1312 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-heavy-machines.png` | Dört ağır makine × dört durum | 16 / 80 | 1217×1293 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-mini-bosses.png` | Üç özgün mini boss × dört durum | 12 / 72 | 1536×1024 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-vehicles.png` | Üç yeni araç × dört durum | 12 / 72 | 887×1774 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-root-engine.png` | Üç evre × bekleme / hazırlık / saldırı / yıkılış | 12 / 72 | 887×1774 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-environment.png` | On iki çevre sınıfı: açılma / etkinleşme / kırılma | 12 / 47 | 1145×1374 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |
| `assets/campaign-root-enemies.png` | Üç kök düşmanı × dört durum | 12 / 72 | 1145×1374 | Değişken gerçek alfa kesimi; ayrıntılı rect, origin, sabit ölçek manifestte |

Toplam: **10 yeni sprite PNG, 114 anlamlı eylem satırı/grubu ve 659 kullanılabilir ayrı çizim**. Kaynakta 660 nominal hücre vardır; birbirine bağlı çizilmiş bir köprü hücresi oynatmadan çıkarıldı ve sayılmadı. Aynı kareyi çoğaltma, boş hücre veya eski kahraman karesini yeniden sayma yapılmadı. Karelerin farklı byte özeti tek başına estetik kalite onayı değildir.

Ayrıca `campaign-panorama.png` üç bölge için üç arka plan paneli içerir; animasyon karesi diye sayılmaz. Kaynak PNG baytları üretilen orijinallerle aynı; mevcut 65 PNG de başlangıç commit’iyle birebir aynı. Yeni resimler kullanıcı isteğiyle AI destekli üretildi, SNK varlığı kullanılmadı. Kimlik, dosya özeti, üretim kaydı ve frame rect/origin listesi `assets/CAMPAIGN-EXPANSION-PROVENANCE.json` içindedir. Yeni tasarımlar teknik olarak incelendi; nihai sanat/kanon onayı verilmiş sayılmaz.

Her örnek bağımsız dokuda 2 kaynak piksel şeffaf gutter kullanır. Kesilmiş kulak, bağlı komşu çizim veya halenin ayak diye alınması test edilir. Bıçak paftasının tek karakter ölçeği, mevcut tabancalı nötr gövdeye bağlandı. Özellikle baykuşta ilk görülen yaklaşık %18 gövde farkı bu şekilde giderildi. Havada duran düşmanın uçuşu ile ayak hizası hatası aynı kabul edilmez.

## Ses

Beş ayrı 24 saniyelik özgün sentez ortam/müzik döngüsü eklendi: kıyı, su, bahçe, kök ve boss. Kaynak, süre ve SHA-256 `assets/audio/CAMPAIGN-AUDIO.json` içindedir. Kurtarma, bağ kesme, hediye, sır, mekanizma, düşman, muhafız ve boss için mevcut prosedürel ses sistemi genişletildi. Pause/mute/volume gerçek stream üzerinde sınanır. Her karaktere ve her araca ayrı profesyonel hareket/foley ses seti bu çalışmada tamamlanmadı; miksin fiziksel cihazda dinlenmesi NOT TESTED.

## C · Mühendislik ve doğrulama

Yeni sistemler `campaign_rescue`, `campaign_content`, `campaign_enemies`, `campaign_weapons`, `campaign_vehicles`, `campaign_catalog`, `campaign_environment_view` modüllerine ayrıldı. Eski `RunnerWorld`, motor, sonsuz koşu kayıtları ve kontrol eşlemeleri korunur. Yeni schema 2, eski schema 1 kurtarmalarını otomatik hediye üretmeden taşır. `snapshot` derin kopyadır; sonraki dünya değişimi kaydı geriye dönük değiştiremez.

Bulunan somut nedenler ve onarımlar:

- Yeni bıçak baykuşunun ölçeği bekleme yerine aktif tabancalı gövdeye eşlenmiyordu; sabit atlas ölçeği düzeltildi.
- Namlu çok yakın kapının ötesinde başlayabiliyordu; ilk uçuşun başlangıcı dahil segment çarpışması eklendi.
- Aktif köprü/kırık iskele kayıt dönüşünde yalnız görsel bayrak taşıyordu; fizik yüzeyi de yeniden kuruluyor.
- Hızlı ışın kareler arasında hedefi atlayabiliyordu; düşman ve boss isabeti artık segment üzerindedir.
- Ödülden önce kayıt alındığında bekleyen hediye kaybolmasın diye hediye kimliği kurtarmadan ayrı tutulur; alan çıkışı bu kısa teslimatı bekler.
- Kapanın ana boss tetiklemesi ve novanın ömür sonunda tek patlama tüketimi açıkça ele alındı.
- Yeni 24 saniyelik müzik `playing` durumuna bakılarak her karede yeniden başlatılabiliyordu. Gerçek WebAudio probunda eski adayda 118 uzun örnek başlangıcı görüldü; tek parça/açma sınırında başlatma ve stream oynatmaya geçişle yeni adayda uzun örnek oluşturma sıfır, müzik başlatma sayısı bir oldu. Pause/mute/yeniden açma regresyonu kalıcı teste eklendi.
- Yeni CJK metinleri font dışına taşıyordu; ek OFL alt kümesi yeniden üretildi ve her yeni metin için glyph kontrolü eklendi.

Test sonuçları, aday kimliği, ölçümler, ekranlar ve açık sınırlar aynı klasördeki `verification.json` ve `README.md` içindedir. Headless model, kurulmuş render sahnesi, gerçek tarayıcı girişi ve fiziksel cihaz aynı kanıt türü değildir.

### Dosya ve doğrulama sorumlulukları

| Dosya / sistem | Değişiklik | Doğrulama / sınır |
|---|---|---|
| `campaign_world.gd` | Sonlu rota, yüzey/hasar/isabet, schema 2 ve alan geçişi | 18 model tamamlanması; eski schema 1; özel silah hedefleri |
| `campaign_rescue.gd` | 43 sabit NPC, 6 rol, tek kesme ve kalıcı hediye | 43 tek ödül; 36 yan oda yaklaşımı; 15 gerçek Firefox kurtarması |
| `campaign_content.gd`, `campaign_enemies.gd` | Karşılaşma, oda, 9 yeni normal/4 ağır/3 muhafız, çevre | Gerçek saldırı/hasar ve üç rota; kanon TASLAK |
| `campaign_weapons.gd`, `campaign_vehicles.gd` | On özel silah, dört araç davranışı/taşıma | Gerçek mermi isabeti/cephane, dalma, tahliye; eski kızağın yeni wreck paftası yok |
| `campaign_catalog.gd`, `campaign_view.gd`, `campaign_environment_view.gd` | İzole kaynak kareler, sabit ölçek/origin, bölge ve aksiyon çizimi | 659 farklı runtime crop; 48 kurulu sahne kontrolü; kullanıcı sanat onayı ayrı |
| `campaign_game.gd`, `campaign_touch.gd` | Aynı ortak kontroller, bağlamsal bıçak, kompakt boss HUD, güvenli ses döngüsü | Chromium 30 / Firefox 88 gerçek giriş kontrolü; fiziksel kol/cihaz NOT TESTED |
| Locale JSON / CJK alt kümesi | 11 dilde yeni metin; özgün OFL lisansı korunur | Bütün yeni karakterler/font glyph'leri; farklı ölçek/yön menüleri |
| `register_campaign_expansion.py`, `prepare_campaign_audio.py` | Tekrar üretilebilir alfa kayıtları ve özgün sentez | Orijinal PNG değiştirilmez; hash/provenance kayıtları |
| `tests/`, `run_source_tests.py`, build workflow | Katı kaynak hata denetimi, çizim/giriş/ses regresyonu | Son sonuçlar kanıt klasöründe; uzak CI çalıştırılmadı/yayın yapılmadı |

## D · İşlevsel referans karşılaştırması

| Ölçü | Metal Slug 3 Mission 1 | Bu yerel AIONIA görevinde |
|---|---|---|
| Ana yaprak rota / karar | UNKNOWN | 3 / 2 |
| Normal mekanik arketip | UNKNOWN | 17 |
| Ayrı ağır sınıf | UNKNOWN | 4 |
| NPC rolü / fırsat | UNKNOWN | 6 / rota başına 22–24, haritada 43 |
| Sürülebilir tür | UNKNOWN | 4 |
| Temel dışı silah / destek | UNKNOWN | 10 / 8 |
| Etkileşimli çevre | UNKNOWN | 12 sınıf |
| Mini boss / ana boss evresi | UNKNOWN | 3 / 3 |
| Yeni animasyon grubu / kare | UNKNOWN | 114 / 659 |

SNK tarafının doğrulanmamış sayıları uydurulmadı; içerik veya kalite eşitliği iddiası yoktur. Esin yalnız genel dallanma, kurtarma ve run-and-gun ilkeleridir.

## E · Açık sınırlar

- 9–13 dakika insan oynama süresi ölçülmedi. Model aktif zamanı bu hedefin yerine geçmez.
- Sualtı dalış odası ve ayrı yer altı tüneli yerine mevcut mimaride iki gerçek yükseltilmiş yan alan/rota kullanılır. Tam sahne tasarımları hâlâ genişletilebilir.
- Profesyonel ses son işlemi, bütün hareket/araç sesleri, fiziksel Poco/iPhone/Xbox/PS kolu, yeni imzalı Android/iOS paketleri ve hedef düşük cihazda 60 FPS NOT TESTED.
- Kullanıcı nihai sanat onayı alınmadı; yeni isimler TASLAK.
- Bu görevde GitHub/Vercel/Pages yayını ve platform Release dağıtımı YAPILMADI. Önceki sürümün canlı testleri yeni yerel sürümün testi gibi gösterilmez.
