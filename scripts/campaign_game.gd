class_name AionCampaignGame
extends Node2D

const Words = preload("res://scripts/campaign_text.gd")
const FONT = preload("res://assets/PixelifySans.ttf")
const TRAVEL_DURATION := .36
const REDUCED_TRAVEL_DURATION := .1
const GRENADE_SOUNDS := {
	"grenade":preload("res://assets/audio/grenade-release.wav"),
	"grenade_bounce":preload("res://assets/audio/grenade-bounce.wav"),
	"grenade_blast":preload("res://assets/audio/grenade-blast.wav"),
	"hero_roll":preload("res://assets/audio/hero-roll.wav"),
	"hero_tongue":preload("res://assets/audio/hero-tongue.wav"),
	"hero_contact":preload("res://assets/audio/hero-contact.wav"),
	"sprint_ignite":preload("res://assets/audio/sprint-ignite.wav"),
	"boss_charge_warning":preload("res://assets/audio/root-charge.wav")
}
const WEAPON_SOUNDS := {
	"pistol":preload("res://assets/audio/fire-pistol.wav"),
	"heavy":preload("res://assets/audio/fire-heavy.wav"),
	"scatter":preload("res://assets/audio/fire-scatter.wav"),
	"arc":preload("res://assets/audio/fire-arc.wav"),
	"beam":preload("res://assets/audio/fire-beam.wav"),
	"disc":preload("res://assets/audio/fire-disc.wav"),
	"harpoon":preload("res://assets/audio/fire-harpoon.wav"),
	"seeker":preload("res://assets/audio/fire-seeker.wav"),
	"spore":preload("res://assets/audio/fire-spore.wav"),
	"trap":preload("res://assets/audio/fire-trap.wav"),
	"nova":preload("res://assets/audio/fire-nova.wav"),
	"skimmer":preload("res://assets/audio/fire-skimmer.wav"),
	"wind":preload("res://assets/audio/fire-wind.wav"),
	"shell":preload("res://assets/audio/fire-shell.wav"),
	"drill":preload("res://assets/audio/fire-drill.wav")
}
var world := AionCampaignWorld.new()
var impact_hold := 0.
var impact_cooldown := 0.
var defeat_sound_wait := 0.
var native_diagnostics := preload("res://scripts/campaign_native_diagnostics.gd").new()
var options := RunnerInterfaceOptions.new()
var pad := RunnerGamepad.new()
var selected_hero := "aion"
var language := "en"
var view: AionCampaignView
var layer: CanvasLayer
var ui: Control
var menu: PanelContainer
var column: VBoxContainer
var subtitle: Label
var boss_health: ProgressBar
var pause_button: Button
var stick: AionCampaignStick
var actions: Dictionary = {}
var screen_transform := Transform2D.IDENTITY
var view_w := 1152.
var view_h := 648.
var portrait := false
var touch_mode := false
var menu_kind := "briefing"
var saved: Dictionary = {}
var save_ok := true
var buttons: Array[Button] = []
var focus_index := 0
var stick_touch := -1
var touch_actions: Dictionary = {}
var held: Dictionary = {}
var left_down := false
var right_down := false
var up_down := false
var down_down := false
var mouse_stick := false
var mouse_axis := Vector2.ZERO
# Desktop pointer aim: the held gun turns toward the mouse in the play area.
var mouse_aim := false
var mouse_point := Vector2.ZERO
var pad_axis := Vector2.ZERO
var pad_look := Vector2.ZERO
var fade := -1.
var fade_loaded := false
var fade_panel: ColorRect
var boss_announced := false
var last_state := ""
var telemetry_clock := 0.
var save_message: Label
var audio_enabled := true
var motion_enabled := true
var audio_volume := .45
var voices: Array[AudioStreamPlayer] = []
var weapon_voice: AudioStreamPlayer
var sound_cache: Dictionary = {}
static var ambient_cache: Dictionary = {}
var ambient: AudioStreamPlayer
var ambient_key:=""
var ambient_started:=false
var ambient_starts:=0
var accessibility_callback: JavaScriptObject
var accessibility_stamp := ""
var active_input := "keyboard"
var ui_generation := 0
var ui_ready := false
var leaving_scene := false
var pad_menu_wait := 0.0
var help_step := 0
var outro_step := 0
var hud_panel: CampaignHUD
var hud_items := ForgeItemBank.new()
var presentation_stage := ""
var presentation_time := 0.0
var presentation: CampaignPresentation
var presentation_skip: Button
var complete_presented := false
var result_elapsed:=2.
var result_score: Label
var result_tick:=-1
var help_return := ""
var detail_page := 0
var settings_page := 0
var menu_previous := "paused"
var result_records: Dictionary = {}
var new_best := false
var resume_on_ready := false
var application_active := true
var checkpoint_invalid := false
var launch_on_ready := false
var settings_ok := true

# The large data-campaign QA mirror is for browser automation or ?aion-qa only.
var web_qa := false
var web_hidden_callback: JavaScriptObject
var web_update_callback: JavaScriptObject
var offer_label: Label
var offered_second := -1
var picker_preview: RunnerHeroPreview
var picker_info: Label
var confirm_buttons_down: Dictionary={}
const HeroPreview=preload("res://scripts/hero_preview.gd")

func _ready() -> void:
	native_diagnostics.host=self
	var cfg := ConfigFile.new(); cfg.load("user://save.cfg")
	RunnerBrowserSave.restore(cfg)
	options.load_from(cfg); pad.load_from(cfg)
	audio_enabled=bool(cfg.get_value("prefs","audio",true));audio_volume=float(cfg.get_value("prefs","volume",.45))
	motion_enabled=bool(cfg.get_value("prefs","motion",true))
	touch_mode=OS.has_feature("mobile")
	if OS.has_feature("web"): touch_mode=bool(JavaScriptBridge.eval("matchMedia('(pointer:coarse)').matches"))
	load_checkpoint()
	view=AionCampaignView.new();view.host=self;view.world=world;view.font=options.font_for(FONT);add_child(view)
	layer=CanvasLayer.new();add_child(layer)
	ui=Control.new();ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.theme=options.theme(FONT);layer.add_child(ui)
	if OS.has_feature("web"):
		accessibility_callback=JavaScriptBridge.create_callback(accessible_action)
		JavaScriptBridge.get_interface("window").aionAccessibleAction=accessibility_callback
		web_qa=bool(JavaScriptBridge.eval("navigator.webdriver===true||/[?&]aion-qa(=|&|$)/.test(location.search)"))
		# Godot's Web platform reports no focus loss for a hidden tab.
		web_hidden_callback=JavaScriptBridge.create_callback(on_web_page_hidden)
		JavaScriptBridge.get_interface("window").aionPageHidden=web_hidden_callback
		web_update_callback=JavaScriptBridge.create_callback(prepare_web_update)
		JavaScriptBridge.get_interface("window").aionSaveForUpdate=web_update_callback
		JavaScriptBridge.eval("if(!window.aionVisibilityInstalled){window.aionVisibilityInstalled=true;document.addEventListener('visibilitychange',()=>{if(document.hidden)window.aionPageHidden?.()})}")
		JavaScriptBridge.eval("if(!window.aionPageHideInstalled){window.aionPageHideInstalled=true;window.addEventListener('pagehide',()=>window.aionPageHidden?.())}")
		JavaScriptBridge.eval("(()=>{const c=document.getElementById('canvas');if(!c)return;['data-state','data-page','data-ui-ready','data-ui'].forEach(k=>c.removeAttribute(k));c.dataset.mode='campaign'})()")
	get_viewport().size_changed.connect(resize)
	Input.joy_connection_changed.connect(func(_id,_connected):release_all())
	resize(false)
	if launch_on_ready:begin_new()
	elif resume_on_ready and saved_can_resume():resume_saved()
	else:
		world.begin(selected_hero)
		build_ui()

func _exit_tree() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{const c=document.getElementById('canvas');c?.removeAttribute('data-campaign');c?.removeAttribute('data-mode');window.aionAccessibleAction=null;window.aionPageHidden=null;window.aionSaveForUpdate=null})()")

func on_web_page_hidden(_arguments: Array) -> void:
	if not is_inside_tree():return
	# Release inputs and pause an active run, as on focus loss. A hidden tab runs
	# no frames, so application_active stays untouched and cannot remain stuck.
	cancel_unspent_actions();release_all()
	if is_instance_valid(ui):
		if world.state=="playing":toggle_pause()
		elif world.state in CampaignLives.TRANSITIONS or world.state=="travel":save_checkpoint()

func prepare_web_update(_arguments: Array) -> bool:
	if world.state=="playing":
		toggle_pause()
	elif world.state in CampaignLives.TRANSITIONS or world.state=="travel" or (not save_ok and (menu_kind=="paused" or world.completed)):
		save_checkpoint()
	return save_ok

func t(key: String) -> String:
	if key.begins_with("arc_"):key=key.trim_prefix("arc_")
	return Words.word(language,key)
func old(key: String) -> String: return GameText.get_text(language,key)
func font_size(size: int) -> int: return roundi(size*options.text_scale)
func menu_title() -> String:
	return t({"briefing":"title","help":"controls","paused":"pause","dead":"game_over","continue_offer":"continue_choose","complete":"report","result_details":"details","outro":"won","settings":"settings"}.get(menu_kind,"title"))

func safe_rect(raw: Vector2) -> Rect2:
	if OS.has_feature("web"):
		var json = JavaScriptBridge.eval("(()=>{const d=document.createElement('div');d.style.cssText='position:fixed;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';document.body.append(d);const s=getComputedStyle(d),a=[parseFloat(s.paddingLeft),parseFloat(s.paddingTop),parseFloat(s.paddingRight),parseFloat(s.paddingBottom),innerWidth,innerHeight];d.remove();return JSON.stringify(a)})()")
		var a = JSON.parse_string(str(json))
		if a is Array and a.size()==6:
			var unit := Vector2(raw.x/maxf(1,float(a[4])),raw.y/maxf(1,float(a[5])))
			return Rect2(Vector2(float(a[0]),float(a[1]))*unit,raw-Vector2(float(a[0])+float(a[2]),float(a[1])+float(a[3]))*unit)
	if OS.has_feature("mobile"):return options.native_safe_layout(raw)
	return Rect2(Vector2.ZERO,raw)

