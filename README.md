# Aion Endless Run

Sevimli, çevrimdışı bir pixel-art koşu oyunu. **Space ile zıpla, Esc ile mola ver.** İleri ateş et, engellerin altından takla at, çukurları aş ve kendi rekorunu geç. Godot **4.6.3**, oyun **0.20.0**.

**[Güncel oyunu oyna](https://kaansavukduran.github.io/aion_endless_run/) · [0.20.0 indir](https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.20.0)** · [Vercel adresi](https://aionendlessrun.vercel.app/) · [Paket ve platform durumu](docs/RELEASE.md) · [AIONIA uygulama notları](AIONIA_STANDARD.md) · [Doğrulama](docs/evidence-v0200/README.md)

![Gerçek oyunun kompakt ana menüsü](docs/evidence-v0200/screenshots/main-dark.png)

0.20.0: Altı kahraman için396 farklı çizilmiş poz içeren altı yeni pixel-art pafta; malzeme gölgeleri, seçici konturlar ve okunaklı hareket. Yüz hizası, tam kulak/ayak kesimi, tek alçak omuz taklası ve silah eki doğrulanır. Özgün kaynak PNG'ler korunur. Tabanca sınırsızdır;0,32 saniyelik atış aralığı ve mevcut yetenekler korunur. İki oynama adresinin rekorları ayrı saklanır.

## Oyna

Telefon kontrolleri seçimin üzerine iki yana bölündü: solda Zıpla, sağda Ateş et/Takla. Tabanca her zaman elde; sınırsız mermi, 0,32 saniyelik ortak atış aralığı. Doldurma yoktur. Dikey ekranda kısa canlı yetenek durumları okunaklı kalır. Ayarlardan eski sağ küme seçilebilir. Koyu/açık/sistem teması, sistem/pixel yazı ve büyütülmüş menü metni saklanır. Kol eylemleri yeniden atanabilir; titreşim varsayılan kapalıdır. [Kontroller](docs/CONTROLS.md).

Başlangıç kartlarından karakterini seç; koşu sırasında karakter değişmez. İlk dil cihaz/tarayıcı dilidir; desteklenmeyen diller İngilizce açılır. **TR / EN / CS / AZ / DE / FR / JA / KO / ZH / ES / IT** menüsünden değiştirebilirsin; seçimin ve rekorun cihazda saklanır.

| Karakter adı (bütün dillerde) | Yetenek |
| --- | --- |
| Aion | Çift zıplama |
| Kutsanmış | En fazla üç can; küçük takipçiler gecikmeli zıplar |
| Melun | Shift / Depar basılı: dört ayakla hızlan |
| Ömer | Zıpla ve basılı tut: süzül, hava akımını yakala |
| Emre | Zıplamayı basılı tut: şarj et; bırak: sıçra |
| Eren | Tek, anında sıçrama; kendine ait ayrı karakter paftası |

| Eylem | Klavye / fare | Telefon | Standart Xbox / PlayStation |
| --- | --- | --- | --- |
| İleri ateş | Sol veya sağ tık / F basılı | Ateş et basılı | RB / R1 veya RT / R2 |
| Ek ateş girişi | R / J basılı | Aynı Ateş et düğmesi | X / □ basılı |
| Zıpla / süzül | Space; Ömer için basılı, Emre için tutup bırak | Zıpla; Emre için tutup bırak | A / ×; Emre için tutup bırak |
| Takla | Aşağı / S / Ctrl | Aşağı kaydır veya Takla | B / ○ |
| Melun deparı | Shift; karakterin üstünü basılı tut | Depar veya karakterin üstünü basılı tut | LB / L1 |
| Duraklat | Esc | Duraklat | Start / Options |

Yumruk eylemi kaldırıldı. Her kahraman düz ileri tabanca sıkar; mermi bittiği için durmaz; doldurma eylemi yoktur. Toplanan şimşek, normal koşudaki tabanca atışına ek alan etkisi verir. Düşerken düşmanın üstüne basarak sekebilirsin. Telefon hem dikey hem yatay oynanır; döndürmek koşuyu sıfırlamaz. İki parmakla eşzamanlı geçerli eylemler çalışır. Kısa telefon öğreticisini okurken dünya bekler.

Altı biyom: Kehribar Çölü, Ayaz Vadisi, Sisli Bataklık, Bakır Şehir, Fener Ormanı ve Kor Sırtı. Gündüz/gece, hava olayları, kargalar, cüceler, seyrek ateş bitkileri, çukurlar ve kargaların taşıdığı üst engeller vardır. Her **15 saniyelik aktif normal koşu** yeni seviyedir; menü, duraklatma, sarılma ve boss zamanı bu sayaca girmez. Her on seviyede sarılma ve ve üç tasarımı dönen boss kovalamacası vardır. Boss arenasında normal parkur temizlenir. İsteğe bağlı antrenman üç boss’u doğrudan denetir ve rekoru değiştirmez.

Meyveler +25, temiz aşılan engeller +10; mesafe de skor kazandırır. On toplanabilir güç bulunur. Sıçrama tılsımı 9 saniye daha yüksek zıplatır, şans parası 12 saniye meyve puanını ikiye katlar, buz feneri 8 saniye yakındaki yaklaşan düşmanları yavaşlatır. Dev mantar varsayılan %2 uygun eşya olasılığıyla nadirdir; ilk 20 saniyede ve önceki mantardan sonraki 45 saniyede gelmez. Mantar dalgasının toplam cüce üretimi yaklaşık yarıya indirildi; ortam cüceleri değişmedi. Her 100’ün katı eşiğinden sonraki ilk uygun boss zaferi **Fragaria çileğini** sunar. Bu nesne yalnız kısa kutlamadır; güç, puan veya başka oynanış ödülü vermez.

## 0.20.0 · Yeni kahraman pixel-art paftaları

Aion, Ömer, Melun, Kutsanmış, Emre ve Eren için6 yeni pafta,396 farklı çizilmiş poz. Daha belirgin malzeme gölgeleri, piksel kümeleri ve seçici konturlar; özgün renkler ve karakter kimlikleri korunur. Koşu/ateş/uçuş yüz kaydı, tam kulak/ayak kesimi, alçak tek omuz taklası ve dar silah eki aynı mevcut oyun akışına bağlıdır. Özgün PNG'ler saklanır.

[Sanat sözleşmesi](docs/ART_BIBLE.md) · [Doğrulama](docs/evidence-v0200/README.md). Kontroller ve kayıt sistemi korunur; şarjör/reload geri eklenmez.

## 0.19.0 · Sabit yüz hizası, omuz taklası, Eren

Yanlış mavi renk işaretçisi Aion ve Melun'un bazı ateş karelerinde yüz yerine başka ayrıntıyı seçiyordu. Bütün yüzün burun/yanak/çevre piksellerini karşılaştıran kayıt, aynı fizik noktası ve karakter ölçeğinde gerçek yüzü sabitler. Kaynak piksel fazı da tüm döngüde aynıdır. Hareketli kanat ve kuyruklar dondurulmaz; eski PNG'ler değiştirilmez.

Beş kahraman için60 gerçek omuz taklası pozu; Eren için79 ayrı çizilmiş hareket/ateş/takla/hasar pozu. Taklada diz bükme, ellerin yere inmesi, omuz üzerinden öne dönüş ve doğrulma okunur. Basılı takla sürekli top gibi dönmez, eğilerek bekler. Emre'nin şarjı, Ömer'in süzülmesi, Melun'un dört ayak deparı, Aion'un çift sıçraması ve gecikmeli koyun takipçileri korunur.

Aşağıdaki sürüm bölümleri tarihçedir; eski şarjör/doldurma ve dönen top taklası güncel oyunda yoktur.

## 0.18.0 · Alçak takla ve şarjlı Emre sıçraması

Beş kahramana12'şer yeni çizilmiş poz: diz bükme, yere yaklaşma, saat yönünde öne takla ve doğrulma. Sabit fizik noktası/tek ölçek kullanılır; karakter çizimi ezilip dikey olarak sıkıştırılmaz. Basılı taklada giriş pozu tekrar etmez, karakter alçakta dönmeye devam eder. Koyun takipçileri kendi gecikmeli yol kayıtlarına göre aynı hareketi yapar.

Emre zıplama basılıyken yerde güç biriktirir, bırakınca sıçrar.1,2 saniyede tam güce ulaşır; kısa basış alçak, uzun basış yüksek tek sıçrama verir. Klavye, dokunma ve gamepad aynı eylemi kullanır. Havada ikinci şarj yoktur. Dokunma iptali/odak kaybı/yön değişimi birikmiş gücü yanlışlıkla sıçratmaz. Şarj oranı küçük piksel işaretleriyle görünür; uzun seviye barı geri eklenmedi.

Ana menü, sonuç, duraklatma, karakterler, diller, ilk yardım ve uzun ayarlar fare tekerleği istemez. Uzun içerikte Önceki/Sonraki okları kullanılır; sonuçta Yeniden koş ve Ana menü erişilebilir kalır. %200 yazı ve mevcut tema/font tercihi korunur. Sayısal ayarın adı ile kaydırıcısı aynı gruptadır. Seçilen iki yana bölünmüş mobil düzen ve5 mermili tabanca korunur.

## 0.17.0 · Her zaman tabanca, kompakt menü

Beş mermi, elle bir saniyelik doldurma; normal koşuda ve boss'ta aynı silah. Özgün karakter çizimleri korunur. Ömer süzülürken ve Melun dört ayaklı depar yaparken tabanca ayrı, kendi paftasından alınmış parça olarak çizilir; hareket animasyonu değişmez.

Ana menü %200 yazıda da beş kısa isimli kart ve üç işlemi kaydırmadan gösterir. Eski dil tercihleri bir kez cihaz/tarayıcı diline döner; yeni açık seçimler saklanır. Dil menüsünde **Sistem dili** seçeneği bulunur. Tema, yazı büyüklüğü ve rekorlar sıfırlanmaz. Uzun seviye/XP barları kaldırıldı; seviyeler 15 aktif saniyedir. Kaktüs, çam/fener, söğüt, şehir saksısı, orman ve kor bitkileri üçer çizilmiş pozla hafifçe salınır; hareket kapalıysa sabittir.

## 0.16.0 · Aionverse manzaraları, meyveler ve Emre

Altı biyom artık piksel resimli Aionverse manzaraları kullanır: gözlemevleri, botanik laboratuvarları, bakır çatılar, karlı dağlar, bataklık seraları ve fenerli ormanlar. Hareket, gece/gündüz, hava ve boss geçişleri korunur.

Sıradan kristaller yerine **muz, elma, armut, kayısı, kara üzüm, portakal, kiraz ve şeftali** toplanır; her biri +25 puandır. Daha sık 3–5'li meyve dizileri, zeminden toplanabilen yükseklikte ve tehlikelerden uzakta çıkar. Uçan engelin üstüne kristal koyan karşılaşma kuralı kaldırıldı; sonradan gelen tehlikelerle yerleşim yeniden denetlenir. Güç mıknatısı ve şans bonusu meyvelerle çalışır; nadir Fragaria çileği ayrı kutlama olarak kalır.

**Tavşan Emre** beşinci oynanabilir kahramandır. Sahibinin resmi paftasındaki açık kahverengi kürk, yeşil göz, mavi gömlek ve kırmızı kravat korunur. 144 çizilmiş poz; tek güçlü sıçrama, dönüşümlü yumruk/tekme, takla, boss tabancası, donma/yanma ve düşüş. Diğer 41 PNG değişmedi. [Gerçek ekranlar ve test kapsamı](docs/evidence-v0160/README.md).

## 0.15.1 görsel iyileştirmesi

Yarasa, balçık, kabuk böceği ve fırtına ışığı için 24 ayrıntılı animasyon karesi eklendi. Telefon tuşları simetrik basamaklı çerçeveler, elle çizilmiş piksel ikonlar ve belirgin basılı/bekleme durumları kullanır. İki yana bölünmüş kontroller, dokunma alanları ve özgün kahraman çizimleri korunur. [Çalışan oyun görüntüleri ve doğrulama](docs/evidence-v0151/README.md).

## 0.15.0

Normal düşmanlar tek vuruşta veya üstüne basınca yenilir; yenmek 10 XP, üstüne basmak 15 XP, boss yenmek 100 XP verir. Her 100 XP koşu ustalık derecesini artırır; süreye bağlı seviyeler yine 20 saniyedir. Şimşek yakın saldırıda harcanmaz: sağ tık/F/RB/Şimşek ile 1500 birimlik geniş bir hat boyunca vurur. Yarasa, balçık, kabuk böceği ve fırtına ışığı eklendi. Boss sonrası arka plan/koşu sıçraması giderildi; hız, silah ve gösterge yumuşak geçer. [Ayrıntılar](docs/UPGRADE-0.15.0.md).

## 0.14.1 düzeltmesi

Android sistem yazı tipiyle 9:16 ekranda Ayarlar ve karakter başlığının çakışması giderildi. Telefon menüsü iki yönde kompakt bir başlık ve karakter seçimine kadar gerçek ayrılmış yükseklik kullanır. 1440×2560 kaynak ve 450×800 tarayıcı regresyonu ile gerçek Android UI sınırı kontrolü eklendi. [0.14.1 kanıtları](docs/evidence-v0141/README.md).

## 0.13.1 düzeltmesi

Dikey boss açıklaması ekrana sığacak biçimde sarılır; can barıyla çakışmaz. Telefonun kısa boss ipucu gerçek dokunma eylemlerini gösterir ve can bilgisi tekrarlanmaz. [Güncel doğrulama](docs/evidence-v0131/README.md).

## 0.13.0 değişiklikleri

Aion ve diğer kahramanların kare hizalaması düzeltildi. Yanlış uzak göz/gaga/solungaç seçimi yerine incelenmiş yakın göz ve gerektiğinde gövde dönüş noktası kullanılır. **Yedi kahraman PNG’si değiştirilmedi.** Doğal kuyruk/kanat/dönüş hareketleri korunur; fizik konumu kare başına kaydırılarak sorun saklanmaz.

Keskin çerçeveler, Pixelify Sans ve sıcak palet oyunun dünyasına uyar. Ana/sonuç menüsü ekrana sığar; uzun ayarlar kaydırılabilir. Sağ altta basılı/bekleme/kullanılamıyor durumlarını gösteren basamaklı yuvarlak dokunma düğmeleri vardır. Web açılışı Fragaria Interactive markasını ve gerçek indirme yüzdesini gösterir. Önceki Firefox dosya doğrulaması, bozuk önbellekten kurtarma, kayıtlar ve çevrimdışı güncelleme korunur.

## İndir

Windows: Setup ile kur veya portable ZIP’i tamamen çıkartıp EXE’yi aç. Linux: DEB, çalıştırma izni verilen AppImage veya portable tar.gz. macOS: universal DMG veya portable ZIP. Android: ARM64/x64 APK; önceki sürümle aynı uygulama kimliği ve imza, versionCode23. Gerçek paket listesi ve özetleri Releases içindedir. Önceki sürümler korunur.

İlk web yüklemesi internet ister; doğrulanmış tüm dosyalar önbelleğe alındıktan sonra çevrimdışı açılır. Mac paketi ad-hoc imzalıdır; Developer ID/noter onayı ve Windows Authenticode yoktur. Yerel iPhone/TestFlight/App Store için sahibinin Apple imzalaması gerekir; yerel portable iPhone paketi sunulmaz. Safari web sürümü ayrı bir seçenektir.

## Kaynaktan çalıştır ve derle

Godot 4.6.3 standard ile `project.godot` dosyasını içe aktar, **F5** ile başlat:

```sh
godot --editor --import --quit
godot --path .
python3 tests/test_web_packaging.py
godot --headless --script tests/test_runner_ux.gd
```

Tüm on altı kaynak/sahne testini `.github/workflows/build.yml` çalıştırır. Testler için gerçek oyuncu kaydından ayrı geçici XDG veri klasörleri kullan. Web: `python3 packaging/build_web.py`, çıktı `build/web`. Diğer hedefler resmi export templates ile `export_presets.cfg` içindedir. Android imza bilgileri kaynak kodda tutulmaz. Ayrıntılar: [BUILD](docs/BUILD.md), [VERCEL](docs/VERCEL.md), [VALIDATION](docs/VALIDATION.md). Tarihsel geliştirme notları [FORGE](FORGE.md) ve önceki kanıt klasörlerinde korunur.

GitHub geliştirme kaynağıdır. İstenen Drive proje kökü: [aion_endless_run](https://drive.google.com/drive/folders/1aj8Ma6N1ET_m4pNtDzPzCzYpbaaQsECf). `packaging/archive_project.py` tam commit’in özgün kaynak yollarıyla tarihli kopyasını, dosya boyutlarını ve SHA-256 envanterini üretir; Git geçmişi/issue/PR yedeği veya sürekli senkronizasyon değildir. Drive teslim işlemleri ayrı teslim raporunda doğrulanır.

## Görseller ve lisans

FireAxolotl/Extension kaynakları ve önceki paftalar korunur. Güncel kahraman tasarımları ile her PNG’nin kaynak/kare/hiza bilgileri `assets/*-PROVENANCE.json` içindedir. Yeni arayüz fontunun OFL lisansı ve Fragaria varlığının kökeni depodadır. [Kaynak ve lisans kayıtları](THIRD_PARTY_NOTICES.md). Chrome dinozorunun kodu veya görseli alınmadı. Hesap, reklam, telemetri, çevrimiçi puan tablosu veya ücretli kilit yok.

## English

An offline Godot pixel runner with five original heroes and six biomes. Version 0.17 uses an always-equipped, straight-firing pistol with five rounds and a one-second manual reload. Short proper names are identical in all eleven languages. The main menu fits at 100–200% text, including portrait and landscape. A one-time legacy language migration follows the device/browser locale without clearing records or appearance settings; later explicit choices persist. Levels take 15 active seconds. Eighteen new botanical poses add gentle wind animation while all 45 previous asset PNGs remain unchanged. Installers and portable editions are under Releases; evidence distinguishes browser/native-emulator tests from physical device and Apple distribution checks.
