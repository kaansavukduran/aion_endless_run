class_name RunnerFrontText
extends RefCounted
# New front-of-house copy lives here; existing game/campaign translations remain authoritative.
const KEYS := ["skip","demo","how","attract","intro","hero","confirm","move","jump","shoot","grenade","vehicle","rescue","secret","route","ability","previous","next"]
const WORDS := {
	"tr":["Atla","TANITIM · Herhangi bir tuşla dön","Nasıl oynanır?","Boştayken oynanış tanıtımı","Açılışı tekrar izle","Kahramanın","Seçimi onayla","Yürü ve nişan al","Zıpla","Ateş ve yakın etkileşim","Enerji bombası","Araca bin / araçtan in","Fener bekçilerini kurtar","Gizli alanları keşfet","Üst ve alt yolları keşfet","Kahramanın yeteneği","Önceki","Sonraki"],
	"en":["Skip","DEMO · Any input returns","How to play","Idle gameplay demonstration","Replay opening","Your hero","Confirm selection","Move and aim","Jump","Fire and close interaction","Energy grenade","Enter / leave vehicle","Rescue lantern keepers","Discover hidden areas","Explore upper and lower paths","Your hero's ability","Previous","Next"],
	"cs":["Přeskočit","UKÁZKA · Návrat libovolným vstupem","Jak hrát","Ukázka při nečinnosti","Přehrát úvod","Tvůj hrdina","Potvrdit výběr","Pohyb a míření","Skok","Střelba a blízká interakce","Energetický granát","Nastoupit / vystoupit","Zachraň strážce luceren","Objev skryté oblasti","Vyber si cestu","Schopnost hrdiny","Předchozí","Další"],
	"az":["Keç","TƏQDİMAT · Qayıtmaq üçün toxun","Necə oynanılır?","Boş vaxtda oyun təqdimatı","Açılışı yenidən göstər","Qəhrəmanın","Seçimi təsdiqlə","Hərəkət və nişan","Tullan","Atəş və yaxın əlaqə","Enerji bombası","Nəqliyyata min / en","Fənər gözətçilərini xilas et","Gizli yerləri kəşf et","Yolunu seç","Qəhrəmanın bacarığı","Əvvəlki","Sonrakı"],
	"de":["Überspringen","DEMO · Beliebige Eingabe zurück","Spielanleitung","Spielvorführung bei Inaktivität","Intro wiederholen","Dein Held","Auswahl bestätigen","Bewegen und zielen","Springen","Feuern und Nahinteraktion","Energiegranate","Einsteigen / aussteigen","Laternenwächter retten","Geheime Orte entdecken","Route wählen","Heldenfähigkeit","Zurück","Weiter"],
	"fr":["Passer","DÉMO · Toute entrée pour revenir","Comment jouer","Démonstration après inactivité","Revoir l'introduction","Votre héros","Confirmer le choix","Se déplacer et viser","Sauter","Tir et interaction proche","Grenade d'énergie","Monter / descendre","Sauver les gardiens","Découvrir les zones cachées","Choisir sa route","Capacité du héros","Précédent","Suivant"],
	"ja":["スキップ","デモ · 操作すると戻ります","遊び方","待機中のプレイデモ","オープニング再生","ヒーロー","選択を決定","移動と照準","ジャンプ","射撃と近距離操作","エネルギー爆弾","乗る・降りる","灯りの番人を救出","隠しエリアを探す","ルートを選ぶ","ヒーローの能力","前へ","次へ"],
	"ko":["건너뛰기","데모 · 조작하면 돌아갑니다","플레이 방법","대기 중 플레이 시연","오프닝 다시 보기","영웅","선택 확인","이동과 조준","점프","사격과 근접 상호작용","에너지 폭탄","탑승 / 하차","등불지기 구출","숨은 장소 발견","경로 선택","영웅 능력","이전","다음"],
	"zh":["跳过","演示 · 任意操作返回","玩法说明","闲置时演示游戏","重播开场","你的英雄","确认选择","移动与瞄准","跳跃","射击和近距离互动","能量炸弹","上车 / 下车","救出灯塔守卫","探索隐藏区域","选择路线","英雄能力","上一页","下一页"],
	"es":["Saltar","DEMO · Cualquier entrada para volver","Cómo jugar","Demostración al estar inactivo","Repetir introducción","Tu héroe","Confirmar selección","Moverse y apuntar","Saltar","Disparo e interacción cercana","Granada de energía","Subir / bajar del vehículo","Rescatar guardianas","Descubrir zonas secretas","Elegir ruta","Habilidad del héroe","Anterior","Siguiente"],
	"it":["Salta","DEMO · Qualsiasi comando per tornare","Come giocare","Dimostrazione durante l'inattività","Rivedi introduzione","Il tuo eroe","Conferma scelta","Muoversi e mirare","Saltare","Fuoco e interazione vicina","Granata d'energia","Salire / scendere","Salvare le guardiane","Scoprire zone segrete","Scegliere il percorso","Abilità dell'eroe","Precedente","Avanti"]
}
static func quick_controls(language: String,input: String,touch: bool,pad) -> PackedStringArray:
	var tr: bool=GameText.language_for_locale(language)=="tr"
	var move: String="Yürü" if tr else "Move"
	var fire: String="Ateş et" if tr else "Fire"
	var skill: String="Yetenek" if tr else "Skill"
	var bomb: String="Bomba" if tr else "Grenade"
	if input=="gamepad":
		return PackedStringArray(["L · "+move,pad.binding_name("jump")+" · "+word(language,"jump"),pad.binding_name("shoot")+" · "+fire,pad.binding_name("duck")+" · "+bomb+"   Y · "+skill])
	if touch:
		return PackedStringArray(["↔ ↕ · "+move,word(language,"jump")+" · "+fire,bomb,skill])
	return PackedStringArray(["A / D · "+move,"Space · "+word(language,"jump"),"F · "+fire,"G · "+bomb+" / E · "+skill])

