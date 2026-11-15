extends Node3D

const STATS := {
	"slime": {"hp": 30, "atk": 6, "spd": 3.0, "xp": 12, "gold": 3, "aggro": 9.0, "reach": 1.5, "r": 0.6},
	"slime_small": {"hp": 18, "atk": 5, "spd": 3.6, "xp": 4, "gold": 1, "aggro": 12.0, "reach": 1.2, "r": 0.4},
	"wolf": {"hp": 42, "atk": 9, "spd": 6.5, "xp": 20, "gold": 5, "aggro": 14.0, "reach": 1.7, "r": 0.6},
	"skeleton": {"hp": 60, "atk": 12, "spd": 3.8, "xp": 26, "gold": 8, "aggro": 12.0, "reach": 1.9, "r": 0.5},
	"bat": {"hp": 28, "atk": 8, "spd": 6.0, "xp": 18, "gold": 4, "aggro": 14.0, "reach": 1.5, "r": 0.5},
	"rey_esqueleto": {"hp": 900, "atk": 26, "spd": 3.6, "xp": 500, "gold": 300, "aggro": 24.0, "reach": 3.4, "r": 1.3, "boss": true, "name": "Rey Esqueleto"},
	"slime_rey": {"hp": 700, "atk": 22, "spd": 2.6, "xp": 450, "gold": 280, "aggro": 24.0, "reach": 3.2, "r": 2.1, "boss": true, "name": "Rey Limo"},
	"dragon": {"hp": 1800, "atk": 38, "spd": 4.2, "xp": 1500, "gold": 1000, "aggro": 28.0, "reach": 4.6, "r": 2.5, "boss": true, "name": "Dragon de Ceniza"},
}
var kind := ""
var world
var hp := 1.0
var max_hp := 1.0
var atk := 1.0
var spd := 3.0
var radius := 0.5
var home := Vector3.ZERO
var atk_cd := 0.0
var swing := -1.0
var swing_hit := false
var slow_t := 0.0
var aggro_on := false
var boss := false
var busy := 0.0
var no_respawn := false
var dying := false
var t := 0.0
var yaw := 0.0
var m: Dictionary = {}
var q: Array = []
var sp1 := 4.0
var sp2 := 8.0
var phase2 := false
var moving := false
var leap_t := -1.0
var leap_from := Vector3.ZERO
var leap_to := Vector3.ZERO

func setup(k: String, w, p: Vector3):
	kind = k; world = w; position = p; home = p
	var s = STATS[k]
	var mult := 1.0
	boss = s.has("boss")
	if not boss: mult = 1.0 + Vector2(p.x, p.z).distance_to(Vector2(w.CENTER) * w.T) / (160.0 * w.T) * 3.0
	hp = s["hp"] * mult; max_hp = hp; atk = s["atk"] * mult; spd = s["spd"]; radius = s["r"]
	yaw = randf() * TAU
	match k:
		"slime": m = Gfx.slime(Color(0.35, 0.8, 0.35), 1.0)
		"slime_small": m = Gfx.slime(Color(0.45, 0.85, 0.4), 0.6)
		"slime_rey":
			m = Gfx.slime(Color(0.3, 0.75, 0.55), 3.6)
			Gfx.box(m["body"], Vector3(2.0, 0.5, 2.0), Vector3(0, 2.7, 0), Color(0.96, 0.8, 0.2), 0.6)
		"wolf": m = Gfx.quadruped(Color(0.5, 0.5, 0.55), Color(0.3, 0.3, 0.35), 0.9, false)
		"skeleton":
			m = Gfx.humanoid(Color(0.92, 0.92, 0.86), Color(0.8, 0.8, 0.75), Color(0.85, 0.85, 0.8), Color.WHITE, 1.0, true)
			Gfx.make_weapon(m["hand"], "sword", Color(0.55, 0.5, 0.45))
		"rey_esqueleto":
			m = Gfx.humanoid(Color(0.9, 0.9, 0.84), Color(0.3, 0.1, 0.35), Color(0.25, 0.1, 0.3), Color.WHITE, 2.2, true)
			Gfx.make_weapon(m["hand"], "sword", Color(0.7, 0.2, 0.9), 2.2)
			Gfx.box(m["head"], Vector3(0.9, 0.3, 0.9), Vector3(0, 1.05, 0), Color(0.96, 0.8, 0.2), 0.6)
		"bat": m = Gfx.bat(1.0)
		"dragon": m = Gfx.dragon()
	add_child(m["root"])
	if boss:
		Gfx.label3d(self, s["name"], Vector3(0, 6.0 if k == "dragon" else (6.5 if k == "slime_rey" else 5.2), 0), Color(1, 0.8, 0.3), 64)

