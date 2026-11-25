class_name CampaignFieldUI
extends RefCounted

const TEXT := {
	"map":["Harita","Map"],
	"equipment":["Ekipman","Equipment"],
	"kit":["Ekipman","Kit"],
	"upgrades":["Gelişim","Upgrades"],
	"passages":["Geçitler","Passages"],
	"notes":["Notlar","Notes"],
	"effects":["Etkiler","Effects"],
	"shore_short":["Kıyı","Shore"],
	"quay_short":["İskele","Quay"],
	"relay_short":["Röle","Relay"],
	"arena_short":["Motor","Engine"],
	"back":["Geri","Back"],
	"current":["Buradasın","You are here"],
	"checkpoint":["Son kontrol noktası","Last checkpoint"],
	"checkpoint_entry":["Bölge girişi","Section entrance"],
	"checkpoint_flag":["İkmal bayrağı","Supply flag"],
	"upper":["Üst iskele","Upper deck"],
	"middle":["Orta yol","Causeway"],
	"lower":["Alt geçit","Lower passage"],
	"dry":["Kuru kanal","Drained channel"],
	"rumored":["Olası geçit","Possible passage"],
	"visited":["İzlenen yol","Path taken"],
	"open":["Açık","Open"],
	"locked":["Kilitli","Locked"],
	"pump_hint":["Alt kanaldaki pompayı çalıştır","Start the lower-channel pump"],
	"shore_goal":["Fener bekçisine ulaş","Reach the lantern keeper"],
	"quay_goal":["Kırık İskele’ye ilerle","Reach Broken Quay"],
	"fork_one_goal":["Kıyı kavşağına ilerle","Reach the coast junction"],
	"fork_goal":["Fiziksel bir geçit seç","Find a passage"],
	"signal_goal":["Sinyali Bakır Röle’ye kadar izle","Follow the signal to Copper Relay"],
	"relay_goal":["Sinyalin kaynağına ilerle","Reach the source of the signal"],
	"arena_goal":["Kök Motoru’nu durdur","Stop the Root Engine"],
	"final_clue":["Bakım emri donmuş gözlemevini işaret ediyor.","The maintenance order points to the frozen observatory."],
	"mechanism":["Pompa","Pump"],
	"root_hatch":["Kök kapağı","Root hatch"],
	"pistol_name":["Tabanca","Pistol"],
	"fists":["Yumruk","Fists"],
	"sidearm_stock":["Yedek tabanca mermisi","Sidearm rounds"],
	"life":["Can","Life"],
	"reserve":["Yedek","Spare"],
	"ability":["Özel yetenek","Special ability"],
	"supplies":["Aktif etkiler","Active effects"],
	"no_effects":["Aktif güçlendirme yok","No active boosts"],
	"relay_part":["Röle parçası","Relay part"],
	"upgrade_locked":["Bir bekçiyi kurtarınca bir gelişim seçebilirsin.","Rescue a keeper to choose an upgrade."],
	"upgrade_locked_short":["Önce bir bekçiyi kurtar.","Rescue a keeper first."],
	"upgrade_chose":["Seçili gelişim","Selected upgrade"],
	"upgrade_ready":["Bu görev için bir gelişim seç.","Choose one upgrade for this mission."],
	"insight":["Zekâ","Insight"],
	"spark":["Büyü","Magic"],
	"guard":["Direnç","Resistance"],
	"insight_effect":["Onarım ipucunu gösterir","Reveals repair clues"],
	"insight_effect_short":["Onarım izi","Repair clue"],
	"spark_effect":["Özel yetenek toparlanması hızlanır","Faster skill recovery"],
	"spark_effect_short":["Hızlı yetenek","Faster skills"],
	"spark_aion":["Havadaki sıçramalar yükselir","Higher air jumps"],
	"spark_aion_short":["Yüksek sıçrama","High air jump"],
	"spark_sheep":["Yardımcı daha uzaktan meyve toplar","Companion gathers from farther away"],
	"spark_sheep_short":["Yardımcı menzili","Longer reach"],
	"guard_effect":["Kalkan daha hızlı dolar","Faster shield recharge"],
	"guard_effect_short":["Hızlı kalkan","Fast shield"],
	"setting_auto_walk":["Yürüme yardımı","Walk assist"],
}
const MAP_POSITIONS := {
	"shore":Vector2(.06,.50),"quay":Vector2(.19,.50),"fork_one":Vector2(.32,.50),
	"canopy":Vector2(.44,.20),"fork_two":Vector2(.57,.20),"terrace":Vector2(.72,.13),
	"roots":Vector2(.69,.66),"water":Vector2(.51,.83),"causeway":Vector2(.53,.50),
	"relay":Vector2(.83,.50),"arena":Vector2(.95,.50),
}
const MAP_LINKS := [
	["shore","quay"],["quay","fork_one"],["fork_one","canopy"],["canopy","fork_two"],
	["fork_two","terrace"],["fork_two","roots"],["fork_one","water"],
	["fork_one","causeway"],["causeway","relay"],["water","relay"],
	["terrace","relay"],["roots","relay"],["relay","arena"],
]
const MAP_GLYPHS := {
	"shore":["..###..","...#...",".#####.","##...##","##.#.##","##...##",".#####."],
	"quay":[".......","#######",".......","#######",".#...#.",".#...#.",".#...#."],
	"fork_one":[".#...#.","..#.#..","...#...","...####","...#...","..#....",".#....."],
	"canopy":["....##.","...####","...###.",".#####.","#####..",".##.#..",".#....."],
	"fork_two":[".......",".#...#.","##...##","#.#.#.#","#..#..#",".......","......."],
	"terrace":[".....##",".....#.","...###.","...#...","####...","#......","#......"],
	"roots":["#######","..###..","...#...",".#.#.#.","..###..","...#...","..#.#.."],
	"water":["...#...","..###..","..###..",".#####.",".##.##.",".#####.","..###.."],
	"causeway":[".......","##...##",".#####.",".#.#.#.",".#####.","##...##","......."],
	"relay":["....###","...###.","..###..","..#....","..###..",".###...","###...."],
	"arena":[".#...#.","#######","##...##","##.#.##","##...##","#######",".##.##."],
}

