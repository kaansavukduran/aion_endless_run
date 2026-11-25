class_name MissionHeroArt
extends RefCounted

## Original Armadillo/Frog sheets, independent of existing hero silhouettes.
## A single fixed scale per animal is used for every action and every frame.
const DATA=preload("res://assets/MISSION-HEROES-PROVENANCE.json")
const HEROES := ["armadillo","frog"]
static var images: Dictionary={}
static var cache: Dictionary={}

static func has(hero: String) -> bool:return hero in HEROES
static func owns(hero: String) -> bool:return has(hero)

static func actions(hero: String) -> Array:
	var result: Array=[]
	for action in DATA.data.clips:
		if str(DATA.data.clips[action].get("hero",hero))==hero:result.append(action)
	return result

static func clip_spec(hero: String,action: String) -> Dictionary:
	assert(has(hero),"Unknown Mission hero: "+hero)
	var name: String=action if DATA.data.clips.has(action) else "idle"
	var clip: Dictionary=DATA.data.clips[name]
	return {"frames":int(clip.frames),"fps":float(clip.fps),"loop":bool(clip.loop)}

static func metrics(hero: String,action: String,frame: int=0) -> Dictionary:
	assert(has(hero),"Unknown Mission hero: "+hero)
	var name: String=action if DATA.data.clips.has(action) else "idle"
	var row: int=int(DATA.data.clips[name].row)
	var atlas_key: String=str(DATA.data.clips[name].get("atlas",hero)) if str(DATA.data.clips[name].get("hero",hero))==hero else hero
	frame=clampi(frame,0,5)
	var authored_frame: int=frame
	var overrides: Dictionary=DATA.data.get("runtime_overrides",{}).get(hero,{})
	if overrides.has(name):
		var override: Dictionary=overrides[name]
		atlas_key=str(override.atlas);row=int(override.row);authored_frame=int(override.order[frame])
	var atlas: Dictionary=DATA.data.atlases[atlas_key]
	var f: Dictionary=atlas.rows[row][authored_frame]
	var rect: Array=f.rect;var scale: float=float(atlas.scale)
	var origin:=Vector2(float(f.origin[0]),float(f.origin[1]))
	var offset: Vector2=(Vector2(float(rect[0])-2.,float(rect[1])-2.)-origin)*scale
	var mouth:=Vector2(float(f.mouth[0]),float(f.mouth[1]))
	# These two stationary atlas rows used the face edge as a proxy for the
	# jaw. Move the cast socket onto the painted tongue in the open cels.
	if hero=="frog" and name=="skill" and frame in [2,3,4]:
		mouth+=[Vector2(-11,-10),Vector2(-12,-9),Vector2(-13,-10)][frame-2]
	if hero=="frog" and name=="skill_crouch" and frame in [2,4]:
		mouth+=Vector2(-13,-8) if frame==2 else Vector2(-19,-8)
	var result: Dictionary={"offset":offset,"size":Vector2(float(rect[2])+4.,float(rect[3])+4.)*scale,"grip_local":(Vector2(float(f.grip[0]),float(f.grip[1]))-origin)*scale,"face_local":(mouth-origin)*scale,"height":float(rect[3])*scale,"source_key":"mission-hero-"+atlas_key,"atlas_key":atlas_key,"source_row":row,"source_frame":authored_frame,"source_scale":scale,"ground_contact":bool(f.ground_contact),"gun_embedded":false,"body_only":true}
	if f.has("grenade_hand"):
		result.grenade_hand_local=(Vector2(float(f.grenade_hand[0]),float(f.grenade_hand[1]))-origin)*scale
		result.grenade_embedded=false
	return result

static func pose(hero: String,action: String,frame: int=0) -> Dictionary:
	var spec:=metrics(hero,action,frame)
	var key: String=str(spec.atlas_key)
	var id:=key+":"+str(spec.source_row)+":"+str(spec.source_frame)
	if cache.has(id):return cache[id]
	var atlas: Dictionary=DATA.data.atlases[key]
	var sheet_image: Image=RunnerSourcePixels.sheet("res://"+str(atlas.path))
	var f: Dictionary=atlas.rows[int(spec.source_row)][int(spec.source_frame)]
	var rect: Array=f.rect
	var crop:=Image.create_empty(int(rect[2])+4,int(rect[3])+4,false,Image.FORMAT_RGBA8)
	for run in RunnerSourcePixels.runs(f):
		crop.blit_rect(sheet_image,Rect2i(int(rect[0])+int(run[1]),int(rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])+2,int(run[0])+2))
	spec.texture=ImageTexture.create_from_image(crop);cache[id]=spec
	return spec

