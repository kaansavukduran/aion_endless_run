# 0.21.0 doğrulaması

Başlangıç: temiz `main`,16c40b3; güncel kaynak korunarak Godot4.6.3 üzerinde geliştirme. Fragaria Unslop uygulandı. Hikâye aralığı5 seviye; seviyeler15 aktif saniye, sarılmalar10 seviyede bir kalır. Kırmızı silah koşu boyunca iki boss hasarı verir, yeni koşuda sıfırlanır. Diyalog otomatik ilerlemez: Devam/Atla kullanılır. Antrenman hızlı girişini korur.

[Kaynak/gerçek sahne sonuçları](source-results.json) · [Yerde ayak hizası: ölçülmüş önce/sonra](ground-registration.json) · [Teslim durumu](verification.json).

Neden kanıtlandı: önceki yerde koşma/ateş karelerinin Y kökü yüzü sabit tutuyordu. Toplanan bacaklar ayakla yol arasında boşluk bırakıyordu. Artık yerdeki çizimde X yüz probuyla, Y opak ayak sınırıyla kayıtlıdır. Fizik X, fizik Y ve tek karakter ölçeği oynatılmaz. Havada/süzülmede sabit gövde kaydı korunur. Namlu da seçilen kareye göre izlenir.

Temiz GitHub ortamında20 Godot grubu/12013 kontrol PASS; `test_boss_story.gd`5/10/15…300 programını, donan sayaçları, gerçek iki hasarlı mermiyi, sıfırlanmayı, kol A düğmesinin gerçek Continue işlemini ve11 dil×2 metin ölçeği×3 ekran oranında görünen diyalog/işlem sınırlarını denetler. Bunlar açık deterministik sahne fixture’larıdır. [138 normal giriş kontrolü](browser-results.json), [11 doğal5. seviye konuşma/kırmızı silah/zafer kontrolü](natural-results.json), [13 DPR3 kontrolü](touch-results.json) ve [4 gerçek kaydırma kontrolü](swipe-results.json) PASS. Son doğal koşu, yardımcı kızın tabancayı ön katmanda teslim ettiği son runtime üzerinde tekrar oynandı; atanmış test seviyesi kullanılmadı.

`fixture-*.png` görselleri gerçek renderer ile, açıkça atanmış sahne durumundan alınmıştır; normal oynanmış koşu kanıtı değildir. Yeni şaşırma paftası mevcut karakter kimliklerini referans alır; bu teknik doğrulama, kullanıcının sanat onayı yerine geçmez. Kaynak PNG değiştirilmeden bölge/span kaydı kullanılır. İlk nötr sütundaki kaynak kenarına değen kuyruklar oynatılmaz; eksiksiz ikinci nötr kullanılır.

Regresyonlar: AER001 yatay Aion kayması; AER002 baykuş süzülmesi; AER006 HUD alanı; AER014 split touch/kol girişleri; AER015 mobil yükleyici ve kayıtlar. Yeni kontroller yerde tüm altı kahramanın opak ayak sınırını, aynı fizik kökünü ve tek ölçeğini denetler. Yeni dokunma sistemi, loader, origin kayıtları veya motor kurulmadı.

Fiziksel Poco/iPhone/kol denenmedi. Chromium CDP dokunma ve emüle Gamepad API, fiziksel cihaz gibi sunulmaz. Mac ad-hoc; native iOS için sahibinin Apple imzası gerekir. Yayın, CI ve paket özetleri tamamlandıkça teslim kaydı güncellenir.

Yayın işlemi, yalnız `release-publication/v0.21.0` dalının açık sürüm talebiyle de başlatılabilir. Kaynak CI kimliği43513378584 ve sürüm0.21.0 sabittir; beş platform kapısı ve runtime eşitliği geçmeden etiket/taslak oluşturulmaz. Eski etiketler/yayınlar taşınmaz veya üstüne yazılmaz.11 sunucu özeti doğrulanmadan taslak kamuya açılmaz. Bu yol, yerel CLI oturumu sona erdiğinde bağlı GitHub aracıyla aynı denetimli teslimi tamamlar.
