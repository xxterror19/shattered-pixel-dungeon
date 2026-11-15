extends CanvasLayer
# HUD tactil (joystick + botones), mochila, misiones y dialogos.

var world
var hud: Control
var root: Control            # contenedor de ventanas
var theme_: Theme
var font: Font
var joy_idx := -1
var joy_origin := Vector2.ZERO
var atk_idx := -1
var sel := -1
var win_open := false
var inv_buttons: Array = []
var info_label: Label
var stats_label: Label
var icon_cache := {}

func setup(w):
	world = w
	font = ThemeDB.fallback_font
	hud = Control.new(); hud.set_anchors_preset(Control.PRESET_FULL_RECT); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud); hud.draw.connect(_draw_hud)
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_ = Theme.new(); theme_.default_font_size = 24
	root.theme = theme_
	add_child(root)

func sz() -> Vector2: return get_viewport().get_visible_rect().size

func buttons() -> Array:
	var s := sz()
	var b := [
		{"id": "attack", "c": Vector2(s.x - 120, s.y - 120), "r": 62, "t": "Atacar"},
		{"id": "dash", "c": Vector2(s.x - 262, s.y - 80), "r": 40, "t": "Embestida"},
		{"id": "heal", "c": Vector2(s.x - 232, s.y - 190), "r": 40, "t": "Curar"},
		{"id": "fire", "c": Vector2(s.x - 120, s.y - 250), "r": 40, "t": "Fuego"},
		{"id": "bag", "c": Vector2(s.x - 60, 56), "r": 38, "t": "Mochila"},
		{"id": "quests", "c": Vector2(s.x - 150, 56), "r": 38, "t": "Misiones"},
	]
	if Game.has_mount: b.append({"id": "mount", "c": Vector2(s.x - 350, s.y - 120), "r": 36, "t": "Montar"})
	if near_npc() != null: b.append({"id": "talk", "c": Vector2(s.x - 360, s.y - 230), "r": 46, "t": "Hablar"})
	return b

func near_npc():
	for n in world.npcs:
		if n.position.distance_to(world.player.position) < 30: return n
	return null

func _draw_hud():
	var s := sz()
	# barras
	hud.draw_rect(Rect2(16, 16, 320, 26), Color(0, 0, 0, 0.6))
	hud.draw_rect(Rect2(18, 18, 316 * clamp(Game.hp / Game.max_hp(), 0, 1), 22), Color(0.85, 0.2, 0.2))
	hud.draw_string(font, Vector2(24, 36), "Vida %d/%d" % [Game.hp, Game.max_hp()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	hud.draw_rect(Rect2(16, 48, 320, 18), Color(0, 0, 0, 0.6))
	hud.draw_rect(Rect2(18, 50, 316 * clamp(float(Game.xp) / Game.xp_needed(), 0, 1), 14), Color(0.3, 0.6, 1.0))
	hud.draw_string(font, Vector2(24, 63), "Nivel %d" % Game.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	hud.draw_string(font, Vector2(16, 96), "Oro: %d" % Game.gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.85, 0.2))
	if joy_idx != -1:
		hud.draw_circle(joy_origin, 60, Color(1, 1, 1, 0.15))
		hud.draw_circle(joy_origin + joy_vec() * 60, 28, Color(1, 1, 1, 0.45))
	for b in buttons():
		var col := Color(0.15, 0.15, 0.2, 0.65)
		var label: String = b["t"]
		var extra := ""
		if Game.SKILLS.has(b["id"]):
			var sk = Game.SKILLS[b["id"]]
			if Game.level < int(sk["level"]): extra = "Nv%d" % sk["level"]; col = Color(0.3, 0.1, 0.1, 0.7)
			elif world.player.cds[b["id"]] > 0.0: extra = "%.0f" % world.player.cds[b["id"]]; col = Color(0.1, 0.1, 0.1, 0.85)
		elif b["id"] == "mount" and Game.mounted: col = Color(0.2, 0.5, 0.2, 0.8)
		hud.draw_circle(b["c"], b["r"], col)
		hud.draw_arc(b["c"], b["r"], 0, TAU, 32, Color(1, 1, 1, 0.7), 2.0)
		var fs := 22 if b["id"] == "attack" else 15
		hud.draw_string(font, b["c"] + Vector2(-b["r"], 6), extra if extra != "" else label, HORIZONTAL_ALIGNMENT_CENTER, b["r"] * 2, fs)

func joy_vec() -> Vector2:
	return joy_vec_v

var joy_vec_v := Vector2.ZERO

func _hit(p: Vector2) -> Variant:
	for b in buttons():
		if p.distance_to(b["c"]) <= b["r"] + 8: return b
	return null

func _input(e):
	if win_open: return
	if e is InputEventScreenTouch:
		if e.pressed:
			var b = _hit(e.position)
			if b != null:
				_press(b["id"])
				if b["id"] == "attack": atk_idx = e.index
			elif e.position.x < sz().x * 0.5 and joy_idx == -1:
				joy_idx = e.index; joy_origin = e.position; joy_vec_v = Vector2.ZERO
		else:
			if e.index == joy_idx: joy_idx = -1; joy_vec_v = Vector2.ZERO
			if e.index == atk_idx: atk_idx = -1
	elif e is InputEventScreenDrag and e.index == joy_idx:
		joy_vec_v = ((e.position - joy_origin) / 60.0).limit_length(1.0)

func _press(id: String):
	match id:
		"attack": world.player.attack()
		"dash", "heal", "fire": world.player.use_skill(id)
		"bag": open_inventory()
		"quests": open_quests()
		"mount": Game.mounted = not Game.mounted
		"talk":
			var n = near_npc()
			if n != null: open_dialog(n.npc_name)

func _process(_dt):
	hud.queue_redraw()
	if win_open:
		world.player.move_vec = Vector2.ZERO; return
	var v := joy_vec_v
	# teclado para pruebas en PC
	var kv := Vector2(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)), int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W)))
	if kv != Vector2.ZERO: v = kv
	world.player.move_vec = v
	if atk_idx != -1 or Input.is_key_pressed(KEY_SPACE): world.player.attack()

