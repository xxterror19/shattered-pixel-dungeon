extends Node2D

const STATS := {
	"slime": {"hp": 30, "atk": 6, "spd": 28, "xp": 12, "gold": 3, "aggro": 70},
	"skeleton": {"hp": 55, "atk": 11, "spd": 36, "xp": 26, "gold": 8, "aggro": 90},
	"vulture": {"hp": 40, "atk": 9, "spd": 55, "xp": 22, "gold": 5, "aggro": 110},
}
var kind := ""
var world
var hp := 1.0
var max_hp := 1.0
var atk := 1.0
var spd := 30.0
var home := Vector2.ZERO
var atk_cd := 0.0
var sprite: Sprite2D
var bar: Label

func setup(k: String, w, p: Vector2):
	kind = k; world = w; position = p; home = p
	var s = STATS[k]
	var mult: float = 1.0 + p.distance_to(Vector2(w.CENTER) * w.T) / (80.0 * w.T) * 1.5
	hp = s["hp"] * mult; max_hp = hp; atk = s["atk"] * mult; spd = s["spd"]
	sprite = Sprite2D.new(); sprite.texture = w.tx(k); add_child(sprite)

func _process(dt):
	var pl = world.player
	if pl == null or pl.dead: return
	atk_cd = max(0.0, atk_cd - dt)
	var d: Vector2 = pl.position - position
	var s = STATS[kind]
	if d.length() < float(s["aggro"]):
		if d.length() > 12.0:
			world.try_move(self, d.normalized() * spd * dt)
			sprite.flip_h = d.x < 0
		elif atk_cd <= 0.0:
			atk_cd = 1.0
			pl.hurt(max(1, int(atk) - Game.defense()))
	elif position.distance_to(home) > 6.0:
		world.try_move(self, (home - position).normalized() * spd * 0.6 * dt)
	if kind == "vulture": sprite.position.y = sin(Time.get_ticks_msec() / 150.0) * 1.5

func hurt(dmg: int):
	hp -= dmg
	world.popup(str(dmg), position, Color(1, 0.9, 0.3))
	sprite.modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if hp <= 0.0: die()

func die():
	world.mobs.erase(self)
	var s = STATS[kind]
	var g := int(s["gold"] * (1 + randi() % 3))
	Game.gold += g
	var up: bool = Game.gain_xp(int(s["xp"]))
	world.popup("+%d oro" % g, position, Color(1, 0.85, 0.2))
	if up: world.popup("¡Nivel %d!" % Game.level, world.player.position, Color(0.5, 1, 1))
	if kind == "skeleton" and randf() < 0.45: Game.add_item("hueso")
	if randf() < 0.12: Game.add_item("pocion")
	elif kind != "skeleton" and randf() < 0.15: Game.add_item("carne")
	Game.on_kill(kind)
	world.respawn_later(kind, home)
	queue_free()