func resize(rebuild: bool=true) -> void:
	if not is_instance_valid(ui):return
	release_all()
	var raw:=get_viewport_rect().size
	var safe:=safe_rect(raw)
	var aspect: float=safe.size.x/maxf(1.,safe.size.y)
	portrait=aspect<1.
	view_w=540. if portrait else maxf(960.,648.*aspect)
	view_h=view_w/aspect
	var factor: float=safe.size.x/view_w
	screen_transform=Transform2D(0,Vector2.ONE*factor,0,safe.position)
	layer.transform=screen_transform
	var zoom:=.72 if portrait else 1.
	view.transform=screen_transform*Transform2D(0,Vector2.ONE*zoom,0,Vector2.ZERO)
	view.scene_w=view_w/zoom;view.scene_h=view_h/zoom
	view.ground=(view_h-(220. if touch_mode else 92.))/zoom
	ui.size=Vector2(view_w,view_h)
	if rebuild:build_ui()

func label(value: String,size: int=20) -> Label:
	var item:=Label.new();item.text=value;item.add_theme_font_size_override("font_size",font_size(size));item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return item
func paragraph(value: String,size: int=20) -> Label:
	var item:=label(value,size);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return item
func action(value: String,callback: Callable,primary: bool=false) -> Button:
	var item:=Button.new();item.text=value;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size.y=maxf(48.,font_size(20)*1.4+12.)
	item.add_theme_font_size_override("font_size",font_size(20));item.pressed.connect(func():sound("menu_confirm");callback.call())
	item.focus_entered.connect(func():sound("menu_focus"))
	if primary:item.add_theme_stylebox_override("normal",options.style("primary","accent",8))
	buttons.append(item);column.add_child(item);return item

func build_ui() -> void:
	ui.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR if options.font_mode=="system" else CanvasItem.TEXTURE_FILTER_NEAREST
	ui_generation+=1
	ui_ready=false
	for child in ui.get_children():
		child.name="RetiredCampaign_"+str(child.get_instance_id())
		if child is CanvasItem:child.hide()
		child.queue_free()
	buttons.clear();actions.clear(); menu=null
	hud_panel=CampaignHUD.new();hud_panel.host=self;hud_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(hud_panel);hud_panel.refresh()
	var band_height: float=hud_panel.strip_height
	pause_button=Button.new();pause_button.name="CampaignPause";pause_button.text="II";pause_button.tooltip_text=old("pause");pause_button.add_theme_font_size_override("font_size",font_size(20));ui.add_child(pause_button)
	pause_button.position=Vector2(view_w-72,4);pause_button.size=Vector2(64,maxf(44.,band_height-8));pause_button.pressed.connect(toggle_pause)
	subtitle=label("",16);ui.add_child(subtitle);subtitle.position=Vector2(12,band_height+6);subtitle.size=Vector2(view_w-24,90);subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color",Color("fff3d8"));subtitle.add_theme_color_override("font_shadow_color",Color("211c29"));subtitle.add_theme_constant_override("shadow_outline_size",4)
	boss_health=ProgressBar.new();ui.add_child(boss_health);boss_health.show_percentage=false;boss_health.max_value=world.boss.max_hp
	boss_health.position=Vector2(12,band_height+6);boss_health.size=Vector2(minf(view_w-24.,340.),10.)
	boss_health.add_theme_stylebox_override("background",options.style("surface","border",1));boss_health.add_theme_stylebox_override("fill",options.style("primary","accent",1))
	if touch_mode: build_touch()
	fade_panel=ColorRect.new();fade_panel.color=Color(0.06,.06,.09,0);fade_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;fade_panel.size=Vector2(view_w,view_h);ui.add_child(fade_panel)
	presentation=null;presentation_skip=null
	if presentation_stage!="":build_presentation()
	if menu_kind!="": build_menu()
	update_hud()
	view.queue_redraw()
	finish_layout.call_deferred(ui_generation)

