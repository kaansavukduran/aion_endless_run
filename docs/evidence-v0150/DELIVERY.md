# 0.15.0 teslim raporu

Kayıt: 2026-11-13 01:10:39 — Europe/Istanbul.

[Canlı oyun](https://aionendlessrun.vercel.app/) · [0.15.0 indirmeleri](https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.15.0) · [Başarılı yayın iş akışı](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43314959959).

## Uygulananlar

- Boss zaferinden sonra 1,25 saniyelik güvenli dönüş, sürekli arka plan/koşu/takipçi mesafesi, hız geçişi, silahın ve boss göstergesinin sönmesi. Bitmek üzere olan güçler de geçiş bitene kadar donuyor.
- Normal düşmanlar tek vuruşta veya üstüne basınca yeniliyor. Yenmek 10 XP, üstüne basmak 15 XP, boss zaferi 100 XP veriyor. Her 100 XP koşu ustalık derecesini artırıyor; normal seviyeler yine 20 aktif saniyede yükseliyor. XP koşuya ait; tekrar başlayınca sıfırlanıyor.
- Sağ tık / F / varsayılan RB veya RT / telefondaki ayrı Şimşek düğmesi: 1500 birim uzunluğunda, iki yanda 92 birimlik alanda düz hat saldırısı. Her basış bir yük harcıyor. Yakın saldırı yük harcamıyor. Boss tabancası basılı ateş davranışını koruyor.
- Yarasa, balçık, kabuk böceği ve fırtına ışığı; bölgesel rastgele karşılaşmalar; Fener Ormanı ve Kor Sırtı ile altı biyom.
- Sıçrama tılsımı, şans parası ve buz feneri. Sıçrama gücü 9 saniye, iki kat kristal puanı 12 saniye, yaklaşan düşmanları yavaşlatma 8 saniye sürüyor. Karakter boyutlarını değiştirmiyorlar.
- AZ, DE, FR, JA, KO, ZH, ES, IT eklendi; TR/EN/CS ile toplam 11 dil. Her dilde 208 anahtar, saklanan tercih, desteklenmeyen dilde İngilizce ve çevrimdışı lisanslı fontlar. Uzun dil listesi ekrana sığıyor ve seçili dil görünür alana kayıyor.

Aion ve arkadaşlarının 40 özgün PNG dosyası byte düzeyinde korundu. Bölünmüş mobil kontroller, portre/yatay oynanış, gamepad eşlemeleri, çift zıplama/süzülme/depar, gecikmeli küçük koyun takipçileri, Fragaria ve kayıtlar korundu. [Değişiklikler ve gerçek nedenler](../UPGRADE-0.15.0.md).

## Gerçek doğrulama

- 13 Godot paketinde **3.452 kaynak/sahne kontrolü**, sıfır hata; son sürüm etiketinin CI kapısında yeniden geçti.
- **223 tarayıcı kontrolü**: 11 dil × iki yön; menü/ayar/başlat/duraklat/dönüş; dört karakterin gerçek animasyonu; dokunma, iptal, çoklu giriş ve döndürme; üç gerçek boss zaferi, çıkış hızı ve XP; rastgele normal koşuda altı biyom ve yeni güçler; Chromium/Firefox bozuk PCK, yeniden deneme, çevrimdışı kayıt ve 0.14.1 → 0.15.0 güncelleme; canlı Firefox.
- **11 paket/tanılama sözleşme testi**. Android tanılama satırı kesilmesi için uzun çok dilli kayıt, eksik parça, bozuk veri ve sıra testleri eklendi.
- Android API30 emülatöründe çevrimdışı gerçek ADB dokunuşlarıyla **7 giriş/yerleşim kontrolü**. Windows kurulum ve portable, Linux DEB/AppImage/portable ve macOS uygulama/DMG üretim/açılış kontrolleri son sürüm iş akışında geçti.
- **9 indirme paketi** ve makbuz/özet dosyaları yayımlandı. Dokuz dosyanın boyutu ve GitHub SHA-256 özeti makbuzla eşleşiyor. Yayımlanan APK ayrıca indirilip byte özeti ve sabit imzası doğrulandı. macOS portable ZIP indirilip CRC ve Intel/ARM64 başlığı kontrol edildi. İki Noto OFL lisansı yayımlanan APK içinde doğrulandı.

Son yayımlanan etiket/kaynak: `6c82b14965cbcdae943e148699ea70d263308c4e`. Sabit imzalı APK uygulama kaynağı: `f805e8d66d129f8828091474cfc4933fd19da91d`; etiketin sonraki değişiklikleri doğrulama belgeleri/CI/pasif sürücülerdir. Canlı Firefox testi üretim commit’i `6c82b14965cbcdae943e148699ea70d263308c4e`, web derlemesi `c9ea8e94854044a9` üzerinde yapıldı. Bu teslim raporunun sonraki dokümantasyon commit’i oyun kodunu değiştirmez.

## Sınırlar

Fiziksel Poco/Xbox/PS/iPhone, Safari veya ekran okuyucu testi yapılmadı. Canlı Firefox masaüstü Gecko üzerinde Android kullanıcı aracısı/dokunmayla denendi; çevrimdışı worker ayrı gerçek yerel testte doğrulandı. Çeviriler ana dili konuşan editör tarafından incelenmedi; Çince basitleştirilmiştir ve CJK için ortak SC biçimli çevrimdışı font kullanılır. macOS ad-hoc imzalıdır; noter/Developer ID, Windows Authenticode ve yerel iOS için sahibin Apple imzası yoktur. iPhone hedefi web/PWA’dır.

Drive için bu turda yeni eşitleme veya kaynak kopyası yapılmış gibi bir iddia yoktur; önceki teslimdeki Drive arşivleri korunur. Bu teslim GitHub geliştirmesi, Vercel yayını ve yeni indirme sürümüdür.
