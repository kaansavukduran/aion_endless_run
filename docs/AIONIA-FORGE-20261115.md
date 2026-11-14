# AIONIA arcade sunumu ve oynanış · çalışma/QA kaydı

Bu kayıt 15 Kasım 2026, Europe/Istanbul geliştirme kapsamını izler. Başlangıç `main` = `101a8a882f42421314900e2549efba4a59d33561`; aynı işe ait açık PR #3'ün `328fd0d42131f9fc857fe50f2a32488023461ce5` çalışması korunarak `feat/aionia-eightway-npc-ui-20261115` dalında devam edilir. Eski sonuçlar yeni adayın PASS kanıtı değildir.

Yetkili proje Godot 4.6.3 tabanlı Aion Endless Run'dır. Motor, mevcut altı kahramanın kimliği, Endless modu, 15 saniyelik seviye temposu, kullanıcı kayıtları ve onaylı Arcade kontrol düzeni korunur: solda sabit joystick; sağda zıpla, bağlamsal ateş/vur/kes, enerji bombası ve gerektiğinde bin/in.

Canlı kaynakları ana geliştirici bu oturumda okudu: AIONIA **1.7**, karakter referans dizini **revizyon 3**, Aion Endless Run regresyon kaydı **1.1**. Bunlar genel oyuna uygulanabilir kurallardır; bu rapor özel belge içeriğinin kamuya kopyası değildir. Ekli kullanıcı belgesi 1–29 kapsamını tarif eder; son mesajdaki hareket, ağızda silah, araç ve NPC davranışları daha yeni özel karardır.

## Durum sözlüğü ve kanıt sınırı

- **Mevcut**: başlangıç kaynak kodunda vardır; bu adayda çalıştırıldığı anlamına gelmez.
- **Yeni**: bu çalışma kapsamında uygulanır; test sonucu ayrı yazılır.
- **Eksik**: hedef henüz uygulanmamış veya doğrulanmamıştır.
- **PASS / FAIL / NOT TESTED / BLOCKED**: yalnız ilgili gözlemin sonucu. Model, fixture, gerçek tarayıcı, indirilen paket ve fiziksel cihaz ayrı kapsamdır.

Tablonun başlangıç sütunu statik kaynak incelemesidir. Güncel kaynak ve son yerel paket `0.25.0 / 3649b43ccdca3bbb`; üç tam görev koşusu önceki `29cde1501f1a9acb` paketine aittir. Model, gerçek tarayıcı ve fiziksel cihaz kapsamları ayrı tutulur. [Seçili ham kanıtlar](evidence-forge-025/README.md).

## 1–29 kapsam matrisi

