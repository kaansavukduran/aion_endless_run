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

Web sürümü ilk tam yüklemede dosyaları HTTPS üzerinden indirir; servis çalışanı bu dosyaları çevrimdışı kullanım için önbelleğe alır. Kurulabilir oyun paketleri ilk açılışta da internete ihtiyaç duymaz. Yeni web sürümü gelince sayfayı yeniden yükle. Rekor ve tercihler alan adına ait yerel kayıtta saklanır; farklı alan adı veya tarayıcı ayrı kayıt kullanır.

İlk yayının başarılı olması, oyun kontrolleri ve çevrimdışı yüklemesi gerçek `.vercel.app` adresinde de doğrulanmalıdır. Depoda yapılandırmanın bulunması tek başına yayımlanmış bir Vercel adresi olduğu anlamına gelmez.