static func word(language: String,key: String) -> String:
	if key=="pick_hero":return "Kahramanını seç" if language=="tr" else "Choose your hero"
	if key=="play_now":return "Başla" if language=="tr" else "Start"
	if key=="selected":return "Seçili" if language=="tr" else "Selected"
	language=GameText.language_for_locale(language)
	var index:=KEYS.find(key)
	return str(WORDS.get(language,WORDS.en)[index]) if index>=0 else key

const ABILITIES := {
	"tr":["İki kez bas: çift sıçrama","Üç koyun birlikte","Basılı tut: dört ayak depar","Tut: süzül · Üç kez kanat çırp","Bas: 1,75× · Tut: 4×","Bas: 1,75× · Tut: 4×"],
	"en":["Press twice: double jump","A flock of three","Hold: four-legged sprint","Hold: glide · Three wing flaps","Tap: 1.75× · Hold: 4×","Tap: 1.75× · Hold: 4×"],
	"cs":["Dva stisky: dvojskok","Stádo tří ovcí","Drž: sprint po čtyřech","Drž: plachti · Tři mávnutí","Stisk: 1,75× · Drž: 4×","Stisk: 1,75× · Drž: 4×"],
	"az":["İki dəfə bas: ikiqat tullan","Üç qoyun birlikdə","Tut: dörd ayaqla qaçış","Tut: süz · Üç qanad çırpma","Bas: 1,75× · Tut: 4×","Bas: 1,75× · Tut: 4×"],
	"de":["Zweimal drücken: Doppelsprung","Eine Herde aus drei Schafen","Halten: Sprint auf vier Pfoten","Halten: gleiten · Drei Flügelschläge","Kurz: 1,75× · Lang: 4×","Kurz: 1,75× · Lang: 4×"],
	"fr":["Deux pressions : double saut","Un troupeau de trois","Maintenir : sprint à quatre pattes","Maintenir : planer · Trois battements","Bref : 1,75× · Long : 4×","Bref : 1,75× · Long : 4×"],
	"ja":["2回押す：二段ジャンプ","3匹の群れ","長押し：四足ダッシュ","長押し：滑空・3回の羽ばたき","短押し1.75×・長押し4×","短押し1.75×・長押し4×"],
	"ko":["두 번 누르기: 이단 점프","세 마리의 양 떼","길게: 네 발 달리기","길게: 활공 · 세 번 날갯짓","짧게 1.75× · 길게 4×","짧게 1.75× · 길게 4×"],
	"zh":["按两次：二段跳","三只羊的队伍","长按：四足冲刺","长按：滑翔・三次振翅","短按1.75×・长按4×","短按1.75×・长按4×"],
	"es":["Pulsa dos veces: doble salto","Un rebaño de tres","Mantén: carrera a cuatro patas","Mantén: planear · Tres aleteos","Toca: 1,75× · Mantén: 4×","Toca: 1,75× · Mantén: 4×"],
	"it":["Premi due volte: doppio salto","Un gregge di tre","Tieni: corsa a quattro zampe","Tieni: plana · Tre battiti d'ali","Tocco: 1,75× · Tieni: 4×","Tocco: 1,75× · Tieni: 4×"]
}
const MISSION_ABILITIES := {
	"armadillo":{
		"tr":"Yetenek tuşuyla yuvarlan. Üç atılıştan sonra 3 saniye bekle.",
		"en":"Press Skill to roll. After three bursts, recharge for 3 seconds."
	},
	"frog":{
		"tr":"Yetenekle küçük düşmanı yut. Tekrar basıp tükür. Yutma aralığı 5 saniye.",
		"en":"Use Skill to swallow a small enemy. Press again to spit it out. Swallow cooldown: 5 seconds."
	}
}
const MISSION_MOTIVATIONS := {
	"aion": ["Kesik fener hattını izler.", "Traces the cut lantern wire."],
	"sheep": ["Sürüsünü güvene taşır.", "Guides the flock to safety."],
	"rabbit": ["İskele bekçilerine yardıma gelir.", "Comes to help the keepers."],
	"eren": ["Yarım kalan imdat çağrısını izler.", "Follows a broken distress call."],
	"armadillo": ["Bakım geçitlerini yeniden açar.", "Reopens the service passages."],
	"frog": ["Su kanalında kalanları arar.", "Looks for survivors in the canal."]
}

