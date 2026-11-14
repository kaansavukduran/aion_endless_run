# Arcade görev 1 · doğrulama kaydı

14 Kasım 2026. Başlangıç: `53e4bd83813dd9085c14981b609a4c3a04237156`. Oynanış ve son yardım yerleşimi adayı: `9ff22a5`. Motor: resmi Godot 4.6.3; proje: 0.23.0. Bu klasör kaynak yedeği veya fiziksel cihaz sertifikasyonu değildir.

## Teslim edilen kapsam

Mevcut ana menüde **Arcade** ile açılan ilk sonlu görev. İki karar düğümü, üç son rota, kontrol noktaları, gerçek NPC kurtarma ödülleri, kırılabilir ikmal, zırhlı fener kızağı, rota mini boss'u ve üç saldırılı Kök Motoru. Altı kahraman, temel sınırsız tabanca, yeni basışla tek yakın vuruş ve kahraman rengine göre fiziksel yay çizen enerji bombası. Dokunmada solda sabit joystick, sağda Zıpla / Ateş-Vur / Bomba; bu modda takla yok. Sonsuz koşu ve eski kayıtları ayrı kalır.

Beş görevin tasarımı [ARCADE-PLAN.md](../ARCADE-PLAN.md), gerçek kontroller ve kayıt sınırları [ARCADE.md](../ARCADE.md) içindedir. Görev 2–5 uygulanmış sayılmaz. Mevcut ilk bölüm bir başlangıç sürümüdür; Metal Slug 3'ün tüm uzunluğuna, sanat hacmine veya nihai kalitesine ulaşıldığı iddia edilmez.

## Ölçülen sonuçlar

| Kontrol | Gerçek kapsam | Sonuç |
|---|---|---|
| GitHub kaynak testleri | 25 gerçek motor paketi; fizik, eski mod, kayıt, giriş, yeni görev; Ubuntu'nun sistem fontu | 18.883 kontrol, sıfır hata; `ci-source-results.json` |
| Yeni görev modeli | Rotalar, altı kimlik, can, saldırı, bomba, binek, tekrar ödülleri, boss ve dil/font kapsamı | 1.468 kontrol; kaynak toplamına dahildir |
| Yeni arayüz | 11 dil, 4 görünüm, %100/%150/%200 metin; bütün yardım sayfalarına gerçek Sonraki; kol olayları | 4.864 kontrol; kaynak toplamına dahildir |
| Yeni pafta geometrisi | Bağlı gerçek gövde, ayak, alfa aralığı, taşma, sabit ölçek ve atlas kimliği | 204 kontrol; kaynak toplamına dahildir |
| Native çizim | Gerçek OpenGL çıktısı, kurulmuş inceleme sahneleri; altı kahramanın koşu/yakın saldırı döngüsü, uçuş, şarj, binek sürüsü, iki yön | 108 kontrol, sıfır hata; `fixture-*`, `native-render.log` |
| Su kanalı | Gerçek Chromium tuşları/dokunması, boss'a kadar oyun, sonuç, eski menüye dönüş, kayıt, çevrimdışı yeniden açış | 27 kontrol, sıfır konsol/betik hatası; `water-*` |
| Bahçe terasları | Aynı gerçek akış; ilk ve ikinci karar düğümünden geçiş | 27 kontrol, sıfır konsol/betik hatası; `terrace-*` |
| Kök geçidi | Aynı gerçek akış; ilk ve ikinci karar düğümünden geçiş | 27 kontrol, sıfır konsol/betik hatası; `roots-*` |
| Firefox | Gerçek Firefox WebGL, tuşlar, dokunarak zıplama, iki yöne dönüş, çevrimdışı açış ve kontrol noktasından sürdürme | 22 kontrol, sıfır konsol/betik hatası; `firefox-*` |
| Üç dokunma eylemi | Gerçek sağ Ateş ve Bomba dokunması, sol joystick + Zıpla çoklu dokunması, iptal, iki yön, çevrimdışı sürdürme | Chromium: 25 kontrol, sıfır hata; `three-touch-*` |
| Yerel normal kaynak ortamı | Aynı 25 paket, yerel sistem fontu | 18.832 kontrol, sıfır hata; sayfa sayısına bağlı eski font matrisi farklı sayıda kontrol üretir; `local-source-results.json` |
| Platform paketleri | Windows kurulum/portable, Linux paket/başlatma, macOS universal app/DMG | Üç CI işi başarılı; aşağıdaki çalışma bağlantısı |
| Android emülatör regresyonu | Geçici test APK'sı, eski sonsuz modun mevcut çevrimdışı giriş/animasyon senaryoları; arcade görevi Android native içinde tamamlanmadı | İlk indirme hatasından sonraki yeniden deneme başarılı; iş `132493216332` |
| Eski sanat | Başlangıç commit'indeki 62 PNG'nin baytları | Tamamı değişmemiş; `original-art-integrity.json` |

