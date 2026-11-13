# 0.19.0 · Gerçek doğrulama

[Oyna · Pages](https://kaansavukduran.github.io/aion_endless_run/) · [Vercel](https://aionendlessrun.vercel.app/) · [Paketler](https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.19.0)

Son uygulama537391a; bu uygulamayı ve paket metadata kaydını içeren4fea30b, [43480686993 numaralı CI](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43480686993) içinde bütün platform kapılarından geçti. [Pages yayını](https://github.com/kaansavukduran/aion_endless_run/actions/runs/43482053479) başarılı koşunun web çıktısını aynen kullanır. Sonraki teslim belgeleri oyun kaynaklarını değiştirmez. Paketlerin herkese açık yükleme doğrulaması tamamlanınca bu rapora eklenir.

| Durum | Gerçek kapsam |
| --- | --- |
| PASS |18 Godot kaynak/sahne grubu,9.556 kontrol; SCRIPT ERROR, eksik RESULT ve FAIL da başarısızlık sayılır. [Sonuçlar](source-results.json). |
| PASS |126 normal giriş: altı karakterin bütün gerçek koşu/ateş kareleri, tek omuz taklası/alçak bekleme/doğrulma, kurt deparı, baykuş süzülmesi, Emre şarjı, Eren, iptal, gamepad A/× ve X/□, %200 menüler. [Ölçümler](browser-poses-and-inputs.json). |
| PASS |Son derlemede13 DPR3 geometri/iki parmak/iptal/yön kontrolü ve4 gerçek aşağı kaydırma kontrolü. [Düğmeler](browser-dpr3.json) · [Kaydırma](browser-swipe.json). |
| PASS |Son Vercel ve Pages adreslerinde Firefox153 ve Chromium151 ile toplam40 gerçek oynama kontrolü. Her adreste doğrulanmış PCK, bütün karakter kartları, Aion yüz/aktör hizası, beşi aşan ateş, Eren/Emre, takla ve döndürme. |
| PASS |İndirilecek gerçek web arşivinin `/aion_endless_run/` alt yolunda ServiceWorker kurulumu, ağ kapalı yeniden açılış ve normal oynayarak kazanılmış rekorun korunması:3 kontrol. [Kayıt](offline-results.json). |
| PASS |API30 Android emülatöründe ağ kapalı11 gerçek ADB giriş/yerleşim kontrolü. Normal ateş, antrenmanda beşi aşan uzun ateş, takla, Ömer süzülme, Eren anında sıçrama, Emre şarj/bırakma ve yön değişimi. [Sonuç](android-input-results.json). |
| PASS |Windows kur/çalıştır; Linux portable/DEB/AppImage çalıştır; macOS universal app/DMG launch smoke. Gerçek CI ZIP özetleri ve CRC'leri doğrulandı. [Dosyalar](artifact-validation.json). |
| PASS |7 web paketleme ve4 Android kayıt ayrıştırma testi. |
| NOT TESTED |Fiziksel Poco/iPhone/kol, yerel Safari ve fiziksel Apple Silicon. Yazılım girdileri fiziksel cihaz yerine sayılmaz. |
| BLOCKED |Yerel iOS mağaza paketi sahibinin Apple imzasını bekler. Mac yalnız ad-hoc; Developer ID/noter ve Windows Authenticode yok. |

Aion ateş karelerinde28,507, Melun'da12,390 oyun birimi yüz kayması özgün pikseller üzerinden ölçüldü. Yanlış iris kaydı mavi bir kıyafet/silah ayrıntısını seçebiliyordu; normal koşuda kesirli kaynak piksel fazları da titreşim üretiyordu. Bütün burun/yanak/yüz çevresiyle yapılan kayıt ve ortak piksel fazı metadata'yı düzeltir. Aktör fiziği her karede oynatılmaz. Eski eye_world testleri aynı yanlış işaretçiyi tekrar kullandığı için tek başına yeterli değildi; bağımsız göz/yüz örnekleri eklendi. [Önceki ölçümler](baseline-anatomy.json) · [Kod sürekliliği](pose-code-integrity.json).

Özgün47 PNG,54a8136 ile byte byte aynıdır.60 yeni omuz taklası pozu ve Eren'in79 gerçek pozu ayrı varlıklardır. Eren'in ilk sırasında7, sonraki9 sırasında8'er kare vardır. İlk taslak referans, nihai kanon onayı olarak sunulmaz. Eren, Emre'den ayrı ve kendi görselleri olan bir seçimdir. [PNG özeti](png-integrity.json).

Menünün büyük boş paneli gerçek şekillendirilmiş içerik ve tema iç boşluğuna göre kısaltıldı. Dil düğmesinin genel büyütülmüş işlem minimumunu miras alıp karta taşması ayrıldı. Düğme sınırı, ikon ve hit alanı cihaz pikseline hizalıdır. Android görüntüsünde kesilen portre yetenek açıklamaları24 boyutluk yazıyı küçültmeden canlı kısa duruma dönüştürüldü; ayrıntılı yardım öğretici/erişilebilir adlarda korunur. Basılı takla bir ileri omuz dönüşünden sonra alçakta bekler; küre olarak dönmez. Doldurma ve şarjör sınırı yok;0,32 saniye atış aralığı ve kayıtlı alternatif bağlar korunur.

126-kontrollü tur, son portre durum yazısı değişikliğinden önceki66119a4b09427c4b derlemesindedir. Son değişiklik yalnız HUD alanındadır; bütün çizim, giriş, fizik fonksiyonları ve animasyon varlıkları aynıdır. Son uygulama ayrıca9.556 CI,17 DPR ve40 canlı kontrolünden geçti. Bu ayrım ölçümleri son derlemede yapılmış gibi göstermemek içindir.

Önceki başarısız denemeler PASS sayılmaz: yavaş yazılım çiziminde bloklayan ekran yakalamaları hareketsiz koşuyu engele kadar uzattı; kısa örnekleme bir Emre karesini kaçırdı. Son sürücü gerçek görünen ateş satırını, gerektiğinde farklı normal koşulardaki kareleri ve gerçekten gerçekleşmiş doğrulma geçişini gözler. DPR kaydırmasında önce test protokolünün ters yönü teşhis edildi; güvenilir hızlı dokunma başlangıç/hareket/bitiş sırası ayrı4 kontrolle doğrulandı. İlk Android denemesinde2,3 duvar saniyesi yalnız4 atışa yetti; eşik düşürülmedi, normal ateş ve gerçek antrenman arenasında uzun ateş ayrı doğrulandı.

Canlı tanıda sistem CA doğrulamalı HTTPS aktarımı kullanılır; TLS denetimi kapatılmaz. Chromium DevTools100MiB ileti sınırı için16MiB tanı dilimleri aynı özgün PCK'yi yeniden birleştirir ve oyun yükleyicisinin SHA denetiminden geçirir. Bu canlı denemelerde ServiceWorker kapalıdır; gerçek çevrimdışı deneme bundan ayrıdır. `tests/browser_verified_tls.py`, `browser_live_quality.py`, `browser_quality.py`, `browser_touch_quality.py`, `browser_swipe_quality.py` ile yeniden üretilebilir.

Fragaria Unslop uygulandı; güncel özel standartv1.7 ve referans/regresyon indeksi okundu. Bu, istenen arayüz/animasyon kapsamının doğrulamasıdır; bütün standarda toplu sertifika değildir. Bağlı ChatGPT sohbeti için read_thread aracı mevcut değildi. Özel standart ve özgün özel referans dosyaları bu herkese açık depoya kopyalanmadı. Sahne dekoru/zemin geometrisi bu değişiklikte düzenlenmedi.