func later(sec: float, fn: Callable): q.append([sec, fn])

func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func hit_player(mult: float):
	var pl = world.player
	if not pl.dead: pl.hurt(max(1, int(atk * mult) - Game.defense()))

func _process(dt):
	if dying: return
	var pl = world.player
	var d := flat(pl.position, position)
	if d > 75.0:
		m["root"].visible = false; return
	m["root"].visible = true
	t += dt; atk_cd = max(0.0, atk_cd - dt); slow_t = max(0.0, slow_t - dt); busy = max(0.0, busy - dt)
	for e in q.duplicate():
		e[0] -= dt
		if e[0] <= 0.0:
			q.erase(e)
			if not dying: e[1].call()
	if pl.dead: _anim(dt); return
	var s = STATS[kind]
	moving = false
	var to: Vector3 = pl.position - position; to.y = 0
	if leap_t >= 0.0:
		leap_t += dt
		var p: float = clamp(leap_t / 0.9, 0.0, 1.0)
		position = leap_from.lerp(leap_to, p); m["body"].position.y = sin(p * PI) * 4.0
		if p >= 1.0: leap_t = -1.0; m["body"].position.y = 0.0
	elif busy <= 0.0 and (aggro_on or d < float(s["aggro"])):
		aggro_on = true
		if boss and (world.boss == null or not is_instance_valid(world.boss)): world.boss = self
		yaw = lerp_angle(yaw, atan2(to.x, to.z), min(1.0, dt * 8.0))
		if d > float(s["reach"]) * 0.85:
			world.try_move(self, to.normalized() * spd * (0.5 if slow_t > 0.0 else 1.0) * dt); moving = true
		elif atk_cd <= 0.0 and swing < 0.0:
			atk_cd = 1.7 if boss else 1.1; swing = 0.0; swing_hit = false
		if boss: _boss_ai(dt, d)
		if d > float(s["aggro"]) * 3.0 and not boss: aggro_on = false
	elif busy <= 0.0 and flat(position, home) > 2.0:
		var back := home - position; back.y = 0
		yaw = lerp_angle(yaw, atan2(back.x, back.z), min(1.0, dt * 6.0))
		world.try_move(self, back.normalized() * spd * 0.7 * dt); moving = true
		if boss and flat(position, home) < 3.0 and hp < max_hp: hp = min(max_hp, hp + max_hp * 0.2 * dt)
	if swing >= 0.0:
		swing += dt
		if swing >= 0.22 and not swing_hit:
			swing_hit = true
			if flat(pl.position, position) < float(s["reach"]) + 0.8: hit_player(1.0)
		if swing >= 0.45: swing = -1.0
	_anim(dt)

