# 0.20.0 · Pixel kahraman doğrulaması

Fragaria Unslop kullanıldı. Canlı AIONIA v1.7, referans dizini rev3 ve oyun regresyon kaydı v1.1,13.11.2026 tarihinde okundu. read_thread aracı mevcut değildi; bağlı sohbet okunmuş gibi gösterilmedi. Özel modelleme paftaları kamu deposuna kopyalanmadı.

Altı yeni pafta/396 kaynak kare. Kedi referansı; malzeme gölgesi, piksel kümeleri ve seçici kontur için yön verir; kostüm/tür/piksel kopyası değildir. Yeni sanatın kullanıcı beğenisi/onayı teknik testten ayrıdır. Önceki49 PNG byte olarak korundu. Güncel kaynak kaydı `assets/PIXEL-HEROES-PROVENANCE.json`; [sanat sözleşmesi](../ART_BIBLE.md).

## Gerçek nedenler

- Eski paftalarda yumuşak kenarlar ve zayıf malzeme ayrımı görsel olarak gözlendi. Yeni çizimler hareket, silah, element ve düşüş durumlarını ortak çizim dilinde kapsar; salt kare sayısı artırılmadı.
- İlk kesimde kısa kül/takla satırı bir alpha tepesini düşürdü; nominal bölücü Emre'yi yarım kesti. Gerçek oluklar ve tam bağlı siluetle düzeltildi. Satır sınırını geçen kulak/ayak geri alınır, komşu sprite taşınmaz.396 çizim sınırlar içinde doğrulandı.
- Koşu/sıçrama/ateş/uçuş; burun, yanak, göz ve kontur içeren bütün-yüz RGB/alpha şablonuyla kaydedilir. Fizik kökeni ve kareye göre ölçek değiştirilmez.
- Altı-poz takla eski12-poz zamanlayıcıya bırakılmadı. Tek omuz turundan sonra son alçak kare bekler; takipçi koyunlar gecikmiş yol kaydını kullanır. Emre şarjı ayrı satırdır. Dar namlu/kabza kesimi ikinci yüz/yanak taşımaz; mermi kökeni yeni namludan ölçülür.
- Son element denetimi, büyüyen efekt kutusunun X kökenini kaydırdığını buldu. Ağır buzda Emre'nin kravatını seçen sınırsız RGB aday eşleşmesi anatomik baş penceresiyle reddedildi. Donma/yanma72 pozda ortak yüz X'i kullanır; zemin Y'si ve tek ölçek korunur. `element-correction.json` ölçümleri kaydeder. Test önce1452 kontrolde72 hata, düzeltme ve gerçek sahne seçimi sonrası1596 kontrolde0 hata verdi.
- Engele çarpma önce sendeleme, düşmana çarpma doğrudan yüzüstü düşüş oynatır. İkinci klip mevcut dört çizimi kullanır; yeni kare sayısına eklenmez.

## Gerçek kanıt

Son temiz [CI43501562033](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43501562033), kaynak6de0867:19 paket/10970 kontrol (`ci-source-results.json`). İlk yerel denemede beş tarihsel kare/kaynak/ölçek beklentisi geçmedi; ilgili paketler güncel sözleşmeyle yeniden denendi. Eski altın piksel örnekleri tarihsel PNG denetimi olarak korundu. Başarısız denemeler PASS sayılmadı.

166 tarayıcı kontrolü:126 normal UI/giriş;13 DPR3 çoklu dokunma/geometri/iptal/yön;4 aşağı-kaydırma;20 public Pages Chromium/Firefox;3 gerçek offline worker/kayıt/Fire. Normal koşu, silah, sıçrama, takla, özel hareket ve ölüm kare verileri son element yamasında byte olarak değişmedi;126 normal-giriş kaydı bu kapsamda geçerlidir.72 element seçimi ayrıca gerçek sahnede denendi. JSON kayıtları gerçek build'leri ayırır; tarayıcı denemeleri dünya/başarı/RNG/kayıt setter'ı kullanmaz.

DPR3 ilk denemesi ölçüm sırasında doğal tehlikede öldü; iptal geçmişti, sonraki pause varsayımı geçmedi. Yön değişimi taze koşuda doğrulandı. Takla bırakma olayı JSON ölçümünden önce gönderilir; veri toplama gecikmesi engel penceresini tüketmez. Canlı smoke'un eski pafta-adı beklentisi sourceRow5 snapshot'ına taşındı; yanlış test beklentisi oyun hatası sayılmadı.

Pages build323d157ff6249dfa, Chromium ve Firefox'ta gerçek açılış/oynanış PASS. Canlı tanı sistem CA doğrulamalı HTTPS aktarımı kullanır; TLS doğrulaması kapatılmaz. DevTools ileti sınırı için16MiB tanı dilimleri aynı SHA doğrulamalı public PCK'yi birleştirir. Canlı tanıda SW kapalıdır; gerçek offline deneme ayrı kayıttadır. Offline reload normal oynayarak kazanılmış rekoru korudu.

Android API30 emülatörde Wi-Fi kapalı11 gerçek ADB kontrolü PASS. Windows Setup+portable, Linux portable/DEB/AppImage ve macOS universal App/DMG native açılış smoke'ları temiz CI'de geçti. Kararlı imzalı APK ayrıca yerelde üretildi; versionCode24 ve önceki kimlik/imza korunur. CI test APK'sı ile kararlı imzalı APK aynı dosya diye sunulmaz. APK/PCK attestation kayıtları, düzeltilmiş288 yüz kaydının gerçek paketlerde kaynakla birebir bulunduğunu doğrular.

36 gerçek Linux X11/llvmpipe hasar sahnesi ayrıca render edildi (`render-fixtures.json`). Bunlar açık durum fixture'ıdır; normal giriş veya fiziksel telefon kanıtı değildir. `tests/render_pixel_states.gd` ile yeniden üretilebilir; temsili dört ekran repoda saklanır.7 web paketleme ve4 Android günlük-parça testi de geçti.

## Yayın ve sınırlar

Vercel'in son6de0867 dağıtımı günlük kota nedeniyle BLOCKED: `Deployment rate limited — retry in 24 hours`. Orada ilk0.20.0 sanat sürümü durur; son element yaması GitHub Pages'tedir. İki adresin rekorları farklı origin'lerde ayrıdır. Vercel'in de son yamayı aldığı iddia edilmez.

Fiziksel Poco X7/Firefox, iPhone/Safari ve fiziksel Xbox/PS kolu NOT TESTED. Native iOS sahibinin Apple imzasını gerektirir. Mac ad-hoc; Developer ID/noter ve Windows Authenticode yok. Kontrol şeması, kayıtlar,15s seviyeler ve düşman/buff dengesi bu sanat görevinde yeniden tasarlanmadı.

Dokuz paket ve iki makbuz [v0.20.0](https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.20.0) altında yayımlandı. Yayın43506636283,11 yüklemenin sunucu SHA-256 özetleri eşleşmeden taslağı açmadı. `public-packages.json`: dokuz kamu paketinin özet/boyut eşleşmesi; ayrıca gerçekten indirilen kararlı APK byte/hash ve macOS ZIP CRC/universal CPU denetimleri. Bütün paketlerin yerelde indirildiği iddia edilmez. Etiket2569d22, CI kaynağı6de0867 ve Android uygulama kaynağıbbf2ebd makbuzda ayrıdır.
