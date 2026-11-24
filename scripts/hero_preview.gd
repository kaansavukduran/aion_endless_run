class_name RunnerHeroPreview
extends Control
signal launch_finished

var hero := "aion"
var clock := 0.
var animate := true
var action := "ability"
## Character-select state hook ("", "idle", "focus", "select", "launch") & diagnostic preview controls.
var select_state := ""
var paused := false
var manual_frame := -1
var show_guides := false
const PLAYABLE_HEROES = preload("res://scripts/world.gd").PLAYABLE_HEROES
const PORTRAITS=preload("res://assets/m1-selection-portraits.png")
const PORTRAIT_SIZE:=Vector2(256,256)
const PORTRAIT_FOCUS_Y:=[.54,.50,.56,.55,.49,.35]
var portrait_art := false
var launch_complete := false
var rendered_frame := -1
var rendered_pose: Dictionary = {}
const SELECT_STATE_SPEC := {
	"idle":{"body_action":"idle_fire","fps":3.0,"loop":true,"foot":[0,0],"body":[0,-40]},
	"focus":{"body_action":"walk","fps":7.0,"loop":true,"foot":[0,0],"body":[0,-40]},
	"select":{"body_action":"idle_fire","fps":6.0,"loop":true,"muzzle_flash":true,"foot":[0,0],"body":[0,-40]},
	"launch":{"body_action":"air_fire","fps":8.0,"loop":false,"foot":[0,0],"body":[0,-40]}
}
var frames := RunnerFrameBank.new()
var body_art := preload("res://scripts/m1_hero_art.gd").new()
var weapon_art := ForgeItemBank.new()
const GunArt=preload("res://scripts/m1_combat_art.gd")
var catalogue := CampaignCatalog.new()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func set_select_state(state: String) -> void:
	var next: String=state if SELECT_STATE_SPEC.has(state) else ""
	if select_state==next:return
	select_state=next
	clock=0.;manual_frame=-1;launch_complete=false;queue_redraw()

func playback_spec() -> Dictionary:
	if portrait_art:
		return {"body_action":"portrait","frames":3,"fps":8.,"loop":select_state!="launch","start":0.}
	var spec: Dictionary=SELECT_STATE_SPEC.get(select_state,{})
	var body_action: String=str(spec.get("body_action",""))
	var clip_start:=0.
	if body_action=="":
		body_action="walk" if action in ["move","armed_walk"] else ("air_fire" if action=="jump" else "idle_fire")
		if action=="ability":
			var phase:=fmod(clock,3.)
			clip_start=floorf(clock/3.)*3.
			if hero in ["armadillo","frog"]:
				if phase>=1. and phase<1.6:body_action="skill";clip_start+=1.
				elif phase>=1.6:clip_start+=1.6
			elif phase>1.:body_action="air_fire";clip_start+=1.

	var count: int=1
	var source_clip: Dictionary={}
	if body_art.has(hero) and body_art.has_method("clip_spec"):
		source_clip=body_art.clip_spec(hero,body_action)
		count=int(source_clip.frames)
	elif body_art.has(hero):
		var source: Array=body_art.DATA.data.runtime_rows[hero][body_action]
		count=body_art.DATA.data.atlases[str(source[0])].frames[int(source[1])].size()
	else:
		var legacy:=legacy_clip()
		count=frames.count(legacy.key,legacy.row)
	# Selection states author their own short presentation timing. The frame
	# count always comes from the body clip, including non-six-frame heroes.
	var fps: float=float(spec.get("fps",source_clip.get("fps",float(count)/.85)))
	return {"body_action":body_action,"frames":count,"fps":fps,"loop":bool(spec.get("loop",source_clip.get("loop",true))),"start":clip_start}

func legacy_clip() -> Dictionary:
	var row:=0
	if animate and fmod(clock,3.)>1.:row=2 if hero=="aion" else (6 if hero in ["wolf","owl","rabbit","eren"] else 1)
	var key: String="runner-"+hero
	if action=="move":row=1
	elif action=="jump":row=2
	elif action=="shoot":key="gun-fire";row=frames.hero_row(hero)
	elif action=="armed_walk":key="gun-run";row=frames.hero_row(hero)
	return {"key":key,"row":row}

func current_frame() -> int:
	var clip:=playback_spec()
	if manual_frame>=0:return clampi(manual_frame,0,int(clip.frames)-1)
	if not animate:return 0
	if portrait_art:
		if select_state not in ["select","launch"]:return 0
		var phase:=clock if select_state=="launch" else fmod(clock,2.6)
		return 2 if phase>=.15 and phase<.32 else (1 if phase>=.08 and phase<.40 else 0)
	var frame:=int(maxf(0.,clock-float(clip.start))*float(clip.fps))
	return posmod(frame,int(clip.frames)) if clip.loop else mini(int(clip.frames)-1,frame)

func set_paused(value: bool) -> void:
	if paused==value:return
	if not value and manual_frame>=0:
		var clip:=playback_spec()
		clock=float(clip.start)+float(manual_frame)/float(clip.fps)
		manual_frame=-1
	paused=value;queue_redraw()

