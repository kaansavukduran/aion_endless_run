# 0.8.0 · Dört biyom, parkur ve izole boss sahnesi

- Ana koşu mesafesi dört biyomda döner; geniş ve okunur zemin boşlukları tek karşılaşma olarak ayrılmış güvenli aralıklarda üretilir. Ekranda yalnızca boyanmış karanlık bir alan değildir: yerdeki ayak gerçekten düşer, bir can kurtarırsa fiziksel kurtarma sıçraması olur.
- Bitkiler başlangıçta zorunlu eğitim eşyası gibi gelmez. Uzun, rastgele koşu aralıkları vardır; kalabalık noktada doğmaz. Ağız uyarısı 0,9 saniye, ardından tek ateş topu. Vurmak veya üstüne basmak işe yarar.
- Her 10. seviyedeki sarılma tamamlanınca `intro → fight → victory → run` geçişi gelir. Kutlamayı kapatan oyuncu da boss ile karşılaşır. Girerken normal karşılaşmalar ve mermiler temizlenir, güçler kalan süreleriyle saklanır. Sahne kayar ama ana mesafe durur; ikinci bir kilometre taşı aynı savaşta tetiklenmez.
- Robot 36 canla başlar; sonraki kilometre taşlarında sınırlı artış olur. Gerçek enerji mermileri can barını azaltır. Oyuncunun üç savaş canı ve darbe sonrası kısa koruması vardır. Uyarılı yüksek atış takla, alçak küre zıplama ister. Atışlar namludan çıkarak hedef yüksekliğine yaklaşır; karşıt kaçınma hareketleri aynı anda zorlanmaz.
- Her 0,19 saniyede en fazla bir enerji atışı; sağ tık/F/RB veya mobil Ateş et tutulabilir. Önceki tek basış yumruk kuralı normal koşuda sürer. Boss’ta görünmez normal yumruk hasarı çalışmaz.
- Zafer 500 + kilometre taşı seviyesi×10 puan verir; mermiler temizlenir, normal üretim için güvenli boşluk ayrılır, güçler geri gelir. Koyunların iz kaydı arenanın sabit ana mesafesinde şişmez; koşuya dönüşte yeniden başlatılır.
- Yeni karakter ölçüsü toplam poz yüksekliği değildir: ayrı dokulara alınan her siluet aynı anatomik baş/kulak referansıyla yerleştirilir. Yatay deparın başı büyütmesi ve atlas kenarında komşu kare parçalarının görünmesi giderilir. Kanat/ayak hareketi doğal sınır değişimi olarak kalır.

## Önceki sürüm notları

# 0.7.0 · Koşu ve savaşın tasarımı

## Güncel davranış

- Sekiz karşılaşma türü karışan torbadan gelir; güvenli mesafe sınırları içinde farklı aralıklar kullanılır. Seyrek ortam cüceleri de sonraki tehlike için boşluk ayırır.
- Saldırı kenar tetiklemelidir: bir basış bir vuruş. Her karakterin iki çizilmiş hareketi sırayla değişir; son 0,16 saniyede sonraki tek basış tamponlanabilir. Takla saldırıyı iptal eder; görünmez vuruş oluşmaz.
- Takla en az 0,68 saniyedir; beş çizilmiş dönme pozu döngü yapar. Dikey ölçek sıkıştırması yoktur. Takipçi koyunlar 112/224 piksel geriden aynı takla/zıplama yolunu izler.
- 900 mesafede bir seviye. Sekiz kutlama kimliği tekrarsız torba, dört efekt ardışık tekrarsız seçim kullanır. Her 10 seviyede yere iniş beklenir; 1 saniye dünya tamamen durur. Bekleyen kilometre taşları kuyrukta korunur. Sonra 2 saniye kalp ve 0,65 saniye koruma vardır. Kutlama kapalıysa seviye ilerler, duraklama oluşmaz.
- Mantar seçimi, ilk 20 saniye ve 45 saniye tekrar sınırından sonra uygun eşya fırsatı başına %2'dir. Ayarlanabilir %0–100 değeri saniye başına oran değildir. Diğer altı güç karışan torbadadır. Devlikte 0,18–1,30 saniye arasında düzensiz küçük cüce grupları ve en fazla 14 canlı dalga cücesi vardır. Süre bitince dalga cüceleri puan vermeden ayrılır; ortam cüceleri kalır. 4. seviyeden itibaren seyrek ortam cüceleri de çıkar.
- Baykuş akımı yukarı/ileri/çaprazdır. İleri hız katkısı gerçek dünya ilerlemesine uygulanır; havada karakterin resmini sağa kaydıran sahte bir etki değildir.
- Mantar renkleri yavaş HSV dalgalarıdır. Kamera en yüksek şiddette yaklaşık %1,2–2,8 yakınlaşır, 0,46 dereceye kadar döner ve 4 piksel kayar. Şiddet bağımsız %0–100; hareket ve ekran efektleri ayrıca kapanabilir. Hızlı tam ekran stroboskop yoktur.

## Önceki tasarım araştırması (0.5.0 tarihsel kayıt)



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

0.5.0’da ilk yakın mantar güç kullanımını öğretiyordu; bu davranış 0.7.0’da yukarıdaki nadir olasılıkla değiştirildi. Sürekli hız artışına ek olarak yumuşak tempo değişimleri vardır. Şimşek havası çevreseldir; önlenemeyen rastgele bir ölüm yaratmaz. 0.5.0’da cüceler yalnızca mantar dalgasında doğuyordu; 0.7.0 ortam cüceleri de ekler. Daha sonra kısa süre mevcut sahneden geçebilirler. Kahramanın devliği biterken bir koruma aralığı verilir.

## Sonraki sürümler için fikirler (bu sürümde yok)

- Hesap gerektirmeyen paylaşılabilir meydan okuma kodları ve aynı rotayı yeniden oynama.
- Karganın evrene uygun buz/kül renk varyantları; önce mevcut tek düşman ailesinin okunabilirliğini korumak.
- İsteğe bağlı kurtarma rotaları ve riskli kristal yayları; temel ilerlemeyi kilitlemeyen kozmetik ödüller.
- Kalabalık yaratmadan kısa arazi şekilleri ve özel biyom geçişleri.

Bu fikirler uygulanmış özellik olarak sunulmaz. Bu sürümün kabul koşulları gerçek saldırı hasarı, düşmana basma, eğilme açıklığı, geçici güçler, değişen karşılaşmalar, iki dil, yatay telefon düzeni ve eski kayıtların korunmasıdır.
