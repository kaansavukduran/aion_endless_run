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
| Firefox | Gerçek Firefox WebGL, tuşlar, sağ Ateş/Bomba ve Zıpla dokunmaları, iki yöne dönüş, çevrimdışı açış ve kontrol noktasından sürdürme | Son eklenen düğme testleriyle 24 kontrol, sıfır konsol/betik hatası; `firefox-*` |
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

Fiziksel Poco, iPhone ve Xbox/PlayStation kolu denenmedi. Gamepad olay testleri gerçek kol donanımının yerine geçmez. Yeni imzalı iOS/Android sürümü yayımlandığı iddia edilmez; mevcut 0.22 indirmeleri korunur. Son platform/yayın durumu ayrı `deployment.json` kaydında belirtilir. Korunan Vercel önizlemesi giriş ekranı arkasındaydı; önizleme URL'sinde oynanış yapılmış sayılmaz. Sonradan birincil canlı oyun adresinde sunulan gerçek paket ayrı açılıp doğrulandı; yayın ve tanılama yöntemi aşağıdadır.

## Gerçek canlı yayın ve son kontroller

`main` birleştirme commit'i **8a93f8dfbb30eb694074e6a481d2e1d7c03c3533**. [Ana dal platform çalışması](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43611409619) başarılı: kaynak 18.883 kontrol, üç masaüstü paket işi, render ve gerçek web dokunma/çevrimdışı testleri, önceki Android çevrimdışı regresyon akışı. İmzalı yeni mobil dağıtım işi atlandı; geçici emülatör APK'sı mağaza sürümü değildir.

| Adres / çıktı | Kimlik | Son gerçek kontrol |
|---|---|---|
| [Vercel](https://aionendlessrun.vercel.app/) | 0.23.0 / `6dd043210443d464` | Canlı kontroller: 23 kontrol, sıfır betik/konsol hatası; `live-vercel-*` |
| [GitHub Pages](https://kaansavukduran.github.io/aion_endless_run/) | 0.23.0 / `48a12e699b25e92f` | Gerçek girişler, teras rotası, boss, sonuç, kayıt ve eski menüye dönüş: 28 kontrol, sıfır hata; `live-pages-*` |
| Yayımlanan Vercel paketinin birebir kopyası | `6dd043210443d464`; 18 dosya SHA-256 ve boyut doğrulaması | Gerçek worker/cache, su rotası/boss/sonuç, kayıt ve çevrimdışı yeniden açış: 29 kontrol, sıfır hata; `public-mirror-*` |
| Gerçek ölüm / yeniden deneme | Aynı public paket, localhost ayna | Tehlikeye doğru normal hareket → gerçek ölüm menüsü → gerçek Yeniden dene dokunması → canlı kıyı kontrol noktası; `retry-*` |

GitHub Pages [yayın çalışması 43612266409](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43612266409) başarılıdır. Kopyalanan dosyalar `public-bundle-integrity.json`, tam kaynak/yayın ayrımı `deployment.json` içindedir. Son belge değişiklikleri yeni oyun derlemesi gibi etiketlenmez.

Vercel'in otomatik `main` derlemesi günlük kotayla engellendi; GitHub'daki Vercel durumunun kırmızı kalması bu gerçek hatayı gösterir. Mevcut önizlemeyi production'a yükseltme API'si de HTTP 422 döndürdü; başarılı diye kaydedilmedi. Bunun ardından Vercel'in desteklediği alias atamasıyla, bütün PR kontrolleri geçmiş **a7a4157** kaynağının hazır statik çıktısı mevcut birincil oyun adresine bağlandı. Bu kaynak ile **8a93f8d** birleştirmesinin Git ağaç kimliği aynıdır: `9adc3455c7fea20ed6a274c5928156d317fd84c3`. Bu, production ortamında yeni bir derleme yapıldığı anlamına gelmez. Koruma ayarları değiştirilmedi; bypass anahtarı veya paylaşım belirteci oluşturulmadı. Birincil adresin gerçek manifesti ve oynanışı ayrı doğrulandı. Deneme için kullanılan ikincil alias önceki deployment'ına geri alındı.

Bu bulut ortamındaki Chromium, ortamın HTTPS proxy kök sertifikasını kendi deposunda tanımıyor. Canlı tarayıcı kontrolleri deponun mevcut `browser_verified_tls.py` sürücüsüyle, sistem CA doğrulaması korunarak iletilen gerçek HTTPS yanıtlarını kullanır. Yalnız bu tanılama bağlamında worker engellidir ve aynı ses worklet baytları Blob üzerinden yüklenir. Canlı kayıtlara production-origin worker kurulumu/çevrimdışı başarısı yazılmaz. Birebir indirilen public paketin localhost aynası ise gerçek worker/cache/çevrimdışı akışını ayrı doğrular; paket baytları değiştirilmez.

Yeni masaüstü kurulum/portable paketleri [ana dal çalışmasının artifacts bölümündedir](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43611409619#artifacts): `desktop-Windows`, `desktop-Linux`, `desktop-macOS`. Bunlar süreli CI çıktılarıdır; GitHub Release veya yeni imzalı Android/iOS sürümü diye sunulmaz. Kaydedilen saklama sonu 12 Şubat 2027'dir.
