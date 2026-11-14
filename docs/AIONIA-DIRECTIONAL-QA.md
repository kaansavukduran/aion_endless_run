# Arcade sekiz yönlü ateş ve kurtarma karakteri ölçeği

> Tarihsel başlangıç kaydı: PR #3'ün `328fd0d42131f9fc857fe50f2a32488023461ce5` durumu. Aşağıdaki açık başlıklar bu ilk incelemeye aittir. Sonraki 0.25.0 uygulaması, gerçek sanat/namlu kayıtları ve test kapsamı [güncel Forge raporunda](AIONIA-FORGE-20261115.md) izlenir.

Durum: geliştirme dalında kodlandı; CI ve tarayıcı testi olmadan production'a hazır sayılmayacak.

## Kapsam
- Arcade için 8 yön: yatay, çapraz, dikey yukarı/aşağı; mevcut özel silahlar gerçek yön vektörüne bağlı.
- Klavye: A/D yürüyüş, W/S veya yukarı/aşağı nişan, F/J/sol tık ateş, Space zıpla, G bomba. Endless girdi düzeni değişmedi.
- Gamepad: sol analog/d-pad iki eksen, sağ analog bağımsız nişan önceliği, kayıtlı ateş tuşu. Dokunma: sol stick X/Y, sağ atış.
- Bağlı NPC ve yakın düşman için yatay nişanda mevcut bıçak/kurtarma etkileşimi; dikey nişan yalnız ateş.
- Kurtarılabilir kız NPC atlasının her satırı, ayakta duran Aion referans siluetinin 2 katı yüksekliğe göre hesaplanıyor. Hesap kaynak atlasın kesilmiş karesini temel alır; saç/aura ayrımı sanat incelemesi gerektirir.
- Yeni kod değiştirmeleri korunmuş eski sprite kaynağının üzerine yazmaz.

## Açık QA
- Onaylı kız karakterin gerçek anatomik yüksekliği ve animasyon kareleri için görsel kontrol gerekiyor. `size.y` kesimi aura veya ekstra parça içeriyorsa ölçüm revize edilecek.
- Yönlü atışın oyuncu silahı çizimi/kol pozu için yeni özgün yön animasyonları henüz tamamlanmış sayılmıyor. Bu nedenle koddaki yön işareti sadece ara geri bildirimdir.
- Attract Mode, yeni animasyonlu ana menü, tüm HUD ekranlarının sanat revizyonu ve sonuç ekranı bu kod dalında henüz tamamlanmadı. Tam kapsam kaynak prompt: `docs/AIONIA-ARCADE-UIUX-PROMPT.md`.
- Godot, gerçek browser, fiziksel dokunma ve gamepad testleri ayrı PASS/FAIL/NOT TESTED/BLOCKED olmalı.
- Vercel production'a yalnız kritik test PASS sonrası geçilecek; önceki çalışan sürüm korunacak.
