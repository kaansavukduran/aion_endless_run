# AIONIA v1.4 · Doğrulama ve teslim kapıları

Bu dosya 0.14.0 kaynak commit'i hazırlanırkenki kayıttır. [Makine sonuçları ve gerçek görüntüler](evidence-v014/README.md). Yayın sonrasında native/URL/paket sonucu, sürümün `BUILD-RECEIPT.json` dosyasında ve Drive teslim raporunda tutulur; kaynak öncesi tahmin başarılı test diye yazılmaz.

| Kapı | Durum | Kanıt / kapsam |
| --- | --- | --- |
| A · Kaynak denetimi | PASS | Güncel main/c54cff0; önceki 03fd1f4 referansı; Godot 4.6.3; Drive 9 JPEG ve 11 eski PNG; lisans/provenans |
| B · Tasarım | PASS | AIONIA_STANDARD, DESIGN_BRIEF, ART_BIBLE, LORE_LINKS, CONTROLS |
| C · Oynanabilir dilim | PASS | Gerçek menü → koşu → zıplama/saldırı/takla → yenilgi/yeniden koş; boss antrenmanı ve üç gerçek zafer |
| D · İçerik | PASS | Dört kahraman PNG'leri korunur; mevcut biyomlar/yetenekler; Fragaria arka planında sekiz farklı mevcut kutlama kimliği |
| E · Otomasyon | PASS | 12 kaynak/sahne süiti, 2.539 kontrol; 184 tarayıcı kontrolü; 5 paket sözleşme testi |
| E · Fiziksel cihaz / ekran okuyucu | NOT TESTED | Fiziksel Poco X7/Firefox, Xbox/PS donanımı ve ekran okuyucu bu ortamda bağlı değil |
| F · Bu kaynak commit'inin yayımlanması | NOT TESTED | Bu kayıt yazıldıktan sonra GitHub native CI ve Vercel çalışır; sonuca makbuz/teslim raporundan bakılmalı |

## Önceki hataların regresyonları

| Kayıt | Durum | Gerçek kontrol |
| --- | --- | --- |
| AER-001 Aion yatay kayma | PASS | Yakın iris örnekleri; fizik ankrajı; tam 7 koşu karesi tarayıcıda sabit bakış X |
| AER-002 baykuş uçuşu | PASS | Agility/fidelity kaynak kontrolleri; gerçek süzülme örnekleri aynı X; hücum ayrı |
| AER-003/004 dokunma/takla | PASS | Gerçek CDP iki parmak, iptal, tek saldırı, aşağı kaydırma; ortak eylem; normal kargaya gerçek hasar kaynak/sahnede |
| AER-005/006/007 arayüz | PASS | TR/EN/CS menü/sonuç; gerçek uzun ayar kaydırması; %200 metinde erişim; başlık/kart içeriği sınır denetimleri |
| AER-008 yön/perf | PASS / NOT TESTED | İki yönde ve tabletlerde gerçek tarayıcı; koşu durumu korunur. Fiziksel telefon performansı ölçülmedi |
| AER-009 mantar cüceleri | PASS | Sabit 128 tohumda toplam 3340 → 1634 (%48,92); normal ortam cücesi ayrı |
| AER-010 seviye | PASS | 20 aktif saniye, mesafe kapısı yok; farklı dt, duraklama/sarılma/boss/uzun sekme çerçevesi |
| AER-011 Fragaria | PASS / NOT TESTED | 100/200/300 eşik ve boss uygunluğu, ödül/puan yok, sekiz arka figür ve temizlenme kaynak/sahne. Doğal 100 seviyelik tam koşu oynanmadı |
| AER-012 yükleme | PASS | Chromium ve gerçek masaüstü Gecko: 10 segment, bayttan yüzde, gerçek sürüm, bozuk/kısa/206/HTML PCK reddi, tekrar dene, cache onarımı, çevrimdışı |
| AER-013 gamepad | PASS / NOT TESTED | Sanal Gamepad API: Xbox/PS profilleri, ana/ayar/durak/sonuç, üç boss, yeniden atama ve bağlantı kes/bağla. Fiziksel donanım denenmedi |

## Erişilebilirlik ve platform sınırları

İlk açılış koyu/sistem yazısı; açık/koyu/sistem, pixel alternatifi, %100–200 menü metni, azaltılmış dekoratif hareket saklanır. Kaydedilmiş açık tercihler korunur. Web normal yazısı, OS fontu tarayıcı sandbox'ından açılamazsa ölçülen Open Sans SemiBold yedeğini kullanır. Logo pixel kalır.

18 koyu/açık token çifti için metin ≥4,5:1 ve sınır ≥3:1 hesaplandı; bu tüm sahnelerin WCAG sertifikası değildir. Godot kontrollerine erişilebilir ad verildi. Web menüsündeki semantik düğme/range karşılıkları aynı gerçek kontrole yönlenir; klavyeyle denenmiştir. Ekran okuyucu ile uçtan uca kullanım ayrıca NOT TESTED. Ses üretimi mevcut akışta korunur; fiziksel hoparlör/dokunsal motor testi yapılmadı. Titreşim varsayılan kapalıdır.

Web açılışı doğrulanmış PCK indirme oranını, native açılış ResourceLoader ilerlemesini gösterir. Hazırlama/doğrulama belirsizdir; sabit sahte yüzde veya zorunlu bekletme yoktur. İşletim sisteminin motor öncesi splash davranışı bütünüyle özelleştirildiği iddia edilmez. Çilek referans türevidir; resmî nihai logo onayı diye sunulmaz.

Native CI tam ana sahne açılmadan biten 5 kare denemesi yerine `-- --aion-smoke-test` ile gerçek `AION_READY` aşamasına ulaşır. Android emülatör testi sabit piksel tahmini yerine pasif yerleşim kayıtlarını okuyup gerçek ADB dokunmaları yapar. Fiziksel telefon/sensör dönüşü aynı test değildir. iOS native imza/TestFlight, macOS Developer ID/noter ve Windows Authenticode sağlanmadı.

## Tekrar çalıştırma

`godot --headless --script tests/test_aionia.gd`; diğer 11 kaynak süiti `.github/workflows/build.yml` içinde. `python3 tests/test_web_packaging.py`. Web çıktısı `python3 packaging/build_web.py` ile üretilir. Tarayıcı kanıtları `tests/browser_aionia.py`, `browser_runner_ux.py`, `browser_panels.py`, `browser_boss_hud.py`, `browser_encounters.py`, `browser_loader.py` ve `browser_upgrade.py` komutlarının gerçek çıktılarıdır. Firefox WebGL için bu bulut ortamında headed Xvfb kullanıldı; Android UA fiziksel telefon sayılmaz.
