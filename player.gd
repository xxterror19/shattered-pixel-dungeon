extends Node3D

var world
var m: Dictionary
var model: Node3D
var move_vec := Vector2.ZERO
var yaw := 0.0
var atk_cd := 0.0
var anim := ""
var anim_t := 0.0
var anim_len := 0.5
var anim_done := false
var combo := 0
var cds := {"dash": 0.0, "spin": 0.0, "slam": 0.0, "fire": 0.0, "bolt": 0.0, "nova": 0.0, "heal": 0.0}
var dash_t := 0.0
var dash_dir := Vector3.BACK
var dash_hit: Array = []
var t := 0.0
var dead := false
var shown_weapon := "?"
var shown_armor := "?"
var horse: Dictionary = {}
var body_y := 0.95
var walk_amt := 0.0

func setup(w):
	world = w
	m = Gfx.humanoid(Color(0.94, 0.76, 0.6), Color(0.25, 0.45, 0.85), Color(0.28, 0.24, 0.38), Color(0.45, 0.27, 0.15))
	model = m["root"]; add_child(model)

func speed() -> float:
	return 7.5 * (1.9 if Game.mounted else 1.0)

func skill_def(id: String) -> Dictionary:
	if id == "heal": return Game.HEAL
	for tp in Game.SKILLS:
		for s in Game.SKILLS[tp]:
			if s["id"] == id: return s
	return {}

func _process(dt):
	t += dt
	atk_cd = max(0.0, atk_cd - dt)
	for k in cds: cds[k] = max(0.0, cds[k] - dt)
	_refresh_gear()
	_refresh_mount()
	var moving := false
	if dead: return
	if dash_t > 0.0:
		dash_t -= dt
		world.try_move(self, dash_dir * 20.0 * dt)
		for mob in world.mobs:
			if not dash_hit.has(mob) and mob.position.distance_to(position) < 1.8:
				dash_hit.append(mob); mob.hurt(int(Game.attack_power() * 1.3 + 4))
	elif move_vec.length() > 0.1:
		var v := move_vec.limit_length(1.0)
		var step: Vector3 = Vector3(v.x, 0, v.y) * speed() * dt
		var slowmul := 0.55 if anim != "" and anim != "spin" else 1.0
		world.try_move(self, step * slowmul)
		yaw = lerp_angle(yaw, atan2(v.x, v.y), min(1.0, dt * 14.0))
		moving = true
	walk_amt = lerp(walk_amt, 1.0 if moving else 0.0, min(1.0, dt * 10.0))
	_animate(dt)
	Game.pos = position
	if Game.hp < Game.max_hp(): Game.hp = min(Game.max_hp(), Game.hp + 0.6 * dt)

func _refresh_gear():
	if shown_weapon != Game.weapon:
		shown_weapon = Game.weapon
		if Game.weapon == "": Gfx.make_weapon(m["hand"], "none", Color.WHITE) if false else null
		var it = Game.ITEMS.get(Game.weapon, null)
		if it: Gfx.make_weapon(m["hand"], it["wtype"], Color(it["col"]))
		else:
			for c in m["hand"].get_children(): c.queue_free()
	if shown_armor != Game.armor:
		shown_armor = Game.armor
		var c := Color(0.25, 0.45, 0.85)
		if Game.armor != "": c = Color(Game.ITEMS[Game.armor]["col"])
		m["torso"].material_override = Gfx.mat(c)

func _refresh_mount():
	if Game.mounted and horse.is_empty():
		horse = Gfx.quadruped(Color(0.55, 0.36, 0.2), Color(0.15, 0.1, 0.08), 1.1, true)
		add_child(horse["root"])
	if horse.size() > 0:
		horse["root"].visible = Game.mounted
		model.position.y = 0.95 if Game.mounted else 0.0

