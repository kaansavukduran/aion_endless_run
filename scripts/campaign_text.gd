class_name AionCampaignText
extends RefCounted
const SUPPLEMENT=preload("res://assets/locales/campaign.json")
const EXPANSION=preload("res://assets/locales/campaign_expansion.json")
const UI=preload("res://assets/locales/campaign_ui.json")
const RHYTHM=preload("res://assets/locales/campaign_rhythm.json")

const EN := {
"arcade":"Play", "endless":"Endless", "title":"Beaconfall", "start":"Begin mission", "continue":"Continue checkpoint", "brief":"The coast's lanterns have gone dark. Free the keepers, follow the broken relay and stop the Root Engine.",
"help":"Move both ways. Hold fire; a nearby enemy changes it to a single close strike. Jump over low shots. Energy grenades break groups and armour.",
"keys":"A/D move · W/S aim up/down · diagonal with A/D · Space jump · F/left click fire · Right click grenade · Shift sprint · E ride · Esc pause", "touch":"Left stick: move left/right, aim up/down/diagonal · Right: jump, fire / close strike, grenade · Upper right: ride, exit or use skill when availableby", "pad":"Left stick / D-pad 8-way aim and move · Right stick independent aim · A/× jump · RB/R1 or X/□ fire · B/○ grenade · Y/△ ride · Start pause",
"grenade":"Grenade", "melee":"Strike", "ride":"Ride / exit", "rescue":"Free keeper", "clear":"Clear the relay", "checkpoint":"Checkpoint saved", "save_failed":"Checkpoint could not be saved. Retry saving before leaving.", "fork":"Choose your route", "fork_one":"Two paths lead inland. The high path divides again; the flooded channel has its own guardian.", "fork_two":"Above the roots, two routes reach the same relay. Which way?",
"shore":"Lantern coast", "quay":"Broken quay", "canopy":"Canopy crossing", "water":"Flooded channel", "terrace":"Garden terraces", "roots":"Root passage", "relay":"Copper relay", "arena":"Root Engine", "boss_intro":"ROOT ENGINE: Every road grows into my cage.\nKEEPER: Cut the signal! Watch its seed fan, jump the root wave, clear the drones.", "boss_warning":"Incoming!", "won":"Mission complete", "won_text":"The lanterns burn again. An unsigned maintenance order points toward the frozen observatory. Missions 2–5 are planned; this build contains Mission 1.", "retry":"Retry checkpoint", "grenades_empty":"No grenades", "keepers":"Keepers", "route":"Route", "weapon":"Weapon", "pistol":"Pistol ∞", "scatter":"Scatter", "arc":"Arc", "shield":"Shield", "move":"Move", "lives":"Life", "saved":"Saved", "save_retry":"Save checkpoint", "pause":"Paused", "dead":"Relay lost", "restart":"New mission", "back":"Main menu", "next":"Continue", "mission":"Mission 1", "settings_hint":"Theme, language, text size and remapped buttons use your main-menu settings.", "boost":"Outer stick: sprint", "special":"Hold jump to charge; release to launch.", "owl":"Hold to glide; tap again for up to three wingbeats."
}
const TR := {
"arcade":"Oyna", "endless":"Sonsuz", "title":"Sönen Fenerler", "start":"Göreve başla", "continue":"Kontrol noktasından sürdür", "brief":"Kıyının fenerleri söndü. Fener bekçilerini kurtar, kopan röleyi takip et ve Kök Motoru’nu durdur.",
"help":"İki yöne ilerle. Ateşi basılı tut; yakınında düşman varsa tek temas vuruşuna dönüşür. Alçak atışların üzerinden zıpla. Enerji bombası gruplara ve zırha etkilidir.",
"keys":"A/D yürü · W/S yukarı/aşağı nişan · çaprazda A/D · Space zıpla · F/sol tık ateş · Sağ tık bomba · Shift depar · E bin · Esc duraklat", "touch":"Sol joystick: sağ/sol yürü, yukarı/aşağı/çapraz nişan · Sağda zıpla, ateş / yakın saldırı, bomba · Sağ üstte bağlama göre bin, in veya özel yetenek", "pad":"Sol analog / yön tuşları sekiz yönlü nişan ve yürüyüş · Sağ analog bağımsız nişan · A/× zıpla · RB/R1 veya X/□ ateş · B/○ bomba · Y/△ bin · Start duraklat",
"grenade":"Bomba", "melee":"Vur", "ride":"Bin / in", "rescue":"Bekçiyi kurtar", "clear":"Röleyi temizle", "checkpoint":"Kontrol noktası kaydedildi", "save_failed":"Kontrol noktası kaydedilemedi. Ayrılmadan önce yeniden kaydet.", "fork":"Yolunu seç", "fork_one":"İçeriye iki yol var. Yüksek yol yeniden ayrılır; su kanalının ise kendi muhafızı var.", "fork_two":"Köklerin üstündeki iki yol da aynı röleye ulaşıyor. Hangi yol?",
"shore":"Fener kıyısı", "quay":"Kırık iskele", "canopy":"Dalların arası", "water":"Su kanalı", "terrace":"Bahçe terasları", "roots":"Kök geçidi", "relay":"Bakır röle", "arena":"Kök Motoru", "boss_intro":"KÖK MOTORU: Her yol kafesime uzanır.\nBEKÇİ: Sinyali kes! Tohum salvosundan kaç, kök dalgasını atla ve dronları indir.", "boss_warning":"Saldırı geliyor!", "won":"Görev tamamlandı", "won_text":"Fenerler yeniden yanıyor. Göndereni bilinmeyen bakım emri donmuş gözlemevini işaret ediyor. Görev 2–5 planda; bu sürüm yalnız ilk görevi içeriyor.", "retry":"Kontrol noktasından dene", "grenades_empty":"Bomba bitti", "keepers":"Bekçiler", "route":"Rota", "weapon":"Silah", "pistol":"Tabanca ∞", "scatter":"Saçma", "arc":"Ark", "shield":"Kalkan", "move":"Yürü", "lives":"Can", "saved":"Kaydedildi", "save_retry":"Kontrol noktasını kaydet", "pause":"Duraklatıldı", "dead":"Röle düştü", "restart":"Yeni görev", "back":"Ana menü", "next":"Devam", "mission":"Görev 1", "settings_hint":"Tema, dil, metin boyutu ve değiştirilen kol tuşları ana menü ayarlarını kullanır.", "boost":"Çubuğun dışı: depar", "special":"Zıplamayı tut: güç biriktir; bırak: sıçra.", "owl":"Tut: süzül; yeniden bas: en çok üç kanat çırpışı."
}
# New campaign copy is isolated from the existing eleven-language runner tables.
# Existing translated action labels remain authoritative in every locale.
const LOCAL := {
"cs":{"arcade":"Hrát","endless":"Nekonečný běh","title":"Zhaslé lucerny","start":"Zahájit misi","continue":"Pokračovat od kontrolního bodu","grenade":"Granát","melee":"Úder","ride":"Nasednout / sesednout","fork":"Vyber cestu","shore":"Pobřeží luceren","quay":"Rozbité molo","canopy":"Koruny stromů","water":"Zatopený kanál","terrace":"Zahradní terasy","roots":"Kořenová chodba","relay":"Měděné relé","arena":"Kořenový stroj","won":"Mise splněna","retry":"Zkusit kontrolní bod","mission":"Mise 1","back":"Hlavní nabídka","next":"Pokračovat"},
"az":{"arcade":"Oyna","endless":"Sonsuz qaçış","title":"Sönən fənərlər","start":"Missiyaya başla","continue":"Yoxlama nöqtəsindən davam et","grenade":"Qumbara","melee":"Vur","ride":"Min / düş","fork":"Yolunu seç","shore":"Fənər sahili","quay":"Qırıq körpü","canopy":"Budaqlar arası","water":"Su kanalı","terrace":"Bağ terrasları","roots":"Kök keçidi","relay":"Mis rele","arena":"Kök mühərriki","won":"Missiya tamamlandı","retry":"Yenidən sına","mission":"Missiya 1","back":"Əsas menyu","next":"Davam"},
"de":{"arcade":"Spielen","endless":"Endloslauf","title":"Erloschene Laternen","start":"Mission starten","continue":"Am Kontrollpunkt fortsetzen","grenade":"Granate","melee":"Schlag","ride":"Auf- / absteigen","fork":"Weg wählen","shore":"Laternenküste","quay":"Zerstörter Kai","canopy":"Baumkronen","water":"Überfluteter Kanal","terrace":"Gartenterrassen","roots":"Wurzelgang","relay":"Kupferrelais","arena":"Wurzelmaschine","won":"Mission geschafft","retry":"Kontrollpunkt wiederholen","mission":"Mission 1","back":"Hauptmenü","next":"Weiter"},
"fr":{"arcade":"Jouer","endless":"Course infinie","title":"Les lanternes éteintes","start":"Lancer la mission","continue":"Reprendre au point de contrôle","grenade":"Grenade","melee":"Frappe","ride":"Monter / descendre","fork":"Choisir une route","shore":"Côte des lanternes","quay":"Quai brisé","canopy":"Canopée","water":"Canal inondé","terrace":"Jardins en terrasse","roots":"Passage des racines","relay":"Relais de cuivre","arena":"Moteur-racine","won":"Mission terminée","retry":"Reprendre au point de contrôle","mission":"Mission 1","back":"Menu principal","next":"Continuer"},
"ja":{"arcade":"プレイ","endless":"エンドレス","title":"消えた灯り","start":"ミッション開始","continue":"チェックポイントから再開","grenade":"グレネード","melee":"近接攻撃","ride":"乗る・降りる","fork":"ルートを選択","shore":"灯りの海岸","quay":"壊れた波止場","canopy":"樹冠の道","water":"浸水した水路","terrace":"庭園の段丘","roots":"根の通路","relay":"銅の中継所","arena":"根のエンジン","won":"ミッションクリア","retry":"再挑戦","mission":"ミッション1","back":"メインメニュー","next":"続ける"},
"ko":{"arcade":"플레이","endless":"무한 달리기","title":"꺼진 등불","start":"임무 시작","continue":"체크포인트에서 계속","grenade":"수류탄","melee":"근접 공격","ride":"타기 / 내리기","fork":"경로 선택","shore":"등불 해안","quay":"부서진 부두","canopy":"나무 위 통로","water":"침수 수로","terrace":"정원 테라스","roots":"뿌리 통로","relay":"구리 중계소","arena":"뿌리 엔진","won":"임무 완료","retry":"체크포인트 재시도","mission":"임무 1","back":"메인 메뉴","next":"계속"},
"zh":{"arcade":"开始游戏","endless":"无尽奔跑","title":"熄灭的灯火","start":"开始任务","continue":"从检查点继续","grenade":"能量手雷","melee":"近战","ride":"乘坐 / 离开","fork":"选择路线","shore":"灯火海岸","quay":"破损码头","canopy":"树冠通道","water":"淹没水道","terrace":"花园梯田","roots":"树根通道","relay":"铜中继站","arena":"树根引擎","won":"任务完成","retry":"重试检查点","mission":"任务一","back":"主菜单","next":"继续"},
"es":{"arcade":"Jugar","endless":"Carrera infinita","title":"Faroles apagados","start":"Iniciar misión","continue":"Continuar desde el control","grenade":"Granada","melee":"Golpe","ride":"Subir / bajar","fork":"Elige tu ruta","shore":"Costa de los faroles","quay":"Muelle roto","canopy":"Copas de los árboles","water":"Canal inundado","terrace":"Jardines en terraza","roots":"Pasaje de raíces","relay":"Relé de cobre","arena":"Motor de raíces","won":"Misión completada","retry":"Reintentar control","mission":"Misión 1","back":"Menú principal","next":"Continuar"},
"it":{"arcade":"Gioca","endless":"Corsa infinita","title":"Lanterne spente","start":"Inizia missione","continue":"Riprendi dal checkpoint","grenade":"Granata","melee":"Colpo","ride":"Sali / scendi","fork":"Scegli il percorso","shore":"Costa delle lanterne","quay":"Molo spezzato","canopy":"Chiome degli alberi","water":"Canale allagato","terrace":"Terrazze del giardino","roots":"Passaggio delle radici","relay":"Relè di rame","arena":"Motore delle radici","won":"Missione completata","retry":"Riprova checkpoint","mission":"Missione 1","back":"Menu principale","next":"Continua"}}

