class_name Gfx
# Modelos low-poly hechos con primitivas + efectos. Todo se anima por codigo.

static var _mats := {}

static func mat(c: Color, emit: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [c.to_html(true), emit, alpha]
	if _mats.has(key): return _mats[key]
	var m := StandardMaterial3D.new(); m.albedo_color = Color(c.r, c.g, c.b, alpha); m.roughness = 1.0
	if emit > 0.0:
		m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = emit
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m

static func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var m := BoxMesh.new(); m.size = size
	mi.mesh = m; mi.material_override = mat(c, emit); mi.position = pos; parent.add_child(mi)
	return mi

static func sphere(parent: Node3D, r: float, pos: Vector3, c: Color, emit: float = 0.0, squash: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var m := SphereMesh.new(); m.radius = r; m.height = 2.0 * r * squash
	m.radial_segments = 12; m.rings = 6
	mi.mesh = m; mi.material_override = mat(c, emit); mi.position = pos; parent.add_child(mi)
	return mi

static func cyl(parent: Node3D, rt: float, rb: float, h: float, pos: Vector3, c: Color, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var m := CylinderMesh.new(); m.top_radius = rt; m.bottom_radius = rb; m.height = h
	m.radial_segments = 8
	mi.mesh = m; mi.material_override = mat(c, emit); mi.position = pos; parent.add_child(mi)
	return mi

static func pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new(); n.position = pos; parent.add_child(n); return n

# ---------------------------------------------------------------- humanoide
# Cuerpo con articulaciones: body, head, armL/armR, legL/legR, hand (donde va el arma)
static func humanoid(skin: Color, tunic: Color, pants: Color, hair: Color, s: float = 1.0, bony: bool = false) -> Dictionary:
	var root := Node3D.new()
	var body := pivot(root, Vector3(0, 0.95 * s, 0))
	var torso := box(body, Vector3(0.55, 0.65, 0.3) * s, Vector3(0, 0.4, 0) * s, tunic)
	box(body, Vector3(0.58, 0.1, 0.32) * s, Vector3(0, 0.1, 0) * s, Color(0.35, 0.22, 0.12))
	if bony:
		for i in 3: box(body, Vector3(0.5, 0.05, 0.05) * s, Vector3(0, 0.25 + i * 0.15, 0.16) * s, Color(0.15, 0.12, 0.14))
	var head := pivot(body, Vector3(0, 0.78, 0) * s)
	box(head, Vector3(0.4, 0.4, 0.4) * s, Vector3(0, 0.2, 0) * s, skin)
	if not bony:
		box(head, Vector3(0.43, 0.14, 0.43) * s, Vector3(0, 0.4, -0.01) * s, hair)
		box(head, Vector3(0.43, 0.3, 0.1) * s, Vector3(0, 0.26, -0.18) * s, hair)
	box(head, Vector3(0.07, 0.07, 0.03) * s, Vector3(-0.1, 0.24, 0.2) * s, Color(0.05, 0.05, 0.08))
	box(head, Vector3(0.07, 0.07, 0.03) * s, Vector3(0.1, 0.24, 0.2) * s, Color(0.05, 0.05, 0.08))
	var armL := pivot(body, Vector3(-0.38, 0.68, 0) * s)
	box(armL, Vector3(0.17, 0.6, 0.17) * s, Vector3(0, -0.28, 0) * s, tunic if not bony else skin)
	sphere(armL, 0.1 * s, Vector3(0, -0.6, 0) * s, skin)
	var armR := pivot(body, Vector3(0.38, 0.68, 0) * s)
	box(armR, Vector3(0.17, 0.6, 0.17) * s, Vector3(0, -0.28, 0) * s, tunic if not bony else skin)
	sphere(armR, 0.1 * s, Vector3(0, -0.6, 0) * s, skin)
	var hand := pivot(armR, Vector3(0, -0.6, 0) * s)
	hand.rotation.x = -PI / 2.0
	var legL := pivot(body, Vector3(-0.15, 0.0, 0) * s)
	box(legL, Vector3(0.2, 0.62, 0.22) * s, Vector3(0, -0.31, 0) * s, pants)
	box(legL, Vector3(0.22, 0.12, 0.3) * s, Vector3(0, -0.66, 0.03) * s, Color(0.25, 0.16, 0.1))
	var legR := pivot(body, Vector3(0.15, 0.0, 0) * s)
	box(legR, Vector3(0.2, 0.62, 0.22) * s, Vector3(0, -0.31, 0) * s, pants)
	box(legR, Vector3(0.22, 0.12, 0.3) * s, Vector3(0, -0.66, 0.03) * s, Color(0.25, 0.16, 0.1))
	return {"root": root, "body": body, "torso": torso, "head": head, "armL": armL, "armR": armR, "legL": legL, "legR": legR, "hand": hand, "s": s}

# armas: se extienden hacia -y local del nodo mano, que ya apunta hacia delante
static func make_weapon(hand: Node3D, wtype: String, col: Color, s: float = 1.0):
	for c in hand.get_children(): c.queue_free()
	if wtype == "staff":
		cyl(hand, 0.05 * s, 0.06 * s, 1.9 * s, Vector3(0, -0.45, 0) * s, Color(0.45, 0.3, 0.16))
		sphere(hand, 0.17 * s, Vector3(0, -1.5, 0) * s, col, 2.0)
		box(hand, Vector3(0.3, 0.05, 0.05) * s, Vector3(0, -1.3, 0) * s, Color(0.7, 0.6, 0.3))
	else:
		box(hand, Vector3(0.28, 0.06, 0.08) * s, Vector3(0, -0.1, 0) * s, Color(0.8, 0.65, 0.2))
		box(hand, Vector3(0.1, 1.05, 0.04) * s, Vector3(0, -0.68, 0) * s, col, 0.3)
		box(hand, Vector3(0.05, 0.1, 0.05) * s, Vector3(0, -1.25, 0) * s, col)

# ---------------------------------------------------------------- cuadrupedos y otros
static func quadruped(body_c: Color, mane_c: Color, s: float, horse: bool) -> Dictionary:
	var root := Node3D.new(); var body := pivot(root, Vector3(0, 0.9 * s, 0))
	box(body, Vector3(0.6, 0.6, 1.4) * s, Vector3.ZERO, body_c)
	var head := pivot(body, Vector3(0, 0.35, 0.75) * s)
	box(head, Vector3(0.32, 0.4, 0.55) * s, Vector3(0, 0.1, 0.2) * s, body_c)
	box(head, Vector3(0.05, 0.1, 0.05) * s, Vector3(-0.1, 0.38, 0.0) * s, mane_c); box(head, Vector3(0.05, 0.1, 0.05) * s, Vector3(0.1, 0.38, 0.0) * s, mane_c)
	box(head, Vector3(0.06, 0.06, 0.03) * s, Vector3(-0.1, 0.2, 0.48) * s, Color(1, 0.9, 0.2) if not horse else Color.BLACK)
	box(head, Vector3(0.06, 0.06, 0.03) * s, Vector3(0.1, 0.2, 0.48) * s, Color(1, 0.9, 0.2) if not horse else Color.BLACK)
	if horse: box(body, Vector3(0.1, 0.5, 0.9) * s, Vector3(0, 0.45, 0.2) * s, mane_c)
	var tail := pivot(body, Vector3(0, 0.2, -0.7) * s); box(tail, Vector3(0.12, 0.12, 0.6) * s, Vector3(0, -0.05, -0.3) * s, mane_c)
	var legs := []
	for p in [Vector3(-0.2, -0.3, 0.5), Vector3(0.2, -0.3, 0.5), Vector3(-0.2, -0.3, -0.5), Vector3(0.2, -0.3, -0.5)]:
		var l := pivot(body, p * s); box(l, Vector3(0.16, 0.65, 0.16) * s, Vector3(0, -0.32, 0) * s, body_c.darkened(0.2)); legs.append(l)
	return {"root": root, "body": body, "head": head, "legs": legs, "tail": tail, "s": s}

static func slime(c: Color, s: float) -> Dictionary:
	var root := Node3D.new(); var body := pivot(root, Vector3.ZERO)
	sphere(body, 0.6 * s, Vector3(0, 0.45 * s, 0), c, 0.2, 0.8)
	sphere(body, 0.25 * s, Vector3(-0.2 * s, 0.7 * s, 0.1 * s), c.lightened(0.5), 0.5, 0.5)
	box(body, Vector3(0.1, 0.16, 0.05) * s, Vector3(-0.2, 0.55, 0.52) * s, Color.BLACK)
	box(body, Vector3(0.1, 0.16, 0.05) * s, Vector3(0.2, 0.55, 0.52) * s, Color.BLACK)
	return {"root": root, "body": body, "s": s}

static func bat(s: float) -> Dictionary:
	var root := Node3D.new(); var body := pivot(root, Vector3(0, 1.6, 0))
	sphere(body, 0.3 * s, Vector3.ZERO, Color(0.25, 0.2, 0.3))
	box(body, Vector3(0.06, 0.06, 0.03), Vector3(-0.1, 0.05, 0.27) * s, Color(1, 0.3, 0.3), 1.0)
	box(body, Vector3(0.06, 0.06, 0.03), Vector3(0.1, 0.05, 0.27) * s, Color(1, 0.3, 0.3), 1.0)
	var wl := pivot(body, Vector3(-0.25, 0.05, 0) * s); box(wl, Vector3(0.9, 0.04, 0.5) * s, Vector3(-0.45, 0, 0) * s, Color(0.35, 0.28, 0.4))
	var wr := pivot(body, Vector3(0.25, 0.05, 0) * s); box(wr, Vector3(0.9, 0.04, 0.5) * s, Vector3(0.45, 0, 0) * s, Color(0.35, 0.28, 0.4))
	return {"root": root, "body": body, "wl": wl, "wr": wr, "s": s}

static func dragon() -> Dictionary:
	var root := Node3D.new(); var body := pivot(root, Vector3(0, 2.0, 0))
	var C := Color(0.55, 0.15, 0.12); var D := Color(0.35, 0.08, 0.08)
	box(body, Vector3(2.0, 1.6, 4.0), Vector3.ZERO, C)
	box(body, Vector3(1.6, 0.3, 3.2), Vector3(0, 0.9, 0), D)
	var neck := pivot(body, Vector3(0, 0.5, 2.0)); box(neck, Vector3(0.9, 0.9, 1.6), Vector3(0, 0.4, 0.6), C)
	var head := pivot(neck, Vector3(0, 0.9, 1.4))
	box(head, Vector3(1.1, 0.9, 1.5), Vector3(0, 0, 0.5), C); box(head, Vector3(0.9, 0.3, 0.9), Vector3(0, -0.4, 0.9), D)
	box(head, Vector3(0.2, 0.2, 0.05), Vector3(-0.35, 0.25, 1.22), Color(1, 0.9, 0.1), 2.0); box(head, Vector3(0.2, 0.2, 0.05), Vector3(0.35, 0.25, 1.22), Color(1, 0.9, 0.1), 2.0)
	box(head, Vector3(0.2, 0.6, 0.2), Vector3(-0.4, 0.7, 0.1), Color(0.9, 0.85, 0.7)); box(head, Vector3(0.2, 0.6, 0.2), Vector3(0.4, 0.7, 0.1), Color(0.9, 0.85, 0.7))
	var wl := pivot(body, Vector3(-0.9, 0.7, 0.3)); box(wl, Vector3(3.0, 0.12, 2.2), Vector3(-1.5, 0, 0), D)
	var wr := pivot(body, Vector3(0.9, 0.7, 0.3)); box(wr, Vector3(3.0, 0.12, 2.2), Vector3(1.5, 0, 0), D)
	var tail := pivot(body, Vector3(0, 0, -2.0)); box(tail, Vector3(0.7, 0.6, 2.8), Vector3(0, 0, -1.4), C); box(tail, Vector3(0.3, 0.9, 0.5), Vector3(0, 0, -2.9), D)
	var legs := []
	for p in [Vector3(-0.8, -0.8, 1.3), Vector3(0.8, -0.8, 1.3), Vector3(-0.8, -0.8, -1.3), Vector3(0.8, -0.8, -1.3)]:
		var l := pivot(body, p); box(l, Vector3(0.5, 1.2, 0.5), Vector3(0, -0.5, 0), D); legs.append(l)
	return {"root": root, "body": body, "head": head, "neck": neck, "wl": wl, "wr": wr, "tail": tail, "legs": legs, "s": 1.0}

# ---------------------------------------------------------------- efectos
static func label3d(parent: Node3D, text: String, pos: Vector3, col: Color, size: int = 48, px: float = 0.012) -> Label3D:
	var l := Label3D.new(); l.text = text; l.position = pos; l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.font_size = size; l.pixel_size = px
	l.outline_size = 12; l.no_depth_test = true; parent.add_child(l)
	return l

static func popup(parent: Node, text: String, pos: Vector3, col: Color = Color.WHITE):
	var l := Label3D.new(); l.text = text; l.modulate = col; l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 56; l.pixel_size = 0.012; l.outline_size = 14; l.no_depth_test = true
	parent.add_child(l); l.global_position = pos + Vector3(0, 2.4, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.4, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)

static func burst(parent: Node, pos: Vector3, c: Color, n: int = 14, speed: float = 5.0):
	var p := CPUParticles3D.new(); p.one_shot = true; p.emitting = true; p.amount = n; p.lifetime = 0.55
	p.explosiveness = 1.0; p.direction = Vector3.UP; p.spread = 180.0
	p.initial_velocity_min = speed * 0.4; p.initial_velocity_max = speed; p.gravity = Vector3(0, -7, 0)
	var m := SphereMesh.new(); m.radius = 0.09; m.height = 0.18; m.radial_segments = 4; m.rings = 2; p.mesh = m
	p.material_override = mat(c, 2.0); parent.add_child(p); p.global_position = pos
	parent.get_tree().create_timer(1.0).timeout.connect(p.queue_free)

static func ring(parent: Node, pos: Vector3, radius: float, c: Color, dur: float = 0.45):
	var mi := MeshInstance3D.new(); var m := CylinderMesh.new(); m.top_radius = 1.0; m.bottom_radius = 1.0; m.height = 0.12; m.radial_segments = 24
	mi.mesh = m; mi.material_override = mat(c, 2.0, 0.55); parent.add_child(mi); mi.global_position = pos + Vector3(0, 0.1, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), dur)
	tw.parallel().tween_property(mi, "transparency", 1.0, dur)
	tw.tween_callback(mi.queue_free)

# disco rojo de aviso que se llena; devuelve el nodo (se borra solo)
static func telegraph(parent: Node, pos: Vector3, radius: float, dur: float):
	var mi := MeshInstance3D.new(); var m := CylinderMesh.new(); m.top_radius = 1.0; m.bottom_radius = 1.0; m.height = 0.06; m.radial_segments = 24
	mi.mesh = m; mi.material_override = mat(Color(1, 0.15, 0.1), 1.0, 0.35); parent.add_child(mi); mi.global_position = pos + Vector3(0, 0.08, 0)
	mi.scale = Vector3(radius, 1, radius)
	var inner := MeshInstance3D.new(); inner.mesh = m; inner.material_override = mat(Color(1, 0.3, 0.1), 1.5, 0.5); mi.add_child(inner); inner.position.y = 0.02
	inner.scale = Vector3(0.05, 1, 0.05)
	var tw := inner.create_tween(); tw.tween_property(inner, "scale", Vector3(1, 1, 1), dur)
	tw.tween_callback(mi.queue_free)

static func line(parent: Node, a: Vector3, b: Vector3, c: Color, dur: float = 0.25):
	var mi := MeshInstance3D.new(); var m := BoxMesh.new(); var d := a.distance_to(b); m.size = Vector3(0.12, 0.12, d)
	mi.mesh = m; mi.material_override = mat(c, 3.0); parent.add_child(mi)
	mi.global_position = (a + b) / 2.0; mi.look_at(b, Vector3.UP) if (b - a).length() > 0.01 else null
	var tw := mi.create_tween(); tw.tween_property(mi, "scale", Vector3(0.1, 0.1, 1), dur); tw.tween_callback(mi.queue_free)

static func slash(parent: Node3D, c: Color):
	var mi := MeshInstance3D.new(); var m := BoxMesh.new(); m.size = Vector3(2.2, 0.06, 0.5)
	mi.mesh = m; mi.material_override = mat(c, 3.0, 0.8); parent.add_child(mi); mi.position = Vector3(0, 1.2, 1.4)
	mi.rotation.y = -1.0
	var tw := mi.create_tween(); tw.tween_property(mi, "rotation:y", 1.0, 0.18)
	tw.parallel().tween_property(mi, "transparency", 1.0, 0.22); tw.tween_callback(mi.queue_free)
