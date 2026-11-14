# AIONIA · AION ENDLESS RUN

## GİRİŞ EKRANI, AÇILIŞ ANİMASYONU, KARAKTER SEÇİMİ, HUD VE ARCADE UI/UX GELİŞTİRME

### 1. ANA GÖREV

Sen deneyimli bir Godot oyun geliştiricisi, pixel-art sanat yönetmeni, UI/UX tasarımcısı, animasyon uzmanı ve QA mühendisisin.

Geliştirilecek mevcut proje:

[https://github.com/kaansavukduran/aion_endless_run](https://github.com/kaansavukduran/aion_endless_run)

**Amaç:** Aion Endless Run'ın girişinden oyunun bitişine kadar bütün kullanıcı arayüzünü, animasyonlarını, bilgi göstergelerini ve oyuncu geri bildirimlerini Metal Slug 3'ün arcade kalitesinden ilham alarak AIONIA evrenine özgü biçimde geliştirmek.

Metal Slug 3'ün şu ilkelerinden yararlan:

- Çok güçlü ve akılda kalan giriş ekranı.

- Kısa, etkileyici açılış animasyonu.

- Oynanışı gösteren Attract Mode.

- Animasyonlu karakter seçimi.

- Tek bakışta anlaşılabilir arayüz.

- Küçük ama işlevsel HUD.

- Etkileyici görev başlangıç ve bitiş efektleri.

- Silah, bomba ve araç durumlarının açıkça gösterilmesi.

- Oyuncuya oyun dünyasının içinden bilgi verilmesi.

- Karakterlerin kişiliklerinin animasyonla yansıtılması.

- Kurtarılan NPC'leri gösteren sonuç ekranları.

- Başarılı/başarısız durumlarda anlamlı geri bildirim.

- Hızlı ve kesintisiz oyun akışı.

**Metal Slug 3'ün grafiklerini, seslerini, müziklerini, logolarını, HUD parçalarını veya ekran kompozisyonlarını kopyalama.**

Bunun yerine aynı işlevsel kalite seviyesinde özgün AIONIA tasarımları oluştur.

Yalnızca fikir veya tasarım dokümanı hazırlama. Mevcut projeyi inceleyerek çalışan kodu, animasyonları, etkileşimleri ve gerçek arayüzleri geliştir. Çalıştırmadığın şeyi test edilmiş gösterme.

Bu komut önceki Mission 1 içerik zenginleştirme isteğini tamamlayan **ayrı bir UI/UX geliştirme kapsamıdır**. Bölüm yapısını, mevcut düşmanları veya rotaları gereksiz yere yeniden oluşturma.

---

### 2. ÖNCE MEVCUT PROJEYİ DENETLE

Godot 4.6.3 altyapısını ve projenin güncel sürümünü koru.

Başlangıç referansı 0.23.0'dır. Ancak çalışmaya başlamadan önce GitHub'daki gerçek son durumu kontrol et.

Önce şunları oku:

- `README.md`

- `project.godot`

- `docs/ARCADE.md`

- `docs/ARCADE-PLAN.md`

- `docs/ART_BIBLE.md`

- `docs/evidence-arcade-m1/README.md`

- `scripts/game.gd`

- `scripts/campaign_game.gd`

- `scripts/campaign_world.gd`

- `scripts/campaign_view.gd`

- `scripts/campaign_text.gd`

- `scripts/brand_loading.gd`

- `scripts/menu_pages.gd`

- `scripts/pixel_interface.gd`

- `scripts/interface_options.gd`

- `scripts/gamepad.gd`

- Mevcut sprite atlasları ve provenance kayıtları.

- İlgili bütün test dosyaları.

Güncel AIONIA tasarım standardını oku:

[https://docs.google.com/document/d/16jj2cwbm8SiVWqDy3N3dzqxTlLoK7JR2_aH6hl4noWY/edit](https://docs.google.com/document/d/16jj2cwbm8SiVWqDy3N3dzqxTlLoK7JR2_aH6hl4noWY/edit)

Karakter referans dizinini oku:

[https://docs.google.com/document/d/1VYC3x06oo2UlvTlC_DbDmWxeLK0OhQXO40MIvXmrz9w/edit](https://docs.google.com/document/d/1VYC3x06oo2UlvTlC_DbDmWxeLK0OhQXO40MIvXmrz9w/edit)

Regresyon standardı:

[https://docs.google.com/document/d/1cpr6yIwVOq2F9rQBlG1sSvFf0Wu9Iir0lJ_KDnqA5lE/edit](https://docs.google.com/document/d/1cpr6yIwVOq2F9rQBlG1sSvFf0Wu9Iir0lJ_KDnqA5lE/edit)

Bu belgelerin en güncel revizyonlarını kullan. Erişilemeyen kaynakları okumuş gibi davranma.

Önce mevcut ekran ve durum envanterini çıkar:

1. Mevcut açılış/yükleme.

2. Ana menü.

3. Karakter seçimi.

4. Sonsuz mod giriş ve HUD.

5. Arcade modu giriş ve HUD.

6. Yardım ekranları.

7. Rota seçimi.

8. Boss konuşmaları.

9. Duraklatma ve ayarlar.

10. Ölüm ve yeniden deneme.

11. Görev sonuçları.

12. Kayıt ve sürdürme.

Mevcut çalışan özellikleri gereksiz yere silme veya ikinci bir kopyasını oluşturma.

---

### 3. MARKA VE SANAT KİMLİĞİ

Marka hiyerarşisi:

- Yayıncı: **Fragaria Interactive**

- Evren: **AIONIA**

- Oyun: **Aion Endless Run**

- İlk Arcade görevi: **Sönen Fenerler**

Görsel sanat yönü:

**Cute + Profound + Epic**

Yani sevimli, derinlikli ve epik bir pixel-art dünyası.

Özgün malzemeler:

- İşlenmiş bakır.

- Fener camı.

- Eski ahşap.

- Yosunlu taş.

- Işık kristalleri.

- Karmaşık ağaç kökleri.

- Kadim mekanik parçalar.

- Ay ışığı.

- Biyolüminesans.

- Fener Ormanı'nın bitki örtüsü.

Metal Slug'ın askerî metal çerçevelerini taklit etme. AIONIA'nın materyal ve renk dilinden arayüz parçaları üret.

Ana menü ile oyun içi HUD, aynı evrenden geliyormuş gibi görünmeli.

Tüm yeni grafikler mevcut pixel-art ölçeğine, renk ilişkilerine ve özgün karakter tasarımlarına uysun.

Arayüz modern, sezgisel ve okunaklı olacak. Gereksiz süslü, şişkin veya jenerik AI arayüzü oluşturma.

---

### 4. YENİ ANİMASYONLU AÇILIŞ

Mevcut Fragaria yükleme sisteminin gerçek ilerleme mekanizmasını koru.

Yükleme tamamlandıktan sonra, kısa ve etkileyici bir AIONIA giriş sunumu oluştur.

**Önerilen süre: 5–8 saniye.** Bu bir tasarım hedefidir; açılışın tamamını atlama seçeneği bulunmalı.

#### Açılışın sahneleri

**00:00–00:01 · Karanlıktaki fener**

Ekran karanlıktır.

Uzakta küçük bir fener yavaşça parlamaya başlar. Çevrede birkaç ışık parçacığı belirir.

**00:01–00:02 · Fener Ormanı ortaya çıkar**

Arka planda ağaçlar, kökler, uzak kuleler ve fener ışıkları farklı katmanlarla görünür.

Parallax sistemi kullan. Parallax, arka plan katmanlarının farklı hızlarda hareket ederek derinlik etkisi vermesidir.

**00:02–00:04 · AIONIA kimliği**

AIONIA logosu belirir. Bakır ve fener ışığı ayrıntıları kısa bir animasyonla canlanır.

Gerçekten onaylanmış logo/marka görseli varsa onu kullan. Onaysız referansı resmî logo kabul etme.

**00:04–00:06 · Kahramanlar**

Altı kahramanın mevcut sprite paftalarından kısa, kendilerine özgü hareketler gösterilir.

Aion çift sıçrama yapabilir, Ömer kanatlarını açabilir, Melun depar pozu alabilir.

Bu hareketlerde karakterlerin mevcut özgün animasyonlarını ve anatomisini koru.

**00:06–00:08 · Menüye dönüş**

Işıklar ana menünün arka planına dönüşür. Logo üstte veya merkezde son konumuna yerleşir.

Oyun menüsü görünür.

#### Açılış kuralları

- Start, Enter, dokunma veya gamepad onayı ile atlanabilir.

- Oyuncu gereksiz yere bekletilmez.

- Ses kapalıysa sessiz çalışır.

- Hareket azaltma aktifse hızlı kamera hareketleri ve yoğun efektler kullanılmaz.

- Sekme odağını kaybettiğinde zamanlamalar bozulmaz.

- Ekran döndürme animasyonu baştan başlatmaz.

- Yükleme yüzdesi, animasyon ilerlemesinden bağımsız kalır.

- Karanlıkta tamamen okunmaz logo veya yanlış kaydırılmış karakter sprite'ı bulunmaz.

---

### 5. ANA MENÜ: YAŞAYAN FENER ORMANI

Ana menüyü yalnızca birkaç düğmenin bulunduğu statik panel olarak bırakma.

Arka planda gerçek, hafif animasyonlu bir AIONIA sahnesi bulunsun.

Sahne öğeleri:

- Uzak ağaçlar.

- Fener kuleleri.

- Yumuşak hava hareketleri.

- Işık parçacıkları.

- Kıyıdaki küçük dalgalar.

- Sallanan yapraklar.

- Çok seyrek görülen küçük canlılar.

- Aydınlanan ve sönen dekoratif fenerler.

Bu arka plan ana menü metinlerinin okunabilirliğini azaltmamalı.

**Temel menü işlemleri:**

1. Arcade.

2. Sonsuz / Endless.

3. Uygunsa devam et.

4. Karakter seçimi.

5. Nasıl oynanır?

6. Ayarlar.

7. İlgili platformda gerçekten mevcutsa çıkış.

İşlemleri dar bir ekranda gereksiz sayıda büyük düğme şeklinde yığma.

En önemli iki oyun modunu belirgin göster. Devam seçeneği yalnızca geçerli kayıt varsa aktif olsun.

Oyuncu iki mod arasında geçiş yaparken uzun, zorunlu bir animasyon izlemek zorunda kalmamalı.

Seçilen menü öğesinde:

- Kısa vurgu animasyonu.

- AIONIA'ya uygun çerçeve değişimi.

- Hafif ses geri bildirimi.

- Klavye ve gamepad odak çerçevesi.

- Dokunmada belirgin basılı durum.

bulunsun.

Düğme devre dışıysa bunun nedeni anlaşılabilsin.

Görev 2–5 henüz oynanabilir değilse onları açılmış veya tamamlanmış olarak gösterme.

---

### 6. ATTRACT MODE: KENDİNİ TANITAN OYUN

Metal Slug 3'ün arcade tanıtım mantığını AIONIA'ya uyarlayarak özgün bir **Attract Mode** oluştur.

Ana menüde yaklaşık 30 saniye kullanıcı girdisi olmadığında, isteğe bağlı oyun tanıtımı başlayabilir.

Bu süre ayarlanabilir bir tasarım tercihidir.

Dört kısa demo önerisi:

**Demo A: Fener kıyısı**

Aion sahilde koşar, düşmana ateş eder ve ilk feneri etkinleştirir.

**Demo B: Su kanalı**

Kullanılabilir bir araçla su kanalından geçilir. Oyuncu akıntı ve mekanik düşmanları görür.

**Demo C: Bahçe terasları**

Baykuş Ömer süzülür. Tavşan karakterlerden biri yüksek platformlara sıçrar.

**Demo D: Kök Motoru**

Boss'un kısa saldırı örüntüsü gösterilir. Hikâye sürprizlerinin tamamı açıklanmaz.

Bu demolar gerçek oyun motorunun sahnelerini, gerçek animasyonlarını ve gerçek mekaniklerini kullanmalı. Sahte oynanış videosu olarak hazırlanmış statik görseller gösterme.

Tanıtım oynanışı gerçek oyuncu kaydını değiştirmemeli.

- Puan kazanılmamalı.

- Kurtarma kaydı yazılmamalı.

- Görev tamamlandı işaretlenmemeli.

- Continue verisi değişmemeli.

- Mevcut sonsuz koşu rekorları etkilenmemeli.

- Kullanıcı herhangi bir giriş yaptığında tanıtım durmalı.

- İstenirse ayardan tamamen kapatılabilmeli.

İlgili sistem çok pahalıya mal oluyorsa aynı motorun kontrollü, kayıt yazmayan demo sahneleri kullanılabilir.

Tanıtım bitince ana menüye temiz dönüş yapılmalı.

---

### 7. ALTI KAHRAMANLI KARAKTER SEÇİMİ

Mevcut seçilebilir kahramanları koru:

1. Aion.

2. Melun Bilge Kurt.

3. Kutsanmış Cahil Kuzu.

4. Baykuş Ömer.

5. Tavşan Emre.

6. Tavşan Eren.

Karakterler tek bir listede küçük metinler olarak değil, kendilerine özgü büyük ve okunabilir portrelerle sunulsun.

Her kartın özellikleri:

- Karakterin gerçek onaylı sprite veya portresi.

- Adı.

- Temel yeteneği.

- Kısa açıklaması.

- Seçildiğinde oynayan animasyonu.

- Seçilme sesi.

- Seçili/odakta/basılı durumları.

- Klavye ve gamepad ile gezinme.

- Dokunmatik seçim.

- Onay düğmesi.

#### Karaktere özgü animasyon

Aion: Solungaç ve kuyruk hareketi, ardından çift sıçrama.

Melun: Dört ayaklı depar hazırlığı.

Kutsanmış: Küçük takipçilerin kendisine yaklaşması.

Ömer: Kanatlarını açma ve kısa süzülme.

Emre: Enerji biriktirip sıçrama hazırlığı.

Eren: Kendi paftasına özgü şarj ve sıçrama hareketi.

Karakterlerin kimliklerini, renklerini, oranlarını veya anatomisini değiştirme.

Animasyon gerçek çizilmiş karelerden oluşsun. Sadece sprite'ı yukarı aşağı hareket ettirip yepyeni animasyon tamamlanmış gibi raporlama.

**UX hedefi:** Oyuncu karakterin ne yapabildiğini görsel olarak anlayabilmeli.

Karakter kartında iki satırlık kısa yetenek açıklaması yeterli olsun; ayrıntılı bilgi isteğe bağlı açılabilsin.

Bütün kahramanları aynı anda küçük ve okunmaz kartlara sıkıştırma. Dar ekranlarda uygun iki satırlı düzen veya sayfalama kullan.

Seçilen kahraman Arcade ve Endless modlarında ilgili mevcut kurallarla kullanılmalı.

---

### 8. HOW TO PLAY: İNTERAKTİF ÖĞRETİCİ

Mevcut yardım sistemini zenginleştir.

Açıklamalar yalnızca uzun metinlerden oluşmasın.

Kısa animasyonlu örnekler bulunsun:

- Yürüme.

- Zıplama.

- Ateş etme.

- Yakın dövüş.

- Bomba.

- Araç kullanma.

- NPC kurtarma.

- Gizli eşya bulma.

- Rota seçimi.

- Karakterin özel yeteneği.

Dokunmatik, klavye ve gamepad için doğru kontrol simgeleri gösterilsin.

Oyuncunun aktif kullandığı giriş yöntemine göre ipuçları değişsin.

Birinci görevde zaten öğrenilmiş eylemler her seferinde zorla tekrar gösterilmesin.

Öğretici atlanabilir olsun. İleride yardım menüsünden tekrar açılabilsin.

Yardım sırasında oyun yanlışlıkla devam edip oyuncuya hasar vermemeli.

---

### 9. MISSION START ANİMASYONU

Arcade modunda birinci görev başladığında özgün bir görev sunumu oluştur.

Başlık:

**GÖREV 1 · SÖNEN FENERLER**

İkinci satır:

**Fener kıyısındaki ışık ağını yeniden etkinleştir.**

Kısa animasyon:

1. Sahne açılır.

2. Karakterin giriş hareketi görülür.

3. Bölüm adı belirir.

4. Kısa görev hedefi görünür.

5. HUD yerleşir.

6. Oynanış başlar.

Önerilen toplam gösterim: 1,5–2,5 saniye.

İstenirse atlanabilmeli.

Bu sırada oyuncunun karakteri kontrol etmeden hasar alması engellenmeli.

Görev yazısı AIONIA'ya özgü font, kontur, renk ve hareket kullanmalı.

Metal Slug'ın MISSION START grafiğini birebir kopyalama.

---

### 10. ARCADE HUD'INI YENİDEN TASARLA

Bu sistem özellikle önemlidir.

HUD, oyun sırasında gereken bilgileri gösteren arayüzdür.

İstenen göstergeler:

| Alan            | Bilgi                                           |
| --------------- | ----------------------------------------------- |
| Kahraman        | Küçük karakter simgesi ve adı                   |
| Can             | Gerçek kalan sağlık/can                         |
| Aktif silah     | Silahın adı ve simgesi                          |
| Mühimmat        | Sınırsız simgesi veya gerçek sayı               |
| Bomba           | Kalan enerji bombası                            |
| Kalkan          | Varsa mevcut koruma                             |
| Araç            | Binilmişse dayanıklılık                         |
| Puan            | Mevcut Arcade skoru                             |
| Kurtarma        | Kurtarılan NPC sayısı                           |
| Bölüm           | Görev 1 ve gerekirse kısa bölge adı             |
| Kontrol noktası | Kaydedildiği anda kısa bildirim                 |
| Boss            | Sadece savaşta boss adı ve uygun can göstergesi |

#### HUD düzenleme kuralları

HUD büyük, sürekli açık bir kontrol paneline dönüşmesin.

Oyun alanını maksimum düzeyde açık bırak.

Üst tarafta küçük, yüksek kontrastlı bilgi grupları kullan. Mobilde kontrollerle üst üste gelmesin.

Gereksiz tekrarları kaldır.

Örneğin can sayısı hem uzun metin hem büyük panel hem de üç ayrı ikonla tekrar edilmesin.

Özel silah yoksa temel tabancanın sınırsız mühimmatını basit bir simgeyle göster.

Özel silah alınınca HUD güncellensin; mühimmat azaldığında okunabilir uyarı versin.

Bomba sıfırsa düğme kullanılabilirlik durumunu doğru göstersin.

Araç dayanıklılığı yalnızca araç gerçekten kullanılırken gösterilsin.

Kalkan bulunmuyorsa boş kalkan çubuğu oluşturma.

Gizli görev hedefleri HUD'a sürekli uzun metin olarak yazılmasın.

**Süre sayacı:** Metal Slug'daki 60'lık zaman sayacını sebepsiz kopyalama. Mevcut Arcade görevi zaman sınırlı değilse zorunlu geri sayım ekleme. İsteğe bağlı geçen süre göstergesi kullanılabilir. Endless modun mevcut 15 saniyelik seviye sistemi aynen korunmalı.

#### Boss HUD

Mevcut boss can çubuğunu koru ve iyileştir.

- Kök Motoru adı.

- Gerçek can oranı.

- Evre değişiminde kısa animasyon.

- Saldırı uyarısı.

- Boss yenildiğinde çubuğun temiz kapanması.

Boss canı ölçülmüyorsa sahte rakam veya sabit animasyon gösterme.

---

### 11. DIEGETIC UI: OYUN DÜNYASININ İÇİNDE BİLGİ VERME

Her şeyi ekranın köşesine yazmak yerine oyuncunun dünyadan bilgi öğrenmesini sağla.

Örnekler:

- Fener sönüyorsa enerji ağı arızalıdır.

- Tamir edilen fener kısa animasyonla yeniden yanar.

- Araç hasar aldığında parçalarında kıvılcımlar oluşur.

- Araç az dayanıklılığa düştüğünde hafif duman çıkabilir.

- NPC kurtarılınca teşekkür animasyonu oynatır.

- Silah değişince karakterin elindeki silah ve mermi efekti değişir.

- Gizli kapı açıldığında çevre hareket eder.

- Kök Motoru hasar aldıkça dış zırhı ve ışığı değişir.

- Son boss evresinde enerji çekirdeği görünür hâle gelir.

Bunların yanında HUD'daki sayılar da doğru kalmalı.

Görsel efektler bilgi taşısın. Rastgele aşırı parçacık, parlama veya kamera sallanması ekleme.

---

### 12. SİLAH, POWER-UP VE ARAÇ GERİ BİLDİRİMİ

Silah toplandığında:

1. Eşya toplanma animasyonu oynasın.

2. Kısa bir ses duyulsun.

3. HUD'daki silah simgesi değişsin.

4. Gerçek mühimmat değeri güncellensin.

5. Yeni mermi efekti kullanılsın.

Güçlendirmeler için:

- Etki süresi gerçek değere bağlı gösterilsin.

- Süre bittiyse görsel kaldırılmalı.

- Oyuncu aynı güçlendirmeyi tekrar alınca kurallar tutarlı olmalı.

- Aynı durum üst üste gereksiz farklı bildirimlerle gösterilmemeli.

Araçlar için:

- Bindim/indim animasyonu.

- Araç can göstergesi.

- Hasar geri bildirimi.

- Onarım geri bildirimi.

- Araç yok olma animasyonu.

- İlgili araç silahı ve mühimmat bilgisi.

Araç kullanımı ekranı gereksiz biçimde değiştirmesin. Oyuncu aynı temel kontrol mantığını kullanmaya devam edebilsin.

---

### 13. NPC KURTARMA ANİMASYONLARI

Mission 1'in kurtarılabilir fener bekçilerini ve diğer dost karakterlerini görsel açıdan zenginleştir.

Her kurtarma olayında:

1. Kurtarma etkileşimi gerçekleşir.

2. Bağ/kafes/engel açılır.

3. NPC özgün kurtulma animasyonu oynatır.

4. Kısa tepki veya teşekkür görülür.

5. Gerçek ödül verilir.

6. HUD'daki kurtarma kaydı artar.

7. Kısa süreli bir bildirim görünür.

NPC rolüne göre farklı animasyonlar kullan:

- Fener Bekçisi.

- Bakım Teknisyeni.

- Işık Kuryesi.

- Bahçıvan.

- Kanal Gözlemcisi.

- Arşiv Muhafızı.

Bunlar önceki Mission 1 içerik planındaki taslak rollerle uyumlu olmalı.

Mevcut kodda gerçekten bulunmayan bir NPC'yi kurtarılmış gibi göstermemelisin.

Aynı NPC kontrol noktasından geri dönülünce yeniden ödül vermemeli.

---

### 14. ROTA SEÇİMİ ARAYÜZÜ

Mevcut iki yol ayrımı korunmalı.

Ancak seçim ekranı daha anlaşılır ve görsel açıdan zengin olmalı.

Örneğin:

**SU KANALI**\
Kısa görsel: Akıntı, su fenerleri, su aracı.

**BAHÇE TERASLARI**\
Kısa görsel: Yüksek ağaçlar, rüzgâr, asma platformlar.

**KÖK GEÇİDİ**\
Kısa görsel: Karanlık kökler, kristaller, mekanik sondaj.

Birinci karar noktasında sadece o anda gerçekten erişilebilir iki seçenek gösterilsin.

İkinci karar noktasında üst yolun iki alt seçeneği gösterilsin.

Oyuncuya daha önce açılmamış veya erişilemeyen rota seçeneği sunma.

Rota ekranında küçük görsel, rota adı ve tek cümlelik açıklama yeterli olsun.

Geri sayım zorunlu olmasın. Oyuncu düşünürken dünya durmalı.

Seçim gamepad, klavye ve dokunma ile yapılabilmeli.

---

### 15. PAUSE, CONTINUE VE ÖLÜM EKRANI

Metal Slug 3'ün büyük geri sayım ve Continue hissinden ilham al, ancak modern ve kullanıcı dostu sürüm oluştur.

**Duraklatma menüsü:**

- Devam et.

- Kontrol noktasından yeniden dene.

- Kontroller.

- Ayarlar.

- Ana menüye dön.

**Ölüm ekranı:**

- Karakterin özgün yenilme animasyonu.

- Kısa başarısızlık mesajı.

- Gerçek son kontrol noktası.

- Yeniden dene.

- Ana menü.

İsteğe bağlı kısa animasyonlu Continue sunumu olabilir, fakat zorunlu geri sayım veya kredi satın alma sistemi ekleme.

Oyuncu ölümden sonra istemeden yeni oyun başlatmamalı.

Mevcut kayıt düzgün yüklenmeli. Bozuk kayıt durumunda anlaşılır hata ve güvenli kurtarma seçeneği bulunmalı.

Ölüm menüsünün butonları küçük telefon ekranlarında görünür kalmalı.

---

### 16. MISSION COMPLETE ANİMASYONU

Kök Motoru yenildiğinde:

1. Boss'un yenilgi animasyonu tamamlansın.

2. Alanın ışıkları geri gelsin.

3. Fenerler tekrar yansın.

4. Karakter kısa bir zafer pozu alsın.

5. Büyük **GÖREV TAMAMLANDI** yazısı belirsin.

6. Kurtarma ve performans ekranı açılsın.

Bu sahne kısa ama tatmin edici olsun.

Boss'un animasyonu bitmeden sonuç ekranı açılmasın.

Oyuncu zafer sırasında hasar almamalı.

Gereksiz uzun, zorunlu bir sinematik bulunmasın; istenirse atlanabilsin.

---

### 17. GÖREV SONU VE NPC KURTARMA SONUÇ EKRANI

Metal Slug'ın Recaptured Prisoner sonuç mantığını AIONIA'ya uyarlayarak özgün bir sonuç ekranı oluştur.

Başlık:

**SÖNEN FENERLER · GÖREV RAPORU**

Gösterilecek bilgiler:

- Seçilen kahraman.

- Tamamlanan rota.

- Gerçek görev süresi.

- Toplanan puan.

- Yenilen düşman sayısı.

- Kurtarılan NPC sayısı.

- Kurtarılan NPC'lerin isimleri veya rolleri.

- Bulunan gizli alanlar.

- Kullanılan silahlar.

- Kullanılan araçlar.

- Can kaybı.

- Boss yenilme durumu.

- Varsa yeni en iyi derece.

Kurtarılan NPC'lerin küçük özgün portreleri bulunabilir.

Karakterlerin kendi animasyonları bu ekranda kısa süreli gösterilebilir.

Görev sonu ekranında özet bilgiler tek bakışta görülsün. Ayrıntılı istatistikler ayrı sayfada açılabilsin.

Uzun içerikleri küçük bir panelin içine sıkıştırıp gereksiz scrollbar çıkarma.

Kayıt sistemi doğru değilse başarıyla kaydedildi mesajı gösterme.

Yeni görevler tamamlanmadıysa oyuncuya açılmış gibi sunma.

---

### 18. HIGH SCORE VE ARCADE İLERLEME

Mevcut Endless rekor sistemi korunacak.

Arcade için ayrı performans kayıtları oluşturulabilir veya mevcut kampanya kayıtları genişletilebilir.

Önerilen bilgiler:

- Kahraman bazında en iyi skor.

- Rota bazında en iyi skor.

- En hızlı tamamlama.

- En fazla kurtarma.

- En az can kaybı.

- Keşfedilen gizli alanlar.

- Tamamlanan görevler.

Aynı başarının tekrar tekrar puan üreterek sömürülmesine izin verme.

Çevrimdışı kayıt düzgün çalışmalı.

Sahte çevrimiçi liderlik tablosu, hesap sistemi veya sosyal özellik ekleme.

---

### 19. ARAYÜZ ANİMASYON ENVANTERİ

Yeni veya genişletilecek animasyonlar için şu aileleri denetle:

**Giriş:**

- Fragaria yükleyiciyle uyumlu geçiş.

- AIONIA logo sunumu.

- Fenerlerin yanması.

- Ana menü arka planı.

**Menü:**

- Odak değişimi.

- Seçim.

- Onay.

- Pasif düğme.

- Menü açılış/kapanışı.

**Karakter:**

- Altı ayrı seçilme animasyonu.

- Yetenek önizlemeleri.

- Portre geçişleri.

**Oynanış:**

- Silah toplama.

- Mühimmat değişimi.

- Bomba.

- Can kaybı.

- Araç hasarı.

- Araç tamiri.

- NPC kurtarma.

- Kontrol noktası.

**Görev:**

- Görev başlangıcı.

- Rota seçimi.

- Mini-boss girişi.

- Boss evre değişimi.

- Boss yenilgisi.

- Görev tamamlandı.

- Sonuç puanlarının hesaplanması.

**Diğer:**

- Duraklatma.

- Continue.

- Ölüm.

- Ayarlar.

- Attract Mode geçişleri.

Her animasyon için gerçek kare sayısı, dosya kaynağı, FPS, süre, döngü, pivot ve hitbox bilgisi kaydedilsin.

Var olan animasyonları tekrar sayarak yeni üretim sayısını şişirme.

---

### 20. SES VE MÜZİK TASARIMI

AIONIA'ya özgü bir arayüz ses sistemi geliştir.

Gerekli kategoriler:

- Giriş kimlik sesi.

- Menü odağı.

- Menü onayı.

- Menüden çıkış.

- Karakter seçimi.

- Görev başlangıcı.

- Silah toplama.

- NPC kurtarma.

- Kontrol noktası.

- Boss uyarısı.

- Boss zaferi.

- Görev tamamlanması.

- Başarısızlık.

- Sonuç ekranı.

- Yeni rekor.

Sesler kısa, birbirinden ayırt edilebilir ve oyunun mevcut ses ayarlarıyla uyumlu olsun.

Tarayıcıda ses kullanıcı etkileşimi gerektiriyorsa autoplay kısıtlamalarına uy.

Ticari oyunlardan ses kopyalama.

Ses araçları yoksa eksik sesleri tamamlanmış göstermeden kalan sistemleri uygula.

---

### 21. RESPONSIVE UI VE ERİŞİLEBİLİRLİK

**Responsive UI**, arayüzün farklı ekran boyutlarına uyum sağlamasıdır.

Aşağıdaki hedeflerde test yap:

- Masaüstü 1152×648.

- Küçük yatay telefon.

- Dikey telefon 393×873.

- Yatay telefon 873×393.

- Tablet.

- %100, %150 ve %200 yazı ölçeği.

- Mevcut 11 dil.

Özellikle daha önce bildirilen sorunları tekrar üretmemek için kontrol et:

- Küçük panelde gereksiz kaydırma.

- Kesilen başlık.

- Ekrandan taşan buton.

- Alt panelin oyun alanını örtmesi.

- Dokunmatik düğmelerin farklı boyutlarda görünmesi.

- Yanlış karakter hizası.

- Sprite pivot kayması.

- Karakterin ayaklarının zeminden kopuk görünmesi.

- Baykuş animasyonunda yatay kayma.

- Aion'un yüz veya solungaç işaretinin kayması.

- Yüzde 200 metinde çakışma.

- Gamepad odak kaybı.

- Telefon döndürülünce HUD'ın bozulması.

- Chrome/Firefox açılış ve önbellek sorunları.

Scrollbar'ı gizlemek, yazıları aşırı küçültmek veya düğmeleri kesmek kabul edilebilir çözüm değildir.

Kısa menüler tek ekrana sığmalı; gerçekten uzun listeler için anlamlı sayfalama veya gerektiğinde kaydırma kullanılmalı.

**Oyun tamamen kontrolcüyle oynanabilir olmalı.** Klavye veya fareye zorunlu dönüş gerektiren menü bulunmamalı.

Fiziksel kontrolcü testi yapılmamışsa test durumunu açıkça belirt.

---

### 22. TEKNİK MİMARİ

Mevcut Godot mimarisini inceleyerek geliştir.

UI kodunu yeni bir devasa script dosyasına doldurma.

İhtiyaç varsa sorumlulukları ayrılmış bileşenler oluştur:

- Başlık sunumu.

- Attract Mode yöneticisi.

- Karakter seçimi.

- Görev giriş sunumu.

- Arcade HUD.

- Oyuncu geri bildirimleri.

- Görev sonuçları.

- Kayıt/ilerleme ekranı.

Ancak mevcut kod bu işlevleri zaten doğru biçimde sağlıyorsa yeni sınıf oluşturarak sistemi gereksiz karmaşıklaştırma.

Godot yerleşim sistemleri, CanvasLayer ve mevcut tema/arayüz yardımcılarını doğru kullan.

Giriş olayları ve animasyon güncellemeleri birbirine gereksiz bağımlı olmamalı.

Animasyon devam ederken oyuncu başka bir ekrana geçerse yarım kalan sinyal veya zamanlayıcı hataları oluşmamalı.

Yeni yapı eski kayıtları ve sahneleri açabilmeli.

---

### 23. TEST VE KALİTE KAPILARI

Önceki oyun testlerini koru.

Yeni kabul testleri:

1. Oyunun gerçek açılışı.

2. Açılış animasyonunun tamamlanması.

3. Açılışın atlanması.

4. Ana menüde Arcade başlatma.

5. Ana menüde Endless başlatma.

6. Altı karakterin seçilmesi.

7. Karakter değiştirme.

8. Karakter yetenek önizlemeleri.

9. Attract Mode başlama ve durma.

10. Demo oynatımının kayıt değiştirmemesi.

11. Yardım ekranlarının kontrolcüyle kullanılması.

12. Mission Start animasyonu.

13. HUD'ın gerçek hasar/can değişimine tepki vermesi.

14. Mühimmat azalması ve silah değişimi.

15. Bomba sayacının güncellenmesi.

16. Araç dayanıklılığının güncellenmesi.

17. NPC kurtarma bildirimi.

18. Rota seçiminin doğru çalışması.

19. Boss HUD ve evre değişimi.

20. Ölüm ve yeniden deneme.

21. Kontrol noktasından sürdürme.

22. Mission Complete.

23. Sonuç istatistiklerinin gerçek veriye dayanması.

24. Mevcut Endless rekorlarının bozulmaması.

25. Bütün dillerde arayüz taşma kontrolü.

26. Mobil yatay/dikey.

27. Gamepad menü gezinmesi.

28. Hareket azaltma ve ses kapatma.

29. Gerçek web yüklemesi.

30. Yeni grafiklerin kaynak ve lisans envanteri.

Bunlara ek olarak AIONIA regresyon standardındaki uygulanabilir maddeleri tekrar denetle.

Test durumlarını:

- PASS

- FAIL

- NOT TESTED

- BLOCKED

olarak raporla.

Ekran görüntüsü, otomatik test, gerçek tarayıcı ve fiziksel cihaz testlerini birbirinin yerine geçirme.

---

### 24. UYGULAMA SIRASI

Bu işi uygulama içinde mantıklı aşamalara böl:

**Aşama 1:** Mevcut arayüz ve veri sistemlerini denetle.

**Aşama 2:** AIONIA giriş sunumu ve ana menüyü geliştir.

**Aşama 3:** Altı karakterli seçim ekranını geliştir.

**Aşama 4:** Attract Mode ve How to Play sistemini ekle.

**Aşama 5:** Mission Start, rota seçimi ve oyun içi kısa bildirimleri geliştir.

**Aşama 6:** Arcade HUD'ını görsel ve işlevsel olarak iyileştir.

**Aşama 7:** Silah, NPC, araç ve boss geri bildirimlerini zenginleştir.

**Aşama 8:** Pause, Continue ve ölüm ekranlarını geliştir.

**Aşama 9:** Mission Complete ve kurtarma sonuçlarını geliştir.

**Aşama 10:** Grafik, animasyon ve sesleri denetle.

**Aşama 11:** Üç Arcade rotasını ve mevcut Endless modunu uçtan uca test et.

**Aşama 12:** Teslim raporunu ve varlık envanterini oluştur.

Bunlar yalnızca yapılacaklar listesi değil, gerçekten uygulanacak geliştirme aşamalarıdır.

Yapılabilen işleri uygula. Yapılamayanları nedenleriyle açık bırak.

---

### 25. TESLİM RAPORU

İş bittiğinde aşağıdaki sonuçları bildir:

**UI/UX envanteri**

| Ekran            | Önceki durum | Yeni durum | Test |
| ---------------- | ------------ | ---------- | ---- |
| Açılış           |              |            |      |
| Ana menü         |              |            |      |
| Karakter seçimi  |              |            |      |
| Attract Mode     |              |            |      |
| How to Play      |              |            |      |
| Mission Start    |              |            |      |
| Arcade HUD       |              |            |      |
| NPC kurtarma     |              |            |      |
| Araç HUD         |              |            |      |
| Boss HUD         |              |            |      |
| Pause            |              |            |      |
| Continue         |              |            |      |
| Mission Complete |              |            |      |
| Sonuç ekranı     |              |            |      |

Ayrıca raporla:

- Yeni üretilen gerçek sprite dosyası sayısı.

- Yeni animasyon sayısı.

- Gerçek farklı animasyon karelerinin sayısı.

- Yeni ses sayısı.

- Yeni UI bileşenleri.

- Korunan eski bileşenler.

- Değiştirilen kod dosyaları.

- Gerçek test sonuçları.

- Kalan hatalar.

- Bilinen görsel eksikler.

- Hangi cihazların test edilmediği.

- Yayın durumu.

Kaynak referansları, özgün görseller ve mevcut kayıtlar korunmalı.

Dışa yayın veya mevcut production sürümünü değiştirme işlemini ayrıca yetkilendirilmeden yapma.

### SON TALİMAT

**Aion Endless Run'ı Metal Slug 3'ün arayüz tasarım kalitesinden ve arcade akıcılığından ilham alan, fakat tamamen özgün AIONIA sanat kimliğine sahip bir oyuna dönüştür.**

Amacın yalnızca daha güzel butonlar yapmak değil; oyuncunun giriş ekranından karakter seçimine, ilk göreve, silah kullanımına, boss savaşına ve görev sonucuna kadar tutarlı, animasyonlu, okunabilir ve keyifli bir deneyim yaşamasını sağlamak.

Mevcut çalışan sistemi koru, eksikleri tamamla, gereken görselleri ve animasyonları üret, oyun içinde çalıştır, test et ve sonuçları ayrıntılı olarak raporla.

Yalnızca plan çıkarıp bırakma. Erişilebilir kapsamda gerçek uygulamayı gerçekleştir.

---

### 26. SEKİZ YÖNLÜ ATEŞ VE NİŞAN KONTROLLERİ

Oyunun Arcade modunda, normal hareket ve zıplama korunarak **sekiz gerçek atış yönü** uygulanacak: sağ →, sağ-yukarı ↗, yukarı ↑, sol-yukarı ↖, sol ←, sol-aşağı ↙, aşağı ↓ ve sağ-aşağı ↘. Mermiler yalnız animasyonda değil, gerçek fizik/isabet sisteminde doğru yönde ilerleyecek. Diagonaller normalize edilecek; yatay mermilere göre daha hızlı gitmeyecek. Bütün on özel silahın nişan merkezi, yayılan mermi, laser/beam, araç namlusu, çarpışma ve görsel efektleri gerçek vektörlerle tutarlı olmalı.

**Klavye:** A/D ve sol/sağ ok yatay hareket. W veya yukarı ok yukarı; S veya aşağı ok aşağı nişan. W+D/W+A sağ-yukarı/sol-yukarı; S+D/S+A sağ-aşağı/sol-aşağı. F/J/sol tık ateş, Space zıpla, G bomba, E bin/in aynen kalır. Arcade'deki S nişanı eski Endless takla eylemini değiştirmeyecek. Yukarı ateş ederken yatay yürüyüş mümkün olmalı.

**Gamepad:** Sol analog (X yatay hareket, Y dikey nişan) ve D-pad sekiz yönü vermeli. Sağ analog varsa öncelikli bağımsız nişan seçeneği: sola yürürken sağ-yukarı ateş edilebilmeli. Deadzone, bağlantı kesilmesi ve yeniden eşlemeler dikkate alınmalı. **Telefon:** soldaki joystick X/Y ile yön, sağdaki mevcut Ateş/Vur düğmesi ile atış; multitouch çalışmalı. Ayrı ikinci joystick zorunlu değil; isteğe bağlıysa mevcut Zıpla/Ateş/Bomba alanını örtmemeli.

Yakın düşmanla mevcut yakın saldırı ve bağlı NPC'ye bıçakla kurtarma etkileşimleri korunur; yukarıya nişan alırken uzaktaki hedefi vurmak yanlışlıkla yakın etkileşimi açmamalı. Havadayken aşağı ve çapraz aşağı atış gerçek olsun; aşağı mermi zeminin içinde doğmasın. Karakterin kol/silah pozu, namlu efekti ve mermi yönü tutarlı gösterilsin. Eksik özgün yön animasyonunu olmuş gibi sayma.

**Kabul:** Altı kahraman, sekiz yön, klavye/analog/D-pad/dokunma; havada-yerde, zıplama-ateş eşzamanlı, tüm özel silahlar, araçlar, boss/üst platform/objeler, pause/input reset, fizik hızları ve eski Endless modu regresyonları. Sonuçlar PASS/FAIL/NOT TESTED/BLOCKED olacak.

### 27. DOST KIZ NPC'LERİN BOYU: AION 1, NPC 2

Mevcut **kurtarılabilir anime kız NPC** sprite'ları, Aion'un ayakta normal ve efektsiz oyun içi görünür anatomik yüksekliği **1 birim** kabul edildiğinde **2 birim** boyunda olacak. Bu yalnız ilgili kız NPC paftalarına uygulanır. Ana kahramanlar, erkek/diğer NPC'ler, hayvanlar, araçlar ve düşmanlar büyütülmez.

Sadece körlemesine 2× büyütme yapma; Aion'un oyun içi gerçek alfa-gövde yüksekliğini ve kız NPC'nin mevcut alfa-gövde yüksekliğini ölç. Çizim katsayısı = (2 × Aion yüksekliği) / (NPC'nin kaynak görsel ölçeğiyle elde edilen oyun yüksekliği). Silah, aura, partikül ve gölgeleri anatomik boy hesabına katma. Ayak zemine/üst platforma oturacak, saç/kulak kırpılmayacak, bütün animasyonlarda oran ve pivot tutarlı kalacak. Kes, Teşekkür ve ödül etiketleri yeni kafa yüksekliğine taşınacak; kafes ve etkileşim mesafesi gözle görülür biçimde doğru olacak. İki kız NPC ile Aion yan yana 2,0 oran kanıtı, üç rota/gizli oda/telefon yatay-dikey testleri istenecek.

### 28. VERCEL YAYININA AÇIK ONAY VE GÜVENLİ TESLİMAT

Kullanıcı bu konuşmada yeni Aion Endless Run sürümünü **Vercel production'da yayımlamaya açıkça onay verdi**. Önceki metindeki "ayrıca dışa yayın yetkisi alın" talimatı yalnız **kaansavukduran/aion_endless_run → Vercel aion_endless_run** projesinin bu kapsamı için güncellendi. Hedef alan **aionendlessrun.vercel.app**. Başka projeye veya gizli anahtarlara erişim yetkisi yok.

Sıra: güncel kod ve standardı oku; sürüm, Git SHA ve Vercel projeyi doğrula; değişiklikleri uygula; Godot/headless ve gerçek tarayıcı testleri yap; Vercel preview/staged build oluştur; açılış/menü/6 karakter/3 rota/sekiz yönlü atış/2× kız NPC/Endless kayıt regresyonu PASS ise doğrulanmış build'i production'a yayınla; URL, deployment ID, SHA, test raporu ver. Kritik başarısızlık, kota ya da izin engelinde eski production'ı koru, READY sonucunu oynanış doğrulaması sanma. Önceki indirmeler ve kullanıcı kayıtları değişmemeli.

### 29. TAM KAPSAM RAPORU

Orijinal 1–25. bölümlerin tamamı geçerlidir: giriş animasyonu, yaşayan menü, attract mode, 6 karakter seçimi, How to Play, Mission Start, HUD, rota, NPC, araç/silah/boss göstergeleri, Pause/Continue/ölüm, sonuç ekranı, kayıt ve erişilebilirlik. 26–28. bölümler bunlara ek ve bağlayıcıdır; önceki maddelerin yerine geçmez. Bütün ekranların durumunu Mevcut/Yeni/Test Edildi/Eksik/Blocked olarak kaydet; yeni iki talebin testlerini ayrı sun. Yalnız uygulanan ve doğrulanan şeyleri tamamlandı olarak raporla.
