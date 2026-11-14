# AIONIA arcade dönüşümü

Durum: İlk görev geliştirilir. Beş görevlik planın tamamı bitmiş oyun değildir. Yetkili proje aynı Godot 4.6.3 deposudur; karakter kaynakları, kayıtlar ve çalışan sonsuz koşu korunur. Yeni mod kendi ilerleme kaydını kullanır. Yeni motor veya depo kurulmaz.

## Araştırmadan çıkarılan yapı

Metal Slug 3, SNK'nin 2000 tarihli yandan görünüşlü run-and-gun arcade oyunudur. Özgün sürümde Marco, Tarma, Eri ve Fio seçilir. Ateş, zıplama, yakın dövüş, bomba, araç, kurtarma ve boss döngüsü beş göreve bağlanır. Kaynaklar: [SNK/Steam ürün açıklaması](https://store.steampowered.com/app/250180/METAL_SLUG_3/), [oynanış/hikâye](https://en.wikipedia.org/wiki/Metal_Slug_3), [karakterler ve kontroller](https://www.arcadequartermaster.com/mslug3_characters.html).

| Görev | Oyun yapısı | Ana boss | Uyarlamada alınacak ilke |
|---|---|---|---|
| 1 | Kıyı; ilk ayrım su altı/yüzey, yüzeyde ikinci ayrım nehir/depo; üç son rota birleşir | Huge Hermit | İki ardışık karar düğümü, üç farklı rota, ortak final |
| 2 | Zombi bölgesi; isteğe bağlı buz mağarası | Monoeye UFO / Monoeye Artifact karşılaşmasının evreleri | Tek alternatif geçiş ve farklı durum etkileri |
| 3 | Su altı giriş; üst/orta/alt tercihler ve fabrika/üst yol bağlantıları | Jupiter King | Araç ve çevreye göre farklı mücadele |
| 4 | Çöl/harabe; birden çok iç içe geçit | Sol Dae Rokker | En yoğun keşif ve yeniden oynanış ağı |
| 5 | Uzun, büyük ölçüde doğrusal hava/uzay/gemi içi akışı | Rootmars | Eski düşmanlarla ittifak ve uzun final |

