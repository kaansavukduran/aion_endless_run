extends Node2D
var host

func object(key: String,row: int,frame: int,anchor: Vector2,width: float,centered: bool = false,opacity: float = 1.0) -> void:
	var f: Dictionary = host.frames.pose(key,row,frame)
	var texture: Texture2D = f.texture
	var factor: float = width / f.cell_width
	var offset: Vector2 = f.offset
	offset.y = f.top - (f.center_y if centered else f.baseline) - 2.0
	draw_texture_rect(texture,Rect2((anchor+offset*factor).round(),texture.get_size()*factor),false,Color(1,1,1,opacity))

func _draw() -> void:
	if host == null: return
	var world = host.world
	var f = world.frontier
	var ground: float = host.ground
	var clock: float = host.animation_clock() if host.motion else 0.0
	for o in world.obstacles:
		var kind: String = o.kind
		if kind.begins_with("block"):
			var n: int = ["block_crate","block_log","block_road","block_rock","block_vent","block_barrel"].find(kind)
			object("parkour",2,maxi(0,n),Vector2(o.x,ground+2),78)
		elif kind == "gate" or kind.begins_with("arch"):
			var theme: int = int(o.get("theme",world.biome())) % 4
			object("boost-pads",theme,host.frames.cycle("boost-pads",theme,clock,0.9),Vector2(o.x,ground+4),132)
		elif kind.begins_with("carrier"):
			var row := 0 if kind == "carrier_pipe" else 1
			object("carriers",row,host.frames.cycle("carriers",row,clock,0.75),Vector2(o.x,ground-68),190)
		elif kind.begins_with("pit"):
			var width: float = o.get("width",150)
			var left: float = o.x-width*0.5
			var depth: float = maxf(26,host.scene_h-98-ground)
			draw_rect(Rect2(left,ground,width,depth),Color("0a1421"))
			for i in 4: draw_rect(Rect2(left+4,ground+5+i*7,width-8,2),Color(0.08,0.16,0.19,0.65-float(i)*0.12))
			var city: bool = kind == "pit_city" or world.biome() == 3
			object("parkour",3,2 if city else 0,Vector2(left-10,ground+depth),48)
			object("parkour",3,3 if city else 1,Vector2(left+width+10,ground+depth),48)
			draw_line(Vector2(left-15,ground-4),Vector2(left-15,ground-36),Color("d8be86"),3)
			draw_colored_polygon(PackedVector2Array([Vector2(left-15,ground-36),Vector2(left+3,ground-28),Vector2(left-15,ground-21)]),Color("e9907a"))
	for plant in f.plants:
		var frame := posmod(int(clock*5),3)
		if plant.shot and plant.age < 1.4:
			frame = host.frames.progress("boss",3,plant.age/1.4)
		object("boss",3,frame,Vector2(plant.x,ground+3),100)
		if plant.shot and plant.age < 0.9: draw_string(host.FONT,Vector2(plant.x-8,ground-100),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ffbe71"))
	if f.active():
		var row: int = f.boss_kind*3
		var frame: int = host.frames.cycle("boss-designs",row,f.clock,1.0) if host.motion else 0
		if f.warning_time > 0.0 or f.cast_flash>0:
			row += 1
			var phase: float = (0.95-f.warning_time)/0.95*0.25 if f.warning_time>0 else 0.25+(1-f.cast_flash/0.45)*0.75
			frame = host.frames.progress("boss-designs",row,phase) if host.motion else 3
		if f.phase == "victory":
			row = f.boss_kind*3+2
			frame = host.frames.progress("boss-designs",row,f.stage_time/1.6) if host.motion else host.frames.count("boss-designs",row)-1
		if f.phase != "return": object("boss-designs",row,frame,Vector2(f.boss_x,ground+f.boss_y),300 if f.boss_kind==1 else 248,true)
		if f.warning_time > 0.0:
			var low: bool = f.warning == "low"
			draw_line(Vector2(f.boss_x-95,ground+(-14 if low else -82)),Vector2(f.boss_x-190,ground+(-14 if low else -82)),Color(1,0.72,0.38,0.5),2)
			object("power",9,8+posmod(int(clock*8),2),Vector2(f.boss_x-120,ground-195),40,true)
		if f.phase == "intro" and f.stage_time < 0.85 and world.adventure.celebrations_enabled and not world.practice and not f.red_weapon:
			var p: float = smoothstep(0.0,0.85,f.stage_time)
			object("boss",5,host.frames.progress("boss",5,f.stage_time/0.85),Vector2(world.PLAYER_X+92-p*44,ground-58-sin(p*PI)*25),42,true)

	if f.storytelling() and f.story_index==2:
		var girl: int=maxi(0,world.adventure.girl_index)
		var half: int=host.frames.count("celebrants",girl)/2
		var progress: float=smoothstep(0,1.2,f.story_time) if host.decorative_motion() else 1.0
		var anchor:=Vector2(world.PLAYER_X+100-progress*45,ground)
		host.evolution_view.girl(self,girl,half+4,anchor,1.0)

	for p in f.projectiles:
		if p.owner=="hero" and bool(p.get("red",false)):
			var point:=Vector2(p.x,ground+p.y).round()
			draw_rect(Rect2(point-Vector2(18,4),Vector2(28,8)),Color("dd3b45"))
			draw_rect(Rect2(point-Vector2(9,2),Vector2(21,4)),Color("ffd69c"))
			continue
		var icon := 0 if p.owner == "hero" else (2 if p.kind in ["ember","seed"] else 1)
		var frame := icon*2+posmod(int(clock*8),2)
		object("power",9,frame,Vector2(p.x,ground+p.y),39 if p.owner == "hero" else 33,true)
