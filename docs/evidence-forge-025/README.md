# 0.25.0 Forge doğrulaması

Bu dizin gerçek çalıştırmalardan alınmış seçili ham sonuçları içerir. Tam çalışma alanı `/workspace/work/forge-025` idi. Kapsam ve 1–29 madde matrisi: [teslim kaydı](../AIONIA-FORGE-20261115.md).

| Paket | Sonuç ve kapsam |
| --- | --- |
| `combined-source.json` | 40 ayrı Godot kaynak süiti, 33.651 kontrol, sıfır son hata. İlk koşunun başarısızlıkları son etkilenen süitlerle yeniden sınandı; bu, tek bir temiz toplu koşu diye sunulmaz. |
| `runtime-inventory.json` | 384 kaynak/varlık/paketleme dosyası; çalışma ağacı envanteri, temel commit `328fd0d…`. Temiz commit veya Git geçmişi yedeği değildir. |
| `original-art.json` | Önceki 76 PNG'nin baytları korunmuştur. |
| `render-ship.log`, `render-ship/` | 96 bilerek kurulmuş native görsel durum, sıfır hata; normal kullanıcı oynanışı değildir. |
| `final-roots/` | Firefox, `29cde1501f1a9acb`, 70 gerçek tarayıcı kontrolü; tam görev/boss/sonuç/ana menü/offline. |
| `final-terrace/` | Chromium, aynı `29cde…`, 71 kontrol; tam görev/boss/sonuç/ana menü/offline. |
| `final-water/` | Chromium, aynı `29cde…`, 74 kontrol; tam görev ve gerçek araç bin/in. |
| `ship-front-en200/` | Firefox, son `3649…`, 28 kontrol; açılış/altı kahraman/yardım/demoda kayıt değişmemesi/iki yön/Endless ve %200 Pause ilk sayfasındaki Devam/Ana menü. |
| `ship-campaign/` | Chromium, son `3649b43ccdca3bbb`, 22 gerçek kontrol: dokunmatik eşzamanlılık, sanal gamepad, sekiz yön ateş, mermiyle bağ çözme, gezinen NPC'ye temas ve bir defalık ödül. |
| `ship-upgrade/` | Gerçek önceki 0.24 `f21be96bbf646fb9` → son 0.25 `3649…`, 11 kontrol; servis worker, IndexedDB, rekor/karakter/dil ve offline yeniden açılış. Sonraki `test-next-build` yalnız sentetik güncelleme kabuğu denemesidir. |
| `final-audio-verified/` | `29cde…`, 30 WebAudio örneği/34,81 s; pause→play→pause, uzun sample/buffer başlangıcı 0, tek müzik başlangıcı, sıfır hata. |
| `packaging-*.log` | 7 web, 4 Android ve 3 macOS sözleşme/mock kontrolü; fiziksel kurulum testi değildir. |

Son `3649…` derlemesi, `29cde…` üzerindeki üç tam rotadan sonra dar kapsamlı binme/ayna/namlu, Pause ve font onarımlarını içerir. Bu hash farkı saklanmaz; üç tam rota sonucu son derlemeye otomatik mal edilmez. Son Firefox büyük yazı kontrolü de28kontrolle geçti. CI ve yayın makbuzları elde edildiğinde aynı teslim kaydına eklenir.

Tarayıcı kontrolleri gerçek girişleri kullanır; tam görev yürüyüşlerinde teleport, dokunulmazlık veya düşman silme kullanılmaz. Sanal kol fiziksel Xbox/PS testi değildir. Yazılımsal llvmpipe sonuçları telefon performansı veya 60 FPS garantisi değildir. Fiziksel Poco/iPhone, gerçek kol ve gerçek Safari/Edge sınanmadı. Yeni native Release yayımlanmadı.

İlk hatalı denemeler yerel çalışma alanında korundu: eski test düğüm kimliği, sunum biterken eski koordinata dokunma, ayakta ateş denemesinde gerçek ölüm ve demo dönüşünde henüz yerleşmemiş menüye dokunma. Ürün hataları ile sürücü hataları teslim kaydında ayrıdır. Özel standart belgeleri, kullanıcı eki, erişim çerezleri ve geçici preview bağlantıları bu kamu dizinine alınmadı.