# ---------------- ventanas ----------------
func icon_tex(i: int) -> Texture2D:
	if not icon_cache.has(i):
		var at := AtlasTexture.new(); at.atlas = world.tx("icons"); at.region = Rect2(i * 16, 0, 16, 16)
		icon_cache[i] = at
	return icon_cache[i]

func new_window(title: String) -> VBoxContainer:
	for c in root.get_children(): c.queue_free()
	win_open = true; joy_idx = -1; atk_idx = -1; joy_vec_v = Vector2.ZERO
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.55); dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(cc)
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.86, 0.76, 0.55); sb.border_color = Color(0.45, 0.3, 0.15)
	sb.set_border_width_all(5); sb.set_content_margin_all(14)
	pc.add_theme_stylebox_override("panel", sb); cc.add_child(pc)
	var vb := VBoxContainer.new(); pc.add_child(vb)
	var top := HBoxContainer.new(); vb.add_child(top)
	var t := Label.new(); t.text = title; t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05)); top.add_child(t)
	var x := Button.new(); x.text = " X "; x.pressed.connect(close_window); top.add_child(x)
	return vb

func close_window():
	for c in root.get_children(): c.queue_free()
	win_open = false

func dark(l: Label) -> Label:
	l.add_theme_color_override("font_color", Color(0.2, 0.12, 0.05)); return l

func open_inventory():
	var vb := new_window("Mochila")
	var hb := HBoxContainer.new(); vb.add_child(hb)
	var left := VBoxContainer.new(); left.custom_minimum_size = Vector2(320, 0); hb.add_child(left)
	stats_label = dark(Label.new()); left.add_child(stats_label)
	var right := VBoxContainer.new(); hb.add_child(right)
	var grid := GridContainer.new(); grid.columns = 7; right.add_child(grid)
	inv_buttons.clear()
	for i in Game.INV_SIZE:
		var b := Button.new(); b.custom_minimum_size = Vector2(76, 76); b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER; b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		b.pressed.connect(_select.bind(i)); grid.add_child(b); inv_buttons.append(b)
	info_label = dark(Label.new()); info_label.custom_minimum_size = Vector2(0, 36); right.add_child(info_label)
	var row := HBoxContainer.new(); right.add_child(row)
	var use := Button.new(); use.text = "Usar / Equipar"; use.pressed.connect(_use_selected); row.add_child(use)
	var drop := Button.new(); drop.text = "Tirar"; drop.pressed.connect(_drop_selected); row.add_child(drop)
	sel = -1; _refresh_inv()

