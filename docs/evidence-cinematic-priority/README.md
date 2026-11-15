# Ara sahne katman önceliği · 0.26.1

Yeni hareket gövdesi gerçek `Game.update_friend()` zincirinin sonunda çalışıp eski tepki/sarılma pozlarını ve verilen kırmızı silahı örtüyordu. Seçicinin ara sahne önceliği düzeltildi. Ayça eski erkek tavşana dönüşmez; iki koyun takipçisi kendi yeni iki ayaklı çiziminde görünür kalır.

- [Kalıcı gerçek ana sahne testi](../../tests/test_cinematic_heroes.gd): dört karakter, hareket açık/kapalı, üç konuşma anı, gerçek sarılma geçişi, opak kaynak piksel karşılaştırması, yatay yüz kaydı, zemin ve verilen silah. [Önceki 292 hata](selector-before.log) korunur.
- [52 paketin taze kaynak sonucu](source-results.json): 35.721 kontrol başarılı; `cinematic_heroes` 728/0.
- [12 native sahne makbuzu](native-scenes.log) ve [özet/hashler](verification.json). Bunlar gerçek ana sahnede **açıkça kurulmuş durum/render fixture** görüntüleridir; normal oynanışla boss'a ulaşma iddiası değildir. Yakalama seçici düzeltmesinden sonra, patch sürümü artırılmadan önce yapıldı; logdaki 0.26.0 bu yüzden korunur.
- [Aion tepki](aion-shock.png), [Ayça silah teslimi](rabbit-gift.png), [Kutsanmış ve takipçileri sarılma sırasında](sheep-hug.png).

Arcade rotaları ve fizik bu yamada değişmez. Önceki [üç normal girişle tam rota](../M1-FLOW-VALIDATION.md) sonucu kendi donmuş build'ine aittir. Yeni public sürümün doğrulaması ayrı dağıtım kimliğine bağlanır. Fiziksel telefon/gerçek kol testi yapılmış sayılmaz.