static func body_spec(w) -> Dictionary:
	var action: String="idle";var frame: int=posmod(int(w.time*5.),6)
	var face: int=MissionHeroAbilities.body_facing(w)
	var confined: bool=CampaignRoutes.low_ceiling(w)
	if w.state in ["dying","dead","respawn_pending","continue_offer"]:
		action="death";frame=CampaignLives.collapse_frame(w)
		if not confined and w.state=="dying" and w.death_time<CampaignLives.impact_duration(w.death_cause):
			action="hurt";frame=clampi(int(w.death_time/CampaignLives.impact_duration(w.death_cause)*4.),0,3)
		# Start from the animal's genuinely collapsed source cels under a real
		# roof. Early upright fall cels cannot fit the existing crawl hull.
		if confined:frame=3+clampi(int(w.death_time/.8*3.),0,2)
	elif w.hurt_time>0.:
		# This is an explicit constrained-pose adaptation, not a claim of new
		# low hurt drawings. Existing low blink/flinch + world hurt tint conveys
		# damage while keeping the head inside the actual collision clearance.
		action="crouch_fire" if confined else "hurt";frame=clampi(int((.3-w.hurt_time)*15.),0,5)
	elif not w.grenade_throw.is_empty():
		action="crouch_grenade_throw" if w.crouching() else "grenade_throw"
		frame=CampaignGrenade.frame_at(float(w.grenade_throw.elapsed))
		face=int(w.grenade_throw.direction)
	elif MissionHeroAbilities.active(w):
		action="skill"
		var phase: String=str(w.hero_skill.phase);var clock: float=float(w.hero_skill.clock)
		if w.character=="armadillo":
			match phase:
				"windup":frame=clampi(int(clock/MissionHeroAbilities.ROLL_WINDUP*2.),0,1)
				"roll":frame=2+posmod(int(clock*16.),2)
				"brake":frame=4
				_:frame=5
		else:
			match phase:
				"windup":frame=0 if clock<.06 else 1
				"extend","spit":frame=2
				"retract":frame=3 if float(w.hero_skill.extent)>90. else 4
				_:frame=5
			var gait: Dictionary=MissionFrogTongueArt.motion_spec(w,phase,face)
			if not gait.is_empty():
				action=str(gait.action);frame=int(gait.frame)
			elif w.crouching():
				action="skill_crouch"
				if phase=="retract" and frame==3:frame=2
		# Frogs may crouch and jump while attacking. The mouth remains attached
		# to the same body frame used by the renderer and hit segment.
	elif w.rescue_time>0. or (w.melee_time>0. and absf(w.velocity.x)<=1. and w.grounded()):
		# Shared action clocks own the interaction phase, including stationary
		# firing bodies. Locomotion/idle time must never replace a knife/cut cel.
		action="crouch_fire" if w.crouching() else "idle_fire"
		frame=clampi(int((.6-w.rescue_time)/.6*6.),0,5) if w.rescue_time>0. else clampi(int((.28-w.melee_time)/.28*6.),0,5)
	elif w.crouching() or w.charging:
		if w.charging:
			action="crouch_fire";frame=clampi(int(w.charge_ratio()*6.),0,5)
		elif absf(w.velocity.x)>1.:
			action="crouch_walk_back" if w.velocity.x*face<0. else "crouch_walk"
			frame=posmod(int(w.walk_distance/110.*6.),6)
		else:action="crouch_fire";frame=clampi(int((.18-w.shot_flash)/.18*6.),0,5) if w.shot_flash>0. else posmod(int(w.time*5.),6)
	elif not w.grounded():
		action="air_fire";frame=RunnerWorld.flight_frame_for(w.velocity.y,w.air_time,6)
	elif absf(w.velocity.x)>1.:
		action="walk_back" if w.velocity.x*face<0. else "walk"
		frame=posmod(int(w.walk_distance/174.*6.),6)
	elif w.shot_flash>0.:
		action="idle_fire";frame=clampi(int((.18-w.shot_flash)/.18*6.),0,5)
	if not w.pose_motion_enabled and w.grenade_throw.is_empty():frame=0
	else:frame=M1CombatArt.backstep_frame(action,frame)
	return {"hero":w.character,"action":action,"frame":frame,"mirror":face,"key":"mission-hero"}