func _refresh_inv():
	for i in Game.INV_SIZE:
		var id: String = Game.inventory[i]
		var b: Button = inv_buttons[i]
		b.icon = icon_tex(int(Game.ITEMS[id]["icon"])) if id != "" else null
		b.text = "E" if id != "" and (id == Game.weapon or id == Game.armor) else ""
		b.modulate = Color(1, 1, 0.5) if i == sel else Color.WHITE
	stats_label.text = "Nivel %d\nVida %d/%d\nAtaque %d\nDefensa %d\nOro %d\nArma: %s\nArmadura: %s\nEnemigos: %d" % [
		Game.level, Game.hp, Game.max_hp(), Game.attack_power(), Game.defense(), Game.gold,
		Game.ITEMS[Game.weapon]["name"] if Game.weapon != "" else "-",
		Game.ITEMS[Game.armor]["name"] if Game.armor != "" else "-", Game.kills]
	if sel >= 0 and Game.inventory[sel] != "":
		var it = Game.ITEMS[Game.inventory[sel]]
		info_label.text = "%s - %s" % [it["name"], it["desc"]]
	else: info_label.text = ""

func _select(i: int):
	sel = i; _refresh_inv()

func _use_selected():
	if sel < 0: return
	var id: String = Game.inventory[sel]
	if id == "": return
	var it = Game.ITEMS[id]
	match it["type"]:
		"weapon": Game.weapon = id
		"armor": Game.armor = id
		"potion":
			Game.hp = min(Game.max_hp(), Game.hp + float(it["heal"])); Game.inventory[sel] = ""
	_refresh_inv()

func _drop_selected():
	if sel < 0 or Game.inventory[sel] == "": return
	var id: String = Game.inventory[sel]
	if id == Game.weapon: Game.weapon = ""
	if id == Game.armor: Game.armor = ""
	Game.inventory[sel] = ""
	_refresh_inv()

func open_quests():
	var vb := new_window("Misiones")
	var any := false
	for id in Game.quests:
		any = true
		var q = Game.QUESTS[id]
		var l := dark(Label.new())
		if Game.quests[id]["state"] == "done": l.text = "[Hecha] %s" % q["title"]
		else: l.text = "%s\n   %s (%d/%d)" % [q["title"], q["text"], Game.quest_progress(id), q["need"]]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD; l.custom_minimum_size = Vector2(620, 0)
		vb.add_child(l)
	if not any:
		var l := dark(Label.new()); l.text = "Habla con los aldeanos del pueblo (los que tienen !)"; vb.add_child(l)

const SHOP := {
	"Bayu": ["espada_hierro", "armadura_hierro"],
	"Mara": ["pocion", "carne", "armadura_cuero"],
	"Toro": ["hacha", "baston", "pocion"],
}

func open_dialog(npc: String):
	var vb := new_window(npc)
	var l := dark(Label.new()); l.autowrap_mode = TextServer.AUTOWRAP_WORD; l.custom_minimum_size = Vector2(620, 0)
	vb.add_child(l)
	var text := "Buen dia, viajero."
	for id in Game.QUESTS:
		var q = Game.QUESTS[id]
		if q["giver"] != npc: continue
		if Game.quest_ready(id):
			text = "¡Lo lograste! (%s)" % q["title"]
			_btn(vb, "Entregar mision", _turn_in.bind(id, npc))
		elif Game.quests.has(id) and Game.quests[id]["state"] == "active":
			text = "%s (%d/%d)" % [q["text"], Game.quest_progress(id), q["need"]]
		elif not Game.quests.has(id) and (not q.has("after") or (Game.quests.has(q["after"]) and Game.quests[q["after"]]["state"] == "done")):
			text = q["text"]
			_btn(vb, "Aceptar: " + q["title"], _accept.bind(id, npc))
	l.text = text
	for id in SHOP.get(npc, []):
		var it = Game.ITEMS[id]
		_btn(vb, "Comprar %s (%d oro)" % [it["name"], it["price"]], _buy.bind(id, npc))

func _btn(vb: Control, t: String, cb: Callable):
	var b := Button.new(); b.text = t; b.pressed.connect(cb); vb.add_child(b)

func _accept(id: String, npc: String):
	Game.quests[id] = {"state": "active", "progress": 0}
	open_dialog(npc)

func _turn_in(id: String, npc: String):
	var q = Game.QUESTS[id]
	if q["kind"] == "collect": Game.remove_items(q["target"], int(q["need"]))
	Game.quests[id]["state"] = "done"
	Game.gold += int(q["gold"]); Game.gain_xp(int(q["xp"]))
	if q.has("item"): Game.add_item(q["item"])
	if q.has("mount"): Game.has_mount = true
	world.popup("Mision completada", world.player.position, Color(0.5, 1, 0.5))
	close_window()

func _buy(id: String, npc: String):
	var it = Game.ITEMS[id]
	if Game.gold >= int(it["price"]) and Game.add_item(id):
		Game.gold -= int(it["price"])
	open_dialog(npc)