| Madde | Başlangıçta gözlenen kaynak durumu | Bu çalışmanın kabul koşulu | Ara adayda uygulama / gerçek test |
| --- | --- | --- | --- |
| 1 · Bütünsel arcade kalitesi | Mission 1 üç rota, düşman/NPC/araç ve eski Endless mevcut | Eski bölümü yeniden kurmadan girişten sonuca tutarlı, özgün akış | Uygulandı · giriş, üç rota/boss/sonuç ve Endless gerçek tarayıcı akışı; yayın makbuzu ayrıca izlenir. |
| 2 · Kaynak denetimi | Main ve açık PR #3 farklı; PR3 başarısız CI içeriyor | Mevcut dal/diff, belgeler, kaynak görseller ve gerçek giriş incelensin; çalışmaları koru | PASS · main/PR/diff ve canlı kaynaklar okundu; özgün çalışmalar korundu |
| 3 · Marka/sanat | ART_BIBLE, provenance, altı farklı kimlik, kırmızı gerçek ilerleme yükleyicisi mevcut | Cute + Profound + Epic; bakır/fener camı/ahşap/kök materyalleri; onaysız görseli resmî logo sayma | Yeni 5 PNG / 144 farklı çizim TASLAK; 76 eski PNG bayt özeti PASS |
| 4 · Açılış | Fragaria gerçek yükleyici mevcut; ayrı 5–8 s AIONIA sunumu yok | Atlanabilir açılış, mevcut gerçek çizimler; hareket azaltma, sessiz kullanım, odak/dönüş güvenliği | Yeni · kaynak 1.964 kontrol; Chromium doğal bitiş + Enter ile atlama PASS |
| 5 · Yaşayan ana menü | Mod düğmeleri, karakter kartları, ayarlar mevcut; arka plan sahnesi mevcut biyoma bağlı | Fener Ormanı sunumu, iki mod, geçerli Continue, karakter/yardım/ayar; bütün temel eylemler erişilir | Uygulandı · TR/%100 ve EN/%200 iki yön tarayıcı; son Pause birincil eylemleri 361 kaynak kontrolünde PASS; son Firefox 28 kontrol PASS. |
| 6 · Attract Mode | Başlangıçta bağımsız kayıt yazmayan demo yöneticisi yok | Gerçek motor/model oynanışı; tüm girdilerle çıkış; oyuncu kayıt/puan/başarı değiştirmeme; kapatma ayarı | Yeni · gerçek hareket/atış, manuel ve 30 s boşta başlama, girdiyle çıkış, iki kaydın değişmemesi Chromium PASS |
| 7 · Altı kahraman seçimi | Altı kart ve gerçek sprite var; kısa yetenek sunumu sınırlı | Altı ayrı mevcut kimlik, gerçek kare önizlemeleri, yetenek metni, odak/onay; dar ekran sayfalama | Yeni · altı gerçek seçim/onay Chromium PASS; yeni/korunan poz kaynakları ayrı kayıtlı |
| 8 · Etkileşimli yardım | CampaignGo ile sayfalı metin öğretici var | Gerçek poz/eylem örnekleri; aktif girişe uygun ipucu; atlama/tekrar açma; dünya durur | Yeni · kaynak/sunum testleri PASS; Chromium gerçek Next/Previous/geri PASS |
| 9 · Mission Start | Yardımdan doğrudan oynanışa geçiyor | Kısa, atlanabilir bölüm/hedef ve kahraman sunumu; sunumda hasar/simülasyon ilerlemez | Yeni · 1.418 sunum kontrolü ve normal tarayıcıda yardımdan oynanışa geçiş PASS |
| 10 · Compact HUD | Skor, sağlık, bomba, silah/mühimmat ve boss metinleri kısmen mevcut | Gerçek kahraman/can/silah/mühimmat/bomba/kurtarma; yalnız aktif kalkan/araç/boss; oyun alanını koru | Uygulandı · gerçek durum HUD; 6.127 kampanya UI kontrolü ve üç tam rota PASS. |
| 11 · Dünya içi bilgi | Lamba, hasar, silah/mermi, boss evreleri ve NPC animasyon altyapısı var | Görsel bilgi gerçek duruma bağlı; gereksiz tekrar/efekt yok | Korundu/genişletildi · gerçek üç rota/boss yürüyüşü ve son 96 görsel fixture PASS. |
| 12 · Silah/güç/araç | On özel silah ve bufflar var; bin/in ani | Eşya/silah ve gerçek sayaçlar; araç geçişi/hasar/tamir/yok olma; temel kontrol düzeni korunur | Uygulandı · 1.189 araç kayıt +2.746 namlu kontrolü, gerçek bin/in; son 96 fixture gömülme/ayna onarımını kapsar. |
| 13 · NPC kurtarma | Gerçek bıçak teması kurtarır, yaklaşık .9 s sonra otomatik hediye verilir | Bıçak veya mermi bağ çözer; NPC gezinir; oyuncu teması teşekkür/hediye; bir defalık kalıcı ödül | Uygulandı · üç tam rotada 20'şer gerçek kurtarma; son pakette 22 giriş/kurtarma kontrolü PASS. |
| 14 · Rota seçimi | İlk ayrım canopy/water, ikinci terrace/roots mevcut | Yalnız erişilebilir seçenek; küçük gerçek rota görseli + kısa açıklama; dünya durur; tüm girişler | Mevcut + yeni görsel · gerçek water/terrace/roots dalları final29 üzerinde PASS |
| 15 · Pause/Continue/ölüm | Pause/save retry/back, ölüm retry ve kayıt yükleme mevcut | Kontroller/ayarlar erişilir; checkpoint retry, güvenli bozuk kayıt; yanlışlıkla yeni oyun başlatma yok | Yeni/genişletilmiş · gerçek sanal Gamepad Start/A resume, yön değişimi ve Firefox retry PASS; fiziksel kol NOT TESTED |
| 16 · Mission Complete | Boss sonrası mevcut victory evresi ve metinli outro var | Boss ölümü tamamlanır, dünya güvenli, ışık/gerçek kahraman zaferi, kısa atlanabilir sunum | Yeni · üç gerçek tam görevde boss/zafer/outro/sonuç akışı PASS (29cde… adayı) |
| 17 · Görev raporu | Skor/rekor/kurtarma/rota temel özeti var | Gerçek süre/kahraman/rota/kill/rescue/secret/silah/araç/can kaybı/boss; kısa özet, erişilir ayrıntı | Uygulandı · gerçek üç tam görevin sonuç/ana menü/kayıt akışı PASS; 1.418 sunum +6.127 UI kaynak kontrolü. |
| 18 · Arcade kayıtları | Ayrı campaign.v1/checkpoint ve best_score mevcut | Hero/rota performansı gibi gerçek kayıtlar; offline; idempotent; Endless rekorunu koru | Genişletildi · üç rotada offline Continue ve gerçek 0.24→0.25 PWA güncellemesinde 11 kontrol PASS; eski rekor/karakter/dil korunur. |
| 19 · Animasyon envanteri | Mevcut kaynak atlaslar ve pivot/provenance var | Yeni dosya/gerçek farklı kare/FPS/süre/döngü/pivot/çarpışma envanteri; eskiyi yeni sayma | Yeni envanter · 124 kahraman + 20 nesne =144 çizim; 10 yeni çizilmiş klip/6 ters çıkış oynatımı ayrı |
| 20 · Ses | Beş özgün ortam döngüsü ve kısa sentez efekt altyapısı mevcut | Menü/başlangıç/kurtarma/sonuç/rekor/boss gibi ayırt edilir durum sesleri; mute/autoplay güvenliği | Yeni durum ses kancaları/kısa sentezler; önceki ortam döngüleri korunur; fiziksel ses değerlendirmesi NOT TESTED |
| 21 · Responsive/erişilebilirlik | Önceki kayıtta iki yön/11 dil/büyütme var | Güncel aday: 1152×648, 393×873, 873×393, küçük telefon/tablet, %100/150/200 ve 11 dil | Kaynak matrisi PASS · 11 dil/%100–200, 6.127 UI kontrolü; gerçek TR/%100 ve EN/%200 iki yön. Fiziksel cihazlar NOT TESTED; son Firefox 28 kontrol PASS. |
| 22 · Mimari | Mevcut Godot bölünmüş dünya/view/game/catalogue yapısı | Ayrı sorumluluklar; devasa yeni script yok; event/timer temizlik; eski kayıtları aç | Uygulandı · mevcut Godot sorumluluk modülleri, geriye uyumlu kayıt; 40 ayrı kaynak süiti PASS. |
| 23 · Kalite kapıları | Mevcut 30 kaynak paketi ve browser/fixture sürücüleri var | Gerçek açılış/oynanış/menü/kayıt/rota/boss/sonuç; hata logunu başarısız say | PASS · son sonuçları süit adına göre birleştirilmiş 40 paket/33.651 kontrol; üç gerçek tam rota 215 kontrol; son paket campaign22 +PWA11 PASS. |
| 24 · Uygulama sırası | Bu Forge hedefleri henüz bitmiş sayılmaz | Kaynak → hareket/NPC/araç → sunum/HUD → üç rota ve Endless → rapor | Uygulama tamamlandı · kaynak/hareket/NPC/araç/sunum/HUD/üç rota/Endless doğrulandı; son Firefox 28 kontrol PASS; CI/yayın kapısı devam ediyor. |
| 25 · Teslim raporu | Eski 0.24 yerel ve yayın kanıtları mevcut | Yeni adayın ayrı sürüm/SHA/build/kanıt/eksik listesi; fiziksel testleri açık ayır | Bu rapor ve ham kanıt envanteri mevcut · son commit, CI ve dağıtım makbuzu yayın sırasında eklenecek. |
| 26 · Sekiz yön | PR3 vektör atışı/klavye/sol-sağ analog/dokunma eklemiş; özgün yön pozları eksik | Altı kahraman, tüm özel silahlar/araçlar, normalize yönler, gerçek isabet; bağlamsal kesme sınırı | Uygulandı · 354 yön/ölçek, 1.924 gerçek kahraman namlu ve 2.746 araç namlu kontrolü PASS; son pakette sekiz gerçek klavye yönü/atış PASS. |
| 27 · Kız NPC 2× | PR3 boy hesabı crop boyu kullanıyor; Dictionary.size erişim hatası var | Efektsiz anatomik standing Aion referansı 1, kız 2; ayak/baş/etiket/kafes tutarlı | Onarıldı · gerçek nötr Aion 73,243 dünya px, NPC 146,485 px; 354 yön/ölçek +288 görsel kontrol PASS. |
| 28 · Yayın güvenliği | Önceki çalışan 0.24 production ve geri dönüş kaydı var | Bu kapsam için belgede açık Vercel onayı var; kritik testler/preview/live smoke öncesi prod değişmez | Yerel son paket 3649… · eski production korunuyor; stage/live smoke ve CI geçmeden main birleştirilmez. |
| 29 · Tam kapsam | Bu tablo 1–29'u ayrı izler | Yalnız yön/ölçek değişikliğini bütün UI/UX tamamlandı diye sunma | 1–29 ayrı uygulanıp izlenir; sanat kullanıcı onayı, fiziksel test ve üretim yayını ayrıca belirtilir. |