# ---------------------------------------------------------------- jefes
func _boss_ai(dt: float, d: float):
	sp1 -= dt; sp2 -= dt
	if not phase2 and hp < max_hp * 0.4:
		phase2 = true; world.popup("¡Furia!", position, Color(1, 0.3, 0.2))
	var k := 0.6 if phase2 else 1.0
	var pl = world.player
	match kind:
		"rey_esqueleto":
			if sp1 <= 0.0 and d < 12.0:
				sp1 = 6.0 * k; busy = 1.3; var p: Vector3 = pl.position
				Gfx.telegraph(world, p, 4.5, 1.0)
				later(1.0, func():
					Gfx.ring(world, p, 4.5, Color(1, 0.5, 0.2), 0.4); Gfx.burst(world, p, Color(1, 0.6, 0.2), 24, 8.0)
					if flat(pl.position, p) < 4.5: hit_player(1.8))
			elif sp2 <= 0.0:
				sp2 = 13.0 * k; busy = 0.8; world.popup("¡A mi!", position, Color(0.8, 0.5, 1))
				var n := 0
				for mob in world.mobs: if mob.kind == "skeleton" and mob.no_respawn: n += 1
				if n < 4:
					for i in 2:
						var a := randf() * TAU
						var sk = world.spawn_mob("skeleton", position + Vector3(cos(a), 0, sin(a)) * 4.0); sk.no_respawn = true; sk.aggro_on = true
					Gfx.ring(world, position, 5.0, Color(0.7, 0.3, 1.0), 0.5)
		"slime_rey":
			if sp1 <= 0.0 and d < 16.0:
				sp1 = 4.5 * k; var p: Vector3 = pl.position; p.y = 0
				Gfx.telegraph(world, p, 4.0, 0.9)
				leap_t = 0.0; leap_from = position; leap_to = p
				later(0.9, func():
					Gfx.ring(world, p, 4.0, Color(0.4, 1, 0.6), 0.4); Gfx.burst(world, p, Color(0.4, 1, 0.6), 24, 8.0)
					if flat(pl.position, p) < 4.0: hit_player(1.6))
			if phase2 and sp2 <= 0.0:
				sp2 = 18.0
				for i in 3:
					var a := randf() * TAU
					var sl = world.spawn_mob("slime_small", position + Vector3(cos(a), 0, sin(a)) * 3.5); sl.no_respawn = true; sl.aggro_on = true
		"dragon":
			if sp1 <= 0.0 and d < 16.0:
				sp1 = 7.0 * k; busy = 2.2
				var dir := Vector3(pl.position.x - position.x, 0, pl.position.z - position.z).normalized(); yaw = atan2(dir.x, dir.z)
				for i in 3:
					var c: Vector3 = position + dir * (5.0 + 4.0 * i); c.y = 0
					later(0.4 + 0.5 * i, func(): Gfx.telegraph(world, c, 3.4, 0.7))
					later(1.1 + 0.5 * i, func():
						Gfx.ring(world, c, 3.4, Color(1, 0.5, 0.1), 0.4); Gfx.burst(world, c + Vector3(0, 1, 0), Color(1, 0.6, 0.1), 30, 9.0)
						if flat(pl.position, c) < 3.4: hit_player(1.2))
			elif sp2 <= 0.0 and d > 8.0:
				sp2 = 10.0 * k; busy = 1.5
				var tgt: Vector3 = pl.position; var dir := (tgt - position); dir.y = 0; dir = dir.normalized()
				Gfx.telegraph(world, position + dir * 8.0, 2.6, 0.7)
				later(0.7, func():
					var ch := create_tween(); ch.tween_property(self, "position", position + dir * 14.0, 0.5)
					later(0.5, func(): if flat(pl.position, position) < 3.6: hit_player(1.8)))

