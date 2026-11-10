# Aion Endless Run

Sevimli bir piksel macerası. **Space ile zıpla, Esc ile mola ver.** Kargalara vur, engellerin altından takla at, dev mantar ve tılsımları topla, kendi rekorunu geç. Bağımsız Godot oyunu; Firefox veya eklenti gerektirmez. Oyun internete bağlanmaz.

![Türkçe başlangıç ekranı ve görünür karakter seçimi](docs/evidence-v09/start-tr-TR.png)

**[Tarayıcıda oyna](https://aionendlessrun.vercel.app/) · [İndirilebilir sürümler](https://github.com/kaansavukduran/aion_endless_run/releases)** · [Sürüm ve platform durumu](docs/RELEASE.md) · [Doğrulama](docs/VALIDATION.md)

## Oyna

1. Releases sayfasından cihazına uygun dosyayı indir.
2. Windows: `Setup.exe` dosyasını açıp kur veya `portable.zip` dosyasını çıkartıp `AionEndlessRun.exe` dosyasına çift tıkla. Portable arşivi tümüyle çıkart; ZIP içinden çalıştırma.
3. Linux: `.AppImage` dosyasına çalıştırma izni verip aç. Debian/Ubuntu için `.deb` paketini kurabilir veya taşınabilir `.tar.gz` arşivini çıkartıp içindeki `AionEndlessRun.x86_64` dosyasını çalıştırabilirsin.
4. macOS: Intel ve Apple Silicon için universal `.app` taşınabilir ZIP veya `.dmg` vardır. İlk sürüm Developer ID ile imzalı/noter onaylı değildir; Gatekeeper açılışı engelleyebilir. Sistem korumalarını kapatmayı önermiyoruz.
5. Android: `.apk` dosyasını açarak kur. Yalnızca indirdiğin kaynağa güvendiğinde sistemin o kaynak için sunduğu yükleme iznini kullan. Paket arm64 ve x86_64 içindir; 32 bit Android desteklenmez.
6. iPhone: Bu sürümde App Store/TestFlight paketi yok. Apple Developer hesabı, dağıtım imzası ve mağaza/test onayı gerekir. Kaynak proje iOS hedefini içerir; web önizlemesi Safari'de alternatif bir oyun sürümüdür, yerel iOS kurulumu değildir.

Ana menüde **Koşuya başla** veya **Space**. Koşarken **Space**, Zıpla düğmesi veya boş alana dokunma ile zıpla. **Sol tık/J/Vur** ile tek saldırı yap; basılı tutmak tekrar saldırmaz; **aşağı ok/S/Ctrl/Takla** ile en az 0,68 saniyelik takla at; basılı tutarak sürdür. Düşerken düşmanın üstüne basarak sekebilirsin. **Esc** veya sağ üst **Duraklat** düğmesiyle mola ver. Yeniden Esc ile kaldığın yerden devam et. Oyun kumandasında A zıplama, X saldırı, B eğilme, LB kurt deparı, Start duraklatmadır. F11 tam ekranı değiştirir.

0.5.0’da **102 yeni karelik üç özgün piksel pafta** saldırı, eğilme, karga, kırmızı şapkalı cüce, eşyalar ve alçak dalı canlandırır. Aion yumruk atar, baykuş kanadını savurur, koyun kafa atar, kurt ısırır. Mantar 10 saniye büyütür ve cüce dalgası başlatır; şimşek, zaman kumu, kanatlı çizme, kalkan, mıknatıs ve can yaprağı geçici güçler verir. Keşfedilen yedi güç cihazda kaydedilir. Karışan karşılaşma torbası, değişen mesafe aralıkları, yumuşak hız değişimleri, yağmur/kar/kum/fırtına, küçük gök şimşeği, düşmana basma komboları ve kısa puan hedefleri koşuları çeşitlendirir. Hafif renk ve kamera efektleri Ayarlar’dan kapatılabilir. Telefon arayüzü her zaman yataydır; ekran kilidi desteklenmediğinde oyun alanı döndürülür. İki parmakla aynı anda zıplama ve saldırı çalışır. [Tasarım ve araştırma notları](docs/GAME-DESIGN.md).

Koyunların aralığı 112/224 piksele çıkarıldı; ilk hızda yaklaşık 0,35/0,70 saniye sonra, öndekinin zıpladığı noktada sırayla havalanırlar. Önceki 0.4 özelliklerinde koyunlar öndekinin izlediği zıplama yolunu mesafeye bağlı gecikmeyle sırayla takip eder. Kurt deparında kıvrılan rüzgâr izleri akar. Baykuş, görünür yükselen hava akımında basılı tutarak biraz yükselebilir. Bu hareketler için yeni 18 karelik ek pafta vardır.

Önceki 48 karelik paftalar kaynak geçmişinde korunur; aktif animasyonlar 0.9’un daha kapsamlı paftalarını kullanır. Web ve indirilebilir sürümün numarası sol üstte görünür. Eski web önbelleğinden geçiş otomatik yapılır; sonraki güncellemeler oyun içindeki düğmeyle açılır.

Her atlanan engel **+10**, her toplanan kristal **+25** puan. Mesafe de skor kazandırır. Hız zamanla artar ve sınırlandırılır. Kehribar Çölü ile Ayaz Vadisi mesafeye göre yer değiştirir; gündüz ve gece bir döngü oluşturur.

Aion varsayılan karakter. Başlangıç kartlarından Baykuş Ömer, Melun Bilge Kurt veya Kutsanmış Cahil Koyun seçilebilir. Hepsi ilk açılışta kullanılabilir. Aion iki kez zıplar; Baykuş Ömer tek zıplamadan sonra Space/dokunmayı basılı tutarak süzülür; koyun yerdeki arkadaşları toplayıp en fazla üç koyunluk sürü oluşturur ve her koyun bir can sağlar; kurt Shift veya karakterin üstüne basılı tutarak hızlanır. Kurtta basılı tutan parmak hızlanmayı sürdürürken ikinci parmakla başka bir yere dokunup zıplayabilirsin. Bir temasta bir koyun eksilir; son koyunda çarpışma koşuyu bitirir. Karakterini başlangıç ekranındaki dört görünür karttan seç. Koşu sırasında veya duraklatma menüsünden karakter değiştirilemez; yeni seçim için Ana menü’ye dön.

**TR / EN / CS** açılır dil menüsü başlangıç, duraklatma ve ayar ekranlarında bulunur. İlk açılış tarayıcı/cihazın ana dilini kullanır: Türkçe `tr`, İngilizce `en`, Çekçe `cs`; diğer diller İngilizce açılır. Otomatik seçim, oyuncu açıkça bir dil seçene kadar cihazı izler. Oyuncunun seçimi sonraki açılışlar için kaydedilir; eski geçerli dil tercihleri de korunur. **Ayarlar** menüsünde de üç dil, bağımsız ses, ekran efektleri ve dekoratif hareket seçenekleri ile ses düzeyi bulunur. Hareket kapalıyken karakter sabit poz kullanır, parçacıklar ve arka plan kaydırması kapanır; zıplama ve engellerin hareketi oynanış için sürer. Düğmeler Tab/Shift+Tab ve Enter ile kullanılabilir. Fare, dokunma ve klavye desteklenir.

Rekor, keşfedilen güçler ve tercihler yereldir. Geçici güçler yalnızca o koşuda sürer. Normal kayıt konumu Godot'un `app_userdata/Aion Endless Run/save.cfg` klasörüdür: Windows `%APPDATA%\Godot\app_userdata\Aion Endless Run`, Linux `~/.local/share/godot/app_userdata/Aion Endless Run`, macOS `~/Library/Application Support/Godot/app_userdata/Aion Endless Run`. Portable burada kurulum gerektirmeyen sürüm anlamındadır; kayıtlar işletim sisteminin kullanıcı veri klasöründe tutulur. Canlı koşu uygulama kapatılınca geri yüklenmez; rekor, seçili karakter ve ayarlar korunur.

## 0.10.0 · Sürüyle boss savaşı ve çalışan gamepad menüleri

**Sürü kaybolmaz:** Boss sırasında küçük koyunlar liderin arkasında görünür kalır. Takip gecikmesi boss kovalamacasının gerçek ilerleme mesafesinden hesaplanır; zıplama ve takla sırayla takip edilir. Koşuya dönüşte izler yeni mesafeye taşınır, koyunlar ışınlanmaz. Boss’un üç savaş canı normal sürü sayısını tüketmez.

**Üç boss:** Kül Muhafızı’nın yüksek/alçak/seri atışlarına Fırtına Vatozu’nun kanatlı dalışı, ikili akımı ve elektrik şeridi; Kök Motoru’nun tohum salvosu, sarmaşık süpürüşü ve sıçrayışı eklendi. Tasarımlar 10/20/30 seviyelerde sırayla gelir, sonra döngü sürer. Her tasarım üç saldırı dizisi ve canı yarıya düşünce daha kısa bekleme kullanır. Önce hangi hattan kaçılacağı görünür; aynı salvoda çelişen yüksek/alçak zorunluluk üretilmez. Ana menüde **Boss antrenmanı** ile seçili kahramanınla üç tasarımı hemen deneyebilirsin. Antrenman normal rekoru ve seviye ilerlemesini değiştirmez; koyuna iki küçük arkadaş verilir.

**Düzeltilen silah:** Koşarak nişan alma ve tek atışın hazırlık/parlama/geri tepme/toparlanması ayrı 12 karelik dizilerdir. Koyun tabancayı iki ön toynağıyla tutar; kurt kürklüdür, yalnızca Aion önlük giyer. Mermi, namlunun ölçülmüş ön konumundan parlama anında çıkar. Silah pozu, ölüm animasyonunun üstünü örtmez.

**Gamepad:** Xbox ve standart PlayStation eşlemelerinde menü yön tuşları/sol çubukla gezilir; **A/Cross veya X/Square seçer**, B/Circle geri döner. Sonuç ekranındaki Yeniden Oyna / Ana Menü / Ayarlar ve duraklatma menüsü çalışır. Oynanışta A/Cross zıpla, X/Square vur, B/Circle takla, LB/L1 depar, RB/R1 veya RT/R2 ateş, Start/Options duraklat. Kol ayrılırsa basılı durumlar temizlenir ve koşu duraklar. Fiziksel cihaz listesi tarayıcı/işletim sisteminin standart eşleme desteğine bağlıdır.

**Gerçek arka katman:** Kutlama karakteri koşu yolunda durmaz. Yolun arkasındaki yükseltilmiş zemine basar; yakın ağaç/nesneler onun önünde çizilir, dünya noktasından paralaksla geride kalır. Saydamlaştırma derinlik yerine kullanılmaz. On seviyelik sarılma için ön kata gelme korunur.

**Ölüm nedenleri:** Ateş, buz ve çukura düşmenin yanında dört kahraman için ayrı 12 karelik engelde sarsılıp düşme ve düşmana çarpıp yüzüstü kapanma dizileri var. Havada darbe alan karakter yere iner. **Üç yeni orijinal pafta, 300 çizilmiş kare**: 96 silah, 108 boss, 96 darbe/yüzüstü düşme. Eski kaynak paftalar korunur.

## 0.9.0 · Daha akıcı hareket ve anlamlı parkur

**Seviye temposu:** Her yeni seviye için önceki seviye sonrasından en az **30 saniye aktif normal koşu** ve **12.000 yeni mesafe** gerekir. İkisinin de dolması gerekir; düşük hızda daha uzun sürer. Duraklama, sarılma ve boss süresi bu süreye eklenmez. Biriken puan/mesafe arka arkaya seviye atlatmaz. Gösterge iki koşulu da gösterir.

**Arka plan kutlaması:** Kutlama beş saniyelik bir arka plan karşılaşmasıdır; karakter dünyanın bir noktasında durur, ilerledikçe sağdan sola kayarak geçilir. Sekiz farklı yetişkin anime karakteri sola, kahramanın gelişine bakar. Her on seviyedeki sarılma, sağdan yaklaşma ve silah verme geçişi korunur.

**Yeni hareket paftaları:** On orijinal PNG’de **997 gerçek çizilmiş kare** var. Kahraman koşu/zıplama/iki saldırı/yetenek/silah/takla döngüleri 12 kare, dünya düşmanları ve robot dizileri 11 kare kullanır. Kutlamalar altı kutlama ve altı sarılma karesi içerir. Donma/ateş/kül, eşyalar ve yeni parkur da yenilendi. Kare sayısı kayıttan okunur; gelecekteki animasyon paftalarında en az 10 gerçek çizilmiş sütun gerekir. Kopya kare veya yapay ara görüntü eklenmez. Kaynaklar değiştirilmeden ve özetleriyle korunur; ayrı saydam paylı dokular komşu kare taşmasını önler. Her kahramanın paftası tek bir ölçek kullanır.

**Tutarlı karakter ve engeller:** Kurt silah tutarken de mor/kremsi kürklüdür, Aion’un önlüğünü giymez. Baykuş yerde sırayla kanat, havada ileri gaga saldırısı yapar. Eski ters U kemerler kaldırıldı; yerde dört biyoma uygun, geçildiğinde 3,5 saniye %18 hız veren şeritler var. Havada boru veya tahtayı iplerle iki karga taşır; altından takla atılabilir, havadan vurularak kırılabilir. Çukurlar, yer engelleri, kargalar, cüceler, seyrek ateş bitkileri ve boss korunur.

## 0.8.0 · Dört biyom ve Kül Muhafızı

**Pafta taşması düzeltmesi:** Karakter kareleri artık ortak atlas UV’lerini örneklemez. Kaynak PNG’ye dokunmadan, yalnızca kayıtlı ana silueti iki piksellik saydam payla ayrı bir bellek dokusuna alırız. Böylece sağa vururken sol tarafta komşu kareden parça çıkamaz. Normal koşu, depar, zıplama, saldırı ve silahlı pozlar, her karede gövdenin toplam yüksekliği yerine ortak baş/kulak referansıyla ölçeklenir. Yatay depar pozu başı büyütmez; bacak bükülmesi ve kanat açılması doğal poz değişimidir. Mantarın kasıtlı devliği ve %72 koyun takipçileri korunur.

**Yeni 84 çizilmiş kare:** Dört kahramanın enerji tabancasıyla koşu/atış pozları, özgün seramik/bronz robot, ateş püskürten bitki, mermiler, silah verme efekti, kök/boru kemerleri, sandık/kütük/yol bariyeri/kaya/menfez/fıçı ve çukur kıyıları. Gerçek kare sınırları, alfa silueti, anatomik oranlar ve PNG özetleri `assets/FRONTIER-PROVENANCE.json` içinde kayıtlıdır.

**Dört biyom:** Kehribar Çölü → Ayaz Vadisi → Sisli Bataklık → Bakır Şehir. Bataklıkta sarkan söğütler, sazlar ve ateşböcekleri; şehirde ışıklı pencereler, çatı hatları ve sokak lambaları vardır. Geçişler yumuşaktır, katmanlar farklı hızlarda kayar. Yeni yer engellerini ve gerçek zemin boşluklarını zıplayarak, alçak kök/boru geçitlerini taklayla aş. Çukura düşmek gerçek düşme animasyonu verir; koruma veya koyun canı kurtarırsa kahraman yukarı sıçrar.

**Seyrek ateş bitkileri:** İlk bitki fırsatı 26–42 saniyelik normal koşudan sonra, sonrakiler 35–70 saniyelik düzensiz aralıklarda gelir; dolu parkurda güvenli boşluğu bekler. Ağzı parlayarak 0,9 saniye uyarır, ardından gerçek ateş topu atar. Yumrukla veya üstüne basarak yenilebilir. Boss sırasında bitki bulunmaz.

**Her 10 seviyede özgün boss kovalamacası:** Önce sarılma, ardından anime karakterinin verdiği enerji tabancası ve **Kül Muhafızı**. Boss sahnesinde normal engeller, çukurlar, cüceler, bitkiler ve eşyalar temizlenir. Arka plan kovalamayı sürdürür, normal seviye mesafesi bekler. Sağ tık / **F** / mobil **Ateş et** basılıyken ileri enerji atışı yap; düşük kürelere zıpla, yüksek atışların altından takla at. Boss’un can barı gerçek mermi isabetleriyle azalır. Üç savaş canın vardır. Zafer +500 + seviye×10 puan verir; normal koşuya korumalı boşlukla dönersin. Önceki güçler savaş boyunca saklanır ve sonra kalan süreleriyle geri gelir. Kutlamaları kapatmak boss’u kapatmaz. Kumandada RB ateştir.

## 0.7.0 · Takla, değişen saldırılar ve seviye kutlamaları

**164 yeni çizilmiş karelik dört özgün pafta:** sekiz saldırı dizisi, dört takla döngüsü, sekiz farklı yetişkin anime kutlama karakteri ve dört hareketli üst engel. Aion iki eliyle sırayla yumruk, baykuş sağ/sol kanat, kurt ısırık/kafa, koyun kafa/çifte kullanır. Her basış tek vuruştur; bir sonraki basış diğer harekete geçer. Sağdaki hedefe vururken komşu kareden arkaya taşan piksel parçası sıkı kare sınırlarıyla giderilir.

0.7 sürümündeki 900 mesafe kuralı 0.9’da 30 saniye + 12.000 yeni mesafe olarak değiştirildi. Farklı saç/kıyafetli sekiz karakter tekrar etmeyen bir torbadan seçilir; konfeti, yıldız, kalp veya baloncuklarla kutlar. Her **10 seviyede**, kahraman yere inince **1 saniyelik sarılma** olur: dünya, düşmanlar ve güç süreleri durur; sonra kalpler ve kısa dokunulmazlıkla devam edilir. Ayarlardan kutlamalar kapatılabilir. En yüksek seviye yerel olarak kaydedilir.

Mantar başlangıçta zorunlu değildir: ilk 20 saniyede çıkmaz, iki mantar arasında en az 45 saniye vardır; uygun eşya fırsatında varsayılan olasılığı **%2**. Ayarlarda %0–100 değiştirilebilir; bu değer saniye başına olasılık değildir. Devlikte düzensiz aralıklı küçük cüce grupları gelir; 4. seviyeden itibaren mantarsız da seyrek cüceler görülebilir. Devlik bittiğinde dalga cüceleri temizlenir ve kısa koruma verilir. Renk dalgaları ve hafif kamera için ayrı şiddet ayarı vardır; hızlı tam ekran flaş kullanılmaz.

Çöl ağacı, buz kemeri, yüzen rün ve mantar kemeri takla engellerini çeşitlendirir. Baykuşun rastgele hava akımı yukarı, ileri veya çapraz olabilir; ileri akım gerçek ilerleme hızını artırır. Daha küçük koyun takipçiler mesafeye göre gecikmeli zıplar ve takla atar. Üç dil, çevrimdışı kayıt/güncelleme ve önceki yetenekler korunur.

## 0.6.0 · Üç dil ve tutarlı karakterler

| Karakter | Türkçe | English | Čeština |
| --- | --- | --- | --- |
| Aion | Aion | Aion | Aion |
| Baykuş | Baykuş Ömer | Omar the Owl | Sova Omar |
| Kurt | Melun Bilge Kurt | Accursed Wise Wolf | Prokletý moudrý vlk |
| Koyun | Kutsanmış Cahil Koyun | Blessed Ignorant Sheep | Požehnaná nevědomá ovečka |

Dört kart oyuna başlamadan görünür. Koşu, zıplama, iniş, süzülme, yükselen hava ve depar kareleri orijinal PNG'ler değiştirilmeden opak karakter sınırlarına göre hizalanır; 0.6 sürümünde normal pozların opak yüksekliği 90 mantıksal piksele eşitleniyordu; 0.8 bunu pozdan bağımsız anatomik referansla değiştirir. Lider koyun normal, takipçiler %72 boyuttadır. Takla çizilmiş dönme kareleri kullanır; karakter dikey olarak ezilmez. **Yalnızca dev mantar gücü büyütür**; zıplama veya rüzgâr büyütmez. Savaş, yedi güç, rastgele karşılaşmalar, hava, iki biyom ve çevrimdışı güncelleme korunur.

## Kaynaktan çalıştır

Godot **4.6.3 standard** sürümünü kur. Bu depoyu indir ve Godot'ta `project.godot` dosyasını içe aktar. **F6 yerine F5** ile ana oyunu başlat. Komut satırı:

```sh
godot --path . --editor --import --quit
godot --path .
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_adventure.gd
godot --headless --path . --script tests/test_localization.gd
godot --headless --path . --script tests/test_evolution.gd
godot --headless --path . --script tests/test_frontier.gd
godot --headless --path . --script tests/test_motion.gd
```

Testler kullanıcı kayıtlarına yazdığı için kendi skorunu korumak istiyorsan testleri ayrı bir OS kullanıcısı veya geçici XDG veri klasörüyle çalıştır. Linux örneği:

```sh
XDG_DATA_HOME="$(mktemp -d)" godot --headless --path . --script tests/test_game.gd
```

Resmi export templates kuruluyken `export_presets.cfg` içindeki Linux, Windows, macOS, Android, Web ve iOS hedefleri kullanılabilir. Çıktı klasörlerini önce oluştur. `.github/workflows/build.yml` her ana dal gönderiminde test ve paket üretir; sürüm etiketi gönderildiğinde doğrulanmış işler tamamlandıktan sonra beta Release yayımlar. Android imza anahtarı kaynak kodda değildir; depoya ait iki Actions secret ve `AION_ANDROID_SIGNING_READY=true` repository variable gerektirir. Ayrıntılar [paketleme notunda](docs/BUILD.md).

## Görsel kaynaklar

FireAxolotl ve FireAxolotl Extension'daki orijinal Aion koşu paftası ve karakter paftaları PNG içerikleri değiştirilmeden korunur. 0.3.0'da baykuş, kurt ve koyunun her biri için Aion tarzında 6×8 (48 kare) ayrı piksel pafta eklendi: bekleme, koşu, zıplama, donma, ateş/duman, kül, yetenek ve iniş. Donma ve kül de artık her karakterin kendi çizilmiş kareleridir. Koşu adımları mesafeye bağlıdır; baykuşun süzülmesi ve kurdun deparı ayrı döngüler kullanır. Kare bölgeleri, hizalama noktaları ve özgün PNG SHA-256 değerleri `assets/FULL-RUNNER-PROVENANCE.json` dosyasındadır. Önceki paftalar kaynak geçmişi için korunur.

[Kaynak ve lisans kayıtları](THIRD_PARTY_NOTICES.md). Chrome dinozorunun görseli veya kodu alınmadı. Hesap, reklam, telemetri, çevrimiçi puan tablosu veya ücretli kilit yok.

## English

A standalone offline Godot runner. **Space / tap to jump, Esc to pause.** Four available characters, fire and ice collisions, local best score, collectible crystals, two scrolling biomes and a day/night cycle. Choose **TR / EN / CS** in the header or change language in Settings. First launch follows the primary browser/device locale; unsupported locales use English. Explicit choices persist. Version 0.8.0 isolates every hero frame into a padded texture, calibrates head size independently of leaning poses, adds marsh/city biomes, real gaps, varied parkour and rare telegraphed fire plants. Every tenth-level hug leads into an original robot chase: hold right click/F/Fire to shoot, jump low orbs, roll high shots, reduce the health bar, then return to the run. Normal hazards/NPCs are absent from boss arenas. New artwork includes 84 original frames. Version 0.7.0 adds 164 generated sprite frames, alternating single-press attacks, drawn ground rolls, distance levels, eight varied adult anime celebrants, a one-second world-frozen hug every ten levels, configurable rare mushrooms, irregular gnome crowds, four overhead barriers, and upward/forward/diagonal owl winds. Smooth color/camera intensity and celebrations can be adjusted separately. Version 0.6.0 adds full Czech localization, exact localized character names, visible pre-run character cards, a locked character during each run and normalized pose sizes. Following sheep are smaller; only mushroom power enlarges the hero. Download installers and portable editions from Releases. Version 0.5.0 adds four distinct melee attacks (left click/J), ducking (Down/S/Ctrl), crows, enemy stomps, giant-mushroom gnome waves, seven collectible powers, changing weather/tempo, short goals and 102 new sprite frames. Sheep follow at clearer spatial delays. Phones always render a landscape playfield with multi-touch controls. Gentle camera/lightning effects can be disabled. Flowing wolf wind and real owl updraft lift are retained. The 48-frame companion sheets, species-specific freeze/ash animations and offline update migration are retained. Abilities include Aion double jump, hold-to-glide owl, collectible sheep lives (up to three) and hold-to-boost wolf. This remains a playable beta. macOS builds use development ad-hoc signing, without Developer ID/notarization; native iPhone distribution requires the owner's Apple Developer signing and App Store/TestFlight setup. See the release notes for actual platform verification, rather than assuming every produced package was device-tested.

## Vercel

[Adım adım Vercel kurulumu](docs/VERCEL.md). GitHub deposunu Vercel hesabında içe aktar, **Other** seç ve **Deploy** düğmesine bas. `vercel.json` derleme komutunu ve çıktı klasörünü belirler. MCP, API anahtarı veya veritabanı gerekmez. Vercel web oyunu içindir; kurulum paketleri Releases bölümündedir.