static func preview_spec(hero: String,action: String,clock: float) -> Dictionary:
	var name: String=action
	if action in ["focus","select"]:name="idle_fire"
	elif action in ["launch","ability"]:name="skill"
	elif action=="backwalk":name="walk_back"
	if not DATA.data.clips.has(name):name="idle"
	var clip:=clip_spec(hero,name)
	var frame: int=posmod(int(clock*float(clip.fps)),int(clip.frames)) if bool(clip.loop) else clampi(int(clock*float(clip.fps)),0,int(clip.frames)-1)
	return {"hero":hero,"action":name,"frame":frame,"mirror":1,"key":"mission-hero"}

## Three small earth chips arc backward from the actual shell contact point.
static func draw_shell_contacts(view) -> void:
	for contact in view.world.shell_contacts:
		var progress: float=clampf((view.world.time-float(contact.born))/MissionHeroAbilities.SHELL_CONTACT_LIFE,0.,1.)
		var center: Vector2=view.at(Vector2(contact.point))
		var direction: float=float(contact.direction)
		for i in 3:
			var offset:=Vector2(-direction*(3.+i*4.+progress*(8.+i*5.)),-3.-sin(progress*PI)*(4.+i*2.))
			var pixel: Vector2=(center+offset).round()
			var alpha: float=(1.-progress)*.78
			view.draw_rect(Rect2(pixel,Vector2(4.,3.)),Color(.38,.30,.24,alpha))
			view.draw_rect(Rect2(pixel,Vector2(3.,1.)),Color(.83,.69,.49,alpha))

## Original pixel cels. Each tongue end has its own contour. The middle
## repeats one shaded cross section, so extension preserves the pixel scale.
const TONGUE_ROOT := ["........","##......","hrr#####","HHhhrrrh","rrRRrHHH","rRRRRRRR","rRRrrRRR","###rrr##","...###.."]
const TONGUE_BODY := [".",".","#","h","H","R","R","#","."]
const TONGUE_TIP := ["...........",".....###...","#####hhh#..","hHHHhhhhh#.","HHHHHhhRr#.","RRRRRRRRrr#","RRRrrRRrrr#","####rrrr##.","....####..."]
const TONGUE_INK := {"#":"592838","r":"b84562","R":"e07590","h":"f39faa","H":"ffd3c4"}
const FLAME_INK := {"#":"9c3c30","r":"db5a37","R":"f88e40","h":"ffbf59","H":"fff1a5"}
const FLAME_CELS := [
	["......#...",".....#r#..","....#rR#..","....#Rr#..","..#.#RR#..",".#r##Rh#..",".#RrrRhR#.","#rRRRhHR#.","#RRhhHHRr#","#rRhHHHRr#",".#rRRRrr#.","..######.."],
	["....#.....","...#r#....","...#Rr#...","...##R#...","....#R#.#.","...#rRR#r#","..#rRRrRr#",".#rRhRhhR#",".#RRhHhRR#","..#rHHHrr#","...#rRr##.","....###..."],
	[".....#....","....#r#...","....#R#...","..#.#Rr#..",".#r##RR#..",".#RrrRh#..",".#RRRhHR#.","#rRhHHHR#.","#RRhHHHRr#",".#rRhHRr#.","..#rRrr#..","...####..."]
]
static var effect_textures: Dictionary={}

static func effect_texture(id: String,rows: Array,palette: Dictionary) -> Texture2D:
	if not effect_textures.has(id):
		var pixels:=Image.create_empty(rows[0].length(),rows.size(),false,Image.FORMAT_RGBA8)
		for y in rows.size():
			for x in rows[y].length():
				var ink: String=rows[y][x]
				if palette.has(ink):pixels.set_pixel(x,y,Color(palette[ink]))
		effect_textures[id]=ImageTexture.create_from_image(pixels)
	return effect_textures[id]

static func draw_tongue(view) -> void:
	var w=view.world
	if w.character!="frog" or w.state not in ["playing","paused"] or w.hero_skill.is_empty() or float(w.hero_skill.get("extent",0.))<1.:return
	draw_tongue_segment(view,view.at(MissionHeroAbilities.mouth(w)),view.at(MissionHeroAbilities.tongue_tip(w)))

static func draw_tongue_piece(canvas,texture: Texture2D,start: Vector2,end: Vector2,half_height: Vector2) -> void:
	canvas.draw_polygon(
		PackedVector2Array([start-half_height,end-half_height,end+half_height,start+half_height]),
		PackedColorArray([Color.WHITE]),
		PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),
		texture)

