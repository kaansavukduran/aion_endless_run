# Aion Endless Run · Sanat ve animasyon kuralları

## Kimlik ve kaynak

0.20.0 güncel sanat katmanı: Aion, Ömer, Melun, Kutsanmış, Emre ve Eren için altı yeni `pixel-*.png` paftası. Kullanıcının kedi referansı; malzeme gölgeleri, seçici koyu kontur, renk kümeleri ve okunaklı siluet için kalite yönüdür; kostüm veya tür kopyası değildir. Özgün model referanslarının renk, tür ve ayırt edici kıyafetleri korunur. Bu çizimler, kullanıcının istediği oyun içi render yenilemesidir; pafta dosya adları yeni kanon onayı anlamına gelmez. Eski bütün kahraman PNG'leri byte düzeyinde korunur. Güncel kaynak: `PIXEL-HEROES-PROVENANCE.json`; eski kayıtlar tarihsel/geri dönüş kaynağıdır.

Kareler eşit varsayılan genişliğe körlemesine bölünmez: gerçek atlas bölgeleri, şeffaf kenarlar ve ortak anatomik referans kullanılır. Güncel yatay hizalama; burun, yanak, göz ve yüz konturunu birlikte içeren, elle incelenmiş bütün-yüz RGB/alpha şablonuyla ölçülür. Tek renkli iris araması kullanılmaz; Aion'un mavi rozeti veya silahı göz sayılmaz. Kapalı gözler de aynı bütün-yüz alanıyla kaydedilir. Gerçek kaynak bileşeni komşu satırın sınırına uzanıyorsa tam siluet geri alınır; kulak/ayak kesilmez ve komşu karakter yapıştırılmaz. Kuyruk/gaga/uzak göz/yüzgeç yanlış pivot olamaz. Fizik konumu kare hizasını örtmek için oynatılmaz.

Paftaların mevcut piksel çözünürlükleri korunur; ortak yeni bir 16/32 piksel ızgarasına yeniden örneklenmez. Nearest filtre, izole kare dokuları ve piksele yuvarlanan çizim kullanılır. Kahraman başına ölçek animasyon boyunca sabittir. Mantarın amaçlı devliği ve küçük takipçiler ayrı davranıştır. Süre ve kare seçimi mevcut `frame_bank.gd`, `game.gd` ve provenance verisindedir; bütün hareketlere tek FPS dayatılmaz.

## Arayüz

Renklerin tek kaynağı `scripts/interface_options.gd`: koyu zemin `181620`, yüzey `27212e`, metin `f5ebd9`, vurgu `ffcf8c`, birincil `81374e`. Açık temanın karşılıkları aynı dosyadadır. Normal metin ve sınırlar için sayısal kontrast testleri vardır; bu bütün ekranın WCAG sertifikası değildir.

Normal arayüz SystemFont + güvenli sans yedeği; seçilebilir Pixelify Sans ve lisansı korunur. Marka/logo/dekoratif dünya metni pixel yazı kullanabilir. Panel köşeleri 0, sınırlar 2 mantıksal piksel, odak 3 piksel. Dokunmatik daireler basamaklı piksel kenarlı ergonomik istisnadır. Durumlar metin, işaret, odak çerçevesi, bekleme yayı ve kullanılamaz çizgisiyle anlatılır.

## Fragaria

`assets/fragaria-strawberry.png` referanstan üretilmiş şeffaf oyun türevidir; resmî nihai logo olduğu iddia edilmez. Özgün Drive referansları değiştirilmeden saklanır; `FRAGARIA-PROVENANCE.json` kaynağı açıklar. Siyah açılış zemini, büyük merkez çileği, Fragaria Interactive, on parça kırmızı/pembe/yeşil/açık gri çubuk ve gerçek sürüm. Web yüzdesi doğrulanan PCK akış baytlarına, yerel yüzde ResourceLoader ilerlemesine bağlıdır. Başlangıç/doğrulama aşaması belirsiz gösterilir; sahte bekleme süresi yoktur.

Kutlamada `evolution-celebrants.png` içindeki sekiz farklı mevcut kimlik kullanılır; yeni kanon kişi icat edilmez. Normal kutlama arka bankta kalır, dünya ilerledikçe geriye kayar. Hareket azaltma kamera sallanması, renk dalgası ve dekoratif konfetiye uygulanır; kahramanın koşusu dondurulmaz.

