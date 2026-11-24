class_name MissionFrogSpitArt
extends RefCounted

const SHEET=preload("res://assets/m1-frog-spit.png")
const CELL := 76

static func draw(v,kind: String,point: Vector2,face: int,frame: int,scale: float,tilt:=0.) -> void:
	var row:=MissionHeroAbilities.SWALLOWABLE.find(kind)
	if row<0:return
	var origin: Vector2=v.at(point)
	var dimensions:=Vector2.ONE*CELL*scale
	v.draw_set_transform(origin,tilt,Vector2(face,1))
	v.draw_texture_rect_region(SHEET,Rect2(-dimensions*.5,dimensions),
		Rect2(CELL*frame,CELL*row,CELL,CELL))
	v.draw_set_transform(Vector2.ZERO)

static func projectile(v,bullet: Dictionary) -> void:
	var position: Vector2=bullet.p
	var direction: Vector2=Vector2(bullet.v).normalized()
	var face: int=-1 if direction.x<0. else 1
	var moving: bool=v.host.motion_enabled and not v.host.options.reduced_motion
	if moving:
		for i in 3:
			var offset: Vector2=-direction*(29.+float(i)*9.)
			var fleck: Vector2=v.at(position+offset+Vector2(0.,(3. if i%2==0 else -3.)*float(i)))
			v.draw_rect(Rect2(fleck,Vector2(7.-i,3.)),Color("b4d580"))
	draw(v,str(bullet.creature),position,face,mini(3,int(float(bullet.age)*15.)) if moving else 0,
		1.14,atan2(direction.y,absf(direction.x)))

static func carried(v) -> void:
	var skill: Dictionary=v.world.hero_skill
	if not skill.has("caught") or float(skill.get("extent",0.))<2.:return
	var growth:=lerpf(.26,1.05,clampf(float(skill.extent)/75.,0.,1.))
	draw(v,str(skill.caught.kind),MissionHeroAbilities.tongue_tip(v.world),-int(skill.face),0,growth)