func _animate(dt):
	var arm_r := -0.55; var arm_l := 0.0; var torso_y := 0.0; var by := body_y
	var ph := t * (14.0 if Game.mounted else 11.0)
	var leg := sin(ph) * 0.85 * walk_amt
	m["legL"].rotation.x = leg; m["legR"].rotation.x = -leg
	arm_l = -leg * 0.7
	by = body_y + sin(t * 2.0) * 0.015 + abs(sin(ph)) * 0.06 * walk_amt
	var spin_y := 0.0
	var lift := 0.0
	if anim != "":
		anim_t += dt
		var p: float = clamp(anim_t / anim_len, 0.0, 1.0)
		match anim:
			"slash":
				var wind := -2.9 if combo % 2 == 0 else -2.4
				var sgn := 1.0 if combo % 2 == 0 else -1.0
				if p < 0.35: arm_r = lerp(-0.55, wind, p / 0.35); torso_y = -0.5 * sgn * (p / 0.35)
				elif p < 0.65: arm_r = lerp(wind, 0.7, (p - 0.35) / 0.3); torso_y = lerp(-0.5 * sgn, 0.7 * sgn, (p - 0.35) / 0.3)
				else: arm_r = lerp(0.7, -0.55, (p - 0.65) / 0.35); torso_y = lerp(0.7 * sgn, 0.0, (p - 0.65) / 0.35)
				arm_l = -arm_r * 0.3
				if p >= 0.45 and not anim_done: anim_done = true; _slash_hit(Game.attack_power() + randi() % 4, 3.2, 0.1)
			"cast":
				if p < 0.4: arm_r = lerp(-0.55, -2.5, p / 0.4)
				elif p < 0.65: arm_r = lerp(-2.5, -1.2, (p - 0.4) / 0.25)
				else: arm_r = lerp(-1.2, -0.55, (p - 0.65) / 0.35)
				arm_l = -1.2 if p < 0.65 else arm_l
				if p >= 0.5 and not anim_done: anim_done = true; _fire_orb(false)
			"spin":
				spin_y = p * TAU * 2.0; arm_r = -1.45; arm_l = -1.45
				if int(p * 6.0) != int(max(0.0, (anim_t - dt) / anim_len) * 6.0): _slash_hit(int(Game.attack_power() * 0.9) + 2, 3.4, -2.0)
			"slam":
				lift = sin(min(p / 0.5, 1.0) * PI) * 1.4 if p < 0.5 else 0.0
				arm_r = lerp(-2.9, 0.3, p) ; arm_l = arm_r
				if p >= 0.5 and not anim_done:
					anim_done = true
					Gfx.ring(world, position, 5.0, Color(1, 0.7, 0.2), 0.4); Gfx.burst(world, position, Color(1, 0.8, 0.3), 24, 8.0)
					_slash_hit(int(Game.attack_power() * 2.5) + 6, 5.0, -2.0)
			"fireball", "bolt", "nova":
				if p < 0.4: arm_r = lerp(-0.55, -2.5, p / 0.4)
				elif p < 0.65: arm_r = lerp(-2.5, -1.2, (p - 0.4) / 0.25)
				else: arm_r = lerp(-1.2, -0.55, (p - 0.65) / 0.35)
				if p >= 0.5 and not anim_done: anim_done = true; _skill_effect(anim)
		if anim_t >= anim_len: anim = ""
	m["armR"].rotation.x = arm_r; m["armL"].rotation.x = arm_l
	m["torso"].rotation.y = torso_y
	m["body"].position.y = by + lift
	model.rotation.y = yaw + spin_y
	if not horse.is_empty() and horse["root"].visible:
		horse["root"].rotation.y = yaw
		for i in 4: horse["legs"][i].rotation.x = sin(ph + (PI if i % 3 == 0 else 0.0)) * 0.9 * walk_amt
		m["legL"].rotation.x = -1.2; m["legR"].rotation.x = -1.2
		model.position.y = 0.95 + 0.04 * sin(ph * 2.0) * walk_amt

func _start(a: String, len_: float):
	anim = a; anim_t = 0.0; anim_len = len_; anim_done = false

func nearest_mob(r: float):
	var best = null; var bd := r
	for mob in world.mobs:
		var d: float = mob.position.distance_to(position)
		if d < bd: bd = d; best = mob
	return best

func _face_nearest(r: float):
	var mob = nearest_mob(r)
	if mob:
		var d: Vector3 = mob.position - position
		yaw = atan2(d.x, d.z)

func fwd() -> Vector3:
	return Vector3(sin(yaw), 0, cos(yaw))

# daño en arco frontal (dot_min = -2 -> todo alrededor)
func _slash_hit(dmg: int, radius: float, dot_min: float):
	if dot_min > -1.0: Gfx.slash(model, Color(0.8, 0.95, 1.0))
	elif anim == "spin": Gfx.ring(world, position, radius, Color(0.8, 0.95, 1.0), 0.25)
	for mob in world.mobs.duplicate():
		var d: Vector3 = mob.position - position
		d.y = 0
		if d.length() < radius + mob.radius and (dot_min < -1.0 or d.normalized().dot(fwd()) > dot_min):
			mob.hurt(dmg)
			Gfx.burst(world, mob.position + Vector3(0, 1, 0), Color(1, 0.9, 0.5), 6, 4.0)