Üç oynanış kaydı farklı aday derlemelerine aittir; her JSON kendi `build` kimliğini saklar. Su kanalı son yardım düzeltmesi dahil `69f32a110a9e3532`; teras `49f29e8432608ce2`; kök geçidi `755af337995a342f`. Aradaki son değişiklikler öğretici sayfalama/font kapsamıdır; önceki kayıtlar son derleme diye yeniden etiketlenmez. Otomasyon salt okunur oyun gözlemleriyle normal tuş/dokunma gönderir; durum atlatma, ölümsüzlük veya kayıt enjeksiyonu kullanmaz. Bu hızlı test koşuları yaklaşık 70–83 saniyedir; insan oynama süresi ya da tasarımda hedeflenen 6–10 dakikanın ölçümü değildir.

`fixture-*` görüntüleri özellikle kurulmuş çizim sahneleridir; sıradan girişlerle bölüm tamamlamanın kanıtı değildir. `*-mission-complete.png` ve `*-playthrough.json` gerçek oyun akışına aittir. Tek kare sabitliği veya geometri testi tek başına estetik onay değildir.

## Kanıtlanan ve giderilen nedenler

- Kahraman listesi ile atlas satır sırası aynı değildi. Kimlik eşlemesi artık atlasın kahraman adından yapılır; liste sıra numarası kullanılmaz.
- Yeni yakın dövüş paftası eşit yükseklikte çizilmemişti. Eşit bölme koyunun halesini kesiyor, sonraki satırın kulaklarını alıyordu. Gerçek alfa aralıkları ve bağlı gövde/ayak kaydı kullanılır. Fizik konumu kareye göre oynatılmaz.
- Tavşanın görünmez tavanı şarjlı sıçrama yüksekliğini sınırlıyordu. Üst sınır ve düşey kamera birlikte düzeltildi; normal ve dolu şarj farklı yükseklik verir.
- Ubuntu'nun geniş sistem fontunda Almanca/Fransızca yardım %200 ölçekte taşıyordu. Genel yardım iki kısa sayfaya bölündü; bilgi saklanmadı veya yazı küçültülmedi. Bütün sayfalar yeniden tıklandı.
- Eski menüye dönüş doğrudan düğme sinyali içinde sahne değiştiriyordu. Değişim ertelendi; tekrar girişte eski erişilebilirlik/kampanya gözlemleri temizlenir. Son gerçek dönüş/çevrimdışı testleri sıfır motor hatasıdır.
- İlk Android CI denemesi emülatör kurulurken “Error on ZipFile unknown archive” ile durdu. Bu koşuda oyun çalıştırılmadı; indirme hatası oyun başarısı diye sayılmaz.

Platform işi ve Android tekrarının gerçek kaydı: [Test and package / 43609386959](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43609386959). Android tekrarında mevcut çevrimdışı regresyon akışı geçti. Bu, fiziksel telefon testi veya yeni arcade görevinin Android native içinde uçtan uca oynandığı anlamına gelmez.

Ek font teşhisi sırasında bütün sistem fontlarını zorla DejaVu'ya çeviren deneysel Fontconfig dosyası, özellikle Liberation Sans isteyen eski testleri de değiştirdi ve dört eski yerleşim kontrolünü bozdu. Bu özel zorlamanın sonucu başarılı tam test diye sunulmaz. Normal Ubuntu CI'da aynı eski test paketi 2.660 kontrolle geçmiştir; yeni yardımın DejaVu testi de 4.864 kontrolle geçmiştir.

## Sınırlar

Fiziksel Poco, iPhone ve Xbox/PlayStation kolu denenmedi. Gamepad olay testleri gerçek kol donanımının yerine geçmez. Yeni imzalı iOS/Android sürümü yayımlandığı iddia edilmez; mevcut 0.22 indirmeleri korunur. Son platform/yayın durumu ayrı `deployment.json` kaydında belirtilir. Korunan Vercel önizlemesi giriş ekranı arkasındaydı; önizleme oynanışı yapılmış sayılmaz. Canlı adres doğrulaması ancak gerçek üretim derlemesi açıldıktan sonra kaydedilir.
