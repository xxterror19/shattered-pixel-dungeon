extends Node3D
# Mundo abierto 3D: terreno generado, arboles, enemigos, jefes y NPCs.

const W := 160
const H := 160
const T := 2.0                       # metros por celda
const CENTER := Vector2i(80, 80)
const BOSS_SPOTS := {"slime_rey": Vector2i(36, 112), "rey_esqueleto": Vector2i(126, 40), "dragon": Vector2i(128, 128)}
const NPC_DEFS := [["Bayu", Vector2i(3, -3), Color(0.9, 0.75, 0.2)], ["Mara", Vector2i(-4, -3), Color(0.7, 0.3, 0.7)],
	["Toro", Vector2i(2, 4), Color(0.6, 0.25, 0.2)], ["Elda", Vector2i(-4, 3), Color(0.25, 0.45, 0.85)]]

var blocked := PackedByteArray()
var ents: Node3D
var player
var mobs: Array = []
var npcs: Array = []
var ui
var cam: Camera3D
var boss = null
var save_t := 0.0
var game_t := 0.0
var cam_pos := Vector3.ZERO

func _ready():
	blocked.resize(W * H)
	_build_env()
	ents = Node3D.new(); add_child(ents)
	var spawns := _build_world()
	var loaded: bool = Game.load_game()
	if not loaded:
		for i in 3: Game.add_item("pocion")
	player = Node3D.new(); player.set_script(preload("res://player.gd")); ents.add_child(player)
	player.setup(self)
	player.position = Game.pos if loaded and Game.pos != Vector3.ZERO else wpos(CENTER) + Vector3(0, 0, 8)
	cam = Camera3D.new(); cam.fov = 55; cam.far = 220; add_child(cam)
	cam_pos = player.position + Vector3(0, 13, 11); cam.position = cam_pos
	cam.look_at(player.position + Vector3(0, 1, 0))
	for n in NPC_DEFS:
		var npc := Node3D.new(); npc.set_script(preload("res://npc.gd")); ents.add_child(npc)
		npc.setup(self, n[0], n[2])
		var tp: Vector2i = CENTER + n[1]
		npc.position = wpos(tp)
		blocked[tp.y * W + tp.x] = 1
		npcs.append(npc)
	for sp in spawns: spawn_mob(sp[0], wpos(Vector2i(sp[1], sp[2])))
	for k in BOSS_SPOTS: spawn_mob(k, wpos(BOSS_SPOTS[k]))
	ui = CanvasLayer.new(); ui.set_script(preload("res://ui.gd")); add_child(ui)
	ui.setup(self)

func wpos(c: Vector2i) -> Vector3:
	return Vector3(c.x * T + T / 2.0, 0, c.y * T + T / 2.0)

func _build_env():
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.76, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.78, 0.82, 0.9); env.ambient_light_energy = 0.75
	env.fog_enabled = true; env.fog_light_color = Color(0.6, 0.78, 0.95); env.fog_density = 0.006
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, 35, 0); sun.light_energy = 1.0; add_child(sun)

func _build_world() -> Array:
	var cand := {"slime": [], "wolf": [], "skeleton": [], "bat": []}
	var noise := FastNoiseLite.new(); noise.seed = 4242; noise.frequency = 0.035
	var noise2 := FastNoiseLite.new(); noise2.seed = 99; noise2.frequency = 0.06
	var rng := RandomNumberGenerator.new(); rng.seed = 4242
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	var trees: Array = []; var rocks: Array = []
	for y in H:
		for x in W:
			var d := Vector2(x - CENTER.x, y - CENTER.y).length()
			var h := noise.get_noise_2d(x, y); var f := noise2.get_noise_2d(x, y)
			var col := Color(0.38, 0.66, 0.27)
			var edge := x < 2 or y < 2 or x >= W - 2 or y >= H - 2
			var arena := false
			for k in BOSS_SPOTS:
				if Vector2(x, y).distance_to(Vector2(BOSS_SPOTS[k])) < 7.0: arena = true
			if arena:
				col = Color(0.42, 0.38, 0.36)
			elif edge:
				col = Color(0.2, 0.45, 0.8); blocked[y * W + x] = 1
			elif d < 14:
				col = Color(0.62, 0.47, 0.3) if d < 8 else Color(0.4, 0.68, 0.28)
			elif h < -0.22:
				col = Color(0.2, 0.47, 0.82); blocked[y * W + x] = 1
			elif h > 0.34 and d > 40:
				col = Color(0.5, 0.49, 0.52)
				if rng.randf() < 0.07: rocks.append(Vector2i(x, y)); blocked[y * W + x] = 1
				elif rng.randf() < 0.05: cand["skeleton"].append([x, y])
			else:
				col = Color(0.27, 0.55, 0.24) if f > 0.15 else Color(0.38, 0.66, 0.27)
				if rng.randf() < (0.14 if f > 0.15 else 0.035):
					trees.append(Vector2i(x, y)); blocked[y * W + x] = 1
				elif f > 0.15 and rng.randf() < 0.02: cand["wolf"].append([x, y])
				elif rng.randf() < 0.012: cand["slime"].append([x, y])
				elif d > 30 and rng.randf() < 0.004: cand["bat"].append([x, y])
			var j := rng.randf_range(-0.04, 0.04)
			img.set_pixel(x, y, Color(col.r + j, col.g + j, col.b + j))
	var tex := ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(W * T, H * T); mi.mesh = pm
	var m := StandardMaterial3D.new(); m.albedo_texture = tex; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; m.roughness = 1.0
	mi.material_override = m; mi.position = Vector3(W * T / 2.0, 0, H * T / 2.0); add_child(mi)
	_multimesh(trees, 0, rng); _multimesh(trees, 1, rng); _multimesh(rocks, 2, rng)
	var out: Array = []
	var lim := {"slime": 55, "wolf": 40, "skeleton": 45, "bat": 25}
	for k in cand:
		var arr: Array = cand[k]
		for i in range(arr.size() - 1, 0, -1):
			var j := rng.randi_range(0, i); var t = arr[i]; arr[i] = arr[j]; arr[j] = t
		for i in min(lim[k], arr.size()): out.append([k, arr[i][0], arr[i][1]])
	return out

