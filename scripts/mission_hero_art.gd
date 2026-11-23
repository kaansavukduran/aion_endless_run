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
	var result: Dictionary={"offset":offset,"size":Vector2(float(rect[2])+4.,float(rect[3])+4.)*scale,"grip_local":(Vector2(float(f.grip[0]),float(f.grip[1]))-origin)*scale,"face_local":(Vector2(float(f.mouth[0]),float(f.mouth[1]))-origin)*scale,"height":float(rect[3])*scale,"source_key":"mission-hero-"+atlas_key,"atlas_key":atlas_key,"source_row":row,"source_frame":authored_frame,"source_scale":scale,"ground_contact":bool(f.ground_contact),"gun_embedded":false,"body_only":true}
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
	if not images.has(key):
		var pixels:=RunnerSourcePixels.image("res://"+str(atlas.path))
		if pixels.is_compressed():pixels.decompress()
		pixels.convert(Image.FORMAT_RGBA8);images[key]=pixels
	var f: Dictionary=atlas.rows[int(spec.source_row)][int(spec.source_frame)]
	var rect: Array=f.rect
	var crop:=Image.create_empty(int(rect[2])+4,int(rect[3])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		crop.blit_rect(images[key],Rect2i(int(rect[0])+int(run[1]),int(rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])+2,int(run[0])+2))
	spec.texture=ImageTexture.create_from_image(crop);cache[id]=spec
	return spec

static func body_spec(w) -> Dictionary:
	var action: String="idle";var frame: int=posmod(int(w.time*5.),6)
	var face: int=MissionHeroAbilities.body_facing(w)
	var confined: bool=CampaignRoutes.low_ceiling(w)
	if w.state in ["dying","dead","respawn_pending","continue_offer","continue_pick"]:
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
				"extend":frame=2
				"retract":frame=3 if float(w.hero_skill.extent)>90. else 4
				_:frame=5
			var gait: Dictionary=MissionFrogTongueArt.motion_spec(w,phase,face)
			if not gait.is_empty():
				action=str(gait.action);frame=int(gait.frame)
			elif w.crouching():action="skill_crouch"
		# Frogs may crouch and jump while attacking. The mouth remains attached
		# to the same body frame used by the renderer and hit segment.
	elif w.rescue_time>0. or (w.melee_time>0. and absf(w.velocity.x)<=1. and w.grounded()):
		# Shared action clocks own the interaction phase, including stationary
		# firing bodies. Locomotion/idle time must never replace a knife/cut cel.
		action="crouch_fire" if w.crouching() else "idle_fire"
		frame=clampi(int((.6-w.rescue_time)/.6*6.),0,5) if w.rescue_time>0. else clampi(int((.28-w.melee_time)/.28*6.),0,5)
	elif w.crouching():
		if absf(w.velocity.x)>1.:
			action="crouch_walk_back" if w.velocity.x*face<0. else "crouch_walk"
			frame=posmod(int(w.walk_distance/110.*6.),6)
		else:action="crouch_fire";frame=clampi(int((.18-w.shot_flash)/.18*6.),0,5) if w.shot_flash>0. else posmod(int(w.time*5.),6)
	elif not w.grounded():
		action="air_fire";frame=clampi(int((.18-w.shot_flash)/.18*6.),0,5) if w.shot_flash>0. else RunnerWorld.flight_frame_for(w.velocity.y,w.air_time,6)
	elif absf(w.velocity.x)>1.:
		action="walk_back" if w.velocity.x*face<0. else "walk"
		frame=posmod(int(w.walk_distance/174.*6.),6)
	elif w.shot_flash>0.:
		action="idle_fire";frame=clampi(int((.18-w.shot_flash)/.18*6.),0,5)
	if not w.pose_motion_enabled and w.grenade_throw.is_empty():frame=0
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

## A pixel ribbon follows the exact mouth/tip used by first-contact checks.
## Alternating two-pixel cells and a shaded rounded tip are discrete pixel
## art, not a stretched blurry tongue image or detached projectile.
static func draw_tongue(view) -> void:
	var w=view.world
	if w.character!="frog" or w.state not in ["playing","paused"] or w.hero_skill.is_empty() or float(w.hero_skill.get("extent",0.))<1.:return
	var origin: Vector2=view.at(MissionHeroAbilities.mouth(w))
	var tip: Vector2=view.at(MissionHeroAbilities.tongue_tip(w))
	draw_tongue_segment(view,origin,tip)

static func draw_tongue_segment(canvas,origin: Vector2,tip: Vector2) -> void:
	var d: Vector2=(tip-origin).normalized();var side:=Vector2(-d.y,d.x)
	var count:=maxi(1,int(ceil(origin.distance_to(tip)/3.)))
	for i in count:
		var p: Vector2=origin.lerp(tip,float(i)/float(count)).round()
		canvas.draw_rect(Rect2(p-Vector2(3.,3.),Vector2(6.,6.)),Color("703749"))
		canvas.draw_rect(Rect2(p-Vector2(2.,2.),Vector2(4.,4.)),Color("e98296" if i%3 else "f6a2ac"))
	canvas.draw_rect(Rect2(tip.round()-Vector2(5.,4.),Vector2(10.,8.)),Color("703749"))
	canvas.draw_rect(Rect2(tip.round()-Vector2(4.,3.),Vector2(8.,6.)),Color("ee8f9c"))
	canvas.draw_rect(Rect2((tip-side*2.).round()-Vector2(2.,1.),Vector2(4.,2.)),Color("ffd0cc"))