static func text(host, key: String) -> String:
	if TEXT.has(key):return str(TEXT[key][0 if host.language=="tr" else 1])
	return host.t(key)

static func upgrade(w, key: String) -> bool:
	return CampaignUpgrades.selected(w,key)

static func equipped_weapon(host) -> String:
	var w: AionCampaignWorld=host.world
	if bool(w.mount.ridden):return host.t(CampaignVehicles.kind(w))+" ∞"
	if w.ammunition<=0:return text(host,"fists")
	var name: String=text(host,"pistol_name") if w.weapon=="pistol" else host.t(w.weapon)
	return "%s · %d"%[name,w.ammunition]

static func region(host) -> String:
	var w: AionCampaignWorld=host.world
	var locations: Array=CampaignContent.SCENES.get(w.section,[])
	if not locations.is_empty():
		return host.t(str(locations[clampi(int(w.player.x/w.length()*locations.size()),0,locations.size()-1)]))
	return host.t(w.section)

static func layer_key(w) -> String:
	if w.section=="causeway":return "middle"
	if not CampaignRoutes.is_fork(w.section):return ""
	var feet:=CampaignRoutes.foot(w)
	if feet.y<=CampaignRoutes.UPPER_FLOOR+19.:return "upper"
	if feet.y>CampaignRoutes.LOWER_FLOOR*.5:
		return "dry" if w.section=="fork_one" and w.activated.has("fork_one:pump") and feet.y>CampaignRoutes.LOWER_FLOOR+20. else "lower"
	return "middle"

static func goal_key(w) -> String:
	match w.section:
		"shore":
			for keeper in w.rescued:
				if str(keeper).begins_with("shore:"):return "quay_goal"
			return "shore_goal"
		"quay":return "fork_one_goal"
		"fork_one":
			if not w.activated.has("fork_one:pump"):
				if w.activated.has("fork_one:technician:relay_part") or upgrade(w,"insight"):return "pump_hint"
			return "fork_goal"
		"fork_two":return "fork_goal"
		"relay":return "relay_goal"
		"arena":return "final_clue" if w.completed else "arena_goal"
	return "signal_goal"

static func objective(host) -> String:
	return region(host)+" · "+text(host,goal_key(host.world))