func step_frame(delta: int=1) -> int:
	var clip:=playback_spec()
	var next: int=current_frame()+delta
	manual_frame=posmod(next,int(clip.frames)) if clip.loop else clampi(next,0,int(clip.frames)-1)
	paused=true
	queue_redraw()
	return manual_frame

func _process(dt: float) -> void:
	if not is_visible_in_tree() or not animate or paused:return
	if portrait_art and select_state not in ["select","launch"]:return
	clock+=minf(dt,.10 if portrait_art else .05)
	queue_redraw()
	if select_state=="launch" and not launch_complete:
		var clip:=playback_spec()
		if clock>=float(clip.frames)/float(clip.fps):
			launch_complete=true
			launch_finished.emit()
func _draw() -> void:
	if portrait_art:
		draw_portrait()
		return
	var state_spec: Dictionary=SELECT_STATE_SPEC.get(select_state,{})
	var clip:=playback_spec()
	var active_frame: int=current_frame()
	var pose: Dictionary
	if body_art.has(hero):
		pose=body_art.pose(hero,str(clip.body_action),active_frame)
	else:
		var legacy:=legacy_clip()
		pose=catalogue.pose("rescue-heroes",frames.hero_row(hero),active_frame) if action=="rescue" else frames.pose(legacy.key,legacy.row,active_frame)
	rendered_frame=active_frame
	rendered_pose=pose
	var factor: float=float(pose.get("scale",1.))
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*factor)
	var fit: float=minf(1.25,minf(size.x/150.,size.y/110.))
	var anchor:=Vector2(size.x*.5,size.y-6.).round()
	draw_set_transform(anchor,0,Vector2.ONE*fit)
	if select_state in ["select","launch"]:
		draw_arc(Vector2(0,-4),28. if select_state=="select" else 34.,0.,TAU,20,Color("ffcf8c",.55 if select_state=="select" else .8),2.)
	draw_texture_rect(pose.texture,Rect2((Vector2(pose.offset)*factor).round(),dimensions),false)
	if hero=="frog" and str(clip.body_action)=="skill" and active_frame in [2,3,4]:
		var mouth:=Vector2(pose.face_local)
		var reach: float=float([0,0,56,56,24,0][active_frame])
		MissionHeroArt.draw_tongue_segment(self,mouth,mouth+Vector2(reach,0))
	var muzzle_pos:=Vector2.ZERO
	var has_muzzle:=false
	if bool(pose.get("body_only",false)) and not (hero in ["armadillo","frog"] and str(clip.body_action)=="skill"):
		var socket: Dictionary=GunArt.weapon_metrics("pistol")
		if action=="rescue" and select_state=="":
			# Same short cutting blade and registered hand as the live action.
			draw_rect(Rect2(Vector2(pose.grip_local)+Vector2(-3,-2),Vector2(6,5)),Color("87583f"))
			var blade:=PackedVector2Array([Vector2(1,-2),Vector2(20,-2),Vector2(24,0),Vector2(1,2)])
			for i in blade.size():blade[i]+=Vector2(pose.grip_local)
			draw_polygon(blade,PackedColorArray([Color("d7e9e8")]))
		else:
			var gun: Dictionary=weapon_art.pose("pistol")
			draw_texture_rect(GunArt.weapon_texture(weapon_art,"pistol"),Rect2(Vector2(pose.grip_local)+Vector2(socket.offset),Vector2(socket.size)),false)
		muzzle_pos=Vector2(pose.grip_local)+Vector2(socket.muzzle);has_muzzle=true
		if (action=="shoot" or bool(state_spec.get("muzzle_flash",false))) and animate and active_frame in [2,3]:
			draw_line(muzzle_pos,muzzle_pos+Vector2(5,0),Color("ffcf8c"),2.)
	if show_guides:
		# Diagnostic-only overlay: collision hull, foot pivot [0,0], body pivot [0,-40], muzzle.
		draw_rect(Rect2(-16.,-74.,32.,74.),Color("67e0ff",.85),false,1.5)
		draw_line(Vector2(-8,0),Vector2(8,0),Color("e87e9a"),1.5)
		draw_line(Vector2(0,-8),Vector2(0,8),Color("e87e9a"),1.5)
		draw_circle(Vector2(0,-40),3.,Color("ffcf8c"))
		if has_muzzle:draw_circle(muzzle_pos,2.5,Color("9ef58e"))
	draw_set_transform(Vector2.ZERO)


func draw_portrait() -> void:
	var row:=AionCampaignWorld.HEROES.find(hero)
	if row<0 or size.x<=0. or size.y<=0.:return
	rendered_frame=current_frame()
	var crop_size:=size/maxf(size.x/PORTRAIT_SIZE.x,size.y/PORTRAIT_SIZE.y)
	var focus:=Vector2(.52,float(PORTRAIT_FOCUS_Y[row]))*PORTRAIT_SIZE
	var crop_start: Vector2=(focus-crop_size*.5).clamp(Vector2.ZERO,PORTRAIT_SIZE-crop_size)
	var cell_origin:=Vector2(rendered_frame,row)*PORTRAIT_SIZE
	var source:=Rect2(cell_origin+crop_start,crop_size)
	rendered_pose={"source_key":"m1-selection-portraits","source_frame":rendered_frame,"source_rect":source}
	draw_texture_rect_region(PORTRAITS,Rect2(Vector2.ZERO,size),source)
