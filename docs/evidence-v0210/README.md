# 0.21.0 doğrulaması

Başlangıç: temiz `main`,16c40b3; güncel kaynak korunarak Godot4.6.3 üzerinde geliştirme. Fragaria Unslop uygulandı. Hikâye aralığı5 seviye; seviyeler15 aktif saniye, sarılmalar10 seviyede bir kalır. Kırmızı silah koşu boyunca iki boss hasarı verir, yeni koşuda sıfırlanır. Diyalog otomatik ilerlemez: Devam/Atla kullanılır. Antrenman hızlı girişini korur.

[Kaynak/gerçek sahne sonuçları](source-results.json) · [Yerde ayak hizası: ölçülmüş önce/sonra](ground-registration.json) · [Teslim durumu](verification.json).

Neden kanıtlandı: önceki yerde koşma/ateş karelerinin Y kökü yüzü sabit tutuyordu. Toplanan bacaklar ayakla yol arasında boşluk bırakıyordu. Artık yerdeki çizimde X yüz probuyla, Y opak ayak sınırıyla kayıtlıdır. Fizik X, fizik Y ve tek karakter ölçeği oynatılmaz. Havada/süzülmede sabit gövde kaydı korunur. Namlu da seçilen kareye göre izlenir.

Temiz GitHub ortamında20 Godot grubu/12013 kontrol PASS; `test_boss_story.gd`5/10/15…300 programını, donan sayaçları, gerçek iki hasarlı mermiyi, sıfırlanmayı, kol A düğmesinin gerçek Continue işlemini ve11 dil×2 metin ölçeği×3 ekran oranında görünen diyalog/işlem sınırlarını denetler. Bunlar açık deterministik sahne fixture’larıdır. [138 normal giriş kontrolü](browser-results.json), [11 doğal5. seviye konuşma/kırmızı silah/zafer kontrolü](natural-results.json), [13 DPR3 kontrolü](touch-results.json) ve [4 gerçek kaydırma kontrolü](swipe-results.json) PASS. Son doğal koşu, yardımcı kızın tabancayı ön katmanda teslim ettiği son runtime üzerinde tekrar oynandı; atanmış test seviyesi kullanılmadı.

`fixture-*.png` görselleri gerçek renderer ile, açıkça atanmış sahne durumundan alınmıştır; normal oynanmış koşu kanıtı değildir. Yeni şaşırma paftası mevcut karakter kimliklerini referans alır; bu teknik doğrulama, kullanıcının sanat onayı yerine geçmez. Kaynak PNG değiştirilmeden bölge/span kaydı kullanılır. İlk nötr sütundaki kaynak kenarına değen kuyruklar oynatılmaz; eksiksiz ikinci nötr kullanılır.

Regresyonlar: AER001 yatay Aion kayması; AER002 baykuş süzülmesi; AER006 HUD alanı; AER014 split touch/kol girişleri; AER015 mobil yükleyici ve kayıtlar. Yeni kontroller yerde tüm altı kahramanın opak ayak sınırını, aynı fizik kökünü ve tek ölçeğini denetler. Yeni dokunma sistemi, loader, origin kayıtları veya motor kurulmadı.

Fiziksel Poco/iPhone/kol denenmedi. Chromium CDP dokunma ve emüle Gamepad API, fiziksel cihaz gibi sunulmaz. Mac ad-hoc; native iOS için sahibinin Apple imzası gerekir. Yayın, CI ve paket özetleri tamamlandıkça teslim kaydı güncellenir.

Yayın işlemi, yalnız `release-publication/v0.21.0` dalının açık sürüm talebiyle de başlatılabilir. Kaynak CI kimliği43513378584 ve sürüm0.21.0 sabittir; beş platform kapısı ve runtime eşitliği geçmeden etiket/taslak oluşturulmaz. Eski etiketler/yayınlar taşınmaz veya üstüne yazılmaz.11 sunucu özeti doğrulanmadan taslak kamuya açılmaz. Bu yol, yerel CLI oturumu sona erdiğinde bağlı GitHub aracıyla aynı denetimli teslimi tamamlar.

0.21.0 kamuya yayımlandı: [oyna · Pages](https://kaansavukduran.github.io/aion_endless_run/) · [oyna · Vercel](https://aionendlessrun.vercel.app/) · [dokuz paket + iki makbuz](https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.21.0).

[Temiz kaynak ve platform CI](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43513378584):20 grup/12013 kontrol; Windows/Linux/macOS paket açılışları ve11 Wi-Fi kapalı native Android girişi PASS. Android emülatörü disposable test-key APK kullanır; kamu APK'sının mevcut kalıcı imzası, sürüm25, tam byte özeti ve iki güncel kaynak provenance dosyası ayrıca doğrulanır. Fiziksel cihaz sonucu değildir.

[Canlı tarayıcılar](live-browser-results.json): iki origin×Chromium/Firefox toplam40 PASS; Gecko headed, Android UA ile çalışır. Bu CA-doğrulamalı tanı sürücüsü SW'yi kapatır, bu nedenle [gerçek çevrimdışı kayıt testi](offline-results.json) ayrı tutulur. [Kamu web arşivinin19 dosyası](offline-archive.json), aynı service-worker testindeki CI dosyalarıyla eşleşir. [Dokuz kamu paket özeti, indirilen APK ve macOS universal ZIP/CRC](public-packages.json) PASS. Toplam209 tarayıcı kontrolü kaydedildi.

Mac DMG'nin ilk CI denemesi `hdiutil: Resource busy` ile başarısız oldu; yalnız ilgili iş yeniden çalıştırıldı ve ardından gerçek paket açılışı geçti. İlk yayın taslağı oluşturuldu, fakat tag üzerinden taslak okuma404 döndü. Aynı güvenlik kapılarıyla tekrarında mevcut taslak listeden bulundu,11 dosya sunucu özetinden doğrulanıp kamuya açıldı. Sonraki taslak okuması listeden yapılacak şekilde düzeltildi. Yayınlanan eski sürümlere veya etiketlere dokunulmadı.

Vercel önce kota hatası bildirdi; daha sonra0.21.0 build`a1477e9143d34430` kamuya geldi. Pages build`020a6c0cc31d0fdc`. İkisi de gerçek tarayıcıda doğrulandı. Farklı Godot dışa aktarımlarının içerik parmak izleri farklıdır; aynı runtime kaynakları kullanılır. İki origin'in rekorları ayrıdır. Native iOS imzası, fiziksel Poco/iPhone/Safari veya fiziksel oyun kolu test edilmiş sayılmaz.
