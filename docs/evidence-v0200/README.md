# 0.20.0 · Pixel kahraman doğrulaması

Fragaria Unslop kullanıldı. Canlı AIONIA v1.7, referans dizini rev3 ve regresyon kaydı v1.1,13.11.2026 tarihinde okundu. Bağlı sohbetin read_thread aracı mevcut değildi. Özel modelleme paftaları kamu deposuna kopyalanmadı.

Altı yeni PNG ×66 farklı çizilmiş poz =396 kaynak çizim. Kedi görseli malzeme gölgesi/piksel kümeleri için yön verir; kostüm/tür/piksel kopyası değildir. Yeni sanatın kullanıcı beğenisi/onayı ile teknik test ayrı şeylerdir. Önceki49 oyun PNG'si byte olarak korundu (`source-art-integrity.json`). Güncel kayıt: `assets/PIXEL-HEROES-PROVENANCE.json`. Sanat ve zamanlama: [ART_BIBLE](../ART_BIBLE.md).

## Gerçek nedenler ve düzeltmeler

- Eski paftalarda yumuşak kenarlar ve zayıf malzeme ayrımı görsel olarak gözlendi. Salt kare sayısı artırılmadı; altı kahramanın hareket, silah ve element/düşüş durumları aynı yeni çizim diliyle hazırlandı.
- İlk otomatik kesimde kısa kül/takla satırı bir alpha tepesini düşürdü; nominal satır bölücüsü Emre'yi yarım kesti. Gerçek oluklar ve tam bağlı kaynak silueti ile düzeltildi. Satır sınırını geçen kulak/ayak geri alındı; komşu sprite taşınmadı. Son kaynak denetiminde396 çizimin tamamı kırpılma sınırının içinde. Başarısız ilk deneme PASS sayılmadı.
- Yatay sabitleme; burun, yanak, göz ve konturu içeren bütün-yüz RGB/alpha şablonundan ölçülür. Tek renkli iris/badge araması yoktur. Fizik kökeni veya kareye göre ölçek değiştirilmez.
- Yeni altı-poz takla, eski12-poz çizim takvimine bırakılmadı: tek omuz turu sonrası son alçak kare bekler. Takipçiler aynı seçimi gecikmiş yol kayıtlarında yapar. Emre şarjı ayrı poz satırıdır.
- Silah eki dar namlu/kabza bölgesine indirildi; ikinci yüz/yanak taşımaz. Mermi kökeni yeni paftadaki namluyla ölçülür.
- Ölüm sebebi ayrımı korunur: engele çarpma önce sendeleme, düşmana çarpma doğrudan yüzüstü düşüş. İkinci oynatma klibi mevcut dört düşüş çizimini kullanır; yeni çizim sayısına eklenmez.

## Gerçek testler

-19 Godot paketi/10694 kontrol: seçilen son sonuçlar `source-results.json`. İlk tam denemede yeni kare sayısı/kaynak kalibrasyonu yüzünden beş tarihsel beklenti geçmedi; etkilenen paketler yeniden çalıştırıldı. Eski altın piksel örnekleri tarihsel PNG denetimi olarak korundu. Yeni kaynak için396 kesim/ölçek ve216 bütün-yüz şablon kontrolü ayrıca eklendi. Temiz CI tam koşusu yayın aşamasında ayrıca kaydedilecek.
-126 normal UI/giriş kontrolü: altı kahramanın bütün koşu/ateş kareleri, düşük tek takla/bekleme/doğrulma, bütün Ömer uçuş ve Melun depar kareleri, ayrı Eren sıçraması, Emre şarj/bırak, ateş iptali, emüle standart gamepad A/X menü onayı, duraklatılmış yön değişimi ve%200 açık tema menüleri. `browser-results.json` gerçek test edilen build'i kaydeder; dünya/başarı/kayıt/RNG setter'ı kullanılmadı.
-13 DPR3 gerçek CDP dokunma kontrolü: simetrik piksel sınırları, iki parmak Fire+Jump, iptal ve duraklatılmış yön değişimi. İlk DPR3 denemesi inceleme sırasında doğal tehlikede öldü; kontrol iptali geçmişti, sonraki pause varsayımı geçmedi. Yön testi ayrı taze koşuda doğrulandı; ölüm başarısız sayılmadı veya düşmanlar kaldırılmadı.
-7 web paketleme ve4 Android günlük-parça ayrıştırma testi geçti.

Ekran görüntüleri gerçek Godot Web oyunudur. Kaynak pafta önizlemesi, çalışan oyun kanıtı sayılmadı. Fiziksel Poco X7/Firefox, iPhone/Safari ve fiziksel Xbox/PS kolu: NOT TESTED. Emülasyon bunların yerine geçmez.

Yayın/native/çevrimdışı son sonuçları doğrulanınca eklenecek. Henüz yapılmayan kontrol PASS sayılmaz. Kontrol şeması, kayıtlar,15s seviyeler, buff/düşman dengesi bu sanat görevinde yeniden tasarlanmadı.