## Güncel son yerel doğrulama · 3649b43ccdca3bbb

40 ayrı kaynak süitinin son sonuçları **33.651 kontrol PASS**; bu tek temiz toplu koşu iddiası değildir. Son native renderer96durum PASS. Son Chromium campaign22 ve gerçek eski0.24→0.25 PWA11 PASS. Son Firefox EN/%200 28 kontrol PASS: altı kahraman, yardım, açılış, kayıt yazmayan demo, iki yön, Endless ve ilk sayfada sabit Devam/Ana menü gerçek dokunmayla doğrulandı. Üç son paket tarayıcı kapsamı toplam61kontrol; CI/Vercel yayını ayrıca izlenir.

Son ürün onarımları: büyük yazıda Pause Devam/Ana menü tüm sayfalarda sabit; binme sırasında gövde yere gömülmez; sola inme gövde/örtü aynı yöndedir; azaltılmış harekette namlu ve çizim aynı kareyi kullanır; dropdown desteklenen ▼ glifini kullanır. Native portre önizlemesindeki kesilme, fizik durdurulmuş test sahnesinin yeniden boyutlandırmadan sonra pozu güncellememesiydi; gerçek son Firefox portre ekranında kesilme yoktur. Renderer güncellendi; oyun bu yanlış bulguyla değiştirilmedi.

