# Mission1 · 0.26.0 teslim ve doğrulama

Oyun kodu `b7f6d2693c9e47de148a4336bf7dcc0cdaa5ef7a` üzerinden main dalındadır. Bu ağacın oyun dosyaları test edilen`a961e6e5be3d382de971f1d0aeab5c0769905f28` ile aynıdır. Bu belge ve README/FORGE bağlantıları oyun kodunu değiştirmez. Son yayın commit/build kimliği Vercel ve GitHub Actions kayıtlarından ayrıca doğrulanır; önceki build sonucu yeni yayının sonucu sayılmaz.

## Değişiklikler

- Dört oynanabilir karakter: Aion, Kutsanmış, Ayça ve Eren. Ayça eski Emre karakter yuvasında kendine ait etekli/tokalı çizimiyle bulunur. Ömer/Melun artık ikişer saldırı yapan yardımcı güçlerdir. Dil seçimi TR/EN'dir; eski kaynaklar ve kayıtlar silinmez.
- Üst köprü/alt kanal üzerinden fiziksel yol ayrımları; metinden rota seçme yoktur. Aşağı/S veya joystick aşağı ile eğilerek ilerle ve ateş et. Mevcut bomba, zıplama, yakın saldırı ve kol eşlemeleri korunur.
- Ortak gövde, el ve zemin kayıtları; ateş ederken yürüyüş sürer. Hareket, duruş, hava ve eğilme kareleri ortak ölçekte kullanılır. Portreler ve iki moddaki koyun takipçileri güncel paftayı kullanır.
- Araçlarda üç can ve kaynak çizimden ayrılan, kesintisiz dönen gerçek namlu; zemine uygun binme/inme. Örümcek mayın hedefe yürür ve beş saniyede patlar. NPC'ler yüzlerinin yönüne yürür; çantadan çıkan gerçek ikmal temasla alınır.
-81 eski PNG byte-byte aynıdır. Dokuz yeni PNG:120 etkin gövde karesi,24 Ayça hasar/ölüm karesi,12 örümcek karesi ve6 statik eşya.48 eski taslak eğilme karesi runtime'a ek kare gibi sayılmaz. Yeni bıçak/yumruk paftası iddiası yoktur; bu eylemler kayıtlı elin üzerinde prosedürel bıçak/vuruş katmanı kullanır.

## Gerçek testler

[Son başarılı aday CI](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43706073148): kaynak testleri, Linux, Windows, macOS ve gerçek Android emülatör girişi başarılıdır. Native Android18 kontrolü iki parmakla eğilerek ilerleme+ateş etme, bırakınca girişin çözülmesi ve yön değişiminde kayıt korunmasını içerir. Bu, fiziksel Poco veya gerçek kol testi değildir. İmzalı yeni GitHub Release yayımlanmadı.

Yerelde tek taze51-suite koşusu34.993 kontrol geçirdi. Hosted kaynak koşusu35.062 kontrol geçirdi; font/yerleşim taramalarında platforma göre kontrol sayısı değişir. [Yerel özetler](evidence-m1-flow/source-results-local.json), [animasyon/rota doğrulaması](M1-FLOW-VALIDATION.md).

| Normal oynanan rota | Kontrol | Gerçek NPC eşya ödülü | Yeniden deneme | Sonuç |
| --- | ---: | ---: | ---: | --- |
| Su |85|18|0| Boss HP0,3.evre, görev sonu, kayıt, ana menü |
| Teras |88|19|0| Boss HP0,3.evre, görev sonu, kayıt, ana menü |
| Kökler |95|21|0| Boss HP0,3.evre, görev sonu, kayıt, ana menü, gerçek offline yeniden açılış |

Bu sonuçlar yerel donmuş web çıktısı`1cb17f4b134c91d0` içindir. Dünya konumu/hasar/kayıt enjekte edilmedi; klavye, dokunma ve gerçek menü kontrolleri kullanıldı. [Makbuzlar ve gerçek görev sonu görüntüleri](evidence-m1-flow/README.md).

Korumalı Vercel önizlemesi`892d8a31f061772b`50 gerçek giriş/kurtarma kontrolünü geçti; [ayrı makbuz](evidence-m1-flow/preview-checks.json). Kullanılan doğrulanmış TLS tanı sürücüsü service worker'ı kapattığından bu uzak çevrimdışı kurulumu kanıtlamaz. Public son yayın ayrıca kontrol edilir.

İzole Firefox1538:30 kontrol; dokunma, iki yön, gerçek NPC teması, offline yeniden açılış/Devam başarılı, script/tarayıcı hatası0. Tek tarayıcı ve yazılımsal llvmpipe ile6,035 saniyede320 Godot process karesi≈53,02Hz;364 fizik karesi≈60,31Hz; tarayıcı rAF52,85Hz. Bu fiziksel telefon veya en ağır sahne performans sertifikası değildir.

## Doğrulanmış hatalar ve test önkoşulları

Gerçek düzeltmeler: eski silah ikonlarında ters yön/hatalı fiziksel namlu, hasar karelerinde namlu ucu kaydı, son mermide görünür silah değişimi, eski Ayça portresi, hareket bankasının ölüm karelerini örtmesi, koyun takipçisinin eski paftası, geri dönüşte basamağa ışınlanma, yeni tüyün düşen taşı silmesi ve süresi bitmiş yardımcının yeni saldırı üretmesi. Regresyonlar bunları ayrı kapsar.

[İlk CI](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43704593167) başarısız makbuzları korunur. Linux testinin ekranı karakterinHP0/ölü olduğunu gösterdi; bağımsız eğilme testinden önce gerçek kontrol noktası düğmesiyle canlı oyuncu önkoşulu kurulur. Android testinde portrait'e dönüş sonrası güncel Godot yerleşimi beklenmiyordu. Eski seçilmiş dokunma noktası kaydedilmediğinden kesin koordinat nedeni varsayım olarak kalır; yeni test yönü, fiziksel sınırları ve her seçilmiş noktayı kaydeder. Düzeltilen18-kontrollü emülatör turu başarılıdır; oyun bu testleri geçirmek için yavaşlatılmadı veya dokunulmaz yapılmadı.

## Skill kapsamı ve sınırlar

Üç istenen skill okundu. Proje içi `.agents/skills/unslop` ve `.agents/skills/fragaria-unslop` paketleri gerçek hata sınıflarıyla güncellendi;16 Markdown dosyası/16 bağlantı doğrulandı. Bulut skill API'si salt okunur olduğundan buluttaki kurulu kopyaların değiştiği iddia edilmez. Kurallar gelecekte hiç hata olmayacağı garantisi vermez.

Fiziksel Poco/iPhone, gerçek Xbox/PlayStation kolu, Edge/Safari ve en ağır mobil sahneler yerelde test edilmedi. Yeni imzalı indirme paketi veya Drive eşitlemesi yayımlanmadı. Mission2–5 tamamlanmış sayılmaz; bu teslim Mission1'i geliştirir.