static func location(host) -> String:
	var key:=layer_key(host.world)
	return text(host,"current")+" · "+region(host)+(" · "+text(host,key) if not key.is_empty() else "")

static func checkpoint(host) -> String:
	var w: AionCampaignWorld=host.world
	var name: String=host.t(str(w.rally.get("section",w.checkpoint)))
	var kind: String=text(host,"checkpoint_flag" if float(w.rally.get("x",140.))>180. else "checkpoint_entry")
	return text(host,"checkpoint")+" · "+name+" · "+kind

static func visited(w) -> Dictionary:
	var result: Dictionary={"shore":true,w.section:true}
	for stage in MAP_POSITIONS:
		if w.discovered.has("map:section:"+stage):result[stage]=true
	if w.section!="shore":result["quay"]=true
	if w.section not in ["shore","quay"]:result["fork_one"]=true
	for stage in w.route:
		if MAP_POSITIONS.has(stage):result[stage]=true
	if result.has("fork_two") or result.has("terrace") or result.has("roots"):
		result["canopy"]=true
		result["fork_two"]=true
	if w.section=="arena":result["relay"]=true
	return result

static func map_routes(host) -> Array[String]:
	var w: AionCampaignWorld=host.world
	var found:=visited(w)
	var rows: Array[String]=[]
	# The labels describe what the player has seen at the relevant junction.
	# Unknown paths stay outlined on the illustration and become named here.
	if not found.has("fork_one"):
		rows.append(text(host,"fork_one_goal"))
		return rows
	if w.section in ["canopy","fork_two","terrace","roots"] or found.has("fork_two"):
		rows.append(route_status(host,"upper","terrace",found))
		rows.append(route_status(host,"lower","roots",found))
		var hatch: String=text(host,"open" if CampaignRoutes.hatch_open(w) else "locked")
		rows.append(text(host,"root_hatch")+" · "+hatch)
	else:
		rows.append(route_status(host,"upper","canopy",found))
		if w.STAGES.has("causeway"):rows.append(route_status(host,"middle","causeway",found))
		rows.append(route_status(host,"lower","water",found))
		var pump: bool=w.activated.has("fork_one:pump")
		if pump or w.activated.has("fork_one:technician:relay_part") or upgrade(w,"insight"):
			rows.append(text(host,"mechanism")+" · "+text(host,"dry" if pump else "locked"))
	return rows

static func route_status(host, layer: String, destination: String, found: Dictionary) -> String:
	var status: String=text(host,"visited" if found.has(destination) else "rumored")
	return text(host,layer)+" · "+host.t(destination)+" · "+status

static func equipment_effects(host) -> Array[String]:
	var w: AionCampaignWorld=host.world
	var effects: Array[String]=[]
	for key in w.buffs:
		if float(w.buffs[key])>0.:
			effects.append(host.t(str(key))+" %d s"%ceili(float(w.buffs[key])))
	for assist in w.assists:
		if int(assist.remaining)>0:
			var name: String=host.old("name_owl" if assist.kind=="owl" else "name_wolf")
			effects.append(name+" ×"+str(assist.remaining))
	if w.character=="sheep" and w.flock>1:effects.append(host.t("flock_support"))
	if w.activated.has("fork_one:technician:relay_part") and not w.activated.has("fork_one:pump"):
		effects.append(text(host,"relay_part"))
	return effects

static func upgrade_effect(host, key: String, compact: bool=false) -> String:
	var suffix: String="_short" if compact else ""
	if key=="spark":
		if host.world.character=="aion":return text(host,"spark_aion"+suffix)
		if host.world.character=="sheep":return text(host,"spark_sheep"+suffix)
	return text(host,key+"_effect"+suffix)

static func screen_summary(host) -> String:
	if host.menu_kind=="map":
		var summary:=location(host)+" · "+checkpoint(host)+" · "+text(host,goal_key(host.world))
		if int(host.get_meta("field_page",0))>0:
			summary+=" · "+" · ".join(map_routes(host))
			var note:=CampaignStory.latest_note(host.world,host.language)
			if not note.is_empty():summary+=" · "+note
		return summary
	var w: AionCampaignWorld=host.world
	var status:=equipment_status(host)
	if w.weapon!="pistol":status+=" · "+text(host,"sidearm_stock")+" %d"%w.pistol_reserve
	status+=" · "+ability_summary(host)+" · "+effects_summary(host)
	var selected:=CampaignUpgrades.choice(w)
	if not selected.is_empty():status+=" · "+text(host,"upgrade_chose")+" · "+text(host,selected)
	return status