Aşağıdaki ara koşular ve önceki BEKLİYOR durumları tarihsel teşhis kaydıdır; güncel sonuç tablosuyla karıştırılmamalıdır.

## Son mesajdaki ek kabul koşulları

| Kimlik | İstek / geçiş ölçütü | Kontrol türü | İlk sonuç |
| --- | --- | --- | --- |
| FORGE-MOUTH-OWL | Ömer uçarken tabancayı gagasında/ağzında tutar; süzülme ve üç kanat döngüsünde silah yerinden kopmaz | Kaynak ankrajı + tam çizilmiş klip + oyun renderı | NOT TESTED |
| FORGE-MOUTH-WOLF | Melun koşarken tabancayı ağzında taşır; dört ayaklı depar kimliği korunur | Kaynak ankrajı + hareket/ateş renderı | NOT TESTED |
| FORGE-VEHICLE-SIZE | Aion normal anatomik yükseklik 1 ise araç görünür gövdesi yaklaşık 2 | Aynı dünya/ölçek/zeminde gerçek alfa-gövde ölçümü | NOT TESTED |
| FORGE-VEHICLE-ENTER | Altı seçili kahraman gerçek binme/kapak/içeri geçme animasyonu gösterir; araçta dışarıda asılı kalmaz | Altı model ve gerçek bin/in/destruction; farklı yönler | NOT TESTED |
| FORGE-RABBIT-TAP | Emre ve Eren tıkla/bırak minimum sıçrama tepe yüksekliği Aion tek sıçramasının 1.75×'ı | Aynı fizik dt/apex ölçümü; charge sıfırına yakın release | NOT TESTED |
| FORGE-RABBIT-CHARGE | Basılı süreyle daha yüksek ve tutarlı sıçrama; iptal/odak kaybı gizli sıçrama üretmez | Birkaç süre, klavye/dokunma/gamepad; portre/yatay | NOT TESTED |
| FORGE-OWL-FLAP | Her taze airborne kanat basışı Aion tek sıçrama yüksekliğinin 1.50×'ı kadar yükselme potansiyeli; inişe kadar en fazla üç | Sabit dt fizik; üç kabul, dördüncü ret, landing reset; held glide | NOT TESTED |
| FORGE-NPC-BULLET | Gerçek mermi bağa temas edince tek kez kurtarır; yakın bıçak işlevi de korunur | Mermi segment/isabet, örtülü/saklı/kafes koşulları, tekrarlama | NOT TESTED |
| FORGE-NPC-CONTACT | Serbest NPC sağ/sol güvenli yürür; karakter teması teşekkür ve bir hediye verir; uzaklaşma/retry/resume ödül çoğaltmaz | Normal giriş + snapshot/restore; ayrı sahne fixture sınırı | NOT TESTED |
| FORGE-ART | Zayıf nesne/araç/silah çizimleri yeni özgün kaynakla zenginleşir; mevcut kahramanlar yeniden tasarlanmaz | Aynı oyun ölçeğinde görsel inceleme + kaynak/lisans + kare sayımı | NOT TESTED |