const HERO_SKILL_TEXT := {
 "context_swap_short":["Değiştir","Swap"],
 "skill_roll":["Yuvarlan","Roll"],"skill_tongue":["Dil at","Tongue"],"skill_spit":["Tükür","Spit"],
 "skill_ready":["Hazır","Ready"],"skill_crouch":["Eğil","Crouch"],
 "skill_recover":["Toparlanıyor","Recovering"],"skill_cooldown":["Bekle","Cooldown"],
 "skill_active":["Aktif","Active"]
}

const ARCADE_LIFE_TEXT := {
	"life_rescues":["Bu canda kurtarılan","Rescued this life"],
	"field_points":["Saha puanı","Field score"],
	"clear_bonus":["Bitirme bonusu","Clear bonus"],
	"rescue_bonus":["Kurtarma bonusu","Rescue bonus"],
	"rank_perfect":["Kusursuz!","Perfect!"],
	"rank_great":["Harika!","Great!"],
	"continue_offer":["Devam edecek misin?","Continue?"],
	"continue_pick":["Kahramanını seç","Choose your hero"],
	"continue_choose":["Kahraman seç","Choose hero"],
	"continue_enter":["Mücadeleye dön","Return to action"],
	"continue_keys":["Enter ile kahraman seç.","Press Enter to choose a hero."],
	"continue_pad":["A / × veya Start ile kahraman seç.","Press A / × or Start to choose a hero."],
	"continue_touch":["Kahraman seç’e dokun.","Tap Choose hero."],
	"next_hero":["Sonraki","Next"],"previous_hero":["Önceki","Previous"],"go_back":["Geri","Back"],
	"game_over":["Oyun bitti","Game over"],"continue_count":["Devam","Continues"],
	"reserve_lives":["Yedek yaşam","Spare lives"],
	"restart_mission":["Görevi baştan başlat","Restart mission"],
	"flock_support":["Sürü · Eşya toplar","Flock · Collects items"],
	"downed_shot":["Mermi isabeti","Shot down"],
	"downed_impact":["Çarpışma","Collision"],
	"downed_hazard":["Patlama","Caught in a blast"],
	"downed_pit":["Çukura düştün","Fell into a pit"]
}

