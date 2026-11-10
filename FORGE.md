# Forge · Aion Endless Run

Yetkili kaynak: https://github.com/kaansavukduran/aion_endless_run · `main`.

Yeni bağımsız Godot 4.6.3 oyunu. FireAxolotl kaynaklarına değişiklik yapılmadı. Kaynak PNG'ler değiştirilmeden alındı ve provenance kayıtları korundu. Aion 6×8 koşu paftası gerçek karelerini kullanır; arkadaşlar mevcut bekleme karelerini shader ile pikselleştirir, kendi yeni koşu paftaları henüz yoktur.

Ana akış: Space/sol tık/dokunma zıplama, Esc duraklatma; karakter seçimi, ayarlar, gerçek skor ve kristaller, kalıcı rekor/tercihler, ateş/buz sonlanması, iki biyom, gündüz/gece. Ses yerel sentezlenir. Ağ çağrısı/telemetri yok.

`tests/test_game.gd`: 39 anlamlı fizik ve gerçek sahne/menü/kayıt kontrolü. Son platform ve görsel doğrulama: `docs/VALIDATION.md`. Release kapsamı: `docs/RELEASE.md`. Paketleme: `.github/workflows/build.yml`, `packaging/`, `docs/BUILD.md`. Özel anahtarları kaynağa veya arşive ekleme.

Öncelikli sonraki işler: fiziksel dokunmatik cihaz deneyimi, arkadaşlar için kullanıcı onaylı yan profil koşu/zıplama paftaları, Apple Developer ID/noter onayı ve iOS TestFlight kurulumu. Kaynak projenin iOS hedefinin varlığı iPhone'da kurulabilir paket üretildiği anlamına gelmez. Mevcut ilk beta paketlerini ve etiketlerini koru.
