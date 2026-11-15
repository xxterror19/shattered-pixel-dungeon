extends Node2D

var world
var sprite: Sprite2D
var facing := 0 # 0 abajo, 1 arriba, 2 izquierda, 3 derecha
var move_vec := Vector2.ZERO
var atk_cd := 0.0
var cds := {"dash": 0.0, "heal": 0.0, "fire": 0.0}
var dash_t := 0.0
var dash_dir := Vector2.DOWN
var dash_hit := []
var t := 0.0
var dead := false
var gnode = null
var gt := 0.0

const DIRS := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]

func setup(w):
	world = w
	sprite = Sprite2D.new(); sprite.hframes = 4; sprite.texture = w.tx("hero"); add_child(sprite)

func speed() -> float:
	return 70.0 * (1.8 if Game.mounted else 1.0)

func _process(dt):
	t += dt
	_gather(dt)
	atk_cd = max(0.0, atk_cd - dt)
	for k in cds: cds[k] = max(0.0, cds[k] - dt)
	sprite.texture = world.tx("horse" if Game.mounted else "hero")
	if dash_t > 0.0:
		dash_t -= dt
		world.try_move(self, dash_dir * 260.0 * dt)
		for m in world.mobs:
			if not dash_hit.has(m) and m.position.distance_to(position) < 16:
				dash_hit.append(m); m.hurt(int(Game.attack_power() * 1.2 + 4))
	elif move_vec.length() > 0.1:
		var v := move_vec.limit_length(1.0)
		world.try_move(self, v * speed() * dt)
		if abs(v.x) > abs(v.y): facing = 3 if v.x > 0 else 2
		else: facing = 0 if v.y > 0 else 1
	sprite.frame = facing
	sprite.position.y = -abs(sin(t * 12.0)) * 1.5 if move_vec.length() > 0.1 else 0.0
	Game.pos = position
	if Game.hp < Game.max_hp(): Game.hp = min(Game.max_hp(), Game.hp + 0.6 * dt)

func nearest_mob(r: float):
	var best = null; var bd := r
	for m in world.mobs:
		var d: float = m.position.distance_to(position)
		if d < bd: bd = d; best = m
	return best

func attack():
	if dead or atk_cd > 0.0: return
	atk_cd = 0.45
	var tw := create_tween()
	tw.tween_property(sprite, "offset", DIRS[facing] * 3.0, 0.05)
	tw.tween_property(sprite, "offset", Vector2.ZERO, 0.1)
	var m = nearest_mob(30.0)
	if m: m.hurt(Game.attack_power() + randi() % 4)

func use_skill(id: String):
	if dead or cds[id] > 0.0 or Game.level < int(Game.SKILLS[id]["level"]): return
	cds[id] = float(Game.SKILLS[id]["cd"])
	match id:
		"dash":
			dash_t = 0.18; dash_dir = DIRS[facing]; dash_hit.clear()
		"heal":
			Game.hp = min(Game.max_hp(), Game.hp + Game.max_hp() * 0.4)
			world.popup("+Vida", position, Color(0.4, 1, 0.5))
		"fire":
			var p := Node2D.new(); p.set_script(preload("res://proj.gd")); world.ents.add_child(p)
			var m = nearest_mob(160.0)
			p.setup(world, position, (m.position - position).normalized() if m else DIRS[facing])

func hurt(n: int):
	if dead: return
	Game.hp -= n
	world.popup("-%d" % n, position, Color(1, 0.4, 0.4))
	sprite.modulate = Color(1, 0.5, 0.5)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if Game.hp <= 0.0: die()

func die():
	dead = true
	world.popup("Has caido...", position, Color.WHITE)
	Game.gold = int(Game.gold * 0.9)
	await get_tree().create_timer(1.5).timeout
	position = Vector2(world.CENTER.x * world.T, world.CENTER.y * world.T + 40)
	Game.hp = Game.max_hp(); Game.mounted = false; dead = false

# ---------------- recoleccion ----------------
func start_gather(n):
	var d = Game.NODES[n.res]
	if Game.skill_level(d["skill"]) < int(d["lvl"]):
		world.popup("Necesitas %s nivel %d" % [Game.SKILL_NAMES[d["skill"]], d["lvl"]], position, Color(1, 0.5, 0.4)); return
	if n.depleted: world.popup("Agotado...", position, Color(0.8, 0.8, 0.8)); return
	gnode = n; gt = 0.0

func cancel_gather(): gnode = null

func _gather(dt):
	if gnode == null: return
	if dead or not is_instance_valid(gnode) or gnode.depleted or move_vec.length() > 0.25 or gnode.position.distance_to(position) > 34.0:
		gnode = null; return
	gt += dt
	var d = Game.NODES[gnode.res]
	if gt >= float(d["time"]):
		gt = 0.0
		if not Game.add_item(d["item"]):
			world.popup("Mochila llena", position, Color(1, 0.5, 0.4)); gnode = null; return
		var up: bool = Game.add_skill_xp(d["skill"], int(d["xp"]))
		world.popup("+%s" % Game.ITEMS[d["item"]]["name"], position, Color(0.8, 1, 0.8))
		if up: world.popup("¡%s nivel %d!" % [Game.SKILL_NAMES[d["skill"]], Game.skill_level(d["skill"])], position + Vector2(0, -10), Color(0.5, 1, 1))
		gnode.deplete()
		if gnode.depleted: gnode = null
