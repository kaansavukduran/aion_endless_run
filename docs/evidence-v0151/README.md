# 0.15.1 görsel iyileştirmesi

Dört yeni düşmanın kaba geometrik çizimleri ayrıntılı sprite animasyonlarıyla değiştirildi; mevcut kahraman tasarımları korunur. Telefon tuşlarının her çeyreği aynı integral piksel maskesini kullanır. İkonlar ve çerçeveler önbelleğe alınır; dokunma sınırı çizilen siluettir.

- 14 kaynak/sahne paketi: **3604 başarılı kontrol**. Yeni hedefli 152 kontrol; simetri, gerçek dokunma sınırı, farklı kareler, şeffaf kenarlar, sabit yüz/zemin ve ölçek.
- Gerçek tarayıcıda **29** animasyon/giriş/yön testi son yerel web derlemesinde geçti. Aion çift zıplama, baykuş süzülme, kurt deparı, koyun takipçileri, saldırı, takla, iptal ve çoklu dokunma korunur.
- **6** normal girişli rastgele karşılaşma kontrolü; altı biyom ve dört yeni düşman görülür. Bu tur aynı nihai düşman atlası ve önceki tuş görselleştirme derlemesindedir. Model durumunu değiştiren test API'si kullanılmaz.
- 40 önceki PNG başlangıç commit'iyle byte-byte aynıdır. Yeni PNG değişmeden saklanır; kayıt betiği yalnız metadata üretir.

![Gerçek normal koşuda yarasa ve yeni tuşlar](screenshots/normal-play-bat.png)
![Gerçek normal koşuda balçık](screenshots/normal-play-slime.png)

Aşağıdaki görüntüler gerçek Godot oyun renderer'ından, dört düşmanı aynı karede karşılaştırmak için **bilinçli olarak yerleştirilmiş görsel test sahnesidir**. Rastgele normal koşu kanıtı olarak sunulmaz.

![Yatay görsel test sahnesi](screenshots/fixture-four-enemies-landscape.png)
![Dikey görsel test sahnesi](screenshots/fixture-four-enemies-portrait.png)

İlk yoğun yazılımsal render turunda 5 saniyelik süzülme örnekleme beklemesi doldu. Değişmemiş testler son derlemede 29/29 geçti; eşzamanlı render yükünün kesin payı izole edilmedi. Sonuçlar ve kapsam [verification.json](verification.json) içindedir. Fiziksel Poco veya fiziksel oyun kolu denendiği iddia edilmez. CI/üretim/indirilebilir paket sonuçları tamamlandığında eklenir.