# 0 = tronco, 1 = copa, 2 = rocas (MultiMesh: miles de objetos baratos)
func _multimesh(cells: Array, part: int, rng: RandomNumberGenerator):
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.instance_count = cells.size()
	var mesh: Mesh; var mat: StandardMaterial3D
	if part == 0:
		var c := CylinderMesh.new(); c.top_radius = 0.18; c.bottom_radius = 0.26; c.height = 1.6; c.radial_segments = 6; mesh = c; mat = Gfx.mat(Color(0.42, 0.28, 0.16))
	elif part == 1:
		var c := CylinderMesh.new(); c.top_radius = 0.0; c.bottom_radius = 1.25; c.height = 3.2; c.radial_segments = 7; mesh = c; mat = Gfx.mat(Color(0.18, 0.46, 0.2))
	else:
		var s := SphereMesh.new(); s.radius = 0.9; s.height = 1.3; s.radial_segments = 7; s.rings = 4; mesh = s; mat = Gfx.mat(Color(0.5, 0.5, 0.54))
	mm.mesh = mesh
	for i in cells.size():
		var c: Vector2i = cells[i]
		var sc := rng.randf_range(0.7, 1.05); var p := wpos(c)
		var yoff := 0.8 * sc if part == 0 else (2.9 * sc if part == 1 else 0.35 * sc)
		var b := Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc))
		mm.set_instance_transform(i, Transform3D(b, p + Vector3(0, yoff, 0)))
	var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = mat; add_child(mmi)

func spawn_mob(kind: String, p: Vector3):
	var m := Node3D.new(); m.set_script(preload("res://mob.gd")); ents.add_child(m)
	m.setup(kind, self, p)
	mobs.append(m)
	return m

func respawn_later(kind: String, p: Vector3, secs: float = 25.0):
	get_tree().create_timer(secs).timeout.connect(spawn_mob.bind(kind, p))

func blocked_at(p: Vector3) -> bool:
	var tx := int(floor(p.x / T)); var tz := int(floor(p.z / T))
	if tx < 0 or tz < 0 or tx >= W or tz >= H: return true
	return blocked[tz * W + tx] == 1

func try_move(n: Node3D, step: Vector3):
	if step.x != 0 and not blocked_at(n.position + Vector3(step.x + 0.4 * sign(step.x), 0, 0)): n.position.x += step.x
	if step.z != 0 and not blocked_at(n.position + Vector3(0, 0, step.z + 0.4 * sign(step.z))): n.position.z += step.z

func popup(text: String, pos: Vector3, col: Color = Color.WHITE):
	Gfx.popup(self, text, pos, col)

func _process(dt):
	save_t += dt; game_t += dt
	if save_t > 8.0:
		save_t = 0.0; Game.save_game()
	if player:
		var want: Vector3 = player.position + Vector3(0, 13, 11)
		cam_pos = cam_pos.lerp(want, min(1.0, dt * 6.0))
		cam.position = cam_pos
		cam.look_at(cam_pos - Vector3(0, 13, 11) + Vector3(0, 1, 0))

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Game.save_game()
