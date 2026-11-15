extends Node2D
# Bola de fuego

var world
var dir := Vector2.RIGHT
var life := 1.2

func setup(w, p: Vector2, d: Vector2):
	world = w; position = p; dir = d
	var s := Sprite2D.new()
	var at := AtlasTexture.new(); at.atlas = w.tx("icons"); at.region = Rect2(11 * 16, 0, 16, 16)
	s.texture = at; add_child(s)

func _process(dt):
	life -= dt
	position += dir * 200.0 * dt
	rotation += 10.0 * dt
	for m in world.mobs:
		if m.position.distance_to(position) < 12:
			m.hurt(int(Game.attack_power() * 2.2 + 6)); queue_free(); return
	if life <= 0.0 or world.blocked_at(position): queue_free()
