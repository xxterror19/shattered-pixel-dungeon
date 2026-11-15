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
var acts: Array = []          # objetos interactivos: npcs, recursos, estaciones
var terrain_img: Image
var tiles := PackedByteArray()
var ore_cells: Array = []
var fish_cells: Array = []
var tree_nodes: Array = []
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
	for n in [["Bayu", Vector2i(3, -2)], ["Mara", Vector2i(-4, -2)], ["Toro", Vector2i(1, 4)], ["Gael", Vector2i(-2, 5)]]:
		var npc := Node2D.new(); npc.set_script(preload("res://npc.gd")); ents.add_child(npc)
		npc.setup(self, n[0])
		var tp: Vector2i = CENTER + n[1]
		npc.position = Vector2(tp.x * T + 8, tp.y * T + 8)
		blocked[tp.y * W + tp.x] = 1
		npcs.append(npc); acts.append(npc)
	for st in [["fragua", Vector2i(-7, 0)], ["yunque", Vector2i(-7, 2)], ["fogata", Vector2i(6, -4)], ["banco", Vector2i(5, 2)]]:
		var tp: Vector2i = CENTER + st[1]
		_make_node(st[0], true, Vector2(tp.x * T + 8, tp.y * T + 8)); blocked[tp.y * W + tp.x] = 1
	for c in ore_cells: _make_node(c[0], false, Vector2(c[1] * T + 8, c[2] * T + 8))
	for c in fish_cells: _make_node(c[0], false, Vector2(c[1] * T + 8, c[2] * T + 8))
	for c in tree_nodes: _make_node("arbol", false, Vector2(c[0] * T + 8, c[1] * T + 8))
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
	tiles.resize(W * H)
	terrain_img = Image.create(W, H, false, Image.FORMAT_RGB8)
	var MAPC := [Color(0.38, 0.66, 0.27), Color(0.45, 0.72, 0.3), Color(0.62, 0.47, 0.3), Color(0.2, 0.47, 0.82), Color(0.5, 0.49, 0.52), Color(0.27, 0.55, 0.24)]
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
				elif rng.randf() < 0.03:
					var oc := "cobre" if d < 60 else ("hierro" if d < 90 else "lunar")
					if rng.randf() < 0.35: oc = "carbon" if d < 85 else "hierro"
					ore_cells.append([oc, x, y]); blocked[y * W + x] = 1
				elif rng.randf() < 0.012: spawns.append(["skeleton", x, y])
			else:
				t = 5 if f > 0.15 else (1 if rng.randf() < 0.06 else 0)
				if rng.randf() < (0.16 if f > 0.15 else 0.04):
					if rng.randf() < 0.2: tree_nodes.append([x, y])
					else: objs.append(["tree", x, y])
					blocked[y * W + x] = 1
				elif rng.randf() < 0.012:
					spawns.append(["slime" if d < 55 or rng.randf() < 0.6 else "vulture", x, y])
				elif d > 35 and rng.randf() < 0.004:
					spawns.append(["vulture", x, y])
				elif rng.randf() < 0.01 and d > 12:
					objs.append(["rock", x, y]); blocked[y * W + x] = 1
			layer.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
			terrain_img.set_pixel(x, y, MAPC[t]); tiles[y * W + x] = t
	# puntos de pesca: agua con tierra libre al lado
	var cands: Array = []
	for y in range(3, H - 3):
		for x in range(3, W - 3):
			if tiles[y * W + x] == 3 and blocked[y * W + x] == 1:
				for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + dd.x; var ny: int = y + dd.y
					if blocked[ny * W + nx] == 0 and Vector2(x - CENTER.x, y - CENTER.y).length() > 12:
						cands.append([x, y]); break
	for i in range(cands.size() - 1, 0, -1):
		var j := rng.randi_range(0, i); var tmp = cands[i]; cands[i] = cands[j]; cands[j] = tmp
	for i in min(60, cands.size()):
		var c: Array = cands[i]
		fish_cells.append(["trucha" if Vector2(c[0] - CENTER.x, c[1] - CENTER.y).length() > 55 else "pez", c[0], c[1]])
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

func _make_node(res: String, station: bool, p: Vector2):
	var n := Node2D.new(); n.set_script(preload("res://node.gd")); ents.add_child(n)
	n.setup(self, res, station); n.position = p
	acts.append(n)

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