static func draw_tongue_segment(canvas,origin: Vector2,tip: Vector2) -> void:
	var length:=origin.distance_to(tip)
	if length<1.:return
	var direction: Vector2=(tip-origin)/length
	var half_height:=Vector2(-direction.y,direction.x)*minf(9.,2.+length*.25)
	if direction.x<0.:half_height=-half_height
	var root_end:=origin+direction*minf(16.,length*.35)
	var cap_start:=tip-direction*minf(22.,length*.48)
	var previous:=root_end
	var body:=effect_texture("tongue_body",TONGUE_BODY,TONGUE_INK)
	draw_tongue_piece(canvas,effect_texture("tongue_root",TONGUE_ROOT,TONGUE_INK),origin,root_end,half_height)
	# A shallow flex keeps the long cast organic while the gameplay socket
	# and the actual point of impact stay fixed at the ends.
	for step in range(1,7):
		var progress:=float(step)/6.
		var dip:=sin(progress*PI)*minf(10.,length*.085)
		var next:=root_end.lerp(cap_start,progress)+half_height.normalized()*dip
		draw_tongue_piece(canvas,body,previous,next,half_height)
		previous=next
	draw_tongue_piece(canvas,effect_texture("tongue_tip",TONGUE_TIP,TONGUE_INK),cap_start,tip,half_height)

static func draw_sprint_fire(view,front: bool) -> void:
	var w=view.world
	if w.sprint_fire<=0. or bool(w.mount.ridden) or w.state not in ["playing","paused"]:return
	var tick: int=int((MissionHeroAbilities.SPRINT_FIRE_TIME-w.sprint_fire)*13.) if w.pose_motion_enabled else 0
	var direction: float=-1. if w.velocity.x<0. else 1.
	var foot: Vector2=view.at(w.player)
	var offsets:=PackedVector2Array([Vector2(27,-9),Vector2(39,-3)]) if front else PackedVector2Array([Vector2(-42,-1),Vector2(-29,-11),Vector2(-18,-22),Vector2(17,-21)])
	for i in offsets.size():
		var frame: int=posmod(tick+i,FLAME_CELS.size())
		var texture:=effect_texture("sprint_fire_"+str(frame),FLAME_CELS[frame],FLAME_INK)
		var offset: Vector2=offsets[i]*Vector2(direction,1.)
		var dimensions:=Vector2(20.,24.) if i%2==0 else Vector2(16.,20.)
		view.draw_texture_rect(texture,Rect2((foot+offset-Vector2(dimensions.x*.5,dimensions.y)).round(),dimensions),false)

static func draw_skill_status(view) -> void:
	var w=view.world
	if w.state!="playing" or bool(w.mount.ridden) or w.mount_transition!="":return
	if w.character=="frog":
		var remaining: float=w.frog_cooldown
		var duration:=MissionHeroAbilities.SWALLOW_COOLDOWN
		var phase: String=w.hero_skill.get("phase","")
		if phase in ["recover","cooldown"] and remaining<=0. and w.frog_meal.is_empty():
			duration=.30+MissionHeroAbilities.TONGUE_COOLDOWN
			var finish: float=.30 if phase=="recover" else 0.
			remaining=MissionHeroAbilities.TONGUE_COOLDOWN+finish-float(w.hero_skill.clock)
		if remaining<=0.:return
		var p: Vector2=view.at(Vector2(w.player)+Vector2(0.,-98.))
		p.y=maxf(p.y,86.)
		if w.charging:p.x+=38.
		draw_cooldown_ring(view,p,remaining,duration)
	elif w.character=="armadillo" and w.roll_charges<MissionHeroAbilities.ROLL_CHARGES:
		var p: Vector2=view.at(Vector2(w.player)+Vector2(0.,-92.))
		if w.roll_cooldown>0.:
			draw_cooldown_ring(view,p,w.roll_cooldown,MissionHeroAbilities.ROLL_COOLDOWN)
		else:
			for i in MissionHeroAbilities.ROLL_CHARGES:
				var corner:=p+Vector2(-16+12*i,-4)
				view.draw_rect(Rect2(corner,Vector2(10,9)),Color("322430"))
				view.draw_rect(Rect2(corner+Vector2(2,2),Vector2(6,5)),Color("ffc36b") if i<w.roll_charges else Color("684650"))

static func draw_cooldown_ring(view,p: Vector2,remaining: float,duration: float) -> void:
	view.draw_circle(p,18.,Color("251d2b"))
	var lit:=clampi(ceili(12.*remaining/duration),0,12)
	for i in 12:
		var at: Vector2=(p+Vector2.UP.rotated(TAU*float(i)/12.)*14.).round()
		view.draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),Color("a7e391") if i<lit else Color("5b5365"))
	if view.font!=null and duration>=1.:
		var label:=str(ceili(remaining))
		var width: float=view.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		view.draw_string(view.font,p+Vector2(-width*.5,6.),label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fbe9d5"))
