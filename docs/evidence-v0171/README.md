# 0.17.1 · Tabanca, şarjör ve sığan menü

5.720 kaynak/sahne kontrolü, 34 gerçek Chromium kontrolü (9 menü/dil +25 oynanış), 7 web paketleme ve4 Android kayıt ayrıştırma testi geçti. [Kapsam ve sonuçlar](verification.json).

Beş karakterin gerçek tam tabanca-koşu döngüleri ortak yüz referansını korur. Sol tıkla beş atış ve boş şarjörün durması, normal koşuda R ile bir saniyelik doldurma, RB ile gerçek boss hasarı ve X/□ ile doldurma doğrulandı. Kurt dört ayaklı deparını, baykuş süzülmesini kendi tabanca katmanıyla korur. Mobil ateş dokunmasını iptal etmek tutuşu bırakır; dikey Doldur çalışır. Duraklatıp yön değiştirmek skor/mermi/doldurma sayacını korur. Dünya/RNG enjekte edilmez; eski dil/tema/yazı/rekor için açıkça tanımlanmış kayıt tercihi fixture'ı kullanılır.

![Koyu ana menü](screenshots/main-dark-1100x620.png)
![%200 yazıyla büyük ekran](screenshots/main-large-2048x1024.png)
![%200 yazıyla dikey telefon](screenshots/main-large-393x873.png)
![Normal koşuda tabanca](screenshots/aion-pistol.png)

[Normal gerçek girdilerin kaydı](normal-inputs.webm) · [Dikey dokunma kaydı](portrait-inputs.webm). Bunlar yazılımsal GPU kullanan Chromium testleridir; fiziksel telefon/kol kanıtı değildir. Ateş ettikten sonra ekran görüntüsü alınana kadar atış animasyonu bitmiş olabilir; gerçek mermi ve isabetler pasif durum gözlemleriyle doğrulanır.

Eski dil tercihi sistemi bastırabiliyordu; kullanıcının cihaz kaydı görülmediği için İtalyancanın ilk nedenini kesin bilmiyoruz. Kayıt fixture'ıyla bir kez TR sistem diline dönüş, rekor/tema/%200 yazının korunması, yeni IT seçiminin kalıcılığı ve Sistem dili seçeneği test edildi. Dört boyutta beş kart/üç eylem ekranda, birbirinden ayrı ve kaydırmasızdır. Uzun ayarlar hâlâ kaydırılır.

Aşağıdaki iki görüntü gerçek Godot renderer'ında seçilmiş biyom ve bilerek yerleştirilmiş nesnelerle **görsel test sahnesidir**; normal rastgele koşu kanıtı değildir.

![Çöl bitkileri görsel test sahnesi](screenshots/fixture-play-0.png)
![Orman bitkileri görsel test sahnesi](screenshots/fixture-play-4.png)

45 önceki asset PNG'si byte-byte aynı. Yeni bitki PNG'si üçer kareli6 tür içerir. Yeni adlar bütün11 dilde Aion, Kutsanmış, Melun, Ömer, Emre. Sistem temasını/yazı boyutunu değiştirerek taşma gizlenmedi. 15 aktif saniye seviye olur; boss/sarılma/duraklama sayılmaz. Uzun seviye/XP barları görünmez; rakamlar ve boss HP korunur.

## Yeniden doğrula

`tests/browser_firearm.py --menu-only --evidence ...` ve `--skip-menu --evidence ...` gerçek web çıktısını test eder. 0.16 ve öncesi browser sürücüleri tarihsel yakın-saldırı beklentileri taşır;0.17 silah davranışının kabul sürücüsü bu yeni dosyadır. CI on altı kaynak/sahne paketini ve gerçek yerel Android girişlerini çalıştırır. Üretim/paket sonuçları tamamlandıktan sonra aşağıya eklenir.

## Ek metin ve CI regresyonu

22 ek kontrol,11 dilde hareket/kol yardımını yeni15 saniye ve Doldur eylemiyle eşleştirir.0.17.0 adayında9 gerçek Android girişi geçti; eski `android-melee.png` adını arayan sonraki kapı başarısız oldu, indirme sürümü yayımlanmadı.0.17.1 gerçek `android-fire.png` ve `android-reload.png` görüntülerini denetler. İlk34 tarayıcı kontrolü son kol-yardımı cümlesinden önceki0.17.1 adayında yapılmıştır; son derleme ve yayın sonuçları ayrıca kaydedilir. İki flora görsel test sahnesi, aynı çizimleri kullanan0.17.0 renderer kaydından korunmuştur.
