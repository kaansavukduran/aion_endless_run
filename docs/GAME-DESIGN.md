# 0.5.0 · Koşu macerasının tasarım notları

Yetkili proje: `kaansavukduran/aion_endless_run`. Bu turda klasik zıplama akışını saldırı, eğilme ve kısa güç anlarıyla genişlettik. Kontroller Space/Zıpla, sol tık/J/Vur, aşağı ok/S/Ctrl/Eğil. Eski karakter yetenekleri korunur.

## Araştırmadan seçilen kararlar

[Sure Footing geliştiricisinin üretim sistemi yazısı](https://www.gamedeveloper.com/design/keep-running-procedural-level-generation-in-sure-footing), çeşitliliği yalnızca rastgele sayılarla değil, tasarımcının sınırladığı üretim parametreleri ve değişen tempo ile ele alıyor. Buradan aldığımız tasarım kararı: beş karşılaşma türünü karışan torbadan seçmek, aralıkları geniş bir mesafe aralığında değiştirmek ve en yüksek hızda da zıplama için boşluk bırakmak. Tamamen rastgele, kaçınılmaz engel yığınları üretmiyoruz.

[Microsoft XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) kamera ve hareketli görsel ayarlarının kontrol edilebilmesini öneriyor. Bu nedenle mantar kamerası en fazla yaklaşık 0.23 derece döner, yakınlaştırması %1.2 ile, kayması iki mantıksal piksel ile sınırlıdır; arayüz sabit kalır. Hareket ve ekran efektleri ayrı ayarlardır.

[Microsoft XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118), parlaklık farkını, tekrar sıklığını ve parlayan alanı azaltmayı öneriyor. Şimşek bu yüzden uzak gökyüzünde küçük bir çizim ve tek yumuşak sönüş kullanır; tam ekran, hızlı tekrarlayan beyaz/kırmızı flaş yoktur.

## Bu sürümde uygulanan zenginleştirme

| Öğe | Oyuncunun kararı | Geri bildirim |
| --- | --- | --- |
| Alçak karga | Eğil, zamanında vur veya üstüne bas | Kanat döngüsü, dalış uyarısı, tüy/yıldız yenilme kareleri |
| Yüksek karga | Yerden güvenle geç veya zıplayıp puan için saldır | Ayrı uçuş yüksekliği ve saldırı alanı |
| Alçak dal | Aşağı/S/Eğil tut; devken kır | Eğilme paftası, açıklık işareti |
| Dev mantar | Gücü topla, kısa cüce dalgasında saldır veya sek | Büyüme, süre, hafif renk/kamera, özgün kırmızı şapkalı cüceler |
| Şimşek kristali | Sonraki saldırıyı zincirleyen iki yük kazan | Yük sayısı, gerçek uzak hedeflere çizilen şimşek |
| Zaman kumu / kanatlı çizme | Kısa süreli yavaşlama / hızlanma | Geri sayım ve gerçek hız yüzdesi |
| Kalkan / mıknatıs / can yaprağı | Bir darbe koruması / kristal çekme / sürü canı | Güç adı ve süre, kalkan kırılma geri bildirimi |
| Üstüne basma kombosu | Yere inmeden düşmandan düşmana sek | Artan gerçek puan ve kombo bildirimi |
| Kısa koşu hedefleri | Düşman yen, üstüne bas veya güç topla | Tamamlanan/toplam; tek seferlik +100 puan |
| Yağmur, kar, kum, fırtına | Görsel koşulları oku | İsim, parçacıklar ve seyrek gök şimşeği |
| Gecikmeli koyunlar | Liderin zıplamasını yönet | 112 ve 224 piksel geriden aynı yolu takip; başlangıçta yaklaşık 0.35 ve 0.70 saniye gecikme |

İlk yakın mantar güç kullanımını öğretir; sonraki eşyalar karışık torbadan gelir. Sürekli hız artışına ek olarak yumuşak tempo değişimleri vardır. Şimşek havası çevreseldir; önlenemeyen rastgele bir ölüm yaratmaz. Cüceler yalnızca mantar dalgasında doğar. Daha sonra kısa süre mevcut sahneden geçebilirler. Kahramanın devliği biterken bir koruma aralığı verilir.

## Sonraki sürümler için fikirler (bu sürümde yok)

- Hesap gerektirmeyen paylaşılabilir meydan okuma kodları ve aynı rotayı yeniden oynama.
- Karganın evrene uygun buz/kül renk varyantları; önce mevcut tek düşman ailesinin okunabilirliğini korumak.
- İsteğe bağlı kurtarma rotaları ve riskli kristal yayları; temel ilerlemeyi kilitlemeyen kozmetik ödüller.
- Kalabalık yaratmadan kısa arazi şekilleri ve özel biyom geçişleri.

Bu fikirler uygulanmış özellik olarak sunulmaz. Bu sürümün kabul koşulları gerçek saldırı hasarı, düşmana basma, eğilme açıklığı, geçici güçler, değişen karşılaşmalar, iki dil, yatay telefon düzeni ve eski kayıtların korunmasıdır.