static func equipment_status(host) -> String:
	var w: AionCampaignWorld=host.world
	return equipped_weapon(host)+" · "+text(host,"life")+" %d/%d"%[w.hp,w.max_hp]+" · "+host.t("grenade")+" %d"%w.grenades

static func ability_summary(host) -> String:
	return text(host,"ability")+" · "+RunnerFrontText.ability_summary(host.language,host.world.character)

static func effects_summary(host) -> String:
	var effects:=equipment_effects(host)
	return text(host,"no_effects") if effects.is_empty() else text(host,"supplies")+" · "+" · ".join(effects)

static func add_pause_actions(host) -> void:
	var map: Button=host.action(text(host,"map"),func():open(host,"map"))
	var kit: Button=host.action(text(host,"equipment"),func():open(host,"equipment"))
	map.name="CampaignMap";kit.name="CampaignEquipment"
	pair(host,map,kit)

static func open(host, kind: String) -> void:
	host.set_meta("field_page",0)
	host.menu_kind=kind
	host.build_ui()

static func page(host, index: int) -> void:
	host.set_meta("field_page",index)
	host.build_ui()

static func pair(host, left: Button, right: Button) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	host.column.add_child(row)
	for button in [left,right]:
		button.reparent(row,false)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL

static func detail(host, caption: String, accent: bool=false) -> void:
	var line: Label=host.paragraph(caption,16)
	if accent:line.add_theme_color_override("font_color",host.options.color("accent"))
	host.column.add_child(line)

static func compact_panel(host) -> bool:
	return host.view_h<620. and host.options.text_scale>=1.5

static func prepare_compact(host) -> void:
	host.column.add_theme_constant_override("separation",6)
	host.menu.add_theme_stylebox_override("panel",host.options.style("surface","border",10))

static func build_map(host) -> void:
	var compact:=compact_panel(host)
	if compact:prepare_compact(host)
	var current_page:=clampi(int(host.get_meta("field_page",0)),0,2 if compact else 1)
	if current_page>0:
		var routes:=map_routes(host)
		if current_page==1:
			for index in mini(routes.size(),3) if compact else routes.size():detail(host,routes[index])
		if current_page==2 or not compact:
			if current_page==2:
				detail(host,checkpoint(host))
				if routes.size()>3:detail(host,routes[3])
			var clue:=CampaignStory.latest_note(host.world,host.language)
			if not clue.is_empty():detail(host,clue,true)
	else:
		detail(host,location(host),true)
		var map:=FieldMap.new()
		map.colors=host.options.colors
		map.current=host.world.section
		map.checkpoint=str(host.world.rally.get("section",host.world.checkpoint))
		map.found=visited(host.world)
		map.causeway=host.world.STAGES.has("causeway")
		map.font=host.ui.theme.default_font
		if host.options.text_scale<1.5:
			for id in ["shore","quay","relay","arena"]:map.labels[id]=text(host,id+"_short")
		map.custom_minimum_size.y=106. if compact else (142. if host.options.text_scale>=1.5 else 178.)
		host.column.add_child(map)
		detail(host,text(host,goal_key(host.world)))
		if not compact:detail(host,checkpoint(host))
	var next_page: int=(current_page+1)%(3 if compact else 2)
	var pane: Button=host.action(text(host,["map","passages","notes"][next_page]),func():page(host,next_page))
	var back: Button=host.action(text(host,"back"),func():open(host,"paused"))
	pane.name="CampaignMapPassages";back.name="CampaignMapBack"
	pair(host,pane,back)