## Yeniden üretilmiş önceki CI hatası

Kaynak: PR #3, SHA `328fd0d`, [GitHub run 43641835294](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43641835294). Bu, eski kullanıcı şikâyetinin tahmini değil, bu oturumda okunan gerçek CI hata çıktısıdır.

- `campaign_ui`: 4.939 assertion kontrolü ve 0 assertion hatası yazmasına karşın `SCRIPT ERROR: Invalid access to property or key 'size' on a base object of type 'Dictionary'` içeriyor. Bu yüzden süit PASS değildir.
- `campaign_directional`: aynı hata, tamamlanmadan 150 s timeout / exit 124. Sıfır tamamlanmış kontrol raporu.
- Statik ortak neden: `campaign_view.gd::npc_growth` ve yön testindeki Aion referansı `RunnerFrameBank.pose` sözleşmesinde bulunmayan `.size` alanını okuyor. NPC `CampaignCatalog.pose` ise `.size` döndürüyor. İki bankanın boyut sözleşmesi karıştırılmış. Fiziksel aktörü kaydırmak çözüm değildir.
- Bu kök neden ilgili view/test sahibi tarafından onarılıp aynı süit yeniden çalıştırılana kadar **OPEN / FAIL** kalır. Diğer eski süitlerin yeşil olması bu hatayı kapatmaz.