# ---------------------------------------------------------------- animacion
func _anim(dt: float):
	m["root"].rotation.y = yaw
	var sw: float = clamp(swing / 0.45, 0.0, 1.0) if swing >= 0.0 else -1.0
	var ph := t * 9.0
	var leg := sin(ph) * 0.8 if moving else 0.0
	match kind:
		"skeleton", "rey_esqueleto":
			m["legL"].rotation.x = leg; m["legR"].rotation.x = -leg; m["armL"].rotation.x = -leg * 0.6
			var ar := -0.55
			if sw >= 0.0: ar = lerp(-2.7, 0.6, clamp((sw - 0.15) / 0.4, 0.0, 1.0)) if sw > 0.15 else lerp(-0.55, -2.7, sw / 0.15)
			elif busy > 0.0 and kind == "rey_esqueleto": ar = -2.9
			m["armR"].rotation.x = ar
			m["body"].position.y = 0.95 * m["s"] + abs(sin(ph)) * 0.05 * (1.0 if moving else 0.0)
		"wolf":
			for i in 4: m["legs"][i].rotation.x = sin(ph * 1.4 + (PI if i % 3 == 0 else 0.0)) * 0.8 if moving else 0.0
			m["body"].position.z = 0.6 * sin(sw * PI) if sw >= 0.0 else 0.0
			m["tail"].rotation.y = sin(t * 8.0) * 0.5
		"slime", "slime_small", "slime_rey":
			var hop: float = abs(sin(t * 5.0)) if moving else 0.0
			m["body"].scale = Vector3(1 + (0.12 * (1.0 - hop)), 1 - 0.12 * (1.0 - hop) + 0.1 * hop, 1 + (0.12 * (1.0 - hop)))
			if leap_t < 0.0: m["body"].position.y = hop * 0.5 * m["s"]
			if sw >= 0.0: m["body"].position.z = 0.8 * sin(sw * PI) * m["s"]
			else: m["body"].position.z = 0.0
		"bat":
			var fl := sin(t * 20.0) * 0.8
			m["wl"].rotation.z = fl; m["wr"].rotation.z = -fl
			m["body"].position.y = 1.6 + sin(t * 3.0) * 0.2 - (0.8 * sin(sw * PI) if sw >= 0.0 else 0.0)
		"dragon":
			var fl := sin(t * 3.0) * 0.35
			m["wl"].rotation.z = fl; m["wr"].rotation.z = -fl
			for i in 4: m["legs"][i].rotation.x = sin(ph * 0.8 + (PI if i % 3 == 0 else 0.0)) * 0.5 if moving else 0.0
			m["tail"].rotation.y = sin(t * 1.5) * 0.35
			m["neck"].rotation.x = (-0.5 * sin(sw * PI) if sw >= 0.0 else 0.0) + (-0.4 if busy > 0.5 else 0.0)

func hurt(dmg: int):
	if dying: return
	hp -= dmg; aggro_on = true
	world.popup(str(dmg), position + Vector3(0, radius * 1.4, 0), Color(1, 0.9, 0.3))
	var tw := create_tween(); m["root"].scale = Vector3(1.15, 0.9, 1.15); tw.tween_property(m["root"], "scale", Vector3.ONE, 0.15)
	if boss: world.boss = self
	if hp <= 0.0: die()

func die():
	dying = true; q.clear()
	world.mobs.erase(self)
	if world.boss == self: world.boss = null
	var s = STATS[kind]
	var g := int(s["gold"] * (1 + randi() % 3))
	Game.gold += g
	var up: bool = Game.gain_xp(int(s["xp"]))
	world.popup("+%d oro" % g, position, Color(1, 0.85, 0.2))
	if up: world.popup("¡Nivel %d!" % Game.level, world.player.position, Color(0.5, 1, 1)); Gfx.ring(world, world.player.position, 4.0, Color(0.5, 1, 1), 0.6)
	if kind == "skeleton" and randf() < 0.45: Game.add_item("hueso")
	if kind == "wolf" and randf() < 0.5: Game.add_item("colmillo")
	if kind == "bat" and randf() < 0.5: Game.add_item("polvo")
	if kind == "rey_esqueleto": Game.add_item("corona")
	if kind == "slime_rey": Game.add_item("corona")
	if kind == "dragon": Game.add_item("escama")
	if boss: world.popup("¡Jefe derrotado!", position, Color(1, 0.8, 0.3)); Gfx.burst(world, position + Vector3(0, 2, 0), Color(1, 0.8, 0.3), 60, 12.0)
	elif randf() < 0.12: Game.add_item("pocion")
	elif kind != "skeleton" and randf() < 0.12: Game.add_item("carne")
	Game.on_kill(kind)
	if not no_respawn and kind != "slime_small": world.respawn_later(kind, home, 240.0 if boss else 25.0)
	Gfx.burst(world, position + Vector3(0, 1, 0), Color(0.9, 0.9, 0.9), 12, 5.0)
	var tw := create_tween()
	tw.tween_property(m["root"], "scale", Vector3(1, 0.05, 1), 0.35)
	tw.tween_callback(queue_free)
