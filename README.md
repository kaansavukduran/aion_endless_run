# Aion Endless Run

Sevimli, çevrimdışı bir pixel-art koşu oyunu. **Space ile zıpla, Esc ile mola ver.** Kargalara vur, engellerin altından takla at, çukurları aş ve kendi rekorunu geç. Godot **4.6.3**, oyun **0.16.0**.

**[Tarayıcıda oyna](https://aionendlessrun.vercel.app/) · [İndirilebilir sürümler](https://github.com/kaansavukduran/aion_endless_run/releases)** · [Paket ve platform durumu](docs/RELEASE.md) · [AIONIA v1.4 uygulaması](AIONIA_STANDARD.md) · [Doğrulama](docs/evidence-v0160/README.md)

![Normal koşuda Emre ve meyveler](docs/evidence-v0160/screenshots/normal-fruit-ribbon.png)

## Oyna

Telefon kontrolleri seçimin üzerine iki yana bölündü: solda Zıpla, sağda Vur/Takla; boss’ta Vur yerinde Ateş et. Ayarlardan eski sağ küme seçilebilir. Koyu/açık/sistem teması, sistem/pixel yazı ve büyütülmüş menü metni saklanır. Kol eylemleri yeniden atanabilir; titreşim varsayılan kapalıdır. [Kontroller](docs/CONTROLS.md).

Başlangıç kartlarından karakterini seç; koşu sırasında karakter değişmez. İlk dil cihaz/tarayıcı dilidir; desteklenmeyen diller İngilizce açılır. **TR / EN / CS / AZ / DE / FR / JA / KO / ZH / ES / IT** menüsünden değiştirebilirsin; seçimin ve rekorun cihazda saklanır.

| Karakter | Türkçe | English | Čeština | Yetenek |
| --- | --- | --- | --- | --- |
| Aion | Aion | Aion | Aion | Çift zıplama |
| Baykuş | Baykuş Ömer | Omar the Owl | Sova Omar | Zıpla ve basılı tut: süzül, hava akımını yakala |
| Kurt | Melun Bilge Kurt | Accursed Wise Wolf | Prokletý moudrý vlk | Shift / Depar basılı: dört ayakla hızlan |
| Koyun | Kutsanmış Cahil Koyun | Blessed Ignorant Sheep | Požehnaná nevědomá ovečka | En fazla üç can; küçük takipçiler gecikmeli zıplar |
| Tavşan | Tavşan Emre | Emre the Rabbit | Králík Emre | Güçlü tek sıçrama; yumruk ve tekme |

| Eylem | Klavye / fare | Telefon | Standart Xbox / PlayStation |
| --- | --- | --- | --- |
| Zıpla / süzül | Space; baykuş için basılı | Zıpla; basılı tut | A / × |
| Tek saldırı | Sol tık / J; tekrar için bırak ve bas | Vur; her dokunuş tek saldırı | X / □ |
| Takla | Aşağı / S / Ctrl | Aşağı kaydır veya Takla | B / ○ |
| Kurt deparı | Shift; karakterin üstünü basılı tut | Depar veya kurdun üstünü basılı tut | LB / L1 |
| Şimşek | Sağ tık / F; her basışta bir yük | Ayrı Şimşek düğmesi | RB / R1 veya RT / R2 |
| Boss’ta ateş | Sağ tık / F basılı | Ayrı Ateş et düğmesi | RB / R1 veya RT / R2 |
| Duraklat | Esc | Duraklat | Start / Options |

Düşerken düşmanın üstüne basarak sekebilirsin. Aion sırayla yumruk, baykuş kanat ve havada gaga, koyun kafa/çifte, kurt ısırık/pençe kullanır; depar ısırığı ayrıdır. Telefon hem dikey hem yatay oynanır; döndürmek koşuyu sıfırlamaz. İki parmakla eşzamanlı geçerli eylemler çalışır. Kısa telefon öğreticisini okurken dünya bekler; Devam et veya ilk oyun hareketinle başlar.

Altı biyom: Kehribar Çölü, Ayaz Vadisi, Sisli Bataklık, Bakır Şehir, Fener Ormanı ve Kor Sırtı. Gündüz/gece, hava olayları, kargalar, cüceler, seyrek ateş bitkileri, çukurlar ve kargaların taşıdığı üst engeller vardır. Her **20 saniyelik aktif normal koşu** yeni seviyedir; menü, duraklatma, sarılma ve boss zamanı bu sayaca girmez. Her on seviyede sarılma/silah teslimi ve üç tasarımı dönen boss kovalamacası vardır. Boss arenasında normal parkur temizlenir. İsteğe bağlı antrenman üç boss’u doğrudan denetir ve rekoru değiştirmez.

Meyveler +25, temiz aşılan engeller +10; mesafe de skor kazandırır. On toplanabilir güç bulunur. Sıçrama tılsımı 9 saniye daha yüksek zıplatır, şans parası 12 saniye meyve puanını ikiye katlar, buz feneri 8 saniye yakındaki yaklaşan düşmanları yavaşlatır. Dev mantar varsayılan %2 uygun eşya olasılığıyla nadirdir; ilk 20 saniyede ve önceki mantardan sonraki 45 saniyede gelmez. Mantar dalgasının toplam cüce üretimi yaklaşık yarıya indirildi; ortam cüceleri değişmedi. Her 100’ün katı eşiğinden sonraki ilk uygun boss zaferi **Fragaria çileğini** sunar. Bu nesne yalnız kısa kutlamadır; güç, puan veya başka oynanış ödülü vermez.

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

Windows: Setup ile kur veya portable ZIP’i tamamen çıkartıp EXE’yi aç. Linux: DEB, çalıştırma izni verilen AppImage veya portable tar.gz. macOS: universal DMG veya portable ZIP. Android: ARM64/x64 APK; önceki sürümle aynı uygulama kimliği ve imza, versionCode19. Gerçek paket listesi ve özetleri Releases içindedir. Önceki sürümler korunur.

İlk web yüklemesi internet ister; doğrulanmış tüm dosyalar önbelleğe alındıktan sonra çevrimdışı açılır. Mac paketi ad-hoc imzalıdır; Developer ID/noter onayı ve Windows Authenticode yoktur. Yerel iPhone/TestFlight/App Store için sahibinin Apple imzalaması gerekir; yerel portable iPhone paketi sunulmaz. Safari web sürümü ayrı bir seçenektir.

## Kaynaktan çalıştır ve derle

Godot 4.6.3 standard ile `project.godot` dosyasını içe aktar, **F5** ile başlat:

```sh
godot --editor --import --quit
godot --path .
python3 tests/test_web_packaging.py
godot --headless --script tests/test_runner_ux.gd
```

Tüm on beş kaynak/sahne testini `.github/workflows/build.yml` çalıştırır. Testler için gerçek oyuncu kaydından ayrı geçici XDG veri klasörleri kullan. Web: `python3 packaging/build_web.py`, çıktı `build/web`. Diğer hedefler resmi export templates ile `export_presets.cfg` içindedir. Android imza bilgileri kaynak kodda tutulmaz. Ayrıntılar: [BUILD](docs/BUILD.md), [VERCEL](docs/VERCEL.md), [VALIDATION](docs/VALIDATION.md). Tarihsel geliştirme notları [FORGE](FORGE.md) ve önceki kanıt klasörlerinde korunur.

GitHub geliştirme kaynağıdır. İstenen Drive proje kökü: [aion_endless_run](https://drive.google.com/drive/folders/1aj8Ma6N1ET_m4pNtDzPzCzYpbaaQsECf). `packaging/archive_project.py` tam commit’in özgün kaynak yollarıyla tarihli kopyasını, dosya boyutlarını ve SHA-256 envanterini üretir; Git geçmişi/issue/PR yedeği veya sürekli senkronizasyon değildir. Drive teslim işlemleri ayrı teslim raporunda doğrulanır.

## Görseller ve lisans

FireAxolotl/Extension kaynakları ve önceki paftalar korunur. Güncel kahraman tasarımları ile her PNG’nin kaynak/kare/hiza bilgileri `assets/*-PROVENANCE.json` içindedir. Yeni arayüz fontunun OFL lisansı ve Fragaria varlığının kökeni depodadır. [Kaynak ve lisans kayıtları](THIRD_PARTY_NOTICES.md). Chrome dinozorunun kodu veya görseli alınmadı. Hesap, reklam, telemetri, çevrimiçi puan tablosu veya ücretli kilit yok.

## English

An offline Godot pixel runner with five original heroes, six biomes, melee/rolling, varied weather/enemies/powers and repeating robot boss chases. Version 0.16 adds six illustrated Aionverse landscapes, eight safely placed common fruits and playable Emre the Rabbit with 144 drawn poses, preserving existing hero artwork and controls. Phones support portrait/landscape, multitouch and down-swipe rolls. Eleven languages follow the device locale by default, otherwise English. Levels take 20 active seconds; enemy XP and manually fired lightning remain. Installers and portable editions are under Releases; evidence distinguishes real browser/native-emulator tests from unavailable physical phone/controller and Apple distribution checks.