## Zamanlama ve ölçüm

Fizik 60 Hz, sunum hedefi 60 FPS'tir; bu fiziksel Poco'da ölçülmüş hız değildir. Koşu çevrimi174 dünya pikselidir; altı kahraman da altı farklı çizilmiş ana koşu pozu kullanır. Adım hızı dünya hızıyla artar; kopya karelerle sayım şişirilmez. Baykuş süzülme çevrimi 1 saniye; zıplama kareleri hız/uçuş evresine bağlıdır. Takla en az 0,68 saniye ve ileri saat yönündedir. Saldırı/ateş için kendi keyframe ve temas zamanlamaları korunur. Tek küresel FPS ile bütün paftalar yeniden örneklenmez. Sunucu software-GPU rAF kayıtları Drive doğrulamasında tutulur; cihaz benchmark'ı sayılmaz.

## 0.20.0 pafta sözleşmesi

Altı kaynak paftada11 satır ×6 gerçek çizim =396 çizim vardır. Kaynak PNG'lere yeniden boyutlandırma, palet filtresi veya rötuş uygulanmaz. Keskin siluet için alpha192 altındaki puslu kenar artıkları çizim span'ına alınmaz; bu, yeni çizim veya ek kare diye sayılmaz. PNG'ler kullanıcı yetkisiyle görüntü üretim aracıyla oluşturuldu; elle çizilmiş üretim iddiası yoktur.

| Satır | Eylem | Seçim |
|---|---|---|
| 0 | Bekleme |1,5s nefes/göz kırpma |
| 1 | Silahsız koşu/takipçi |174 dünya px çevrim |
| 2 | Sıçrama/iniş | Fizik hızına ve uçuş evresine bağlı |
| 3 | Tabancalı koşu |174 dünya px çevrim |
| 4 | Ateş | Mevcut0,30s animasyon;0,32s atış aralığı |
| 5 | Alçak omuz taklası | Eğil → el/kanat yere → omuz → kalça → ayak → alçak bekle; tek tur |
| 6 | Hasar/düşüş | Mevcut1,25s ölüm evresi |
| 7–9 | Donma, yanma, kül | Mevcut durum süreleri |
| 10 | Özel hareket | Aion çift sıçrama, Ömer kanatlı süzülme, Melun dört ayak depar, Emre şarj pozu; diğerleri kendi hoplama pozu |

`frame_bank.gd` eski mantıksal eylemleri güncel paftalara yönlendirir. Her kahramanın bütün satırlarında tek ölçek vardır; zıplama/saldırı/depar boyut büyütmez. Takla fizik kökeni sabittir; omuz hareketi çizilmiş pozdan gelir. Basılı tutunca son alçak kare bekler, ters/top döngüsü yoktur. Ömer'in kanat hareketi korunur; yüz sağa sola gezmez. Emre'nin güç biriktirmesi takla satırından değil ayrı şarj satırından çizilir. Havada silah ekinin kesimi daraltılmıştır: ikinci yüz/yanak taşınmaz. Mermi çıkışı yeni namlu ölçüsünü kullanır. Çarpışma kutuları, seviye temposu, kayıtlar, kontrol şeması ve beceriler değiştirilmez.

Kontrol: `python packaging/register_pixel_heroes.py` (Pillow/NumPy/SciPy; PNG'leri değiştirmez), `tests/test_pixel_heroes.gd`, `tests/browser_quality.py`. Başarılı derleme, sanatın kullanıcı tarafından onaylanması veya fiziksel cihaz testi yerine geçmez.

### Element durumlarında sabitlik

Donma ve yanmada büyüyen efekt sınırı, karakterin X kökeni değildir. Bu iki satır da anatomik baş penceresinde sınırlı bütün-yüz araması kullanır; ağır buzda Emre'nin kravatı yüz yerine seçilemez. X ortak yüz işaretine kaydedilir, mevcut zemin Y'si ve tek karakter ölçeği korunur. Bu72 pozun bankadaki kaydı ve gerçek oyun sahnesindeki seçimi ayrı denetlenir. Normal koşu/sıçrama/ateş/takla/özel/ölüm pozlarının bayt verisi bu son düzeltmede değişmemiştir. `tests/render_pixel_states.gd`36 gerçek native-rendered hasar sahnesi üretir; bunlar açık durum fixture'ıdır, normal giriş kanıtı değildir.