## Doğrulama planı ve kanıt konumu

Kaynak/model testleri, normal tarayıcı girdileri ve özel render fixture'ları ayrı kaydedilecek. Yeni `tests/browser_forge.py` doğrudan normal menü düğmelerini, gerçek klavye/dokunmayı ve salt okunur canvas telemetrisini kullanır; kayıt enjeksiyonu, dünya setter'ı, dokunulmazlık, ışınlanma veya doğrudan boss hasarı yoktur. Eksik bir telemetriyi PASS saymak yerine açık hata verir. Üç rotanın tam görevi mevcut `tests/browser_campaign.py` ve model koşularıyla ayrıca sınanır.

Sonuçlar tamamlanınca adayın `docs/evidence-aionia-forge/` alanında kaynak sonuçları, yeni browser JSON/log/görüntüleri, gerçek build manifesti, varlık envanteri ve dağıtım kaydı tutulacak. Henüz oluşturulmamış dosyalar tamamlanmış kanıt değildir.

Fiziksel Poco X7, iPhone/iPad, Xbox/PS kolu ve gerçek cihaz performansı bu bulut ortamında **NOT TESTED**. Chromium/Firefox masaüstü emülasyonunun yerine bu cihazların adı PASS yazılmaz. Safari/WebKit veya Edge çalıştırılmadıysa onlar da ayrı NOT TESTED kalır.

## Yeni aday sonuçları

Bu kayıt ara export **0.25.0 / `1326c4c2d0227925`** içindir. Son kaynak/varlık değişiklikleri sürüyor; bu ara sonuçlar gelecek final build'in testi gibi yeniden etiketlenmez. Ham çalışma kanıtı `/workspace/work/forge-025/` altındadır; henüz kamuya taşınmamış dosyaya kamu bağlantısı uydurulmaz.

