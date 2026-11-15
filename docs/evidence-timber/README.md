# 0.27.1 · Kutu ve ahşap platform

Başlangıç: temiz main `2a20d2f1206bd4e7b1021c463cda0a55fb540e1d`, Godot 4.6.3.

Oyuncunun gösterdiği ikmal kutusu, üç düz şekille çiziliyordu; platform kirişinin yüzeyi de düz renk şeritlerdi. Görsel dil bölümün ayrıntılı ahşap/orman çevresiyle uyuşmuyordu. Bu bir görsel bulgudur; kutu veya platform fiziği bozuk diye yorumlanmadı.

## Uygulanan değişiklik

Özgün, yerelde çizilmiş küçük bir atlas eklendi: ahşap kapak ve çerçeve, damar/düğüm detayları, perçinli demir köşeler; üç kiriş yüzeyi, uç kuşakları, direk, taban bağlantısı ve iki yönlü payanda. [Çizim kaynağı](../../packaging/draw_campaign_timber.py), [kaynak bilgisi](../../assets/CAMPAIGN-TIMBER-PROVENANCE.json).

[Ortak çizici](../../scripts/campaign_timber_art.gd) kaynak pikselini bir oyun birimi olarak kullanır. Kirişin son parçası kesilir, esnetilmez. Kutu aynı 44×42 görünür alanı ve alt hizayı kullanır. Platformun üst sırası mevcut tek yönlü çarpışmanın Y'sindedir; direkler gerçek zemine kadar uzanır, boş çukurda zeminsiz ayak üretilmez. Uzun köprüler aralıklı taşıyıcılar kullanır. Platformun devre dışı kalma/kaldırılma kuralları korunur.

Oyun dünyası, fizik, kutu hasarı/ödülü, rota, kontroller, karakter paftaları, dil ve kayıt biçimlerine dokunulmadı. Sürüm ve paket adları 0.27.1, mobil derleme numarası34 olarak birlikte güncellendi.

## Yerel doğrulama

- Mevcut `campaign`, `campaign_routes`, `campaign_rewards_sweep`, `campaign_combat_patch` paketleri: **793 kontrol, sıfır hata**. [Makbuz](focused-source-results.json). Çizimi taklit eden yeni birim testi eklenmedi; mevcut kutu açma, fiziksel rota ve giriş regresyonları kullanıldı.
- Yükleyici/paketleme için 7, Android paket sözleşmeleri için 27, macOS DMG için 3 mevcut Python kontrolü başarılı. İlk uzak paket kontrolü menüdeki ikinci sürüm sabitinin 0.27.0 kaldığını yakaladı; `scripts/game.gd` sabiti 0.27.1 olarak eşitlendi ve aynı sözleşme kontrolü yeniden geçti.
- Atlas yeniden üretildiğinde aynı SHA-256 verdi; dış görsel/model girdisi yoktur.
- [Önce](before.png) ve [sonra](after.png) aynı kamera ve geometriyle gerçek oyun motorunda render edildi. [Uzun köprü](long-bridge.png), [dikey](portrait.png), [yatay](landscape.png) de incelendi. Bunlar **açıkça kurulmuş renderer fixture'larıdır**, normal kullanıcı girdileriyle bu noktalara ulaşıldığı iddiası değildir.
- İlk yerel screenshot yardımcısı hedef dizin yokken PNG yazamadı; çıktı dizini ve yazma sonucu denetimi eklendi. Bu, oyun hatası veya başarılı görsel kanıt diye kaydedilmedi. Buradaki son dört görüntü gerçek yazma sonucu OK denetimiyle alındı.

Normal web giriş testi ve son uzak CI/yayın durumu, son commit/derleme kimliğiyle teslim raporunda ayrıca belirtilir. Fiziksel telefon veya fiziksel kol denendiği iddia edilmez.

Fragaria Unslop, bu iki nesnenin görsel kimliği ve yüzey/zemin uyumu için uygulandı. Yeni bir genel AIONIA standart uyumluluğu iddiası yoktur.