func finish_layout(generation: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or generation!=ui_generation:return
	ui_ready=true
	metadata()

func build_touch() -> void:
	stick=AionCampaignStick.new();stick.name="CampaignJoystick";stick.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(stick)
	stick.position=Vector2(24,view_h-177);stick.size=Vector2(150,150)
	var right_column := view_w - 120.0
	var left_column := view_w - 230.0
	var points := {
		"jump": Vector2(right_column, view_h - 111.0),
		"attack": Vector2(right_column, view_h - 218.0),
		"grenade": Vector2(left_column, view_h - 111.0),
		"context": Vector2(left_column + 5.0, view_h - 213.0),
	}
	for key in points:
		var item:=AionCampaignTouch.new();item.name="Campaign_"+key;item.action="shoot" if key=="attack" else key
		item.caption={"jump":old("control_jump"),"attack":old("control_shoot"),"grenade":t("grenade")}.get(key,"")
		item.font=options.font_for(FONT);item.palette=options.colors.duplicate();item.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if key=="grenade":item.palette.accent=AionCampaignWorld.COLORS[world.character]
		ui.add_child(item);item.position=points[key];item.size=Vector2.ONE*(90. if key=="context" else 100.);actions[key]=item
	var hint:=label(t("boost"),14);stick.add_child(hint);hint.position=Vector2(0,-29)

func build_menu() -> void:
	release_all()
	if menu_kind=="continue_offer":
		build_continue_picker()
		return
	var shade:=ColorRect.new();shade.color=Color("12101caa");shade.size=Vector2(view_w,view_h);ui.add_child(shade)
	menu=PanelContainer.new();menu.name="CampaignMenu";ui.add_child(menu);menu.add_theme_stylebox_override("panel",options.style("surface","border",16))
	var life_menu:=menu_kind=="dead"
	if life_menu:menu.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	menu.custom_minimum_size.x=minf(view_w-32,(570. if life_menu else 840.) if not portrait else 508.)
	menu.size.x=menu.custom_minimum_size.x
	column=VBoxContainer.new();column.add_theme_constant_override("separation",10);menu.add_child(column)
	var title:=label(menu_title(),24)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(title)
	match menu_kind:
		"briefing":
			if checkpoint_invalid:column.add_child(paragraph(t("save_corrupt"),17))
			column.add_child(paragraph(t("mission")+" · "+old("name_"+selected_hero),18))
			column.add_child(paragraph(t("brief")))
			if saved_can_resume():
				action(t("continue")+" · "+old("name_"+str(saved.get("character","aion"))),resume_saved,true).name="CampaignContinue"
			action(t("restart") if saved_can_resume() else t("start"),begin_new,true).name="CampaignBegin"
			if not saved.is_empty() and bool(saved.get("completed",false)):
				action(t("report"),func():
					if world.restore(saved):menu_kind="complete";new_best=false;build_ui()).name="CampaignLastReport"
			action(t("back"),return_main)
		"help":
			# Two short instruction pairs keep the real chosen font and 200%
			# text readable. System fonts have different line heights on Linux,
			# Windows and mobile; do not shrink text or hide the Skip action.
			var pages: Array[String]=[]
			var sentences: PackedStringArray=t("help").split(". ",false)
			for index in range(0,sentences.size(),2):
				var message: String=". ".join(sentences.slice(index,mini(index+2,sentences.size())))
				if not message.ends_with(".") and not message.ends_with("。"):message+="."
				pages.append(message)
			pages.append(t("touch") if touch_mode else pad_help() if not Input.get_connected_joypads().is_empty() else t("keys"))
			pages.append(t("help_rescue"))
			pages.append(t("help_route"))
			if world.character in world.CHARGE_HEROES:pages.append(t("special"))
			if world.character in ["aion","sheep","rabbit","eren","frog","armadillo"]:pages.append(RunnerFrontText.mission_ability(language,world.character))
			if world.character=="owl":pages.append(t("owl"))
			column.add_child(paragraph(pages[clampi(help_step,0,pages.size()-1)]))
			if options.text_scale<=1.5:
				var example:=CampaignPresentation.new();example.host=self;example.tutorial_topic="help";example.topic_index=mini(help_step,4);example.custom_minimum_size=Vector2(180,68);example.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(example)
			action(t("next"),func():
				help_step+=1
				if help_step>=pages.size():finish_help()
				else:build_ui(),true).name="CampaignGo"
			action(old("story_skip"),finish_help)
		"paused":
			action(old("resume"),close_menu,true).name="CampaignResume"
			action(t("controls"),func():help_return="paused";menu_kind="help";help_step=0;build_ui())
			action(t("settings"),func():menu_previous="paused";menu_kind="settings";settings_page=0;build_ui())
			action(t("restart_mission"),begin_new).name="CampaignRestart"
			action(t("back"),return_main).name="CampaignPauseMain"
		"dead":
			column.add_child(paragraph(old("score")+" %05d · " % world.score+t(world.checkpoint),20))
			action(t("restart"),begin_new,true).name="CampaignRestart"
			action(t("back"),return_main)
		"complete":
			var compact: bool=options.text_scale>1.5 and view_h<760.
			result_score=paragraph("",28)
			result_score.name="CampaignResultScore";column.add_child(result_score)
			update_result_score(0.)
			var rescues:=world.life_rescues()
			if world.losses==0 and rescues>=3:column.add_child(paragraph(t("rank_perfect" if rescues>=6 else "rank_great"),21))
			if not compact:
				var tally:=result_breakdown()
				if not tally.is_empty():column.add_child(paragraph(tally,16))
				column.add_child(paragraph(t("life_rescues")+" %d · "%rescues+t("elapsed")+" "+elapsed_time(world.time)+" · "+t("continue_count")+" %d"%world.continues_used,18))
				if not world.route.is_empty() and options.text_scale<=1.5:
					column.add_child(paragraph(t("route")+": "+" → ".join(world.route.map(func(s):return t(s))),16))
				if new_best:column.add_child(paragraph(t("new_best"),17))
			column.add_child(paragraph(t("to_be_continued"),18))
			var replay:=action(t("restart"),begin_new,true);replay.name="CampaignReplay"
			var details:=action(t("details"),func():detail_page=0;menu_kind="result_details";build_ui());details.name="CampaignReportDetails"
			var back:=action(t("back"),return_main);back.name="CampaignReportMain"
			if (not portrait and view_w>=960.) or compact:
				var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",8);column.add_child(controls)
				for button in ([details,back] if portrait else [replay,details,back]):
					button.reparent(controls);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		"result_details":build_report_details()
		"settings":build_settings()
		"outro":
			var pages: Array[String]=[t("won_text"),t("to_be_continued")]
			var last_page:=outro_step>=pages.size()-1
			column.add_child(paragraph(pages[mini(outro_step,pages.size()-1)],26 if last_page else 20))
			action(t("report" if last_page else "next"),func():
				outro_step+=1
				if outro_step>=pages.size():
					menu_kind="complete";result_elapsed=0.;result_tick=-1
				build_ui(),true)
			action(t("back"),return_main)
	if not save_ok:
		save_message=paragraph(t("save_failed"),16);column.add_child(save_message)
		action(t("save_retry"),func():save_checkpoint();build_ui())
	fit_menu.call_deferred(menu)

func update_result_score(dt: float) -> void:
	if menu_kind!="complete" or not is_instance_valid(result_score):return
	var motion: bool=motion_enabled and not options.reduced_motion
	result_elapsed=minf(1.85,result_elapsed+dt) if motion else 1.85
	var ratio:=clampf(result_elapsed/1.85,0.,1.)
	var value:=roundi(float(world.score)*smoothstep(0.,1.,ratio))
	var caption:=old("score")+" %05d"%value
	if result_score.text!=caption:result_score.text=caption
	var tick:=floori(result_elapsed/.135)
	if dt>0. and ratio<1. and tick!=result_tick:sound("tally_tick")
	result_tick=tick

func fit_menu(target: PanelContainer) -> void:
	if menu_kind=="complete":await get_tree().process_frame
	if not is_instance_valid(target) or not target.is_inside_tree() or not target.is_visible_in_tree(): return
	target.reset_size()
	var height: float=target.get_combined_minimum_size().y
	target.size.y=height
	target.position=Vector2(12.,12.) if menu_kind=="continue_offer" else Vector2(floorf((view_w-target.size.x)*.5),maxf(8.,floorf((view_h-height)*.5)))
	for i in buttons.size():
		if is_instance_valid(buttons[i]) and buttons[i].is_visible_in_tree() and not buttons[i].disabled:
			focus_index=i;buttons[i].grab_focus();break

func menu_back() -> bool:
	match menu_kind:
		"paused":close_menu();return true
		"settings":menu_kind=menu_previous;build_ui();return true
		"result_details":menu_kind="complete";build_ui();return true
		"help":finish_help();return true
		"briefing":return_main();return true
	return false

func elapsed_time(seconds: float) -> String:
	return "%02d:%02d"%[int(seconds)/60,int(seconds)%60]

func result_breakdown() -> String:
	var rescue_points:=world.life_rescues()*AionCampaignWorld.KEEPER_BONUS
	var tally_bonus:=AionCampaignWorld.CLEAR_BONUS+rescue_points
	if not world.awarded.has("mission:1") or world.score<tally_bonus:return ""
	return t("field_points")+" %d · "%(world.score-tally_bonus)+t("clear_bonus")+" %d · "%AionCampaignWorld.CLEAR_BONUS+t("rescue_bonus")+" %d"%rescue_points

func report_lines() -> Array[String]:
	var gun_names: Array=[]
	var vehicle_names: Array=[]
	for key in world.weapons_used:gun_names.append(t(key))
	for key in world.vehicles_used:vehicle_names.append(t(key))
	var roles: Dictionary={}
	for role in world.rescue_roles.values():roles[str(role)]=int(roles.get(str(role),0))+1
	var roles_text: Array[String]=[]
	for role in roles:roles_text.append(t(str(role))+" ×"+str(roles[role]))
	var record: Dictionary=Dictionary(Dictionary(saved.get("performance",{})).get("hero:"+world.character,{}))
	var values: Array[String]=[t("route")+": "+" → ".join(world.route.map(func(s):return t(s))),
		t("elapsed")+": "+elapsed_time(world.time)+" · "+t("defeated")+": "+str(world.kills)+" · "+t("best_chain")+": "+str(world.best_chain),
		t("damage_taken")+": "+str(world.losses)+" · "+t("secrets_found")+": "+str(world.discovered.size()),
		t("keepers")+": "+str(world.rescued.size())+" · "+t("arena")+": "+t("won"),
		old("best")+": %05d"%int(saved.get("best_score",world.score)),
		t("fastest")+": "+elapsed_time(float(record.get("time",world.time)))+" · "+t("best_rescues")+": "+str(record.get("rescues",world.rescued.size()))]
	var tally:=result_breakdown()
	if not tally.is_empty():values.append(tally)
	values.append(t("life_rescues")+" %d · "%world.life_rescues()+t("continue_count")+" %d"%world.continues_used)
	if new_best:values.append(t("new_best"))
	# Long inventories are individual facts, so ten weapons cannot create one
	# unbounded paragraph at 200% text in a short landscape viewport.
	for group in [["used_weapons",gun_names],["used_vehicles",vehicle_names],["rescued_roles",roles_text]]:
		if group[1].is_empty():values.append(t(group[0])+": —")
		else:
			for entry in group[1]:values.append(t(group[0])+": "+str(entry))
	return values

func build_report_details() -> void:
	var values:=report_lines()
	# One or two complete facts per page preserve 200% text without clipping.
	var count:=1 if options.text_scale>=1.5 else 2
	var page_count:=ceili(float(values.size())/count)
	detail_page=clampi(detail_page,0,page_count-1)
	for index in range(detail_page*count,mini(values.size(),(detail_page+1)*count)):
		column.add_child(paragraph(values[index],19))
	column.add_child(label("%d / %d"%[detail_page+1,page_count],16))
	if detail_page<page_count-1:action(t("next"),func():detail_page+=1;build_ui(),true).name="CampaignReportNext"
	if detail_page>0:action(t("previous"),func():detail_page-=1;build_ui()).name="CampaignReportPrevious"
	action(t("summary"),func():menu_kind="complete";build_ui()).name="CampaignReportBack"

func settings_change(key: String) -> void:
	match key:
		"theme":options.theme_mode=["dark","light","system"][( ["dark","light","system"].find(options.theme_mode)+1)%3];options.resolve_theme()
		"font":options.font_mode="pixel" if options.font_mode=="system" else "system"
		"text":options.text_scale=1. if options.text_scale>=2. else options.text_scale+.5
		"motion":options.reduced_motion=not options.reduced_motion
		"audio":audio_enabled=not audio_enabled
		"language":
			var locales: Array=GameText.LANGUAGES
			language=str(locales[(locales.find(language)+1)%locales.size()])
	var cfg:=ConfigFile.new();cfg.load("user://save.cfg");RunnerBrowserSave.restore(cfg);options.save_to(cfg)
	cfg.set_value("prefs","audio",audio_enabled)
	cfg.set_value("prefs","language",language)
	if key=="language":cfg.set_value("prefs","language_override",true);cfg.set_value("prefs","language_mode_revision",2)
	settings_ok=persist_preferences(cfg)
	ui.theme=options.theme(FONT);view.font=options.font_for(FONT);build_ui()

func persist_preferences(cfg: ConfigFile) -> bool:
	# Use the same revisioned browser recovery channel as the main menu, so a
	# quick reload cannot lose a language choice before asynchronous IDBFS sync.
	var revision:=maxi(int(cfg.get_value("meta","revision",0))+1,int(Time.get_unix_time_from_system()*1000.))
	cfg.set_value("meta","schema",1);cfg.set_value("meta","revision",revision)
	var mirror:=RunnerBrowserSave.persist(cfg,revision)
	var result:=cfg.save("user://campaign-prefs.tmp")
	if result==OK:result=DirAccess.rename_absolute("user://campaign-prefs.tmp","user://save.cfg")
	if OS.has_feature("web"):JavaScriptBridge.force_fs_sync()
	return result==OK or mirror

func build_settings() -> void:
	if not settings_ok:column.add_child(paragraph(t("prefs_failed"),17))
	var groups: Array= [
		[["language",str(GameText.LANGUAGE_NAMES.get(language,language))],["theme",old("theme_"+options.theme_mode)],["font",old("font_"+options.font_mode)]],
		[["text",str(roundi(options.text_scale*100.))+"%"],["motion",old("on") if options.reduced_motion else old("off")]],
		[["audio",old("on") if audio_enabled else old("off")]]]
	for item in groups[settings_page]:
		var key: String=item[0]
		action((old("language") if key=="language" else t("setting_"+key))+": "+str(item[1]),func():settings_change(key),false)
	action(t("next")+" %d/3"%[settings_page+1],func():settings_page=(settings_page+1)%3;build_ui())
	action(old("resume"),func():menu_kind=menu_previous;build_ui())

func saved_can_resume() -> bool:
	var phase: String=str(saved.get("phase","playing"))
	return not saved.is_empty() and not bool(saved.get("completed",false)) and phase!="dead" and not (phase in ["continue_offer","continue_pick"] and float(saved.get("offer_remaining",0.))<=0.)

func update_continue_offer() -> void:
	var seconds:=ceili(world.continue_remaining)
	if is_instance_valid(offer_label) and seconds!=offered_second:
		offered_second=seconds
		offer_label.text=str(seconds)

func build_continue_picker() -> void:
	menu=PanelContainer.new();menu.name="CampaignMenu";ui.add_child(menu)
	menu.add_theme_stylebox_override("panel",options.style("surface","border",10))
	menu.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	menu.custom_minimum_size.x=minf(view_w-24.,322.+76.*maxf(0.,options.text_scale-1.))
	menu.position=Vector2(12.,12.)
	column=VBoxContainer.new();column.add_theme_constant_override("separation",6);menu.add_child(column)
	var header:=HBoxContainer.new();column.add_child(header)
	var title:=label(menu_title(),17);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	offer_label=label("",26);offer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	offer_label.custom_minimum_size.x=font_size(36)
	offer_label.add_theme_color_override("font_color",options.color("accent"));header.add_child(offer_label)
	offered_second=-1;update_continue_offer()
	var paging:=HBoxContainer.new();paging.add_theme_constant_override("separation",6);column.add_child(paging)
	var hit_size:=48.
	if touch_mode:
		var logical_to_screen:=screen_transform.x.x
		if OS.has_feature("web"):
			logical_to_screen*=float(JavaScriptBridge.eval("window.innerWidth"))/maxf(1.,get_viewport_rect().size.x)
		else:logical_to_screen/=maxf(1.,DisplayServer.screen_get_scale())
		hit_size=maxf(hit_size,44./maxf(.5,logical_to_screen))
	var confirm:=action(t("continue_enter"),confirm_continue,true);confirm.name="ArcadeConfirmHero"
	confirm.custom_minimum_size.y=maxf(confirm.custom_minimum_size.y,hit_size)
	for direction in [-1,1]:
		var button:=action("‹" if direction<0 else "›",func():page_continue_hero(direction))
		button.tooltip_text=t("previous_hero" if direction<0 else "next_hero")
		button.custom_minimum_size=Vector2(hit_size,maxf(button.custom_minimum_size.y,hit_size))
		button.name="ArcadePreviousHero" if direction<0 else "ArcadeNextHero"
		button.reparent(paging,false)
	picker_preview=HeroPreview.new();picker_preview.portrait_art=true
	picker_preview.hero=world.continue_hero;picker_preview.animate=motion_enabled and not options.reduced_motion
	picker_preview.custom_minimum_size=Vector2(70.,56.);picker_preview.set_select_state("select")
	paging.add_child(picker_preview);paging.move_child(picker_preview,1)
	picker_info=paragraph(old("name_"+world.continue_hero),18)
	picker_info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;picker_info.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	paging.add_child(picker_info);paging.move_child(picker_info,2)
	fit_menu.call_deferred(menu)

func page_continue_hero(direction: int) -> void:
	if world.state!="continue_offer" or world.continue_remaining<=0.:return
	world.continue_hero=world.HEROES[posmod(world.HEROES.find(world.continue_hero)+direction,world.HEROES.size())]
	if is_instance_valid(picker_preview) and is_instance_valid(picker_info):
		picker_preview.hero=world.continue_hero;picker_preview.clock=0.;picker_preview.queue_redraw()
		picker_info.text=old("name_"+world.continue_hero)
	save_checkpoint();metadata()

func confirm_continue() -> void:
	if not CampaignLives.confirm(world,world.continue_hero):return
	selected_hero=world.character
	menu_kind="";save_checkpoint();build_ui()

func finish_help() -> void:
	if help_return!="":menu_kind=help_return;help_return="";build_ui();return
	close_menu()

func build_presentation() -> void:
	if presentation_stage!="boss_reveal":
		presentation=CampaignPresentation.new();presentation.host=self;presentation.clock=presentation_time;presentation.mouse_filter=Control.MOUSE_FILTER_IGNORE;presentation.size=Vector2(view_w,view_h);ui.add_child(presentation)
	presentation_skip=Button.new();presentation_skip.name="CampaignSkipPresentation";presentation_skip.text=old("story_skip");presentation_skip.add_theme_font_size_override("font_size",font_size(18));ui.add_child(presentation_skip)
	var skip_minimum:=presentation_skip.get_combined_minimum_size()
	var skip_width:=minf(maxf(176.,skip_minimum.x+16.),view_w-32.) if presentation_stage=="boss_reveal" else view_w-32.
	var skip_height:=maxf(58.,skip_minimum.y+4.)
	presentation_skip.position=Vector2(view_w-skip_width-16.,view_h-skip_height-18.);presentation_skip.size=Vector2(skip_width,skip_height);presentation_skip.pressed.connect(skip_presentation)
	buttons.append(presentation_skip)

func start_presentation(stage: String) -> void:
	release_all();presentation_stage=stage;presentation_time=0.;menu_kind="";world.state="complete" if stage=="victory" else "story"
	sound("boss_attack" if stage=="boss_reveal" else "victory");build_ui()

func skip_presentation() -> void:
	var stage:=presentation_stage
	if stage=="":return
	presentation_stage="";presentation_time=0.;release_all()
	if stage=="boss_reveal":
		world.boss.engaged=true;world.state="playing";save_checkpoint()
	else:menu_kind="outro";outro_step=0;save_checkpoint()
	build_ui()

func begin_new() -> void:
	release_all()
	checkpoint_invalid=false;world.begin(selected_hero);world.state="playing";menu_kind=""
	presentation_stage="";presentation_time=0.
	help_step=0;help_return="";outro_step=0;boss_announced=false
	view.camera_x=0.;view.camera_y=0.;impact_hold=0.;complete_presented=false;new_best=false
	save_checkpoint();sound("mission_start");build_ui()

func resume_saved() -> void:
	if not saved_can_resume():return
	if not world.restore(saved):checkpoint_invalid=true;world.begin(selected_hero);build_ui();return
	selected_hero=world.character
	menu_kind="continue_offer" if world.state=="continue_offer" else ""
	help_step=0;boss_announced=bool(world.boss.get("engaged",false))
	if world.recovery_view.has_area():
		view.camera_x=world.recovery_view.position.x
		view.camera_y=world.recovery_view.position.y+view.ground
	else:view.camera_x=clampf(world.player.x-view.scene_w*.34,0.,maxf(0.,world.length()-view.scene_w))
	save_checkpoint();build_ui()
func close_menu() -> void:
	release_all();menu_kind="";world.paused_crouch=false;world.state="playing";build_ui()
func toggle_pause() -> void:
	if world.state=="playing":
		world.paused_crouch=world.crouching();world.state="paused"
		release_all();menu_kind="paused";save_checkpoint();build_ui()
	elif menu_kind=="paused":close_menu()
func return_main() -> void:
	if leaving_scene:return
	release_all()
	if menu_kind!="briefing" and (world.checkpoint_ready or world.completed):save_checkpoint()
	if not save_ok: menu_kind="paused";build_ui();return
	leaving_scene=true
	# The emitting Button must remain in-tree until its input event finishes.
	get_tree().call_deferred("change_scene_to_file","res://main.tscn")

func load_checkpoint() -> void:
	var content: String=FileAccess.get_file_as_string("user://campaign.json") if FileAccess.file_exists("user://campaign.json") else ""
	if OS.has_feature("web"):
		var mirror = JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('aion.campaign.v1')||''}catch(_){return ''}})()")
		if mirror is String and not mirror.is_empty():content=mirror
	if content.is_empty():return
	var parsed=JSON.parse_string(content)
	if parsed is Dictionary:
		var probe:=AionCampaignWorld.new()
		if probe.restore(parsed):
			if not parsed.get("performance",{}) is Dictionary:parsed.performance={}
			saved=parsed;return
	checkpoint_invalid=true