| Gerçek koşu | Sonuç | Kapsam ve sınır |
| --- | --- | --- |
| İlk kaynak paketi | 37 paketten 35 PASS; PASS paketlerinde22.574 kontrol | `source-final/source-results.json`; `campaign_ui` timeout/124 ve `campaign_art` eski wolf poz beklentisi FAIL olarak korunur. Başarısız sanat paketindeki204kontrol başarılı toplama katılmaz. |
| Son etkilenen kaynak paketleri | PASS · 7/7 paket,12.680 kontrol | `final-affected/source-results.json`; campaign_ui6.127, campaign_art204, visual222, vehicle art1.189, vehicle muzzle2.746, hero muzzle1.540, mechanics652. UI testi 240s içinde sınırlı paketle yeniden tamamlandı; eski wolf beklentisi yeni gerçek kaynağa göre düzeltildi. |
| Birleştirilmiş kaynak kapsamı | PASS · 39 ayrı paket,32.840 kontrol | Süit adıyla son sonucu alarak iki koşu birleştirildi; tekrar edilen paketler iki kez sayılmadı. Tek komutta39paketin birlikte çalıştığı iddia edilmez. |
| Son native render fixture | PASS · 92 durum | `render-final.log`; bilerek kurulmuş görsel sahneler, normal kullanıcı oynanışı veya fiziksel cihaz testi değildir. |
| Yeni odaklı kaynak paketleri | PASS | Front1.964, campaign presentation1.418, campaign mechanics652, visual222, hero art475, Endless oran120, muzzle1.540, directional354. Bunlar ilgili kaynak koşularıdır; fiziksel donanım değildir. |
| Chromium water tam görev | PASS · 72 kontrol | `browser-water/results.json` + `playthrough.json`; shore→quay→water→relay→arena, 638.55 s duvar zamanı, 0 retry, 19 normal temaslı kurtarma; sonuç/ana menü/offline Continue; betik hatası yok. Bu süre insan oynama süresi değildir. |
| Firefox terrace tam görev | PASS · 72 kontrol | `browser-terrace/results.json` + `playthrough.json`; shore→quay→canopy→terrace→relay→arena, 475.34 s duvar zamanı, 1 gerçek retry, 21 kurtarma; sonuç/ana menü/offline; betik hatası yok. |
| Chromium front + Arcade probu, ilk deneme | Kısmi 25 PASS; sürücü yarışı | Açılış, altı seçim, yardım, iki yön, gerçek demo, kayıt değişmemesi, 30 s idle, Endless/main geçti. İki saniyelik Mission Start doğal biterken eski buton koordinatı okunmuş; hata kaydı zaten `playing`, boş presentation ve 0 script error gösteriyor. Atlatma gerçek Enter girdisine taşındı. |
| Chromium front + Arcade probu, ikinci deneme | Kısmi 35 PASS; oynayış denemesi öldü | Bütün yukarıdaki akış ve sekiz yön/atış geçti. Kahraman yaklaşık7.31 etkin saniye başlangıçta farklı yönlere ateş ederken düşman atışlarına yenildi; sonraki bomba denemesi yapılabilecek durumda değildi. Bu, kanıtlanmış bir dokunma kusuru olarak kaydedilmez; hata görüntüsü ve logu korundu. |
| Hedefli campaign-only tekrar | PASS · 22 kontrol | `browser-campaign-probe/forge-results.json`; gerçek bomba/jump dokunması, sanal Gamepad Start/A, duraklatılmış yön değişimi, sekiz klavye yönü/atış; basılı silahla bağ çözme, uzaktan ödül verilmemesi, NPC yürümesi, hero temasında teşekkür/ödül ve kalıcı kayıt; 0 betik hatası. Yeniden deneme sayısı ham sonuçtadır. |
| Final29 Firefox roots | PASS · 70 kontrol | `final-roots/results.json`; 367.66 s duvar zamanı,0retry,20temaslı kurtarma; görev/sonuç/main/offline;0betik hatası. |
| Final29 Chromium terrace | PASS · 71 kontrol | `final-terrace/results.json`;593.57s duvar zamanı,0retry,20kurtarma; görev/sonuç/main/offline;0betik hatası. |
| Final29 Chromium water | PASS · 74 kontrol | `final-water/results.json`;574.14s duvar zamanı,0retry,20kurtarma; görev/sonuç/main/offline;0betik hatası. |
| Final29 Firefox EN/%200 front | PASS · 26 kontrol | `final-front-en200/forge-results.json`; gerçek ayarla200%,altı seçim/yardım/açılış/demoda kayıt değişmemesi,iki yön,Endless/main;0betik hatası. Bu koşu eski Pause sayfalama yolunu kullanır; aşağıdaki birincil eylem kusurunun onarımını doğrulamış sayılmaz. |
| Son render/namlu tekrarları | PASS | `review-fixes/source-results.json`: visual288, armed muzzle1.924,campaignUI6.127,game127. Önceki sonuçlar süit adıyla yenilenirse39ayrıpakette33.290kontrol olur; tek fresh koşu değildir. Font alt kümesine299glif eklendiği üretim logudur,299test diye sayılmaz. |
| Yeni onarım export / eski0.24→yeni güncelleme / yayın | BEKLİYOR / NOT TESTED | Son Pause/glyph/binme maskesi onarımları için yeni paket bekleniyor; gerçek eski0.24paketi f21be96bbf646fb9 ile güncelleme testi hazırlanmış,henüz çalıştırılmadı. Yeni Vercel yayını yok. |

