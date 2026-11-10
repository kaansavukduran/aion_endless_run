extends Node2D
var host

func object(key: String,row: int,frame: int,anchor: Vector2,width: float,centered: bool = false,opacity: float = 1.0) -> void:
	var f: Dictionary = host.frames.pose(key,row,frame)
	var texture: Texture2D = f.texture
	var factor := width/float(texture.get_width())
	var size := texture.get_size()*factor
	draw_texture_rect(texture,Rect2((anchor-Vector2(size.x*0.5,size.y*0.5 if centered else size.y)).round(),size),false,Color(1,1,1,opacity))

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
		elif kind in ["arch_root","arch_pipe"]:
			object("parkour",0 if kind == "arch_root" else 1,int(clock*5)%6,Vector2(o.x,ground+2),184)
			var color := Color("799d5e") if kind == "arch_root" else Color("d1ac66")
			for i in 7:
				var x: float = o.x-54+i*18
				draw_line(Vector2(x,ground-111),Vector2(x,ground-68-float(i%2)*4),color,4)
			draw_line(Vector2(o.x-56,ground-69),Vector2(o.x+56,ground-69),color,4)
		elif kind.begins_with("pit"):
			var width: float = o.get("width",150)
			var left: float = o.x-width*0.5
			var depth: float = maxf(26,host.view_h-98-ground)
			draw_rect(Rect2(left,ground,width,depth),Color("0a1421"))
			for i in 4: draw_rect(Rect2(left+4,ground+5+i*7,width-8,2),Color(0.08,0.16,0.19,0.65-float(i)*0.12))
			var city: bool = kind == "pit_city" or world.biome() == 3
			object("parkour",3,2 if city else 0,Vector2(left-10,ground+depth),48)
			object("parkour",3,3 if city else 1,Vector2(left+width+10,ground+depth),48)
			draw_line(Vector2(left-15,ground-4),Vector2(left-15,ground-36),Color("d8be86"),3)
			draw_colored_polygon(PackedVector2Array([Vector2(left-15,ground-36),Vector2(left+3,ground-28),Vector2(left-15,ground-21)]),Color("e9907a"))
	for plant in f.plants:
		var frame := int(clock*4)%2
		if plant.shot and plant.age < 1.4: frame = clampi(int(plant.age*4.5),1,5)
		object("boss",3,frame,Vector2(plant.x,ground+3),100)
		if plant.shot and plant.age < 0.9: draw_string(host.FONT,Vector2(plant.x-8,ground-100),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ffbe71"))
	if f.active():
		var row := 0
		var frame := int(f.clock*6)%6 if host.motion else 0
		if f.warning_time > 0.0:
			row = 1
			frame = clampi(int((0.9-f.warning_time)*4),0,3) if host.motion else 2
		if f.phase == "victory":
			row = 2
			frame = mini(5,int(f.stage_time*4)) if host.motion else 5
		object("boss",row,frame,Vector2(f.boss_x,ground+f.boss_y),256,true)
		if f.warning_time > 0.0:
			var low: bool = f.warning == "low"
			draw_line(Vector2(f.boss_x-95,ground+(-14 if low else -82)),Vector2(f.boss_x-190,ground+(-14 if low else -82)),Color(1,0.72,0.38,0.5),2)
			object("boss",4,4,Vector2(f.boss_x-120,ground-195),40,true)
		if f.phase == "intro" and f.stage_time < 0.85 and world.adventure.celebrations_enabled:
			var p: float = smoothstep(0.0,0.85,f.stage_time)
			object("boss",5,mini(5,int(f.stage_time*7)),Vector2(world.PLAYER_X-60+p*108,ground-58-sin(p*PI)*35),42,true)
	for p in f.projectiles:
		var frame := 0 if p.owner == "hero" else (2 if p.kind == "ember" else 1)
		object("boss",4,frame,Vector2(p.x,ground+p.y),39 if p.owner == "hero" else 33,true)