func hand_pos() -> Vector3:
	return position + fwd() * 0.7 + Vector3(0, 1.5, 0)

func _fire_orb(big: bool):
	var it = Game.ITEMS.get(Game.weapon, null)
	var col := Color(it["col"]) if it else Color(1, 0.5, 0.2)
	var d := fwd(); var mob = nearest_mob(16.0)
	if mob: d = (mob.position - position).normalized() * Vector3(1, 0, 1)
	var p := Node3D.new(); p.set_script(preload("res://proj.gd")); world.add_child(p)
	if big: p.setup(world, hand_pos(), d, int(Game.attack_power() * 2.0) + 6, Color(1, 0.5, 0.15), 2.4, 0.3)
	else: p.setup(world, hand_pos(), d, Game.attack_power() + randi() % 4, col, 0.0, 0.2)

func attack():
	if dead or atk_cd > 0.0 or anim != "": return
	if Game.weapon_type() == "staff":
		atk_cd = 0.6; _face_nearest(16.0); _start("cast", 0.55)
	else:
		atk_cd = 0.55; combo = (combo + 1) % 3; _face_nearest(5.0); _start("slash", 0.5)

func use_skill(id: String):
	var def := skill_def(id)
	if dead or def.is_empty() or cds[id] > 0.0 or Game.level < int(def["level"]) or (anim != "" and anim != "slash" and anim != "cast"): return
	if id != "heal" and not Game.SKILLS[Game.weapon_type()].any(func(s): return s["id"] == id): return
	cds[id] = float(def["cd"])
	match id:
		"dash":
			_face_nearest(6.0); dash_t = 0.22; dash_dir = fwd(); dash_hit.clear(); Gfx.burst(world, position, Color(0.8, 0.9, 1), 8, 3.0)
		"spin": _start("spin", 0.7)
		"slam": _start("slam", 0.8)
		"fire": _face_nearest(16.0); _start("fireball", 0.6)
		"bolt": _face_nearest(14.0); _start("bolt", 0.6)
		"nova": _start("nova", 0.6)
		"heal":
			Game.hp = min(Game.max_hp(), Game.hp + Game.max_hp() * 0.4)
			world.popup("+Vida", position, Color(0.4, 1, 0.5)); Gfx.burst(world, position + Vector3(0, 1, 0), Color(0.4, 1, 0.5), 18, 3.5)

func _skill_effect(id: String):
	match id:
		"fireball": _fire_orb(true)
		"bolt":
			var from := hand_pos(); var hit: Array = []
			var cur = nearest_mob(14.0)
			for i in 3:
				if cur == null: break
				hit.append(cur)
				var to: Vector3 = cur.position + Vector3(0, 1.0, 0)
				Gfx.line(world, from, to, Color(0.75, 0.9, 1.0), 0.3); Gfx.burst(world, to, Color(0.8, 0.95, 1), 8, 4.0)
				cur.hurt(int(Game.attack_power() * 1.8) + 4)
				from = to; var nxt = null; var bd := 8.0
				for mob in world.mobs:
					if not hit.has(mob) and mob.position.distance_to(cur.position) < bd: bd = mob.position.distance_to(cur.position); nxt = mob
				cur = nxt
		"nova":
			Gfx.ring(world, position, 7.0, Color(0.5, 0.85, 1.0), 0.5); Gfx.burst(world, position + Vector3(0, 0.5, 0), Color(0.7, 0.9, 1), 30, 7.0)
			for mob in world.mobs.duplicate():
				if mob.position.distance_to(position) < 7.0 + mob.radius:
					mob.hurt(int(Game.attack_power() * 1.6) + 4); mob.slow_t = 3.0

func hurt(n: int):
	if dead: return
	Game.hp -= n
	world.popup("-%d" % n, position, Color(1, 0.4, 0.4))
	Gfx.burst(world, position + Vector3(0, 1, 0), Color(1, 0.3, 0.3), 6, 3.0)
	if Game.hp <= 0.0: die()

func die():
	dead = true; anim = ""
	world.popup("Has caido...", position, Color.WHITE)
	Game.gold = int(Game.gold * 0.9)
	create_tween().tween_property(model, "rotation:x", -1.5, 0.4)
	await get_tree().create_timer(1.8).timeout
	position = world.wpos(world.CENTER) + Vector3(0, 0, 8)
	model.rotation.x = 0.0
	Game.hp = Game.max_hp(); Game.mounted = false; dead = false
