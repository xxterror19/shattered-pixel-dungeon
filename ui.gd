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
		{"id": "bag", "c": Vector2(s.x - 60, 56), "r": 38, "t": "Menu"},
		{"id": "quests", "c": Vector2(s.x - 150, 56), "r": 38, "t": "Misiones"},
		{"id": "map", "c": Vector2(s.x - 240, 56), "r": 38, "t": "Mapa"},
	]
	if Game.has_mount: b.append({"id": "mount", "c": Vector2(s.x - 350, s.y - 120), "r": 36, "t": "Montar"})
	var na = near_act()
	if na != null: b.append({"id": "talk", "c": Vector2(s.x - 360, s.y - 230), "r": 46, "t": "Hablar" if na.kind == "npc" else na.verb()})
	return b

func near_act():
	var best = null; var bd := 30.0
	for n in world.acts:
		if n.kind == "node" and n.depleted: continue
		var d: float = n.position.distance_to(world.player.position)
		if d < bd: bd = d; best = n
	return best

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
	var pl = world.player
	if pl.gnode != null and is_instance_valid(pl.gnode):
		var f: float = clamp(pl.gt / float(Game.NODES[pl.gnode.res]["time"]), 0, 1)
		hud.draw_rect(Rect2(s.x / 2 - 110, s.y - 70, 220, 22), Color(0, 0, 0, 0.7))
		hud.draw_rect(Rect2(s.x / 2 - 108, s.y - 68, 216 * f, 18), Color(0.9, 0.7, 0.2))
		hud.draw_string(font, Vector2(s.x / 2 - 108, s.y - 74), pl.gnode.verb() + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	if Game.free_points() > 0:
		hud.draw_string(font, Vector2(16, 122), "¡%d puntos por gastar (Menu)!" % Game.free_points(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 1, 0.5))
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
		"bag": open_menu("mochila")
		"quests": open_menu("misiones")
		"map": open_menu("mapa")
		"mount": Game.mounted = not Game.mounted
		"talk":
			var n = near_act()
			if n == null: return
			if n.kind == "npc": open_dialog(n.npc_name)
			elif n.kind == "node": world.player.start_gather(n)
			elif n.res == "banco": open_bank()
			else: open_station(n.res)

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

func tab_bar(vb: VBoxContainer, cur: String):
	var hb := HBoxContainer.new(); vb.add_child(hb)
	for t in [["mochila", "Mochila"], ["equipo", "Equipo"], ["habil", "Habilidades"], ["misiones", "Misiones"], ["mapa", "Mapa"]]:
		var b := Button.new(); b.text = t[1]; b.disabled = (t[0] == cur); b.pressed.connect(open_menu.bind(t[0])); hb.add_child(b)

func open_menu(tab: String):
	var vb := new_window("Menu")
	tab_bar(vb, tab)
	match tab:
		"mochila": _tab_bag(vb)
		"equipo": _tab_equip(vb)
		"habil": _tab_skills(vb)
		"misiones": _tab_quests(vb)
		"mapa": _tab_map(vb)

func slot_btn(id: String) -> Button:
	var b := Button.new(); b.custom_minimum_size = Vector2(76, 76); b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER; b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if id != "": b.icon = icon_tex(int(Game.ITEMS[id]["icon"]))
	return b

# ---- mochila ----
func _tab_bag(vb: VBoxContainer):
	var grid := GridContainer.new(); grid.columns = 7; vb.add_child(grid)
	inv_buttons.clear()
	for i in Game.INV_SIZE:
		var b := slot_btn(""); b.pressed.connect(_select.bind(i)); grid.add_child(b); inv_buttons.append(b)
	info_label = dark(Label.new()); info_label.custom_minimum_size = Vector2(0, 36); vb.add_child(info_label)
	var row := HBoxContainer.new(); vb.add_child(row)
	_btn(row, "Usar / Equipar", _use_selected); _btn(row, "Tirar", _drop_selected)
	sel = -1; _refresh_inv()

func _refresh_inv():
	for i in Game.INV_SIZE:
		var id: String = Game.inventory[i]
		var b: Button = inv_buttons[i]
		b.icon = icon_tex(int(Game.ITEMS[id]["icon"])) if id != "" else null
		b.modulate = Color(1, 1, 0.5) if i == sel else Color.WHITE
	if sel >= 0 and Game.inventory[sel] != "":
		var it = Game.ITEMS[Game.inventory[sel]]
		info_label.text = "%s - %s (vale %d)" % [it["name"], it["desc"], it["price"]]
	else: info_label.text = "Toca un objeto"

func _select(i: int):
	sel = i; _refresh_inv()

func _use_selected():
	if sel < 0: return
	var id: String = Game.inventory[sel]
	if id == "": return
	var it = Game.ITEMS[id]
	match it["type"]:
		"equip": Game.equip_item(sel)
		"potion":
			Game.hp = min(Game.max_hp(), Game.hp + float(it["heal"])); Game.inventory[sel] = ""
	_refresh_inv()

func _drop_selected():
	if sel < 0: return
	Game.inventory[sel] = ""; _refresh_inv()

# ---- equipo y estadisticas ----
func _tab_equip(vb: VBoxContainer):
	var hb := HBoxContainer.new(); vb.add_child(hb)
	var left := VBoxContainer.new(); hb.add_child(left)
	for s in Game.SLOTS:
		var row := HBoxContainer.new(); left.add_child(row)
		var b := slot_btn(Game.equip[s]); b.pressed.connect(func(): Game.unequip(s); open_menu("equipo")); row.add_child(b)
		var l := dark(Label.new()); l.custom_minimum_size = Vector2(250, 0)
		l.text = "%s: %s" % [Game.SLOT_NAMES[s], Game.ITEMS[Game.equip[s]]["name"] if Game.equip[s] != "" else "-"]
		row.add_child(l)
	var right := VBoxContainer.new(); right.custom_minimum_size = Vector2(300, 0); hb.add_child(right)
	var st := dark(Label.new())
	st.text = "Nivel %d\nVida %d/%d\nAtaque %d\nDefensa %d\nOro %d\nEnemigos: %d\n\nPuntos libres: %d" % [Game.level, Game.hp, Game.max_hp(), Game.attack_power(), Game.defense(), Game.gold, Game.kills, Game.free_points()]
	right.add_child(st)
	for k in [["hp", "+ Vida (+10)"], ["def", "+ Defensa (+1)"], ["atk", "+ Ataque (+2)"]]:
		var b := Button.new(); b.text = "%s [%d]" % [k[1], Game.stat_pts[k[0]]]; b.disabled = Game.free_points() <= 0
		b.pressed.connect(func(): Game.stat_pts[k[0]] += 1; open_menu("equipo")); right.add_child(b)
	var h := dark(Label.new()); h.text = "Toca una pieza para quitarla"; vb.add_child(h)

# ---- habilidades ----
func _tab_skills(vb: VBoxContainer):
	for s in Game.SKILL_IDS:
		var lv := Game.skill_level(s)
		var a: int = int(Game.skill_xp[s]) - Game.skill_floor(lv); var n: int = Game.skill_floor(lv + 1) - Game.skill_floor(lv)
		var row := HBoxContainer.new(); vb.add_child(row)
		var l := dark(Label.new()); l.custom_minimum_size = Vector2(300, 0); l.text = "%s  Nv %d" % [Game.SKILL_NAMES[s], lv]; row.add_child(l)
		var pb := ProgressBar.new(); pb.custom_minimum_size = Vector2(300, 28); pb.max_value = n; pb.value = a; pb.show_percentage = false; row.add_child(pb)
	var h := dark(Label.new()); h.text = "Mina menas, tala arboles, pesca en el agua.\nFunde en la fragua, forja en el yunque, cocina en la fogata."; vb.add_child(h)

# ---- misiones ----
func _tab_quests(vb: VBoxContainer):
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
		var l := dark(Label.new()); l.text = "Habla con los aldeanos del pueblo."; vb.add_child(l)

# ---- mapa ----
func _tab_map(vb: VBoxContainer):
	var sc := 3
	var img: Image = world.terrain_img.duplicate()
	img.resize(world.W * sc, world.H * sc, Image.INTERPOLATE_NEAREST)
	var mark := func(cell: Vector2, c: Color, r: int):
		var cx := int(cell.x) * sc; var cy := int(cell.y) * sc
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var x := cx + dx; var y := cy + dy
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height(): img.set_pixel(x, y, c)
	for a in world.acts:
		var cell := Vector2(floor(a.position.x / world.T), floor(a.position.y / world.T))
		if a.kind == "npc": mark.call(cell, Color(1, 0.9, 0.1), 3)
		elif a.kind == "station": mark.call(cell, Color(1, 0.5, 0.1), 3)
		elif a.res == "arbol": continue
		elif a.res == "pez" or a.res == "trucha": mark.call(cell, Color(0.7, 1, 1), 1)
		else: mark.call(cell, Color(0.1, 0.1, 0.1), 2)
	mark.call(world.player.position / world.T, Color(1, 0, 0), 5)
	var tr := TextureRect.new(); tr.texture = ImageTexture.create_from_image(img)
	tr.custom_minimum_size = Vector2(440, 440); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; vb.add_child(tr)
	var h := dark(Label.new()); h.text = "Rojo: tu. Amarillo: aldeanos. Naranja: fragua/yunque/fogata/banco. Negro: minas. Celeste: pesca."; vb.add_child(h)

# ---------------- estaciones ----------------
func open_station(st: String):
	var R = Game.RECIPES[st]
	var vb := new_window("%s  (%s Nv %d)" % [R["title"], Game.SKILL_NAMES[R["skill"]], Game.skill_level(R["skill"])])
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(700, 420); vb.add_child(sc)
	var lst := VBoxContainer.new(); sc.add_child(lst)
	for r in R["list"]:
		var need := ""; var ok: bool = Game.skill_level(R["skill"]) >= int(r["lvl"])
		for k in r["need"]:
			need += " %s %d/%d" % [Game.ITEMS[k]["name"], min(Game.count_item(k), int(r["need"][k])), r["need"][k]]
			if Game.count_item(k) < int(r["need"][k]): ok = false
		var b := Button.new(); b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.disabled = not ok
		b.text = "%s (Nv%d) <-%s" % [Game.ITEMS[r["out"]]["name"], r["lvl"], need]
		b.pressed.connect(_craft.bind(st, r)); lst.add_child(b)

func _craft(st: String, r: Dictionary):
	var R = Game.RECIPES[st]
	for k in r["need"]: Game.remove_items(k, int(r["need"][k]))
	if not Game.add_item(r["out"]): Game.add_item(r["need"].keys()[0]); return
	if Game.add_skill_xp(R["skill"], int(r["xp"])): world.popup("¡%s nivel %d!" % [Game.SKILL_NAMES[R["skill"]], Game.skill_level(R["skill"])], world.player.position, Color(0.5, 1, 1))
	open_station(st)

# ---------------- banco ----------------
func open_bank():
	var vb := new_window("Banco (toca para mover)")
	var h := dark(Label.new()); h.text = "Banco"; vb.add_child(h)
	var g1 := GridContainer.new(); g1.columns = 10; vb.add_child(g1)
	for i in Game.BANK_SIZE:
		var b := slot_btn(Game.bank[i]); b.custom_minimum_size = Vector2(56, 56)
		b.pressed.connect(func():
			var id: String = Game.bank[i]
			if id != "" and Game.add_item(id): Game.bank[i] = ""
			open_bank()); g1.add_child(b)
	var h2 := dark(Label.new()); h2.text = "Mochila"; vb.add_child(h2)
	var g2 := GridContainer.new(); g2.columns = 10; vb.add_child(g2)
	for i in Game.INV_SIZE:
		var b := slot_btn(Game.inventory[i]); b.custom_minimum_size = Vector2(56, 56)
		b.pressed.connect(func():
			var id: String = Game.inventory[i]
			var j: int = Game.bank.find("")
			if id != "" and j != -1: Game.bank[j] = id; Game.inventory[i] = ""
			open_bank()); g2.add_child(b)

# ---------------- dialogo y comercio ----------------
const SHOP := {
	"Bayu": ["espada_cobre", "casco_cobre", "peto_cobre", "pocion"],
	"Mara": ["pocion", "carne", "pez_asado"],
	"Toro": ["grebas_cobre", "botas_cobre", "espada_hierro"],
	"Gael": ["pocion", "anillo_vida", "anillo_fuerza", "peto_hierro", "casco_hierro", "grebas_hierro", "botas_hierro"],
}

func open_dialog(npc: String):
	var vb := new_window(npc)
	var l := dark(Label.new()); l.autowrap_mode = TextServer.AUTOWRAP_WORD; l.custom_minimum_size = Vector2(620, 0)
	vb.add_child(l)
	var text := "Buen dia, viajero." if npc != "Gael" else "Compro y vendo de todo. Los minerales y el pescado se pagan bien."
	for id in Game.QUESTS:
		var q = Game.QUESTS[id]
		if q["giver"] != npc: continue
		if Game.quest_ready(id):
			text = "¡Lo lograste! (%s)" % q["title"]
			_btn(vb, "Entregar mision", _turn_in.bind(id, npc))
		elif Game.quests.has(id) and Game.quests[id]["state"] == "active":
			text = "%s (%d/%d)" % [q["text"], Game.quest_progress(id), q["need"]]
		elif Game.quest_available(id):
			text = q["text"]
			_btn(vb, "Aceptar: " + q["title"], _accept.bind(id, npc))
	l.text = text + "\nOro: %d" % Game.gold
	for id in SHOP.get(npc, []):
		var it = Game.ITEMS[id]
		_btn(vb, "Comprar %s (%d oro)" % [it["name"], it["price"]], _buy.bind(id, npc))
	_btn(vb, "Vender objetos...", open_sell.bind(npc))

func open_sell(npc: String):
	var vb := new_window("Vender a " + npc)
	var h := dark(Label.new()); h.text = "Oro: %d  (toca para vender a mitad de precio)" % Game.gold; vb.add_child(h)
	var g := GridContainer.new(); g.columns = 7; vb.add_child(g)
	for i in Game.INV_SIZE:
		var b := slot_btn(Game.inventory[i])
		b.pressed.connect(func():
			var id: String = Game.inventory[i]
			if id != "": Game.gold += int(Game.ITEMS[id]["price"]) / 2; Game.inventory[i] = ""
			open_sell(npc)); g.add_child(b)
	_btn(vb, "Volver", open_dialog.bind(npc))

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
