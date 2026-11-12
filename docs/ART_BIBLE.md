# Aion Endless Run · Sanat ve animasyon kuralları

## Kimlik ve kaynak

Aion, Baykuş Ömer, Melun Bilge Kurt ve Kutsanmış Cahil Koyun'un doğrulanmış paftaları temel kaynaktır. Bu görevde kahraman PNG'leri yeniden çizilmedi. Kaynak/provenans ve `SPRITE-REGISTRATION.json`, `CANONICAL-PROVENANCE.json`, `AGILITY-PROVENANCE.json` korunur. Eski Drive arşivi, güncel sanatı otomatik olarak geçersiz kılmaz.

Kareler eşit varsayılan genişliğe körlemesine bölünmez: gerçek atlas bölgeleri, şeffaf kenarlar ve ortak anatomik referans kullanılır. Yatay hizalama yakın göz irisiyle, ters dönen koyun tekmesinde üst gövde referansıyla yapılır. Kapalı gözler doğru komşu karelerden, gerçek atlas aralıklarıyla ara değerlenir. Kuyruk/gaga/uzak göz/yüzgeç yanlış pivot olamaz. Fizik konumu kare hizasını örtmek için oynatılmaz.

Paftaların mevcut piksel çözünürlükleri korunur; ortak yeni bir 16/32 piksel ızgarasına yeniden örneklenmez. Nearest filtre, izole kare dokuları ve piksele yuvarlanan çizim kullanılır. Kahraman başına ölçek animasyon boyunca sabittir. Mantarın amaçlı devliği ve küçük takipçiler ayrı davranıştır. Süre ve kare seçimi mevcut `frame_bank.gd`, `game.gd` ve provenance verisindedir; bütün hareketlere tek FPS dayatılmaz.

## Arayüz

Renklerin tek kaynağı `scripts/interface_options.gd`: koyu zemin `181620`, yüzey `27212e`, metin `f5ebd9`, vurgu `ffcf8c`, birincil `81374e`. Açık temanın karşılıkları aynı dosyadadır. Normal metin ve sınırlar için sayısal kontrast testleri vardır; bu bütün ekranın WCAG sertifikası değildir.

Normal arayüz SystemFont + güvenli sans yedeği; seçilebilir Pixelify Sans ve lisansı korunur. Marka/logo/dekoratif dünya metni pixel yazı kullanabilir. Panel köşeleri 0, sınırlar 2 mantıksal piksel, odak 3 piksel. Dokunmatik daireler basamaklı piksel kenarlı ergonomik istisnadır. Durumlar metin, işaret, odak çerçevesi, bekleme yayı ve kullanılamaz çizgisiyle anlatılır.

## Fragaria

`assets/fragaria-strawberry.png` referanstan üretilmiş şeffaf oyun türevidir; resmî nihai logo olduğu iddia edilmez. Özgün Drive referansları değiştirilmeden saklanır; `FRAGARIA-PROVENANCE.json` kaynağı açıklar. Siyah açılış zemini, büyük merkez çileği, Fragaria Interactive, on parça kırmızı/pembe/yeşil/açık gri çubuk ve gerçek sürüm. Web yüzdesi doğrulanan PCK akış baytlarına, yerel yüzde ResourceLoader ilerlemesine bağlıdır. Başlangıç/doğrulama aşaması belirsiz gösterilir; sahte bekleme süresi yoktur.

Kutlamada `evolution-celebrants.png` içindeki sekiz farklı mevcut kimlik kullanılır; yeni kanon kişi icat edilmez. Normal kutlama arka bankta kalır, dünya ilerledikçe geriye kayar. Hareket azaltma kamera sallanması, renk dalgası ve dekoratif konfetiye uygulanır; kahramanın koşusu dondurulmaz.

## Zamanlama ve ölçüm

Fizik 60 Hz, sunum hedefi 60 FPS'tir; bu fiziksel Poco'da ölçülmüş hız değildir. Koşu çevrimi 174 dünya pikselidir; Aion/baykuş/koyun 7, kurt 8 ana koşu karesi kullanır, dolayısıyla adım hızı dünya hızıyla artar. Baykuş süzülme çevrimi 1 saniye; zıplama kareleri hız/uçuş evresine bağlıdır. Takla en az 0,68 saniye ve ileri saat yönündedir. Saldırı/ateş için kendi keyframe ve temas zamanlamaları korunur. Tek küresel FPS ile bütün paftalar yeniden örneklenmez. Sunucu software-GPU rAF kayıtları Drive doğrulamasında tutulur; cihaz benchmark'ı sayılmaz.