**Sanat envanteri:** kahraman üretiminde dört yeni PNG, 124 farklı kaynak çizimi, on yeni çizilmiş klip; altı çıkış klibi var olan binme karelerinin ters oynatımıdır, yeni çizim diye sayılmaz. Tutulan 64 yönlü silah pozu ayrı sunum kombinasyonudur, 64 ek çizim değildir. Yeni nesne atlasında bir PNG ve 20 statik simge vardır. Toplam beş yeni PNG ve144 farklı çizim. `original-art.json` ile önceki76PNG'nin76'sı byte-identical. Üretim AI destekli özgün TASLAK'tır; son kullanıcı görsel/kanon onayı anlamına gelmez.

**Son gözlenen UI gerilemesi · AER-005 / AIO-UI-001:** Firefox EN/%200,960×540mantıksal görünümde kısa Endless Pause panelinin ilk sayfası yalnız sayfalama/geri düğmelerini gösteriyordu; Devam/Ana menü sonraki sayfalardaydı. Gerçek görüntü `final-front-en200-third-attempt/failure.png`. Başta sürücü ilk sayfada Ana menü beklediği için durdu; gerçek sayfalama ile26kontrollü akış tamamlandı,ancak bu kusuru kabul edilmiş tasarım yapmaz. Front ekibi aynı durumu253kaynak kontrolünde110başarısızlıkla yeniden üretti ve temel iki eylemi tüm sayfalara sabitleyen dar kapsamlı onarım yapıyor. Yeni export/tarayıcı kontrolü gelene kadar bu alt kayıt FIXED-UNVERIFIED kalır.

Settings testindeki ilk iki deneme farklı nedenle başarısızdı: sürücü eski `Option_text_size_2.0` kimliğini arıyordu; Godot düğüm adını `Option_text_size_2_0` yapıyor. Gerçek sayfaların tamamı gezilmişti; bir sayfalama/girdi kusuru olduğu ileri sürülmez. Kimlik ve gerçek sayfa yanıtını bekleme koşulu düzeltildi; eski hata klasörleri korunur.

Export **0.25.0 / `29cde1501f1a9acb`** üç rotada ve EN/%200 front akışında sınandı. Son küçük onarımlar için üretilecek yeni hash bu sonuçların yerine otomatik yazılmaz. Yeni paket doğrulaması tamamlanınca bu bölüm güncellenecek. Fiziksel Poco X7/iPhone/gerçek Xbox-PS, gerçek Edge/Safari bu koşuların yerine geçmez ve NOT TESTED kalır. Yayın READY tek başına oynanış doğrulaması değildir.

## İlk yayın kapısı · c78ab3c

Gerçek Vercel önizlemesi30048532c94c99a7,45kontrol/0hata ve19dosya bütünlüğü PASS. GitHub43650856407 kaynak40/33.780, Windows ve macOS PASS. Linux/Android'in iki eski test önkoşulu durdu: renderer eski kurt paftasını bekliyordu; emülatör sürücüsü açılışı atlamadan dil menüsü arıyordu. Bunlar geçilmiş sayılmadı. Renderer yeni satır kimlikleriyle108/0yerelde doğrulandı; Android sürücüsü ve yeni CI kontrolü son makbuzda ayrıca izlenecek. Runtime kaynakları/varlıkları bu test onarımında değişmiyor.

## Son dar kapsamlı regresyon onarımı

48dcCI'deAndroid'in15gerçek giriş kontrolü geçti, fakat açılış ekranının tam-sahne görüntüsü diye değerlendirilmesi görüntü kalite kapısını durdurdu. Çekim anı düzeltildi; eşik değişmedi. Firefoxönizlemesinde demo dönüşü hedef koordinatının yerleşimden önce yayımlandığı gerçek probla kanıtlandı:(28,72)yerine(251,151). Menü gizliden görünür olurken var olan Godot-frame hazır sözleşmesi uygulanır;1968front kontrolü PASS. Yeni paket/CI/yayın sonucu önceki paketlerin yerine sessizce yazılmaz.
