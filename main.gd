extends Node2D
# Mundo abierto: terreno generado, objetos, enemigos y NPCs.

const W := 160
const H := 160
const T := 16
const CENTER := Vector2i(80, 80)

var blocked := PackedByteArray()
var layer: TileMapLayer
var ents: Node2D
var player
var mobs: Array = []
var npcs: Array = []
var ui
var tex := {}
var save_t := 0.0

func tx(n: String) -> Texture2D:
	if not tex.has(n): tex[n] = load("res://art/%s.png" % n)
	return tex[n]

func _ready():
	blocked.resize(W * H)
	var spawns := _build_world()
	ents = Node2D.new(); ents.y_sort_enabled = true; add_child(ents)
	_build_objects(spawns)
	var loaded: bool = Game.load_game()
	if not loaded:
		for i in 3: Game.add_item("pocion")
	player = Node2D.new(); player.set_script(preload("res://player.gd")); ents.add_child(player)
	player.setup(self)
	player.position = Game.pos if loaded and Game.pos != Vector2.ZERO else Vector2(CENTER.x * T, CENTER.y * T + 40)
	var cam := Camera2D.new(); cam.zoom = Vector2(3, 3)
	cam.limit_left = 0; cam.limit_top = 0; cam.limit_right = W * T; cam.limit_bottom = H * T
	player.add_child(cam)
	for n in [["Bayu", Vector2i(3, -2)], ["Mara", Vector2i(-4, -2)], ["Toro", Vector2i(1, 4)]]:
		var npc := Node2D.new(); npc.set_script(preload("res://npc.gd")); ents.add_child(npc)
		npc.setup(self, n[0])
		var tp: Vector2i = CENTER + n[1]
		npc.position = Vector2(tp.x * T + 8, tp.y * T + 8)
		blocked[tp.y * W + tp.x] = 1
		npcs.append(npc)
	ui = CanvasLayer.new(); ui.set_script(preload("res://ui.gd")); add_child(ui)
	ui.setup(self)

func _build_world() -> Array:
	var spawns: Array = []
	var noise := FastNoiseLite.new(); noise.seed = 4242; noise.frequency = 0.035
	var noise2 := FastNoiseLite.new(); noise2.seed = 99; noise2.frequency = 0.06
	var rng := RandomNumberGenerator.new(); rng.seed = 4242
	var ts := TileSet.new(); ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new(); src.texture = tx("tiles"); src.texture_region_size = Vector2i(T, T)
	for i in 6: src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	layer = TileMapLayer.new(); layer.tile_set = ts; add_child(layer)
	objs = []
	for y in H:
		for x in W:
			var d := Vector2(x - CENTER.x, y - CENTER.y).length()
			var h := noise.get_noise_2d(x, y)
			var f := noise2.get_noise_2d(x, y)
			var t := 0
			var edge := x < 2 or y < 2 or x >= W - 2 or y >= H - 2
			if edge:
				t = 3; blocked[y * W + x] = 1
			elif d < 14:
				t = 2 if d < 8 else (1 if rng.randf() < 0.1 else 0)
			elif h < -0.22:
				t = 3; blocked[y * W + x] = 1
			elif h > 0.34 and d > 40:
				t = 4
				if rng.randf() < 0.09: objs.append(["rock", x, y]); blocked[y * W + x] = 1
				elif rng.randf() < 0.012: spawns.append(["skeleton", x, y])
			else:
				t = 5 if f > 0.15 else (1 if rng.randf() < 0.06 else 0)
				if rng.randf() < (0.16 if f > 0.15 else 0.04):
					objs.append(["tree", x, y]); blocked[y * W + x] = 1
				elif rng.randf() < 0.012:
					spawns.append(["slime" if d < 55 or rng.randf() < 0.6 else "vulture", x, y])
				elif d > 35 and rng.randf() < 0.004:
					spawns.append(["vulture", x, y])
				elif rng.randf() < 0.01 and d > 12:
					objs.append(["rock", x, y]); blocked[y * W + x] = 1
			layer.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
	return spawns

var objs: Array = []

func _build_objects(spawns: Array):
	for o in objs:
		var s := Sprite2D.new()
		s.texture = tx(o[0])
		var p := Vector2(o[1] * T + 8, o[2] * T + 8)
		s.position = p + (Vector2(0, -8) if o[0] == "tree" else Vector2.ZERO)
		ents.add_child(s)
	for sp in spawns:
		spawn_mob(sp[0], Vector2(sp[1] * T + 8, sp[2] * T + 8))

func spawn_mob(kind: String, p: Vector2):
	var m := Node2D.new(); m.set_script(preload("res://mob.gd")); ents.add_child(m)
	m.setup(kind, self, p)
	mobs.append(m)

func respawn_later(kind: String, p: Vector2):
	get_tree().create_timer(25.0).timeout.connect(spawn_mob.bind(kind, p))

func blocked_at(p: Vector2) -> bool:
	var tx_ := int(floor(p.x / T)); var ty := int(floor(p.y / T))
	if tx_ < 0 or ty < 0 or tx_ >= W or ty >= H: return true
	return blocked[ty * W + tx_] == 1

# mueve un nodo respetando obstaculos (el punto de colision son los pies)
func try_move(n: Node2D, step: Vector2):
	var f := Vector2(0, 6)
	if step.x != 0 and not blocked_at(n.position + Vector2(step.x + 5 * sign(step.x), 0) + f):
		n.position.x += step.x
	if step.y != 0 and not blocked_at(n.position + Vector2(0, step.y + 2 * sign(step.y)) + f):
		n.position.y += step.y

func popup(text: String, p: Vector2, col: Color = Color.WHITE):
	var l := Label.new(); l.text = text; l.scale = Vector2(0.34, 0.34)
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = p + Vector2(-8, -22); l.z_index = 100
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 14, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)

func _process(dt):
	save_t += dt
	if save_t > 8.0:
		save_t = 0.0; Game.save_game()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Game.save_game()
