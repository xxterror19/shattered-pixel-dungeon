extends Node2D

var npc_name := ""
var kind := "npc"
var world
var mark: Label

func setup(w, n: String):
	world = w; npc_name = n
	var s := Sprite2D.new(); s.texture = w.tx("npc_" + n.to_lower()); add_child(s)
	var l := Label.new(); l.text = n; l.scale = Vector2(0.3, 0.3)
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_outline_color", Color.BLACK); l.add_theme_constant_override("outline_size", 8)
	l.position = Vector2(-9, -22); add_child(l)
	mark = Label.new(); mark.scale = Vector2(0.5, 0.5)
	mark.add_theme_font_size_override("font_size", 30)
	mark.add_theme_color_override("font_outline_color", Color.BLACK); mark.add_theme_constant_override("outline_size", 8)
	mark.position = Vector2(-3, -34); add_child(mark)

func _process(_dt):
	var m := ""
	for id in Game.QUESTS:
		var q = Game.QUESTS[id]
		if q["giver"] != npc_name: continue
		if Game.quest_ready(id): m = "?"
		elif not Game.quests.has(id) and (not q.has("after") or (Game.quests.has(q["after"]) and Game.quests[q["after"]]["state"] == "done")) and m == "":
			m = "!"
	mark.text = m
	mark.add_theme_color_override("font_color", Color(1, 0.9, 0.2) if m == "!" else Color(0.5, 1, 0.5))