func save_checkpoint() -> void:
	var data:=world.snapshot()
	data.best_score=maxi(int(saved.get("best_score",0)),world.score if world.completed else 0)
	var records: Dictionary=Dictionary(saved.get("performance",{})).duplicate(true)
	if world.completed:
		var route_key: String="/".join(world.route)
		for key in ["hero:"+world.character,"route:"+route_key]:
			var record: Dictionary=Dictionary(records.get(key,{}))
			new_best=new_best or world.score>int(record.get("score",-1))
			record.score=maxi(world.score,int(record.get("score",0)))
			record.time=minf(world.time,float(record.get("time",world.time)))
			record.rescues=maxi(world.life_rescues(),int(record.get("rescues",0)))
			record.losses=mini(world.losses,int(record.get("losses",world.losses)))
			records[key]=record
	data.performance=records
	var content:=JSON.stringify(data)
	var file:=FileAccess.open("user://campaign.tmp",FileAccess.WRITE)
	var disk_ok:=false
	if file!=null:
		file.store_string(content);file.flush();disk_ok=file.get_error()==OK;file.close()
		if disk_ok:disk_ok=DirAccess.rename_absolute("user://campaign.tmp","user://campaign.json")==OK
	var mirror_ok:=false
	if OS.has_feature("web"):
		mirror_ok=bool(JavaScriptBridge.eval("(()=>{try{localStorage.setItem('aion.campaign.v1',"+JSON.stringify(content)+");return localStorage.getItem('aion.campaign.v1')==="+JSON.stringify(content)+"}catch(_){return false}})()"))
		JavaScriptBridge.force_fs_sync()
	save_ok=disk_ok or mirror_ok
	if save_ok:saved=data.duplicate(true)

func release_all() -> void:
	# Pause clears input sources but retains the frozen visible aim. Menu and
	# settings rebuilds release inputs again, so preservation belongs here.
	var keep_paused_aim: bool=world.state=="paused"
	var frozen_aim: Vector2=world.aim_direction
	held.clear();touch_actions.clear();stick_touch=-1;left_down=false;right_down=false;up_down=false;down_down=false;mouse_stick=false;mouse_axis=Vector2.ZERO;pad_axis=Vector2.ZERO;pad_look=Vector2.ZERO
	world.stop_inputs()
	if keep_paused_aim:world.aim_direction=frozen_aim
	if is_instance_valid(stick):stick.axis=Vector2.ZERO;stick.active=false;stick.queue_redraw()

func set_action(key: String,source: String,down: bool,canceled: bool=false) -> void:
	# A press during the section fade must not remain latched when the next
	# section opens. Releases remain safe even for an already hidden control.
	if down and (fade>=0. or world.state!="playing" or CampaignVehicles.stunned(world)):return
	# Reject compact-form presses before adding a source to held. Reopening
	# the shell must require a new press, never a queued gun/jump/grenade.
	if down and key in ["attack","jump","grenade"] and MissionHeroAbilities.compact(world):return
	var sources: Dictionary=held.get(key,{})
	var before:=not sources.is_empty()
	if down:sources[source]=true
	else:sources.erase(source)
	held[key]=sources
	var after:=not sources.is_empty()
	if before==after:return
	match key:
		"jump":
			if after:world.jump_press()
			else:world.jump_release(not canceled)
		"attack":
			if after:
				update_arcade_aim()
				world.attack_press()
			else:world.attack_release()
		"grenade":
			if after:world.throw_grenade()
		"boost":world.boost_held=after
		"context":
			var item: AionCampaignTouch=actions.context
			if after and item.visible and not item.disabled:activate_context()

