extends Node3D

var npc_name := ""
var world
var mark: Label3D
var m: Dictionary
var t := 0.0

func setup(w, n: String, col: Color):
	world = w; npc_name = n
	m = Gfx.humanoid(Color(0.94, 0.76, 0.6), col, col.darkened(0.4), Color(0.2 + col.r * 0.5, 0.15, 0.1), 1.0)
	add_child(m["root"])
	if n == "Elda": Gfx.make_weapon(m["hand"], "staff", Color(0.5, 0.7, 1.0))
	Gfx.label3d(self, n, Vector3(0, 2.5, 0), Color.WHITE, 40)
	mark = Gfx.label3d(self, "", Vector3(0, 3.2, 0), Color(1, 0.9, 0.2), 90)

func _process(dt):
	t += dt
	var d: Vector3 = world.player.position - position
	m["root"].rotation.y = lerp_angle(m["root"].rotation.y, atan2(d.x, d.z) if d.length() < 8.0 else 0.0, min(1.0, dt * 4.0))
	m["body"].position.y = 0.95 + sin(t * 2.0) * 0.015
	var s := ""
	for id in Game.QUESTS:
		if Game.QUESTS[id]["giver"] != npc_name: continue
		if Game.quest_ready(id): s = "?"
		elif Game.quest_available(id) and s == "": s = "!"
	mark.text = s
	mark.modulate = Color(1, 0.9, 0.2) if s == "!" else Color(0.5, 1, 0.5)
	mark.position.y = 3.2 + sin(t * 4.0) * 0.15
