# Vercel ile ücretsiz web oyunu

Bu depodaki `vercel.json`, Godot oyununu gerçek kaynak koddan derleyip `build/web` klasörünü yayımlar. Sunucu, veritabanı, API anahtarı veya MCP gerekmez. Vercel Hobby kişisel projeler için ücretsizdir ve planın kullanım sınırlarına tabidir. Windows/Android gibi indirilebilir paketler GitHub Releases'ta kalır.

## E-posta hesabına GitHub bağla

1. Vercel panelinde **Import Project → Import** seç.
2. **Import Git Repository → Continue with GitHub / Install GitHub** seç.
3. GitHub'da **Only select repositories** seç. `kaansavukduran/aion_endless_run` deposunu işaretle, **Install & Authorize** düğmesine bas.
4. Vercel'e dön ve `aion_endless_run` satırındaki **Import** düğmesine bas.
5. **Framework Preset: Other**, **Root Directory: .** olsun. Depodaki yapılandırma **Build Command: python3 packaging/build_web.py** ve **Output Directory: build/web** ayarlarını belirler. Ortam değişkeni gerekmez.
6. **Deploy** düğmesine bas. İlk derlemede resmi Godot dosyaları indirildiği için birkaç dakika sürebilir. Başarılı olunca Vercel'in gösterdiği `.vercel.app` adresini aç. **Koşuya başla / Start running** düğmesini görmelisin.

GitHub listesi boşsa Vercel'de **Adjust GitHub App Permissions** bağlantısıyla aynı deponun erişime açıldığını kontrol et. Sonraki `main` gönderimleri aynı Vercel projesini otomatik günceller. Özel alan adı satın almak gerekli değildir.

## Çevrimdışı ve güncelleme

Web sürümü ilk tam yüklemede dosyaları HTTPS üzerinden indirir; servis çalışanı bu dosyaları çevrimdışı kullanım için önbelleğe alır. Kurulabilir oyun paketleri ilk açılışta da internete ihtiyaç duymaz. 0.3.0 eski servis çalışanının önbelleğinden otomatik geçiş yapar. İlk ziyaretinde güncelleme kontrolü için internet açık olsun. Sonraki sürümlerde koşuyu bölmeden **Yeni sürüm hazır · Güncelle** düğmesi belirir; düğme önce oyunu duraklatıp kaydeder, ardından yeni sürümü açar. Rekor ve ayarlar silinmez. Sol üstte sürüm numarası görünür. Oyun motoru/paftalar içerik kimliğine göre ayrı dosya adları kullanır. Rekor ve tercihler alan adına ait yerel kayıtta saklanır; farklı alan adı veya tarayıcı ayrı kayıt kullanır.

İlk yayının başarılı olması, oyun kontrolleri ve çevrimdışı yüklemesi gerçek `.vercel.app` adresinde de doğrulanmalıdır. Depoda yapılandırmanın bulunması tek başına yayımlanmış bir Vercel adresi olduğu anlamına gelmez.

## Bu proje için tamamlanan bağlantı

Canlı oyun: https://aionendlessrun.vercel.app/ . Kullanıcı GitHub erişimini bağladı ve proje Other + kaynak derleme komutuyla yayımlandı. Yeni main gönderimleri Vercel tarafından otomatik yayımlandı. Yeni sürümler aynı adreste açılır; indirme paketleri GitHub Releases içindedir.

## 0.13 Fragaria splash

packaging/web_splash.html supplies responsive separate logo, brand text, progress and actual version. web_updates.py fingerprints the bundled logo/font and includes them in the verified offline manifest. The PCK byte percentage is real; verification/engine preparation is indeterminate. Keep web_boot.js integrity checks/retries/fixed virtual PCK path and deferred sequential offline installation. Upright portrait/landscape controls replace forced orientation; no automatic fullscreen switch interrupts the first touch.