static func build_equipment(host) -> void:
	var w: AionCampaignWorld=host.world
	var compact:=compact_panel(host)
	if compact:prepare_compact(host)
	var current_page:=clampi(int(host.get_meta("field_page",0)),0,2 if compact else 1)
	var skill_page:=2 if compact else 1
	if current_page==skill_page:
		var selected:=CampaignUpgrades.choice(w)
		var locked: String="upgrade_locked_short" if compact else "upgrade_locked"
		var status: String=text(host,"upgrade_ready" if CampaignUpgrades.available(w) else locked)
		if not selected.is_empty():status=text(host,"upgrade_chose")+" · "+text(host,selected)
		detail(host,status,true)
		for key in CampaignUpgrades.OPTIONS:
			var choice_key: String=key
			var action: Button=host.action(text(host,key)+" · "+upgrade_effect(host,key,compact),func():
				if CampaignUpgrades.choose(w,choice_key):host.save_checkpoint();host.build_ui())
			action.name="CampaignUpgrade_"+key
			action.disabled=not CampaignUpgrades.available(w)
	elif current_page==0:
		detail(host,equipment_status(host),true)
		if w.weapon!="pistol":
			detail(host,text(host,"sidearm_stock")+" %d"%w.pistol_reserve)
		detail(host,ability_summary(host))
	if current_page==0 and not compact or current_page==1 and compact:
		detail(host,effects_summary(host))
	var next_page: int=(current_page+1)%(3 if compact else 2)
	var page_keys: Array=["kit","effects","upgrades"] if compact else ["equipment","upgrades"]
	var pane: Button=host.action(text(host,page_keys[next_page]),func():page(host,next_page))
	var back: Button=host.action(text(host,"back"),func():open(host,"paused"))
	pane.name="CampaignEquipmentPage";back.name="CampaignEquipmentBack"
	pair(host,pane,back)

class FieldMap extends Control:
	var colors: Dictionary={}
	var current := ""
	var checkpoint := ""
	var found: Dictionary={}
	var causeway := false
	var font: Font
	var labels: Dictionary={}

	func map_position(id: String) -> Vector2:
		var normal: Vector2=MAP_POSITIONS[id]
		return (Vector2(23.,18.)+normal*(size-Vector2(46.,36.))).round()

	func _ready() -> void:
		mouse_filter=MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color(colors.background))
		draw_rect(Rect2(Vector2.ONE,size-Vector2(2.,2.)),Color(colors.border),false,2.)
		var ink:=Color(colors.muted)
		ink.a=.18
		for ratio in [.25,.5,.75]:
			var y:=floorf(size.y*ratio)
			for x in range(14,int(size.x)-14,6):draw_rect(Rect2(Vector2(x,y),Vector2(2.,1.)),ink)
		for link in MAP_LINKS:
			var start: String=link[0]
			var end: String=link[1]
			if not causeway and "causeway" in [start,end]:continue
			var a:=map_position(start)
			var b:=map_position(end)
			var used: bool=found.has(start) and found.has(end)
			if used:draw_line(a,b,Color(colors.accent),3.)
			else:draw_dashed_line(a,b,Color(colors.border),2.,5.,false)
		for id in MAP_POSITIONS:
			if id=="causeway" and not causeway:continue
			var at:=map_position(id)
			var visited: bool=found.has(id)
			var active: bool=id==current
			var icon_ink:=Color(colors.text) if visited else Color(colors.muted)
			var rim:=Color(colors.accent) if active else Color(colors.border)
			draw_rect(Rect2(at-Vector2(11.,11.),Vector2(22.,22.)),Color(colors.raised if visited else colors.background))
			draw_rect(Rect2(at-Vector2(11.,11.),Vector2(22.,22.)),rim,false,2. if active else 1.)
			var rows: Array=MAP_GLYPHS[id]
			for y in rows.size():
				for x in 7:
					if rows[y][x]=="#":draw_rect(Rect2(at-Vector2(7.,7.)+Vector2(x*2,y*2),Vector2(2.,2.)),icon_ink)
			if id==checkpoint:
				draw_rect(Rect2(at+Vector2(-11.,13.),Vector2(22.,3.)),rim)
			if active:
				draw_colored_polygon(PackedVector2Array([at+Vector2(-6.,-19.),at+Vector2(6.,-19.),at+Vector2(0.,-13.)]),rim)
		if font!=null:
			for id in labels:
				var title: String=labels[id]
				var at:=map_position(id)
				var title_width:=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
				var x:=clampf(at.x-title_width*.5,5.,size.x-title_width-5.)
				draw_string(font,Vector2(x,at.y+36.),title,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(colors.text))
