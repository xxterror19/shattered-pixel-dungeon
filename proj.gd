extends Node3D
# Proyectil magico: esfera brillante con estela; explota al impactar.

var world
var dir := Vector3.BACK
var dmg := 1
var aoe := 0.0
var life := 1.6
var col := Color.WHITE
var rad := 0.2

func setup(w, p: Vector3, d: Vector3, damage: int, c: Color, area: float, r: float):
	world = w; position = p; dir = d.normalized(); dmg = damage; col = c; aoe = area; rad = r
	Gfx.sphere(self, r, Vector3.ZERO, c, 3.0)
	var tr := CPUParticles3D.new(); tr.amount = 14; tr.lifetime = 0.35; tr.direction = Vector3.UP; tr.spread = 40.0
	tr.initial_velocity_min = 0.3; tr.initial_velocity_max = 1.0; tr.gravity = Vector3.ZERO
	var sm := SphereMesh.new(); sm.radius = r * 0.5; sm.height = r; sm.radial_segments = 4; sm.rings = 2; tr.mesh = sm
	tr.material_override = Gfx.mat(c, 2.0); tr.local_coords = false; add_child(tr)

func _process(dt):
	life -= dt
	position += dir * 18.0 * dt
	for mob in world.mobs:
		if mob.position.distance_to(position - Vector3(0, position.y, 0) + Vector3(0, 1, 0)) < 1.0 + mob.radius:
			_explode(); return
	if life <= 0.0 or world.blocked_at(position): _explode()

func _explode():
	Gfx.burst(world, position, col, 16, 6.0)
	if aoe > 0.0:
		Gfx.ring(world, Vector3(position.x, 0, position.z), aoe, col, 0.35)
		for mob in world.mobs.duplicate():
			if mob.position.distance_to(Vector3(position.x, 0, position.z)) < aoe + mob.radius: mob.hurt(dmg)
	else:
		for mob in world.mobs.duplicate():
			if mob.position.distance_to(Vector3(position.x, 0, position.z)) < 1.4 + mob.radius: mob.hurt(dmg); break
	queue_free()