func discard_compact_actions() -> void:
	if not MissionHeroAbilities.compact(world):return
	for key in ["attack","jump","grenade"]:held.erase(key)
	world.attack_release();world.jump_release(false);world.jump_buffer_timer=0.

func cancel_unspent_actions() -> void:
	# Losing the application is an interruption, unlike an explicit pause.
	# Released bombs remain physical projectiles; only the held throw ends.
	CampaignGrenade.cancel(world)
	MissionHeroAbilities.cancel(world)

func activate_context() -> bool:
	if menu_kind!="" or presentation_stage!="" or fade>=0. or world.state!="playing":return false
	update_arcade_aim()
	var used: bool=world.interact()
	discard_compact_actions()
	return used

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		application_active=false
		cancel_unspent_actions();release_all()
		if is_instance_valid(ui):
			if world.state=="playing":toggle_pause()
			elif world.state in CampaignLives.TRANSITIONS:save_checkpoint()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(ui) and menu_kind!="briefing":save_checkpoint()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN or what==NOTIFICATION_WM_WINDOW_FOCUS_IN:application_active=true

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:active_input="touch";mouse_aim=false
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:active_input="gamepad";mouse_aim=false
	elif event is InputEventKey or (event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION):active_input="keyboard"
	if event is InputEventKey and menu_kind in ["continue_offer","dead"] and event.echo and (event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] or event.is_action("ui_accept")):
		get_viewport().set_input_as_handled();return
	if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_START]:
		var identity:=Vector2i(event.device,event.button_index)
		var was_down:=confirm_buttons_down.has(identity)
		if event.pressed:confirm_buttons_down[identity]=true
		else:confirm_buttons_down.erase(identity)
		if event.pressed and was_down and menu_kind in ["continue_offer","dead"]:
			get_viewport().set_input_as_handled();return
	if fade>=0. or world.state=="travel":
		release_all();get_viewport().set_input_as_handled();return
	if presentation_stage!="":
		if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]) or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_B,JOY_BUTTON_START]) or (event is InputEventScreenTouch and event.pressed and not event.canceled):
			skip_presentation();get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion and event.axis==JOY_AXIS_TRIGGER_RIGHT:
		if menu_kind=="":set_action("attack","trigger",event.axis_value>.5)
		get_viewport().set_input_as_handled();return
	if menu_kind=="continue_offer" and event is InputEventKey and event.keycode in [KEY_LEFT,KEY_RIGHT]:
		if event.pressed and not event.echo:page_continue_hero(-1 if event.keycode==KEY_LEFT else 1)
		get_viewport().set_input_as_handled();return
	if event is InputEventJoypadButton:
		if menu_kind!="":
			if not event.pressed:return
			if menu_kind=="continue_offer" and event.button_index in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
				page_continue_hero(-1 if event.button_index==JOY_BUTTON_DPAD_LEFT else 1)
			elif event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_RIGHT]:menu_focus(1)
			elif event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT]:menu_focus(-1)
			elif event.button_index in [JOY_BUTTON_A,JOY_BUTTON_X]:
				var focus:=get_viewport().gui_get_focus_owner()
				if focus is Button and focus.is_inside_tree() and focus.is_visible_in_tree() and not focus.disabled:focus.pressed.emit()
			elif event.button_index==JOY_BUTTON_B:menu_back()
			elif event.button_index==JOY_BUTTON_START:
				if menu_kind=="paused":close_menu()
				elif menu_kind=="continue_offer":confirm_continue()
			get_viewport().set_input_as_handled();return
		if event.button_index==JOY_BUTTON_START and event.pressed:toggle_pause();get_viewport().set_input_as_handled();return
		for key in ["jump","attack","shoot","duck","boost"]:
			if event.button_index==pad.bindings[key]:set_action({"shoot":"attack","duck":"grenade"}.get(key,key),"pad"+str(event.button_index),event.pressed)
		if event.pressed and event.button_index==interact_binding():activate_context()
		get_viewport().set_input_as_handled();return
	if menu_kind!="":return
	if world.state!="playing":get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		var p: Vector2=screen_transform.affine_inverse()*event.position
		if event.pressed and not event.canceled:
			# Each finger owns its initial action until release, even on a
			# disabled button. Dragging across controls never fires them.
			if touch_actions.has(event.index):
				get_viewport().set_input_as_handled();return
			for key in actions:
				if actions[key].hit(p):touch_actions[event.index]=key;set_action(key,"touch"+str(event.index),true);get_viewport().set_input_as_handled();return
			if is_instance_valid(stick) and stick_touch<0 and Rect2(stick.position,stick.size).has_point(p):
				stick_touch=event.index;stick.axis=stick.value(p);stick.active=true;stick.queue_redraw();get_viewport().set_input_as_handled()
		else:
			if touch_actions.has(event.index):
				var action: String=str(touch_actions[event.index])
				set_action(action,"touch"+str(event.index),false,event.canceled)
				touch_actions.erase(event.index);get_viewport().set_input_as_handled()
			if event.index==stick_touch:stick_touch=-1;stick.axis=Vector2.ZERO;stick.active=false;stick.queue_redraw();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if touch_actions.has(event.index):get_viewport().set_input_as_handled();return
		if event.index==stick_touch:stick.axis=stick.value(screen_transform.affine_inverse()*event.position);stick.queue_redraw();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION:
		var p: Vector2=screen_transform.affine_inverse()*event.position
		if event.button_index==MOUSE_BUTTON_RIGHT:
			set_action("grenade","mouse-right",event.pressed);get_viewport().set_input_as_handled();return
		if event.button_index==MOUSE_BUTTON_LEFT:
			if not event.pressed:
				for key in actions:set_action(key,"mouse-touch",false)
				mouse_stick=false;mouse_axis=Vector2.ZERO
				if is_instance_valid(stick):stick.axis=Vector2.ZERO;stick.active=false;stick.queue_redraw()
				set_action("attack","mouse",false)
			else:
				for key in actions:
					if actions[key].hit(p):set_action(key,"mouse-touch",true);get_viewport().set_input_as_handled();return
				if is_instance_valid(stick) and Rect2(stick.position,stick.size).has_point(p):mouse_stick=true;mouse_axis=stick.value(p);stick.axis=mouse_axis;stick.active=true;stick.queue_redraw();get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and not mouse_stick and event.device!=InputEvent.DEVICE_ID_EMULATION:
		mouse_aim=true;mouse_point=event.position
	elif event is InputEventMouseMotion and mouse_stick:
		mouse_axis=stick.value(screen_transform.affine_inverse()*event.position);stick.axis=mouse_axis;stick.queue_redraw();get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if fade>=0. or world.state=="travel":
		release_all();get_viewport().set_input_as_handled();return
	if event is InputEventKey:
		if event.echo:return
		if event.keycode==KEY_ESCAPE and event.pressed:
			if menu_kind!="":menu_back()
			else:toggle_pause()
			get_viewport().set_input_as_handled();return
		if menu_kind!="":return
		match event.physical_keycode:
			KEY_A,KEY_LEFT:left_down=event.pressed
			KEY_D,KEY_RIGHT:right_down=event.pressed
			KEY_W,KEY_UP:up_down=event.pressed
			KEY_S,KEY_DOWN:down_down=event.pressed
			KEY_SPACE:set_action("jump","keyboard",event.pressed)
			KEY_F,KEY_J:set_action("attack","key"+str(event.physical_keycode),event.pressed)
			KEY_G:set_action("grenade","keyboard",event.pressed)
			KEY_SHIFT:set_action("boost","keyboard",event.pressed)
			KEY_E:
				if event.pressed:activate_context()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and menu_kind=="" and event.button_index==MOUSE_BUTTON_LEFT:
		set_action("attack","mouse",event.pressed);get_viewport().set_input_as_handled()

func menu_focus(delta: int) -> void:
	if buttons.is_empty():return
	var focused:=get_viewport().gui_get_focus_owner()
	if focused in buttons:focus_index=buttons.find(focused)
	focus_index=posmod(focus_index+delta,buttons.size());buttons[focus_index].grab_focus()

