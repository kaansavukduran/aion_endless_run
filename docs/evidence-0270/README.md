# 0.27.0 · Araç ödülleri, ara açılara ateş ve kendi ölüm kareleri

Başlangıç temiz main697cfcd/0.26.2. Mevcut Godot4.6.3, dört karakter, TR/EN, kayıtlar ve onaylı joystick/eylem kümesi korunur.

## Değişiklikler

- Araçtaki oyuncunun mantıksal noktası eyer seviyesinde42px yukarıdadır. NPC'nin eski temas kontrolü açıkça araçtakini dışlıyordu. NPC ve eşya teması gerçek zemine bağlı164×132hull alanını kullanır; araç havadayken yerdeki kıza uzaktan temas olmaz. Mevcut teşekkür/çantadan çıkarma ve tek seferlik gerçek eşya toplama akışı çalışır. Temas anındaki teşekkür ve çanta aracın önünde çizilir; araç bunları örtmez. Yaya temas mesafeleri değişmez.
- Sekiz ana hedef yönü korunur; yaya silahı bu hedefler arasında kısa açıdan9rad/s ile döner. Görünen silah, namlu ve mermi aynı gerçek ara yönü kullanır. Basılı ateşte dönüşte70mslik atış fırsatı,180ms sınırlayıcıyla yalnız normal hafif/menzilli silahlarda açılır; mayın/nova/disk aralıksız spamlanmaz. Ateş etmeyen oyuncu sırf nişan değiştirdi diye mermi üretmez. Araçta mevcut kesintisiz analog nişan korunur.
- Dört karakterin hepsinde Shift depar; sağ fare düğmesi bomba. G erişilebilir alternatif olarak kalır. Mevcut Xbox/PS eşlemeleri korunur: A/×zıpla,RB/R1ateş,B/○bomba,LB/L1depar,Start/Optionsmenü. Touch joystick dış kenarı depar verir. Girişler ortak kaynak tutucusundan bırakılır; çift kaynak iki bomba üretmez.
- Dört gerçek rüzgâr karesiyle yeni fenerli bayrak. Bölüm çıkışı ve fiziksel rota bayraklarına bağlıdır; bayrak yeni bir kayıt tetikleyicisi gibi sunulmaz. Normal mermi, izleyen, disk/spor ve araç atışlarında paletli piksel çekirdek/kenar/iz; dalga ve ışında katmanlı piksel görünümü. Çarpışma ölçüsü sırf resim değişti diye büyütülmez.
- Bölgesel düşmanlar, ağır makineler ve muhafızların var olan türe özel ölüm satırları opak oynatılır. Eski9tür için54ayrı yeni çizim: karga,cüce,yarasa/moth,slime,böcek,wisp,drone,seedrobotu,warden. Yürüyüş karelerini ölüm diye kullanma ve global alpha fade kaldırıldı. Uçanlar zemine düşer; son gövde/enkaz pozu görünür kalır,1s sonunda temizlik yapılır. Oyuncu karakterlerinin paftaları yeniden çizilmez. Canlı robot çizimlerinin konumları korunur.

## Kanıt

[55kaynak paketi/38.227kontrol](source-results.json), iki yeni paket55+209kontrol içerir. [Normal menüden gerçek klavye/fare/dokunma ve sentetik Gamepad API ile34kontrol](browser-results.json), hata0; yerel build097f64b69b57dd85. [Ara açıdaki gerçek mermi paketleri](sweep-packets.json). Sanal Xbox gözlemi fiziksel kol testi değildir. İlk yerel sunucunun silinen derleme klasöründeki çalışma dizini nedeniyle verdiğiERR_EMPTY_RESPONSE sonrası aynı derleme sabit --directory kullanan8798sunucusunda çalıştırıldı; oyun/yükleyici hatası diye etiketlenmez.

[Çanta araç önünde](mounted-bag.png), [türe özel opak son pozlar](opaque-deaths.png), [bayrak](flag.png), [ara açı ve mermi](projectile.png):4gerçek oyun renderer'ı görüntüsü, **açıkça kurulmuş fixture**. Bunlar normal girişle o sahnelere ulaşma iddiası değildir. İlk render fixture'ındaki türsüzArrayatama hatası fixture'da düzeltildi, son4görüntü hatasız yakalandı.

[Kayıtlı sanat kaynakları](../../assets/CAMPAIGN-EFFECTS.json) · [yeniden kayıt betiği](../../packaging/register_campaign_effects.py) · [davranış regresyonu](../../tests/test_campaign_rewards_sweep.gd) · [sanat regresyonu](../../tests/test_campaign_effects_art.gd). Önceki PNG'ler değiştirilmez; iki yeni PNG eklenir. Fiziksel Poco/iPhone/gerçekXbox/PS bu görevde test edilmedi. Son uzak CI/yayın ve public açılış son commit'in kendi kimliğinden ayrıca doğrulanmalıdır.

Son bağımsız ölçüm gerçek bir yeni kayıt kusurunu yakaladı: makine bankası offset/size değerlerini zaten oyun biriminde verirken ilk kayıt betiği kaynak pikseli kullanmıştı. Üç robot referansı düzeltildi, hatalı canlı-seed kaydırması kaldırıldı. Eski karelerin gerçek çizim dönüşümüne karşı eklenen altı regresyon önce başarısızdı; düzeltme sonrası 209 sanat kontrolünün tamamı geçti. Buradaki kaynak test makbuzu ve opak ölüm görüntüsü düzeltilmiş b7a29c8 çalışma durumundandır.

## Uzun tarayıcı turunun canlı oyuncu önkoşulu

İlk uzak Linux turunda (Actions 43729737622) ilk üç yön başarılıydı; dördüncü bağımsız nişan kontrolünden önce oyuncu ölmüştü. Hata anında `hp=0`, `state=dead`, `menu=dead`, `shots=3`, tarayıcı betik hatası yoktu. Ölümün hangi darbeden geldiği bu kayıtta yoktur. Bu sonuç, sol-yukarı nişan mekanizmasının bozuk olduğunu kanıtlamaz; test ölü oyuncudan atış bekliyordu.

Test artık her bağımsız yön için canlılık önkoşulunu izler. Gerçek ölüm görülürse JSON ve ekran görüntüsünü giriş temizliğinden önce saklar, normal **Yeniden dene** düğmesine basar ve yalnız o yönü tekrar dener; bütün yön turunda en fazla üç böyle yeniden deneme vardır. Ölümsüzlük, konum ataması veya daha zayıf atış doğrulaması eklenmedi. Oyun davranışı değişmedi.

[51 normal giriş kontrolü](forge-results.json) bu gözlemciyle geçti. Bu yerel tur mevcut 097f64b69b57dd85 web derlemesindeki girişleri doğrular; robot ölçeği düzeltmesinin web görsel kanıtı olarak sunulmaz. Son düzeltilmiş yayının derleme kimliği ve uzak CI sonucu teslim raporunda ayrıca bağlanır.
