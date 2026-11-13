# 0.18.0 · Alçak takla, şarjlı Emre, kaydırmasız menüler

17 kaynak/sahne grubunda **8.492 kontrol**, gerçek Chromium girişlerinde **89 kontrol**, alt dizin üzerinde gerçek çevrimdışı yüklemede **3 kontrol**, web paketleme **7** ve Android kayıt ayrıştırma **4** testi geçti. [Makinece okunur sonuçlar](verification.json).

Beş kahramana toplam60 çizilmiş poz eklendi: diz bükme, yere yaklaşma, saat yönünde öne dönme, doğrulma. Basılı takla yalnız alçak dönüş pozlarında kalır. Sabit gövde/zemin referansı ve her karakter için tek ölçek kullanılır. Önceki46 PNG dosyasının byte düzeyinde aynı olduğu ayrıca doğrulandı. Eski paftalar silinmedi veya yeniden çizilmedi. Koyun takipçileri kendi gecikmeli yol kayıtlarını kullanır.

![Aion yere yaklaşarak öne döner](screenshots/aion-low-roll.png)
![Emre yerde tam şarj](screenshots/emre-full-charge.png)
![Emre yüksek sıçrama](screenshots/emre-high-leap.png)

Emre klavye, standart Gamepad API ve gerçek tarayıcı dokunmasıyla yerde şarj edildi, bırakılınca tam bir sıçrama yaptı. Kısa/orta/tam tutuşun gerçek tepe yükseklikleri artıyor. İptal edilen dokunma ve yön değişimi yanlış sıçrama üretmiyor. Gerçek CDP touchCancel ile, Godot'un iptali normal bırakma olarak ilettiği görüldü; DOM touchcancel yakalama fazında sahiplik temizlenerek düzeltildi. Chrome'un geçerli uzun dokunmada ürettiği uyumluluk pointercancel olayına ayrıca abone olunmuyor. [Girdi kaydı](charge-roll-inputs.webm) · [55 kontrol ve ölçülen yükseklikler](browser-charge-roll.json).

Menü sürücüsündeki ilk deneme, Godot'un düğüm adlarında noktayı alt çizgiye çevirmesi nedeniyle gerçek 200% seçeneğini yanlış adla arıyordu; doğru düğüm adıyla yeniden çalıştırıldı ve bütün sayfalar geçti. Bu bir uygulama arızası olarak raporlanmadı. Döndürmeden sonra testin fiziksel CDP parmağı da kaldırıldı; motorun sahipliği bırakması ile fiziksel girişin sonlandırılması ayrı doğrulandı.

![Büyük yazı, dikey ana menü](screenshots/main-large-393x873.png)
![Büyük yazı, yatay ana menü](screenshots/main-large-873x393.png)

Ana menü dört ekran ölçüsünde ve200% yazıda tek bakışta sığar. Uzun ayarlar açıkça sayfalıdır; bütün font/kol seçeneklerine gerçek Önceki/Sonraki dokunmalarıyla ulaşıldı. Sonuç işlemleri sayfalarda görünür kalır. Gizli autowrap Label ölçümü gerçek şekillendirme sonrası alınır; yazı/tema tercihi küçültülerek taşma saklanmaz. [9 menü/dil kontrolü](browser-menu.json).

[25 tabanca regresyonu](browser-firearm.json): beş karakterin tam tabancalı koşu döngüsü,5 mermi, boş şarjör,1 aktif saniyelik elle doldurma, gerçek boss hasarı, RB/X, baykuş süzülmesi, dört ayaklı kurt, dokunma iptali ve yön değişimi. Bu grup son web-only touchcancel daraltmasından önceki aynı uygulama mekaniğinde çalıştırıldı; yeni55'lik grup son daraltmayı kapsar. Dünya, düşman, fizik veya RNG enjekte edilmedi.9'luk menü grubunda açıkça belgelenen eski İtalyanca/tema/rekor kayıt fixture'ı kullanılır.

## Çevrimdışı ve platform sınırı

`/aion_endless_run/` alt dizininden gerçek ServiceWorker/CacheStorage kurulumu, normal oyunla kazanılmış rekorun çevrimdışı yeniden açılışta korunması ve internet kapalıyken tabanca atışı doğrulandı. Bu yerel alt dizin deneyi Pages üretim yayınının test edildiği anlamına gelmez. [Sonuç](offline-results.json).

Yerel tarayıcı denemeleri yazılımsal GPU ile Chromium'dur; fiziksel Poco/iPhone/kol testi değildir. Android dağıtım APK'sı aynı kalıcı imza veversionCode22 ile oluşturuldu, bytes/SHA/imza doğrulandı. CI'da gerçek Android emülatör girdileri, Windows/Linux/macOS paket kurulum/çalıştırmaları ve üretim Pages adresi tamamlandığında sonuçlar aşağıya eklenir. Vercel0.18.0 ilk adayı yayımladı (`c75d65b445ea55a7`, c9ab407); sonraki geniş sistem fontu düzeltmesi yeniden günlük kotaya takıldı. Kullanıcı ikinci adresi ve GitHub Actions kaynağını açıkça onayladı. İki origin'in kayıtları ayrıdır.

## Uzak ortamda bulunan geniş font regresyonu

İlk GitHub CI koşusu43349358325, yereldeki varsayılan fonttan daha geniş DejaVu Sans ile200%/960×540 düzeninde son karakter kartını ve üç dil seçeneğini ekran dışında buldu. Yerelde aynı gerçek fontla yeniden üretildi. Büyütülmüş yatay menüde karakterlere60%, ana eylemlere40% alan verildi; kart yüksekliği Label şekillendirmesinden ölçülüyor. Sistem dili, diğer11 dil ile aynı ızgarada: fazladan yüksek satır yok. DejaVu Sans ve Liberation Sans, TR/EN ve iki yön için348 ek kontrol eklendi. Son kaynak paketi8.492 kontrol geçti. Son menü tarayıcı deneyi ve gerçek alt-dizin çevrimdışı deneyi yeni `b22e878bec53d134` web çıktısında tekrar geçti.55 davranış ve25 tabanca kontrolünün önceki aday kapsamı ilgili JSON'da korunur; üretim davranışı ayrıca doğrulanır.