func interact_binding() -> int:
	for candidate in [JOY_BUTTON_Y,JOY_BUTTON_X,JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		if candidate not in pad.bindings.values():return candidate
	return JOY_BUTTON_Y

func pad_help() -> String:
	var skill: Dictionary=MissionHeroAbilities.context(world)
	var context_label: String=t("ride")+(" / "+t(str(skill.label_key)) if bool(skill.visible) else "")
	return t("move")+" ↖ ↑ ↗ ← → ↙ ↓ ↘ · "+pad.binding_name("jump")+" "+old("control_jump")+" · "+pad.binding_name("shoot")+" "+old("control_shoot")+" · "+pad.binding_name("duck")+" "+t("grenade")+" · "+pad.binding_name("boost")+" "+old("control_boost")+" · "+str(pad.NAMES[interact_binding()])+" "+context_label

func poll_pad() -> void:
	pad_axis=Vector2.ZERO;pad_look=Vector2.ZERO
	if fade>=0. or world.state=="travel":return
	var pads:=Input.get_connected_joypads()
	if pads.is_empty():return
	var id: int=pads[0]
	if menu_kind!="":
		if menu_kind=="continue_offer":
			var horizontal:=Input.get_joy_axis(id,JOY_AXIS_LEFT_X)
			if absf(horizontal)>.55 and pad_menu_wait<=0.:
				page_continue_hero(1 if horizontal>0. else -1);pad_menu_wait=.3
			if absf(horizontal)<.2:pad_menu_wait=0.
			return
		var vertical:=Input.get_joy_axis(id,JOY_AXIS_LEFT_Y)
		if absf(vertical)>.55 and pad_menu_wait<=0.:menu_focus(1 if vertical>0. else -1);pad_menu_wait=.25
		if absf(vertical)<.2:pad_menu_wait=0.
		return
	var axis:=Input.get_joy_axis(id,JOY_AXIS_LEFT_X)
	if absf(axis)>pad.deadzone:pad_axis.x=signf(axis)*inverse_lerp(pad.deadzone,1.,absf(axis))
	if Input.is_joy_button_pressed(id,JOY_BUTTON_DPAD_LEFT):pad_axis.x=-1.
	if Input.is_joy_button_pressed(id,JOY_BUTTON_DPAD_RIGHT):pad_axis.x=1.
	var vertical: float=Input.get_joy_axis(id,JOY_AXIS_LEFT_Y)
	if absf(vertical)>pad.deadzone:pad_axis.y=signf(vertical)*inverse_lerp(pad.deadzone,1.,absf(vertical))
	if Input.is_joy_button_pressed(id,JOY_BUTTON_DPAD_UP):pad_axis.y=-1.
	if Input.is_joy_button_pressed(id,JOY_BUTTON_DPAD_DOWN):pad_axis.y=1.
	var look_x:float=Input.get_joy_axis(id,JOY_AXIS_RIGHT_X)
	var look_y:float=Input.get_joy_axis(id,JOY_AXIS_RIGHT_Y)
	if Vector2(look_x,look_y).length()>maxf(.25,pad.deadzone):pad_look=Vector2(look_x,look_y).normalized()

func start_travel() -> void:
	release_all();fade=0.;fade_loaded=false

func travel_duration() -> float:
	return REDUCED_TRAVEL_DURATION if options.reduced_motion else TRAVEL_DURATION

func advance_travel(dt: float) -> void:
	if fade<0. or not application_active:return
	var duration:=travel_duration();var midpoint:=duration*.5
	fade+=clampf(dt,0.,.05)
	if fade>=midpoint and not fade_loaded:
		world.finish_travel();release_all();view.camera_x=0.;view.camera_y=0.
		fade_loaded=true;boss_announced=false;save_checkpoint()
	fade_panel.color.a=clampf(fade/midpoint if not fade_loaded else (duration-fade)/midpoint,0.,1.)
	if fade>=duration:
		release_all();fade=-1.;fade_panel.color.a=0.

func update_arcade_aim(dt: float=0.) -> void:
	# Left stick controls movement in X and 8-way aiming in XY. Right stick,
	# when active, overrides aiming without changing movement (twin-stick).
	var axis: float=float(right_down)-float(left_down)
	var vertical: float=float(down_down)-float(up_down)
	if absf(pad_axis.x)>.01:axis=pad_axis.x
	if absf(pad_axis.y)>.01:vertical=pad_axis.y
	if mouse_stick:
		axis=mouse_axis.x;vertical=mouse_axis.y
	if stick_touch>=0 and is_instance_valid(stick):
		axis=stick.axis.x;vertical=stick.axis.y
	var raw:=Vector2(axis,vertical)
	var analog: bool=stick_touch>=0 or mouse_stick or absf(pad_axis.x)>.01 or absf(pad_axis.y)>.01
	# A grounded Down press is a low firing stance, not accidental floor aim.
	if vertical>.55 and world.grounded() and not bool(world.mount.ridden):raw.y=0.
	if pad_look.length_squared()>.25:raw=pad_look;analog=true
	var move_y:=vertical
	if world.character=="armadillo" and analog and not down_down and vertical>0. and absf(axis)>=vertical:
		move_y=0.
	world.move_axis=Vector2(axis,move_y)
	# Mouse aim: any angle toward the pointer, unless a stick, pad or W/S aim is in use.
	if mouse_aim and not analog and not up_down and (not down_down or world.grounded()) and is_instance_valid(view):
		var direction:=pointer_aim()
		if direction!=Vector2.ZERO:world.steer_aim(direction,0.);return
	if raw.length_squared()<.04:raw=Vector2(world.facing,0.)
	if analog and not bool(world.mount.ridden):
		# Sticks aim freely through 360 degrees; a nearly level push stays level.
		if absf(raw.y)<.12*raw.length():raw.y=0.
		world.steer_aim(raw.normalized(),dt);return
	var snapped:=Vector2(signf(raw.x) if absf(raw.x)>.25 else 0.,signf(raw.y) if absf(raw.y)>.25 else 0.)
	if snapped.length_squared()<.5:snapped=Vector2(world.facing,0.)
	world.steer_aim(raw.normalized() if bool(world.mount.ridden) else snapped.normalized(),dt)

func pointer_aim() -> Vector2:
	# Direction from the hand (or vehicle saddle) to the pointer, in screen space.
	var offset: Vector2=Vector2(0.,-42.) if bool(world.mount.ridden) else Vector2(M1CombatArt.placement(world).grip)
	var transform:=view.get_global_transform_with_canvas()
	# Between the two possible hand positions, a mirrored hand would cross
	# the pointer and reverse aim again next frame. Use the body centre there.
	var local_point:=transform.affine_inverse()*mouse_point
	if absf(local_point.x-view.at(world.player).x)<=absf(offset.x):offset.x=0.
	# During _draw the view already subtracts camera_y from its ground line.
	# Pointer events use the unshifted line, so project the same visible grip.
	var hand:=world.player+offset-Vector2(0.,view.camera_y)
	var toward:=mouse_point-transform*view.at(hand)
	return toward.normalized() if toward.length()>10. else Vector2.ZERO

func _process(dt: float) -> void:
	impact_cooldown=maxf(0.,impact_cooldown-dt);defeat_sound_wait=maxf(0.,defeat_sound_wait-dt)
	native_diagnostics.step(dt)
	world.pose_motion_enabled=motion_enabled and not options.reduced_motion
	if not is_instance_valid(view):return
	if presentation_stage!="" and application_active:
		presentation_time+=clampf(dt,0.,.05)
		var duration:=1.65 if presentation_stage=="boss_reveal" else 1.8
		if presentation_time>=duration:skip_presentation()
	update_ambient()
	update_result_score(dt)
	pad_menu_wait=maxf(0.,pad_menu_wait-dt)
	poll_pad()
	if world.state=="playing" and menu_kind=="" and fade<0.:
		update_arcade_aim(clampf(dt,0.,.05))
		discard_compact_actions()
		if (stick_touch>=0 or mouse_stick):world.boost_held=absf(world.move_axis.x)>.85 or not Dictionary(held.get("boost",{})).is_empty()
		var simulation_dt: float=clampf(dt,0.,.05)
		if impact_hold>0. and motion_enabled and not options.reduced_motion:
			var held_time: float=minf(impact_hold,simulation_dt);impact_hold-=held_time;simulation_dt-=held_time
		else:impact_hold=0.
		if simulation_dt>0.:world.step(simulation_dt)
	if world.state=="travel" and fade<0. and application_active:
		if last_state!="travel":release_all()
		if world.advance_exit(dt):start_travel()
	if world.state=="respawn_pending" and application_active:
		var area:=Rect2(view.camera_x,view.camera_y-view.ground,view.scene_w,view.ground+60.)
		CampaignLives.start_entry(world,area)
		view.camera_x=world.recovery_view.position.x
	if world.state in ["victory","dying","respawn"] and application_active:world.step(dt)
	if world.state=="continue_offer" and menu_kind=="continue_offer":
		var visible_play:=application_active
		if OS.has_feature("web"):visible_play=visible_play and not bool(JavaScriptBridge.eval("document.hidden || !document.hasFocus()"))
		if visible_play:
			var before:=ceili(world.continue_remaining)
			world.step(dt)
			if before!=ceili(world.continue_remaining):
				save_checkpoint()
				if world.continue_remaining>0.:sound("continue_tick")
		update_continue_offer()
	advance_travel(dt)
	if fade<0. and world.section=="arena" and not boss_announced and world.state=="playing" and absf(world.player.x-float(world.boss.x))<view.scene_w*.40:
		boss_announced=true;world.stop_inputs();start_presentation("boss_reveal")
	if (menu_kind=="" or (menu_kind=="continue_offer" and world.state=="dead")) and presentation_stage=="" and world.state in ["continue_offer","dead","complete"]:
		menu_kind=world.state;release_all()
		if world.state=="complete" and not complete_presented:
			complete_presented=true;save_checkpoint();start_presentation("victory")
		else:
			if world.state=="complete":menu_kind="outro";save_checkpoint()
			build_ui()
	for event in world.pending_events:
		if event in ["checkpoint","rescue","rescue_gift","secret","mechanism","life_changed","vehicle_impact","vehicle_wreck","shield_hit"] and menu_kind!="briefing":save_checkpoint()
		if event=="enemy" and impact_cooldown<=0. and motion_enabled and not options.reduced_motion and world.state=="playing":impact_hold=.035;impact_cooldown=.18
		if event in ["vehicle_impact","vehicle_wreck"]:
			if event=="vehicle_impact":release_all()
			sound("hurt" if event=="vehicle_impact" else "blast")
		if event.begins_with("shot:"):sound_weapon(event.trim_prefix("shot:"))
		elif event in ["melee","grenade","grenade_bounce","grenade_blast","hero_roll","hero_tongue","hero_contact","sprint_ignite","blast","pickup","rescue","hurt","cut","rescue_gift","gift_drop","npc_contact","secret","mechanism","enemy_shot","scout_shot","lob_throw","hive_drop","hive_splash","guardian","boss_attack","boss_port","boss_wave","boss_beam","boss_charge_warning","complete","checkpoint","enemy","armour_hit","shield_hit"]:sound(event)
	world.pending_events.clear()
	# Camera movement follows physics, never an atlas bounding box or ear tip.
	var old_camera:=Vector2(view.camera_x,view.camera_y)
	if world.state not in CampaignLives.TRANSITIONS:
		var desired_x:=clampf(world.player.x-view.scene_w*.34,0.,maxf(0.,world.length()-view.scene_w))
		if world.entry_guard and not options.reduced_motion:
			view.camera_x=lerpf(view.camera_x,desired_x,1.-exp(-minf(dt,.05)*8.))
		else:view.camera_x=desired_x
		var desired_y:=minf(0.,world.player.y+225.)
		if CampaignGround.PROFILES.has(world.section):desired_y+=maxf(0.,world.player.y)*.95
		desired_y=CampaignRoutes.camera_y(world,desired_y)
		view.camera_y=desired_y if options.reduced_motion else lerpf(view.camera_y,desired_y,1.-exp(-minf(dt,.05)*9.))
		world.recovery_view=Rect2(view.camera_x,view.camera_y-view.ground,view.scene_w,view.ground+60.)
	if world.state!="paused" or not old_camera.is_equal_approx(Vector2(view.camera_x,view.camera_y)):
		view.queue_redraw()
	update_hud()
	telemetry_clock+=dt
	if telemetry_clock>.1:telemetry_clock=0.;metadata()
	last_state=world.state

func update_hud() -> void:
	if not is_instance_valid(hud_panel):return
	hud_panel.refresh()
	var region: String=world.section
	if CampaignContent.SCENES.has(region):region=str(CampaignContent.SCENES[region][clampi(int(world.player.x/world.length()*3.),0,2)])
	subtitle.text=t("mission")+" · "+t(region)
	if world.weapon!="pistol" and world.ammunition<=5:subtitle.text+=" · "+t("low_ammo")
	if world.notice_time>0. and world.notice!="" and (save_ok or world.notice!="arc_checkpoint"):subtitle.text+="\n"+t(world.notice)
	if not save_ok:subtitle.text+="\n"+t("save_failed")
	var active_controls: bool=menu_kind=="" and fade<0. and world.state=="playing" and presentation_stage==""
	pause_button.visible=active_controls
	hud_panel.visible=menu_kind=="" and presentation_stage==""
	subtitle.visible=hud_panel.visible
	boss_health.position.y=hud_panel.strip_height+6.
	if boss_health.position.x+boss_health.size.x>pause_button.position.x:
		boss_health.position.y=maxf(boss_health.position.y,pause_button.position.y+pause_button.size.y+6.)
	boss_health.visible=world.section=="arena" and bool(world.boss.active) and menu_kind=="" and presentation_stage==""
	boss_health.value=world.boss.hp
	if boss_health.visible:
		var boss_cue: String=""
		var pattern:=int(world.boss.attack)%3
		if float(world.boss.get("beam_warning",0.))>0.:boss_cue=" · "+t("boss_beam_move")
		elif float(world.boss.get("echo_wait",0.))>0.:boss_cue=" · "+t("boss_echo")
		elif float(world.boss.windup)>0.:
			if pattern==1:boss_cue=" · "+t("boss_wave_jump")
			elif pattern==2 and int(world.boss.phase)==3:boss_cue=" · "+t("boss_dash")
			else:boss_cue=" · "+t("boss_warning")
		elif int(world.boss.phase)==2 and world.boss_vulnerable():boss_cue=" · "+t("boss_core")
		subtitle.text=t("arena")+" · "+t("phase")+" "+str(world.boss.phase)+boss_cue
	subtitle.position.y=boss_health.position.y+(20. if boss_health.visible else 0.)
	if is_instance_valid(stick):stick.visible=active_controls
	for key in actions:
		var item: AionCampaignTouch=actions[key]
		var prev_vis:=item.visible;var prev_p:=item.pressed;var prev_act:=item.action;var prev_cap:=item.caption;var prev_dis:=item.disabled;var prev_cd:=item.cooldown
		if key!="context":item.visible=active_controls
		item.pressed=not Dictionary(held.get(key,{})).is_empty()
		if key=="attack":
			var near:=not world.close_enemy().is_empty() and not bool(world.mount.ridden)
			var captive:=not CampaignRescue.cut_target(world).is_empty()
			item.action="cut" if captive else ("melee" if near else "shoot");item.caption=t("cut") if captive else (t("melee") if near else old("control_shoot"));item.cooldown=world.fire_time/.32;item.disabled=MissionHeroAbilities.compact(world)
		if key=="grenade":item.disabled=not CampaignGrenade.can_press(world);item.cooldown=world.grenade_time/.55
		if key=="jump":
			var diving: bool=bool(world.mount.ridden) and CampaignVehicles.kind(world)=="shell"
			item.caption=t("dive") if diving else old("control_jump");item.action="dive" if diving else "jump"
			item.disabled=MissionHeroAbilities.compact(world)
		if key=="context":update_touch_context(item,active_controls)
		if item.visible and (item.visible!=prev_vis or item.pressed!=prev_p or item.action!=prev_act or item.caption!=prev_cap or item.disabled!=prev_dis or not is_equal_approx(item.cooldown,prev_cd)):
			item.queue_redraw()

func update_touch_context(item: AionCampaignTouch,active_controls: bool) -> void:
	if not active_controls or not world.mount_transition.is_empty() or CampaignVehicles.stunned(world):
		item.hide();return
	var skill: Dictionary={}
	if not CampaignRhythm.offer(world).is_empty():item.action="swap_weapon"
	elif bool(world.mount.ridden):item.action="exit_vehicle"
	elif CampaignVehicles.can_board(world):item.action="board"
	else:
		skill=MissionHeroAbilities.context(world)
		if not bool(skill.visible):
			item.hide();return
		item.action=str(skill.label_key)
	item.visible=true
	item.disabled=not skill.is_empty() and not bool(skill.ready)
	var status: String=str(skill.get("status_key",""))
	item.caption=t("context_swap_short" if item.action=="swap_weapon" else (status if item.disabled and status=="skill_land" else item.action))
	item.cooldown=float(skill.get("cooldown",0.))
	var accessible_name: String=t(item.action)
	if item.accessibility_name!=accessible_name:item.accessibility_name=accessible_name
	var description: String=t(status) if item.disabled else ""
	if item.disabled and float(skill.get("remaining",0.))>0.:description+=" %.1f s"%float(skill.remaining)
	if item.accessibility_description!=description:item.accessibility_description=description

func update_ambient() -> void:
	if not audio_enabled:
		if ambient_started and is_instance_valid(ambient):ambient.stop()
		if is_instance_valid(weapon_voice) and weapon_voice.playing:weapon_voice.stop()
		ambient_started=false
		return
	var key: String=world.section if world.section in ["water","roots"] else "forest"
	if world.section=="arena" and bool(world.boss.get("engaged",false)):key="boss-battle"
	if not is_instance_valid(ambient):
		ambient=AudioStreamPlayer.new();ambient.playback_type=AudioServer.PLAYBACK_TYPE_STREAM;add_child(ambient)
	if ambient_key!=key:
		ambient.stop();ambient_started=false
		if not ambient_cache.has(key):
			if key in ["forest","boss-battle"]:
				var track: AudioStreamOggVorbis=load("res://assets/audio/mission1-"+key+".ogg").duplicate()
				track.loop=true
				ambient_cache[key]=track
			else:
				var track: AudioStreamWAV=load("res://assets/audio/campaign-"+key+".wav").duplicate()
				track.loop_mode=AudioStreamWAV.LOOP_FORWARD
				track.loop_end=int(track.get_length()*track.mix_rate)
				ambient_cache[key]=track
		ambient.stream=ambient_cache[key];ambient_key=key
	var music_gain:=.23 if key=="boss-battle" else .20
	if world.completed:music_gain*=1.-smoothstep(0.,1.2,world.victory_time)
	ambient.volume_db=linear_to_db(maxf(.001,audio_volume*music_gain))
	# Web sample playback does not provide a reliable frame-by-frame playing
	# signal for a paused/looping source. Start once at a track/unmute boundary.
	if not ambient_started:ambient.play();ambient_started=true;ambient_starts+=1
	ambient.stream_paused=menu_kind!="" or world.state not in ["playing","victory"]

func sound_weapon(kind: String) -> void:
	if not audio_enabled:return
	if not is_instance_valid(weapon_voice):
		weapon_voice=AudioStreamPlayer.new()
		weapon_voice.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(weapon_voice)
	weapon_voice.stream=WEAPON_SOUNDS.get(kind,WEAPON_SOUNDS.pistol)
	weapon_voice.volume_db=linear_to_db(maxf(.001,audio_volume*.75))
	weapon_voice.play()

func sound(event: String) -> void:
	if not audio_enabled:return
	if event in ["enemy","armour_hit"]:
		if defeat_sound_wait>0.:return
		defeat_sound_wait=.055
	if voices.is_empty():
		for i in 6:
			var voice:=AudioStreamPlayer.new();voice.playback_type=AudioServer.PLAYBACK_TYPE_STREAM;add_child(voice);voices.append(voice)
	if not sound_cache.has(event):
		if GRENADE_SOUNDS.has(event):sound_cache[event]=GRENADE_SOUNDS[event]
		else:
			var bytes:=PackedByteArray();var count:=3600 if event in ["blast","hurt"] else (2400 if event in ["enemy","armour_hit"] else 1400)
			var pitch: float={"melee":210.,"grenade":350.,"blast":75.,"pickup":880.,"rescue":660.,"hurt":140.,"cut":1050.,"rescue_gift":990.,"gift_drop":780.,"npc_contact":920.,"secret":740.,"mechanism":320.,"enemy_shot":280.,"guardian":190.,"boss_attack":110.,"boss_port":310.,"boss_wave":68.,"boss_beam":424.,"complete":1040.,"menu_focus":440.,"menu_confirm":730.,"mission_start":620.,"victory":1180.,"checkpoint":820.,"continue_tick":385.}.get(event,660.)
			if event.begins_with("boss_"):count=4500 if event=="boss_wave" else 2800
			if event=="enemy":pitch=180.
			elif event=="armour_hit":pitch=1140.
			elif event=="scout_shot":pitch=410.;count=1400
			elif event=="lob_throw":pitch=155.;count=2800
			elif event=="hive_drop":pitch=195.;count=2100
			elif event=="hive_splash":pitch=95.;count=3500
			elif event=="tally_tick":pitch=990.;count=850
			elif event=="shield_hit":pitch=875.;count=2600
			bytes.resize(count*2)
			for i in count:
				var phase: float=float(i)/22050.;var envelope: float=pow(1.-float(i)/count,2.)
				var sample:=sin(phase*pitch*TAU*(1.-float(i)/count*.4))*envelope*.22
				if event=="enemy":sample=(sin(phase*180.*TAU)*.6+sin(phase*73.*TAU)*.4)*envelope*.26
				elif event=="armour_hit":sample=(sin(phase*1140.*TAU)*.6+sin(phase*1733.*TAU)*.4)*envelope*.20
				bytes.encode_s16(i*2,int(sample*32700.))
			var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.data=bytes;sound_cache[event]=stream
	for voice in voices:
		if not voice.playing:voice.stream=sound_cache[event];voice.volume_db=linear_to_db(maxf(.001,audio_volume));voice.play();break
	if event=="hurt" and pad.haptics:
		for id in Input.get_connected_joypads():Input.start_joy_vibration(id,.2,.35,.1)

func metadata() -> void:
	if not OS.has_feature("web"):return
	accessible_update()
	if not web_qa:return
	var data: Dictionary=world.snapshot(false)
	data.merge({"state":world.state,"menu":menu_kind,"section":world.section,"player":[world.player.x,world.player.y],"facing":world.facing,"hp":world.hp,"shots":world.shots,"grenades":world.grenades,"melee":world.melee_time,"mounted":world.mount.ridden,"boss_hp":world.boss.hp,"save_ok":save_ok,"view":[view_w,view_h],"camera":view.camera_x,"pose":view.hero_marker,"actions":{},"transform":[screen_transform.x.x,screen_transform.origin.x,screen_transform.origin.y],"enemies":[],"platforms":[],"gates":[],"pits":[]})
	for key in actions:
		if key!="context" or actions[key].visible:data.actions[key]=[actions[key].position.x,actions[key].position.y,actions[key].size.x,actions[key].size.y]
	if is_instance_valid(stick):data.stick=[stick.position.x,stick.position.y,stick.size.x,stick.size.y]
	for e in world.enemies:
		if not bool(e.defeated):data.enemies.append({"kind":e.kind,"x":e.x,"y":e.y,"hp":e.hp,"windup":e.windup,"recover":e.get("recover",0.),"attacks":e.attacks})
	for p in world.platforms:data.platforms.append([p.position.x,p.position.y,p.size.x,p.size.y])
	for g in world.gates:data.gates.append({"x":g.x,"closed":world.gate_closed(g)})
	for p in world.pits:data.pits.append([p.x,p.y])
	var rects: Dictionary={}
	if ui_ready:
		for b in buttons:
			if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():rects[b.name]=[b.global_position.x,b.global_position.y,b.size.x,b.size.y,b.text]
	data.buttons=rects
	data.context_action={"visible":false}
	var context: AionCampaignTouch=actions.get("context")
	if is_instance_valid(context) and context.is_visible_in_tree():
		data.context_action={"rect":[context.position.x,context.position.y,context.size.x,context.size.y],"visible":true,"disabled":context.disabled,"text":context.caption,"icon":context.action}
	data.ui_generation=ui_generation
	data.ui_ready=ui_ready
	data.raw=[get_viewport_rect().size.x,get_viewport_rect().size.y]
	data.velocity=[world.velocity.x,world.velocity.y]
	data.move_axis=[world.move_axis.x,world.move_axis.y]
	data.keyboard_movement=[left_down,right_down,up_down,down_down]
	data.vehicle_stunned=CampaignVehicles.stunned(world)
	data.npcs=[]
	for n in world.npcs:data.npcs.append({"id":n.id,"x":n.x,"y":n.y,"freed":n.freed,"age":n.free_age,"gift":n.gift,"secret":n.secret,"phase":n.get("phase","bound"),"facing":n.get("facing",-1),"thank_age":n.get("thank_age",0.)})
	data.continue_remaining=world.continue_remaining;data.continue_hero=world.continue_hero
	data.boss_y=world.boss.y;data.boss_engaged=world.boss.engaged
	data.boss_warning=world.boss.get("beam_warning",0.);data.boss_beam_x=world.boss.get("beam_x",-999.);data.boss_x=world.boss.x;data.boss_phase=world.boss.phase;data.mount_type=CampaignVehicles.kind(world);data.music_starts=ambient_starts;data.native_memory=Performance.get_monitor(Performance.MEMORY_STATIC);data.node_count=Performance.get_monitor(Performance.OBJECT_NODE_COUNT);data.rescue_candidate=CampaignRescue.cut_target(world).get("id","");data.rescue_time=world.rescue_time;data.weapon=world.weapon;data.ammunition=world.ammunition;data.objects=world.objects;data.rooms=world.rooms
	data.bullets=[]
	for bullet in world.bullets:
		if bullet.owner=="enemy":data.bullets.append([bullet.p.x,bullet.p.y,bullet.v.x,bullet.v.y,bullet.kind])
	data.camera_y=view.camera_y;data.ground=view.ground
	data.travel_active=fade>=0. or world.state=="travel";data.travel_target=world.travel_target
	data.grounded=world.grounded();data.invulnerable=world.invulnerable;data.aim=[world.aim_direction.x,world.aim_direction.y]
	data.shield_charge=world.shield_charge;data.shield_ready=world.shield_ready()
	data.presentation=presentation_stage;data.presentation_time=presentation_time;data.help_step=help_step;data.hud_summary=hud_panel.summary;data.report_lines=report_lines();data.input_kind=active_input;data.mount_transition=world.mount_transition;data.mount_transition_time=world.mount_transition_time
	# Passive acceptance observations: these mirror real state, never mutate it.
	data.engine_process_frames=Engine.get_process_frames();data.engine_physics_frames=Engine.get_physics_frames()
	data.engine_process_seconds=Performance.get_monitor(Performance.TIME_PROCESS);data.engine_physics_seconds=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	data.crouching=world.crouching()
	data.charging=world.charging;data.charge_ratio=world.charge_ratio();data.jumps=world.jumps
	data.sprint_fire=world.sprint_fire;data.sprint_recovery=world.sprint_recovery
	data.roll_charges=world.roll_charges;data.roll_cooldown=world.roll_cooldown
	data.rally=world.rally;data.retry_count=world.retry_count;data.chain=world.chain;data.chain_time=world.chain_time;data.best_chain=world.best_chain
	data.weapon_offer=CampaignRhythm.offer(world);data.bridge_timers=world.bridge_timers;data.boss_ports=world.boss.get("ports",[]);data.boss_dash=world.boss.get("dash",0.)
	var hit: Vector2=world.player_hit_center()
	data.player_hit_center=[hit.x,hit.y];data.player_hit_radius=world.player_hit_radius()
	data.assist_attacks=world.assist_attacks;data.assists=[]
	for assist in world.assists:
		var stones:=[]
		for stone in assist.stones:stones.append({"x":stone.x,"y":stone.y,"age":stone.age})
		data.assists.append({"kind":assist.kind,"remaining":assist.remaining,"age":assist.age,"phase":assist.phase,"x":assist.x,"y":assist.y,"stones":stones})
	data.pickups=[]
	for item in world.pickups:
		if not world.taken.has(str(item.id)):data.pickups.append(item.duplicate(true))
	data.hero_projectiles=[]
	var mouth: Vector2=MissionHeroAbilities.mouth(world)
	var tongue_tip: Vector2=MissionHeroAbilities.tongue_tip(world)
	data.hero_skill={"phase":world.hero_skill.get("phase",""),"clock":world.hero_skill.get("clock",0.),"hits":world.hero_skill.get("hits",[]).duplicate(),"extent":world.hero_skill.get("extent",0.),"mouth":[mouth.x,mouth.y],"tongue_tip":[tongue_tip.x,tongue_tip.y]}
	data.grenade_throw={"phase":world.grenade_throw.get("phase",""),"elapsed":world.grenade_throw.get("elapsed",0.),"released":world.grenade_throw.get("released",false)}
	data.bombs=[]
	for bomb in world.bombs:data.bombs.append({"p":[bomb.p.x,bomb.p.y],"v":[bomb.v.x,bomb.v.y],"age":bomb.age})
	data.grenade_blasts=[]
	for blast in world.blasts:
		if str(blast.get("kind",""))=="grenade":data.grenade_blasts.append({"p":[blast.p.x,blast.p.y],"age":blast.age})
	for bullet in world.bullets:
		if bullet.owner=="hero":data.hero_projectiles.append({"p":[bullet.p.x,bullet.p.y],"v":[bullet.v.x,bullet.v.y],"kind":bullet.kind,"age":bullet.age})
	data.spiders=[]
	for bullet in world.bullets:
		if str(bullet.kind)=="trap":data.spiders.append({"p":[bullet.p.x,bullet.p.y],"age":bullet.age,"target":bullet.get("target","")})
	JavaScriptBridge.eval("document.getElementById('canvas')?.setAttribute('data-campaign',"+JSON.stringify(JSON.stringify(data))+");")

func accessible_action(args: Array) -> void:
	if args.size()<2:return
	var item=instance_from_id(int(str(args[1])))
	if not is_instance_valid(item) or not item is Button or not item.is_inside_tree() or not ui.is_ancestor_of(item) or not item.is_visible_in_tree() or item.disabled:return
	if str(args[0])=="focus":item.grab_focus()
	elif str(args[0])=="activate":item.pressed.emit()

func accessible_update() -> void:
	if not ui_ready:return
	var entries:=[]
	for item in ui.find_children("*","Button",true,false):
		if item.is_visible_in_tree():entries.append({"id":str(item.get_instance_id()),"label":item.tooltip_text if item.text in ["II","‹","›"] else item.text,"disabled":item.disabled,"toggle":false,"pressed":false})
	var summary: String=menu_title() if menu_kind!="" else hud_panel.summary
	if menu_kind=="continue_offer":summary+=" · %d · "%ceili(world.continue_remaining)+old("name_"+world.continue_hero)
	if menu_kind=="" and world.section=="arena" and bool(world.boss.active):summary+=" · "+t("arena")+" %d/%d"%[world.boss.hp,world.boss.max_hp]+" · "+t("phase")+" "+str(world.boss.phase)
	if presentation_stage=="boss_reveal":summary=t("arena")
	elif presentation_stage=="victory":summary=t("won")+" · "+t("lights_restored")
	var payload:=JSON.stringify({"items":entries,"language":language,"page":menu_kind,"summary":summary})
	if payload==accessibility_stamp:return
	accessibility_stamp=payload
	var api=JavaScriptBridge.get_interface("AionAccessibility")
	if api!=null:api.update(payload)