Rota kaynakları: [bölüm bazlı rehber](https://steamcommunity.com/sharedfiles/filedetails/?id=3712081380), [rota kabul noktaları](https://www.playstationtrophies.org/game/metal-slug-3/print-guide/). "45 rota" ifadesi rehberlerde keşif/başarım noktaları için kullanılıyor; bunu 45 bağımsız uçtan uca harita diye çevirmiyoruz. Mission 3/4'ün her geçiş kenarının kesin sayısı henüz doğrulanmış değil. Bu sayılar eşleşmiş gibi sunulmaz; ilgili görev uygulanmadan önce harita çıkarılacak. Mission 1 için iki karar düğümü ve üç son yol açıkça doğrulanmıştır.

### Kategoriler ve sayım sınırı

1. Oyuncu: dört kişi; yürüme, nişan, ateş, yakın dövüş, sıçrama, hasar, ölüm ve dönüşüm durumları.
2. Silahlar: sınırsız temel tabanca; özel silah/mühimmat; yakın dövüş; bombalar; araç topları. Heavy Machine Gun, Rocket Launcher, Shotgun, Flame Shot, Laser, Enemy Chaser, Iron Lizard, Drop Shot ve Super Grenade kaynak rehberlerde listelenir. Güç artışı ve kaynak yönetimi, araç hasarı ve tamiriyle birlikte çalışır.
3. Düşmanlar: piyade rolleri, zırhlı/kara araçları, hava/deniz birimleri, biyolojik yaratıklar, durum etkili yaratıklar, uzaylı/robotlar, mini boss ve ana boss. Aynı türün varyantı ayrı oyun türü veya ayrı ana boss sayılmaz.
4. NPC: sıradan esirler; Rumi/Madoka ikmal desteği; Hyakutaro ve Utan gibi takipçi yardımcılar; President gibi özel kurtarma karşılaşmaları. Aynı dosyadaki çok sayıda NPC pozu tek NPC değildir.
5. Etkileşimli çevre: kırılabilir duvar/sandık, kapı/kol, platform, gizli geçit, taşıt ve ikmal noktaları.
6. Hikâye: çoğu olay oynanışın içinde anlatılır. Kısa görsel şakalar, kurtarmalar, tehdit büyümesi, kaçırılma ve ittifak değişimi uzun metnin yerine sahnelenir. Finalde Morden kılığına giren uzaylı ortaya çıkar; kaçırılan karakter değiştirilir, eski rakipler ortak tehdide karşı birleşir. Bu olaylar bizim oyuna isim/görsel/sahne kopyası olarak aktarılmaz.

Mini boss adlandırmaları kaynaklar arasında değişir. Büyük mutant yengeç/yaratık karşılaşmaları, Monoeye evreleri, Allen, Hairbuster Riberts, Hi-Do, Rugname, Fake Rootmars ve Clone Incubator gibi ara karşılaşmalar aynı sayım kuralıyla ayrıştırılmalıdır. Beş ana görev boss'u ile bütün ara savaşlar aynı toplam değildir.

[The Spriters Resource arşivi](https://www.spriters-resource.com/neo_geo_ngcd/ms3/) erişim anında 138 dosya kaydı gösteriyor: 5 oyuncu paftası (Eri'nin zombi varyantı dahil), 10 araç kaydı, 5 NPC kaydı, 60 "Enemies & Bosses", 30 arka plan, 22 çeşitli ve 6 kullanılmayan içerik. Bunlar arşiv kayıtlarıdır; oyunun toplam düşman, kare veya animasyon sayısı değildir. Bütün orijinal animasyonların resmî ve doğrulanmış bir toplamı bulunamadı. "Aynı sayıda sprite sheet tamamlandı" denmeyecek. SNK görselleri, müzikleri veya ripped paftaları projeye alınmaz.

## Beş görevlik özgün oyun planı

| Görev | AIONIA içeriği | Hikâye/görev rolü | Durum |
|---|---|---|---|
| 1 · Sönen Fenerler | Fener kıyısı; sazlık, üst bahçe ve kök geçidi; özgün binek; Kök Motoru | Kesilen fener ağını onar; sivilleri kurtar; sahte bakım emrinin izini bul | Bu aşamada oynanabilir yapılır |
| 2 · Cam Ayazı | Kar vadisi, buz mağarası, terk edilmiş gözlemevi | Ağın ikinci parçası, donma ve alternatif geçit | Plan |
| 3 · Bakırın Hafızası | Şehir kanalı, sera fabrikası, çatı rotası | Üretim ağındaki çelişkili emirler, daha karmaşık araç/rota kullanımı | Plan |
| 4 · Kor Antlaşması | Volkanik harabe, üç topluluğun çatışan geçitleri | Eski rakiplerin aynı komutla yönetildiğinin açığa çıkması | Plan |
| 5 · Omega-3 Yörüngesi | Kalkış, dış uzay, robot filosu, istasyon ve çekirdek | Kullanıcının kararı: Omega-3 gerçek ortak tehdit; eski düşmanlar dost olur, birlikte robot ordusuyla savaşılır | Uzun final planı |

Son görev diğerlerinden belirgin biçimde uzun hedeflenir. Hedef süreler tasarım bütçesidir, ölçülmüş sonuç değildir: ilk dört görev yaklaşık 6–10'ar, final 15–20 dakika; tekrar/rota keşfi hariç. Metal Slug 3 ile eşit üretim hacmi veya aynı nihai sanat kalitesi bu ilk aşamada tamamlanmış sayılmaz.

Yeni yer, makine ve bölüm adları bu oyun uyarlamasının çalışma adlarıdır; evrenin geçmişine dair onaylanmış yeni tarih icat edilmez. Omega-3'ün kötü yapay zekâ olması ve final ittifakı doğrudan kullanıcının bu görevdeki hikâye kararıdır. Bağlanan eski ChatGPT sohbetini açan read_thread aracı bu ortamda yoktur; o sohbet okunmuş gibi kaynak gösterilmez.

## İlk görevin kabul koşulları

- Altı mevcut kahraman kendi kimliği ve hareketleriyle seçilir. Aion çift sıçrar; Ömer süzülür ve üç havada kanat hakkı kullanır; Melun depar yapar; Kutsanmış'ın küçük takipçileri gecikmeli izler; Emre/Eren tut/bırak şarjlı sıçrar.
- Otomatik koşu yerine gerçek sağ/sol hareket, kameranın izlediği sonlu platform haritası, başlangıç/orta/boss kontrol noktaları ve görev sonu vardır.
- İlk ayrım sazlık/yüzey; yüzeyde ikinci ayrım üst bahçe/kök geçidi. Üç son rota farklı düşman, platform ve ikmal düzeninden geçip aynı son arenaya birleşir.
- Kurtarılabilir NPC ve kırılabilir ikmal sandıkları gerçek sonuç verir. Hiçbir NPC'de dost ateşi yoktur.
- Özgün binek oyuncuyu taşır, ayrı canı ve güçlü atışı vardır; inme/binebilme gerçektir.
- Normal düşmanlar tek vuruşla yenilir. Mini boss ve ana boss ayrı can havuzları, okunabilir hazırlık ve kaçınılabilir saldırılar kullanır.
- Silah güçlendirmeleri, karakter rengine göre fiziksel yayı olan ışıklı bombalar ve yakın mesafede bağlamsal yakın dövüş vardır. Temel tabanca sınırsızdır, reload geri gelmez.
- Konuşma/rota seçimi/pause sırasında dünya durur. Ölüm ve yeniden deneme, checkpoint ve kurtarılan kişi kimlikleri tutarlı çalışır. Tekrar para/puan üretilemez.
- Gerçek başlangıç, iki karar düğümü, üç rota, binek, boss, ölüm/yeniden deneme ve görev sonu test edilir. Fiziksel telefon/kol ayrıca raporlanır; emülasyon fiziksel test sayılmaz.

## Kullanıcının yeni kontrol onayı

Solda **sabit joystick**; sağda **Zıpla**, **Ateş / yakındaki düşmana karaktere uygun yakın dövüş**, **Bomba**. Yeni bölüm modunda takla eylemi yoktur. Eski sonsuz mod kendi çalışan eşlemesini korur. Bombalar karakterin paletinden alınan renklerle bilim kurgu enerjisi taşır. Klavye/gamepad ortak eylemlerini ve kayıtlı eşlemeleri bozmadan yeni modun bomba/etkileşim işlevleri açıkça etiketlenir.

## Uygulama sırası

1. Ayrı kampanya modeli: elle hareket, platformlar, karşılaşmalar, iki çatallanma, kontrol noktaları ve sonlu görev akışı.
2. Mevcut pafta ve zemin sistemiyle yeni bölüm görünümü; özgün makine/düşman karelerini ekle, ayak/gövde kaydını denetle.
3. Onaylanan joystick ve üç eylem; klavye/gamepad, menüler, konuşma ve yön değişimi.
4. NPC, binek, ikmal, mini boss, boss ve hikâye sonunu birbirine bağla.
5. İlk görev rotalarını ve önceki kayıt/animasyon/açılış regresyonlarını gerçek girişlerle doğrula; çalışan web çıktısını ayrıca aç. Sonraki dört görevi bitmiş gibi gösterme.