static func word(locale: String,key: String) -> String:
	if ARCADE_LIFE_TEXT.has(key):return str(ARCADE_LIFE_TEXT[key][0 if GameText.language_for_locale(locale)=="tr" else 1])
	if HERO_SKILL_TEXT.has(key):return str(HERO_SKILL_TEXT[key][0 if GameText.language_for_locale(locale)=="tr" else 1])
	locale=GameText.language_for_locale(locale)
	if RHYTHM.data.has(locale) and RHYTHM.data[locale].has(key):return str(RHYTHM.data[locale][key])
	if key=="fork_one":return "Fener Kavşağı" if locale=="tr" else "Lantern Junction"
	if key=="fork_two":return "Asma Geçit" if locale=="tr" else "Hanging Passage"
	if key=="boss_wave_jump":return "Kök dalgası · Zıpla" if locale=="tr" else "Root wave · Jump"
	if key=="boss_beam_move":return "İşaretli alandan çık" if locale=="tr" else "Leave the marked spot"
	if key=="continue_short":return "Sürdür" if locale=="tr" else "Continue"
	if key in ["owl_feather","arc_owl_feather"]:return "Ömer’in Tüyü · İki kaya saldırısı" if locale=="tr" else "Omar’s Feather · Two stone strikes"
	if key in ["wolf_charm","arc_wolf_charm"]:return "Melun’un Tılsımı · İki ısırık" if locale=="tr" else "Melun’s Charm · Two bites"
	if key=="help_route":return "Yolu dünya belirler: basamaklardan tırman, alçak geçitte eğilip sürün ya da kökle kilitli kapağı kırıp aşağı in." if locale=="tr" else "The world sets your path: climb the steps, crouch through a low passage, or break a root lock to open the hatch."
	if key=="keys":return "A/D yürü · S/↓ eğil · W/↑ yukarı nişan · Space zıpla · F/sol tık ateş · Sağ tık bomba · Shift depar · E etkileşim/özel yetenek · Esc" if locale=="tr" else "A/D move · S/↓ crouch · W/↑ aim up · Space jump · F/left click fire · Right click grenade · Shift sprint · E interact/use skill · Esc"
	if key=="crouch":return "Eğil" if locale=="tr" else "Crouch"
	if key=="touch":return "Sol joystick: yürü (dış kenarda depar); aşağı tutarak eğil · Sağda zıpla, ateş ve bomba · Sağ üstte bağlama göre bin, in veya özel yetenek" if locale=="tr" else "Left stick: move (outer edge sprints); hold down to crouch · Right: jump, fire and grenade · Upper right: ride, exit or use skill when available"
	if UI.data.has(locale) and UI.data[locale].has(key):return str(UI.data[locale][key])
	if EXPANSION.data.has(locale) and EXPANSION.data[locale].has(key):return str(EXPANSION.data[locale][key])
	if key=="keys":return word(locale,"move")+" A/D ←/→ · "+word(locale,"aim")+" W/S ↑/↓ · "+GameText.get_text(locale,"control_jump")+" Space · "+GameText.get_text(locale,"control_shoot")+" F/J · "+word(locale,"grenade")+" G · "+word(locale,"ride")+" E · Esc"
	if key=="pad":return word(locale,"move")+" ←/→ · "+word(locale,"aim")+" ↖↑↗←→↙↓↘ · A/× "+GameText.get_text(locale,"control_jump")+" · RB/R1 "+GameText.get_text(locale,"control_shoot")+" · B/○ "+word(locale,"grenade")+" · Y/△ "+word(locale,"ride")
	if locale=="tr" and TR.has(key): return str(TR[key])
	if LOCAL.has(locale) and LOCAL[locale].has(key): return str(LOCAL[locale][key])
	if SUPPLEMENT.data.has(locale) and SUPPLEMENT.data[locale].has(key):return str(SUPPLEMENT.data[locale][key])
	return str(EN.get(key,key))
