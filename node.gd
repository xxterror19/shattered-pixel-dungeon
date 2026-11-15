extends Node2D
# Objeto interactivo: recurso (mena, arbol, pesca) o estacion (fragua, yunque, fogata, banco).

var kind := "node"        # "node" o "station"
var res := ""
var depleted := false
var respawn_t := 0.0
var sprite: Sprite2D
var world
var label: Label

func setup(w, r: String, is_station: bool):
	world = w; res = r; kind = "station" if is_station else "node"
	sprite = Sprite2D.new(); add_child(sprite); _show()
	if kind == "station":
		label = Label.new(); label.text = r.capitalize(); label.scale = Vector2(0.28, 0.28)
		label.add_theme_font_size_override("font_size", 26); label.add_theme_color_override("font_outline_color", Color.BLACK); label.add_theme_constant_override("outline_size", 8)
		label.position = Vector2(-10, -20); add_child(label)

func _show():
	if kind == "station": sprite.texture = world.tx("station_" + res); return
	if res == "arbol":
		sprite.texture = world.tx("node_tocon" if depleted else "tree"); sprite.position = Vector2.ZERO if depleted else Vector2(0, -8)
	elif res == "pez" or res == "trucha": sprite.texture = world.tx("node_pesca"); sprite.modulate = Color(1, 0.8, 0.6) if res == "trucha" else Color.WHITE
	else: sprite.texture = world.tx("node_vacio" if depleted else "node_" + res)

func verb() -> String:
	if kind == "station": return "Banco" if res == "banco" else "Usar"
	return Game.NODES[res]["verb"]

func deplete():
	var r: float = Game.NODES[res]["respawn"]
	if r <= 0.0: return
	depleted = true; respawn_t = r; _show()

func _process(dt):
	if depleted:
		respawn_t -= dt
		if respawn_t <= 0.0: depleted = false; _show()
