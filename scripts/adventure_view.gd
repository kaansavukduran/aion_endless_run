extends Node2D

const META = preload("res://assets/ADVENTURE-PROVENANCE.json")
const ENEMIES = preload("res://assets/adventure-enemies.png")
const ITEMS = preload("res://assets/adventure-items.png")
var host

func atlas(name: String, row: int, frame: int, anchor: Vector2, width: float, centered: bool = false) -> void:
	var data: Dictionary = META.data.atlases[name]
	var left := roundf(float(frame) * float(data.width) / 6.0)
	var right := roundf(float(frame + 1) * float(data.width) / 6.0)
	var top: float = data.row_y[row]
	var height: float = data.row_y[row + 1] - top
	var factor := width / (right - left)
	var bottom := height * 0.5 if centered else float(data.baselines[row][frame])
	draw_texture_rect_region(ENEMIES if name == "enemies" else ITEMS, Rect2((anchor - Vector2(width * 0.5, bottom * factor)).round(), Vector2(width, height * factor)), Rect2(left, top, right - left, height), Color(1.22, 1.22, 1.30) if name == "enemies" and row < 3 else Color.WHITE)

func _draw() -> void:
	if host == null: return
	var world = host.world
	var a = world.adventure
	if not a.enabled: return
	var clock: float = host.animation_clock()
	var ground: float = host.ground
	# Weather never changes collision bounds or hides the foreground silhouettes.
	if a.weather in ["rain", "storm", "snow", "sand"]:
		var tint := Color("a7c9ea") if a.weather in ["rain", "storm"] else (Color("ebf6ff") if a.weather == "snow" else Color("e4c695"))
		tint.a = 0.38
		for i in 64:
			var x := fposmod(i * 151.0 - clock * (180.0 if a.weather == "sand" else 45.0), host.view_w)
			var y := 146.0 + fposmod(i * 93.0 + clock * (510.0 if a.weather in ["rain", "storm"] else 70.0), ground - 145.0)
			if a.weather in ["rain", "storm"]: draw_line(Vector2(x, y), Vector2(x - 4, y + 15), tint, 2)
			else: draw_rect(Rect2(Vector2(x, y).round(), Vector2(3, 3)), tint)
	if a.thunder_time > 0.0 and host.effects_enabled and host.motion:
		var bolt := PackedVector2Array([Vector2(a.thunder_x, 147), Vector2(a.thunder_x - 20, 185), Vector2(a.thunder_x + 8, 181), Vector2(a.thunder_x - 24, 236)])
		draw_polyline(bolt, Color(0.87, 0.91, 1.0, minf(0.7, a.thunder_time * 1.4)), 4)
	for obstacle in world.obstacles:
		if obstacle.kind == "arch":
			atlas("items", 2, int(clock * 6) % 6, Vector2(obstacle.x, ground - 48), 174)
			draw_polyline(PackedVector2Array([Vector2(obstacle.x - 10, ground - 28), Vector2(obstacle.x, ground - 19), Vector2(obstacle.x + 10, ground - 28)]), Color("d9ebd6"), 3)
	for item in a.items:
		var bob := sin(clock * 4.0 + item.id) * 3.0
		var point := Vector2(item.x, ground + item.y + bob)
		var frame := int(clock * 7) % 6
		if item.kind == "mushroom": atlas("items", 0, frame, point, 63, true)
		else:
			var icons := {"lightning":0,"slow":1,"haste":2,"shield":3,"magnet":4,"leaf":5}
			atlas("items", 1, icons[item.kind], point, 46, true)
	for enemy in a.enemies:
		var row := 0 if enemy.kind == "crow" else 3
		var frame := int(clock * (11 if enemy.kind == "crow" else 10) + enemy.id) % 6
		if enemy.hp <= 0:
			row = 2 if enemy.kind == "crow" else 5
			frame = mini(5, int(enemy.defeat * 10)) if host.motion else 5
		elif enemy.hurt > 0.0:
			row = 2 if enemy.kind == "crow" else 5
			frame = 0
		elif enemy.kind == "crow" and enemy.diving: row = 1
		elif enemy.kind == "gnome" and enemy.x < world.PLAYER_X + 160: row = 4
		var anchor := Vector2(enemy.x, ground + enemy.y + (24.0 if enemy.kind == "crow" else 23.0))
		atlas("enemies", row, frame, anchor, 80 if enemy.kind == "crow" else 65)
		if enemy.hp > 0 and enemy.hp < enemy.max_hp:
			draw_rect(Rect2(enemy.x - 15, ground + enemy.y - 39, 30, 4), Color("34283c"))
			draw_rect(Rect2(enemy.x - 15, ground + enemy.y - 39, 30.0 * enemy.hp / enemy.max_hp, 4), Color("ffc576"))
		if enemy.kind == "crow" and enemy.diving and enemy.hp > 0 and enemy.x > world.PLAYER_X + 135:
			draw_string(host.FONT, Vector2(enemy.x - 4, ground + enemy.y - 43), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffd57a"))
	if a.lightning_time > 0.0:
		var source := Vector2(world.PLAYER_X + 20, ground + world.y - 54)
		for target in a.lightning_targets:
			var end: Vector2 = target + Vector2(0, ground)
			var midpoint := (source + end) * 0.5 + Vector2(12, -20)
			draw_polyline(PackedVector2Array([source, midpoint, midpoint + Vector2(-10, 18), end]), Color("f8df94"), 4)
	if float(a.powers.shield) > 0.0:
		draw_arc(Vector2(world.PLAYER_X, ground + world.y - a.body_height(world) * 0.5), a.body_height(world) * 0.65, 0, TAU, 24, Color(0.55, 0.94, 0.88, 0.7), 3)
	if a.giant() and host.effects_enabled and host.motion:
		for i in 8:
			var hue := fposmod(clock * 0.035 + float(i) / 8, 1.0)
			var color := Color.from_hsv(hue, 0.35, 0.95, 0.12)
			var x := fposmod(i * 197.0 + sin(clock * 0.8 + i) * 12, host.view_w)
			draw_circle(Vector2(x, 220.0 + sin(i + clock * 0.6) * 55), 5 + i % 3, color)