## İlk CI ve gerçek Vercel önizlemesi

`c78ab3c` için GitHub run43650856407: kaynak işi **40 süit /33.780 kontrol PASS**, Windows ve macOS PASS. Bu taze CI sayısı yerel birleştirilmiş33.651sayısından ayrı kayıttır; ortam/yazı metriğine göre UI matrisindeki gerçek dallar değişir. Linux eski renderer yalnız `pixel-wolf` beklediği için altı kurt kimlik kontrolünde durdu; Android eski sürücü yeni açılışı atlamadan LanguageMenu aradı. İki başarısızlık ham JSON'da korunur.

Renderer yeni kurdun gerçek `forge-mouth-carry` satır2 kimliğini ve diğer beş kahramanın kendi piksel paftası satır3 kimliğini doğrular. Donmuş fixture'da önceki kahramanın elle atanmış .12s atış parlaması sonraki koşuya taşınmaması için temizlendi. Güncel renderer **108 kontrol,0hata**. Ürün kodu değişmedi.

Vercel protected preview dpl_CbG5NyhMq9rH4563u31yzvC5Zzng, aynı c78commit, gerçek sunucu derlemesi **30048532c94c99a7**: **45 gerçek giriş kontrolü PASS**,0hata; 19dosya,13manifest varlığının SHA-256özeti ve WASM MIME PASS. Canlı tarayıcı bu ortamın sistem TLS güven zinciri üzerinden çalıştı; sertifika denetimi kapatılmadı. Bu tanı sürücüsünde servis worker kapalıdır; canlı offline testi diye sunulmaz. PWA/offline kanıtı ayrı ship-upgrade ve tam rota sonuçlarıdır. Geçici görüntüleme yetkisi/çerezi bu dizine alınmadı, Vercel koruması değiştirilmedi.

Android sürücüsü artık her gerçek başlangıçta yalnız görünen SkipOpening'e dokunur, gerçek ana menüyü bekler ve antrenmana Yardım→sayfalama→BossTraining yoluyla girer. Önceki15emülatör iddiası korunmuştur; dört paket-dekodlama mock kontrolü ve Python derleme denetimi PASS. Bu yerel sözleşme testi, yeni APK'nın emülatörde geçtiği anlamına gelmez; sonraki CI sonucu ayrı gereklidir.

## Son hazır menü sözleşmesi ve Android görüntüsü

Son48dcönizlemesinde isteğe bağlı Firefox/%200tam akış,23başarılı kontrolden sonra demo dönüşünün ilk StartRun dokunmasında durdu; bu28PASSsayılmaz. Odaklı gerçek-giriş probunda üç döngünün birinde eski(28,72)hedefi kaçtı, yerleşmiş(251,151)hedefi çalıştı. `demo-return-probe/targeted-results.json` bu başarısız ilk dokunmayı ve sonraki ölçümü açıkça ayırır. İki tarayıcı rAF'sinin iki Godot yerleşim karesi olduğu varsayımı yanlıştı.

Menü gizliden görünür hale geçince UI-hazır bayrağı artık geçersiz kılınır; var olan iki gerçek Godot process-frame bariyerinden sonra güncel hedefler yayımlanır. Fizik, karakter pivotu, çizimler veya kontrol şeması değişmez. Yeni dört regresyon kontrolü dahil1968front kontrolü PASS. Yeni web paketi ve yayın kontrolleri bu son düzeltmeyi ayrıca sınayacak.

48dcAndroid emülatöründe15gerçek giriş iddiası geçti; son görüntü denetimi,148renkli kasıtlı açılışı tam sahne sanıp durdu. Son sürücü ilk tam-sahne görüntüsünü gerçekSkipOpening/ana menü hazır olduktan sonra alır.200renklik kalite eşiği düşürülmez.4Android paket mock kontrolü ve Python derleme denetimi PASS; yeni emülatör görsel sonucu ayrıca gereklidir.