static func motivation(language: String, hero: String) -> String:
	var options: Array = MISSION_MOTIVATIONS.get(hero, [])
	if options.is_empty():
		return ""
	return str(options[0 if GameText.language_for_locale(language) == "tr" else 1])

static func endless_limited_label(language: String) -> String:
	return "Sonsuz · 4" if GameText.language_for_locale(language)=="tr" else "Endless · 4"

static func endless_availability(language: String) -> String:
	return "Sonsuz: ilk dört kahramanla." if GameText.language_for_locale(language)=="tr" else "Endless: original four heroes."

static func mission_ability(language: String,hero: String) -> String:
	var tr:=GameText.language_for_locale(language)=="tr"
	match hero:
		"aion":return "Üç kez zıpla." if tr else "Jump up to three times."
		"sheep":return "Yanına en çok bir koyun al." if tr else "Recruit up to one sheep companion."
		"rabbit","eren":return "Depara başlarken 3 saniye ateşle korunursun. Yeniden yakmak için 3 saniye bekle ve tekrar depara bas." if tr else "Sprint to ignite for 3 seconds. Wait 3 seconds and sprint again to reignite."
	return ability(language,hero)

static func ability_summary(language: String,hero: String) -> String:
	var tr:=GameText.language_for_locale(language)=="tr"
	match hero:
		"armadillo":return "Üç atılış" if tr else "Three roll bursts"
		"frog":return "Güçlü sıçrama ve dil" if tr else "Charged jump and tongue"
		"rabbit","eren":return "Güçlü sıçrama ve ateşli depar" if tr else "Charged jump and flame sprint"
	return mission_ability(language,hero)

static func ability(language: String,hero: String) -> String:
	language=GameText.language_for_locale(language)
	if MISSION_ABILITIES.has(hero):return str(MISSION_ABILITIES[hero].get(language,MISSION_ABILITIES[hero].en))
	var index: int=["aion","sheep","wolf","owl","rabbit","eren"].find(hero)
	return str(ABILITIES.get(language,ABILITIES.en)[maxi(0,index)])
