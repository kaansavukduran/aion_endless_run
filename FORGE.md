# Forge · Aion Endless Run

Yetkili kaynak: https://github.com/kaansavukduran/aion_endless_run · `main`.

Yeni bağımsız Godot 4.6.3 oyunu. FireAxolotl kaynaklarına değişiklik yapılmadı. Kaynak PNG'ler değiştirilmeden alındı ve provenance kayıtları korundu. Aion 6×8 koşu paftası gerçek karelerini kullanır. 0.2.0 için wolf/sheep/owl kimliklerinden yeni sağa bakan 6×6 koşu/zıplama/süzülme paftası üretildi. Orijinal paftalar korunur; yeni PNG değiştirilmeden çizilir, hücre taban çizgileri kayıtlıdır.

Ana akış: Space/sol tık/dokunma zıplama, Esc duraklatma; karakter seçimi, ayarlar, gerçek skor ve kristaller, kalıcı rekor/tercihler, ateş/buz sonlanması, iki biyom, gündüz/gece. Ses yerel sentezlenir. Ağ çağrısı/telemetri yok.

`tests/test_game.gd`: 40 anlamlı fizik ve gerçek sahne/menü/kayıt kontrolü. Son platform ve görsel doğrulama: `docs/VALIDATION.md`. Release kapsamı: `docs/RELEASE.md`. Paketleme: `.github/workflows/build.yml`, `packaging/`, `docs/BUILD.md`. Özel anahtarları kaynağa veya arşive ekleme.

Öncelikli sonraki işler: fiziksel dokunmatik cihaz deneyimi, Apple Developer ID/noter onayı ve iOS TestFlight kurulumu. Kaynak projenin iOS hedefinin varlığı iPhone'da kurulabilir paket üretildiği anlamına gelmez. Mevcut ilk beta paketlerini ve etiketlerini koru.

İlk teslim 0.1.0 beta: Windows NSIS+ZIP, Linux DEB+AppImage+tar.gz, macOS universal DMG+ZIP, Android release APK ve ek Web arşivi. 40 kaynak/gerçek sahne kontrolü ve 12 gerçek tarayıcı kontrolü. Native Android emülatör testi ANGLE/SwiftShader ile ekran içeriğini ve offline başlangıç/Space/Esc akışını denetler; eski GLES çeviricisinin boş ekranı başarısız kabul edilir. Windows ve Linux kurulumdan sonra da açılır; macOS native ilk açılışı CI’da geçti.

Android release imza anahtarı `/workspace/work/signing` özel derleme alanındadır, kaynakta veya Release içinde değildir. GitHub secrets yazma denemesi 403 döndürdü. İleriki imzalı güncellemeler için aynı anahtarın güvenli saklanması ve sahibinin GitHub Actions secret ayarını tamamlaması gerekir; `docs/BUILD.md` izlenir. iOS App Store/TestFlight ve macOS Developer ID/noter onayı tamamlanmadı.

Son doğrulanmış oyun kodu: `c36b105`. Tam başarılı CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42825770482 . Sonraki yalnızca belge/ekran görüntüsü kaydı oyun kaynaklarını değiştirmez. Release içindeki BUILD-RECEIPT.json ile SHA256SUMS gerçek yüklenen dosyaları tanımlar.

## 0.2.0 geliştirmesi

Aion çift zıplar. Baykuş tek zıplar; Space/dokunma basılıyken düşüşte süzülür ve bırakınca normal düşer. Koyun aralıklı görünen arkadaşları temasla toplar; toplam en fazla 3 koyun, her koyun 1 can. Kurt Shift veya karakter üzerine basılı tutularak 1.55 kat hızlanır; ikinci dokunma parmağıyla aynı anda zıplanır. Tüm basılı kontroller duraklatma, odak kaybı ve karakter seçiminde temizlenir.

Yerelde 84 kaynak/sahne kontrolü, 12 temel web akışı ve 12 yeni yetenek/touch akışı geçti. Ekran görüntüleri `docs/evidence-v02/` içinde kaydedilir. Vercel kaynak derlemesi hem hazır Godot hem sıfırdan resmi indirmeyle doğrulandı. Kullanıcının Vercel adresi: https://aionendlessrun.vercel.app/ . Bu adresin 0.2.0 yayını yeni main gönderiminden sonra ayrıca doğrulanır. Native CI ve 0.2.0 Release teslimi tamamlanınca son kayıt eklenir; 0.1.0 korunur.
