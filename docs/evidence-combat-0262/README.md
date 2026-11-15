# 0.26.2 · Hedefli savaş düzeltmeleri

Başlangıç main `6e621ff4a803448caf73ac760ca0d594615a8a28`. Aynı Godot4.6.3, kayıt yapısı ve giriş eşlemeleri korunur.

- Korsanın eski yürüyüş kaynağında arka kol saç altında tamamen gizleniyordu; maske silinmesi değildi. Yeni6kare yalnız bu karakterin yürüyüşüne bağlanır. Diğer NPC pozları ve orijinal PNG değişmez. [Kaynak](../../assets/pirate-walk.png), [kayıt bilgisi](../../assets/PIRATE-WALK-PROVENANCE.json), [yeniden kayıt betiği](../../packaging/register_pirate_walk.py).
- Örümceğin özel güncellemesi ortak mermi/ip kontrolünü atlıyordu. Patlama yakındaki ipi çözer ve örümcek bağlı NPC'yi de hedef alır. Gizli NPC/kilitli kafes kuralları, beş saniye üst sınırı ve temasla ödül kuralı korunur.
- Dört araçta gerçek zıplama/iniş, havada fazladan zıplama engeli. Shell'in eski zıpla=dal davranışı kullanıcının yeni zıplama isteğiyle değişir. Kaynak namlu yerinden üçlü yayılım ve görünür piksel çekirdeği; iki yönde210birim uzaktaki küçük düşmana gerçek segment çarpışması sınandı. Hızlar/nişan ekseni ve3can değişmedi.
- Saçma980hız/1,15sömür; izleyen760/3,3s; mor spor520/1,4s. Eski değerler680/0,65;460/2,5;260/0,85 idi. Atış sayıları ve cephane tüketimi korunur. İzleyen mermi dönüş hesabında da yeni hız kullanılır.

[53taze kaynak paketi/37.960kontrol](source-results.json) ve [25normal girişle tarayıcı kontrolü](browser-results.json) başarılı; script/tarayıcı hatası0. Yerel web build `707dd5e1aabd6e4b`. [77yeni kontrol](../../tests/test_campaign_combat_patch.gd) fizik, gerçek mermi/isabet, patlamayla kurtarma ve pafta kayıtlarını sınar. Güncel araç namlu testleri9506kontrol geçirir; eski tek atış/dalış beklentileri yeni açık kullanıcı kararıyla güncellenmiştir.

[Sol yürüyüş](pirate-left.png) ve [araç zıplaması](vehicle-jump.png) gerçek oyun renderer'ından **açıkça kurulmuş durum fixture** görüntüleridir; normal kontrollerle bu sahnelere ulaşıldığı iddiası değildir. Toplam8görüntü incelendi. Fiziksel telefon/kol testi yapılmadı. Yayın/CI son commit'in kendi kaydından ayrıca doğrulanmalıdır.
