extends Node
# Estado global: estadisticas, equipo, habilidades, inventario, banco, misiones y guardado.

const INV_SIZE := 35
const BANK_SIZE := 60
const SAVE_PATH := "user://save2d.json"
const SLOTS := ["weapon", "helmet", "chest", "legs", "boots", "ring"]
const SLOT_NAMES := {"weapon": "Arma", "helmet": "Casco", "chest": "Peto", "legs": "Grebas", "boots": "Botas", "ring": "Anillo"}
const TIERS := ["cobre", "hierro", "acero", "lunar"]
const TIER_NAMES := ["cobre", "hierro", "acero", "lunar"]
const TIER_ATK := [8, 16, 28, 45]
const TIER_DEF := {"helmet": [2, 4, 7, 11], "chest": [4, 8, 14, 22], "legs": [3, 6, 10, 16], "boots": [1, 3, 5, 8]}
const TIER_LVL := [1, 15, 30, 45]
const TIER_PRICE := [30, 90, 240, 600]
const BARS_NEEDED := {"weapon": 3, "helmet": 2, "chest": 5, "legs": 4, "boots": 2}
const SKILL_IDS := ["mineria", "tala", "pesca", "cocina", "herreria"]
const SKILL_NAMES := {"mineria": "Mineria", "tala": "Tala", "pesca": "Pesca", "cocina": "Cocina", "herreria": "Herreria"}

# recursos del mundo: habilidad, nivel, xp, objeto, segundos, reaparicion
const NODES := {
	"cobre": {"skill": "mineria", "lvl": 1, "xp": 12, "item": "mena_cobre", "time": 2.0, "respawn": 15.0, "verb": "Minar"},
	"carbon": {"skill": "mineria", "lvl": 8, "xp": 22, "item": "carbon", "time": 2.5, "respawn": 18.0, "verb": "Minar"},
	"hierro": {"skill": "mineria", "lvl": 15, "xp": 40, "item": "mena_hierro", "time": 3.0, "respawn": 20.0, "verb": "Minar"},
	"lunar": {"skill": "mineria", "lvl": 40, "xp": 100, "item": "mena_lunar", "time": 4.0, "respawn": 30.0, "verb": "Minar"},
	"arbol": {"skill": "tala", "lvl": 1, "xp": 10, "item": "madera", "time": 2.0, "respawn": 12.0, "verb": "Talar"},
	"pez": {"skill": "pesca", "lvl": 1, "xp": 10, "item": "pez", "time": 2.5, "respawn": 0.0, "verb": "Pescar"},
	"trucha": {"skill": "pesca", "lvl": 15, "xp": 36, "item": "trucha", "time": 3.0, "respawn": 0.0, "verb": "Pescar"},
}

var ITEMS := {}
var RECIPES := {}   # estacion -> lista de recetas

const QUESTS := {
	"mina": {"giver": "Bayu", "title": "Limpiar la mina", "text": "Los esqueletos invaden las rocas. Derrota a 5.", "kind": "kill", "target": "skeleton", "need": 5, "gold": 60, "xp": 80, "item": "espada_hierro"},
	"cobre": {"giver": "Bayu", "title": "Primeras menas", "text": "Mina 6 menas de cobre (Mineria) y traelas.", "kind": "collect", "target": "mena_cobre", "need": 6, "gold": 40, "xp": 60, "item": "casco_cobre"},
	"limos": {"giver": "Bayu", "title": "Plaga de limos", "text": "Elimina 8 limos del bosque.", "kind": "kill", "target": "slime", "need": 8, "gold": 80, "xp": 100, "item": "peto_cobre", "after": "mina"},
	"huesos": {"giver": "Mara", "title": "Huesos para la curandera", "text": "Necesito 3 huesos para mis remedios.", "kind": "collect", "target": "hueso", "need": 3, "gold": 30, "xp": 50, "item": "pocion"},
	"pesca": {"giver": "Mara", "title": "Cena de pescado", "text": "Pesca 5 peces en la orilla del lago.", "kind": "collect", "target": "pez", "need": 5, "gold": 50, "xp": 70, "item": "anillo_vida"},
	"buitres": {"giver": "Toro", "title": "Caza de buitres", "text": "Los buitres asustan al ganado. Derrota a 4 y te dare un caballo.", "kind": "kill", "target": "vulture", "need": 4, "gold": 100, "xp": 150, "mount": true},
	"lena": {"giver": "Toro", "title": "Lena para el invierno", "text": "Tala arboles y traeme 10 de madera.", "kind": "collect", "target": "madera", "need": 10, "gold": 60, "xp": 80, "item": "botas_cobre"},
}

const SKILLS := {
	"dash": {"name": "Embestida", "level": 1, "cd": 4.0},
	"heal": {"name": "Curar", "level": 3, "cd": 12.0},
	"fire": {"name": "Bola de fuego", "level": 5, "cd": 6.0},
}

var level := 1
var xp := 0
var hp := 100.0
var gold := 0
var inventory: Array = []
var bank: Array = []
var equip := {"weapon": "espada_madera", "helmet": "", "chest": "", "legs": "", "boots": "", "ring": ""}
var skill_xp := {"mineria": 0, "tala": 0, "pesca": 0, "cocina": 0, "herreria": 0}
var stat_pts := {"hp": 0, "def": 0, "atk": 0}
var quests := {}
var has_mount := false
var mounted := false
var pos := Vector2.ZERO
var kills := 0

func _init():
	_build_items()

func _ready():
	inventory.resize(INV_SIZE); inventory.fill("")
	bank.resize(BANK_SIZE); bank.fill("")

func _it(id: String, name: String, type: String, icon: String, price: int, desc: String, extra: Dictionary = {}):
	var d := {"name": name, "type": type, "icon": IconIdx.IDX[icon], "price": price, "desc": desc}
	d.merge(extra); ITEMS[id] = d

func _build_items():
	_it("espada_madera", "Espada de madera", "equip", "sword_wood", 10, "Arma. Ataque +4", {"slot": "weapon", "atk": 4})
	for i in 4:
		var t: String = TIERS[i]; var tn: String = TIER_NAMES[i]; var pr: int = TIER_PRICE[i]
		_it("espada_" + t, "Espada de " + tn, "equip", "sword_" + t, pr * 2, "Arma. Ataque +%d" % TIER_ATK[i], {"slot": "weapon", "atk": TIER_ATK[i]})
		_it("casco_" + t, "Casco de " + tn, "equip", "helmet_" + t, pr, "Casco. Defensa +%d" % TIER_DEF["helmet"][i], {"slot": "helmet", "def": TIER_DEF["helmet"][i]})
		_it("peto_" + t, "Peto de " + tn, "equip", "chest_" + t, pr * 2, "Peto. Defensa +%d" % TIER_DEF["chest"][i], {"slot": "chest", "def": TIER_DEF["chest"][i]})
		_it("grebas_" + t, "Grebas de " + tn, "equip", "legs_" + t, int(pr * 1.5), "Grebas. Defensa +%d" % TIER_DEF["legs"][i], {"slot": "legs", "def": TIER_DEF["legs"][i]})
		_it("botas_" + t, "Botas de " + tn, "equip", "boots_" + t, pr, "Botas. Defensa +%d" % TIER_DEF["boots"][i], {"slot": "boots", "def": TIER_DEF["boots"][i]})
		_it("bar_" + t, "Barra de " + tn, "misc", "bar_" + t, pr / 3, "Material de herreria")
	_it("anillo_vida", "Anillo de vida", "equip", "ring_vida", 300, "Anillo. Vida maxima +25", {"slot": "ring", "hp": 25})
	_it("anillo_fuerza", "Anillo de fuerza", "equip", "ring_fuerza", 300, "Anillo. Ataque +4", {"slot": "ring", "atk": 4})
	_it("mena_cobre", "Mena de cobre", "misc", "ore_cobre", 3, "Se funde en la fragua")
	_it("carbon", "Carbon", "misc", "ore_carbon", 4, "Combustible para fundir")
	_it("mena_hierro", "Mena de hierro", "misc", "ore_hierro", 8, "Se funde en la fragua")
	_it("mena_lunar", "Mena lunar", "misc", "ore_lunar", 25, "Mineral raro")
	_it("madera", "Madera", "misc", "log", 2, "Sirve para cocinar")
	_it("pez", "Pez", "misc", "fish_pez", 3, "Cocinalo en una fogata")
	_it("trucha", "Trucha", "misc", "fish_trucha", 9, "Cocinala en una fogata")
	_it("pez_asado", "Pez asado", "potion", "fish_pez_asado", 8, "Cura 40 de vida", {"heal": 40})
	_it("trucha_asada", "Trucha asada", "potion", "fish_trucha_asada", 20, "Cura 90 de vida", {"heal": 90})
	_it("pocion", "Pocion de vida", "potion", "potion", 15, "Cura 60 de vida", {"heal": 60})
	_it("carne", "Carne", "potion", "meat", 6, "Cura 30 de vida", {"heal": 30})
	_it("hueso", "Hueso", "misc", "bone", 2, "Material de esqueleto")
	# recetas: fragua (fundir), yunque (forjar), fogata (cocinar)
	var fr := [
		{"out": "bar_cobre", "need": {"mena_cobre": 2}, "lvl": 1, "xp": 15},
		{"out": "bar_hierro", "need": {"mena_hierro": 2, "carbon": 1}, "lvl": 15, "xp": 38},
		{"out": "bar_acero", "need": {"bar_hierro": 1, "carbon": 2}, "lvl": 30, "xp": 75},
		{"out": "bar_lunar", "need": {"mena_lunar": 2, "carbon": 2}, "lvl": 45, "xp": 150},
	]
	var yu := []
	for i in 4:
		for pair in [["weapon", "espada_"], ["helmet", "casco_"], ["chest", "peto_"], ["legs", "grebas_"], ["boots", "botas_"]]:
			var n: int = BARS_NEEDED[pair[0]]
			yu.append({"out": pair[1] + TIERS[i], "need": {"bar_" + TIERS[i]: n}, "lvl": TIER_LVL[i], "xp": n * [12, 30, 60, 120][i]})
	var fo := [
		{"out": "pez_asado", "need": {"pez": 1, "madera": 1}, "lvl": 1, "xp": 15},
		{"out": "trucha_asada", "need": {"trucha": 1, "madera": 1}, "lvl": 15, "xp": 42},
	]
	RECIPES = {"fragua": {"skill": "herreria", "list": fr, "title": "Fragua"}, "yunque": {"skill": "herreria", "list": yu, "title": "Yunque"}, "fogata": {"skill": "cocina", "list": fo, "title": "Fogata"}}

# ---------------- habilidades y estadisticas ----------------
func skill_level(s: String) -> int: return 1 + int(sqrt(float(skill_xp[s]) / 40.0))
func skill_floor(l: int) -> int: return (l - 1) * (l - 1) * 40
func add_skill_xp(s: String, n: int) -> bool:
	var before := skill_level(s); skill_xp[s] += n
	return skill_level(s) > before

func free_points() -> int: return (level - 1) - int(stat_pts["hp"]) - int(stat_pts["def"]) - int(stat_pts["atk"])
func equip_sum(key: String) -> int:
	var n := 0
	for s in SLOTS:
		var id: String = equip[s]
		if id != "" and ITEMS[id].has(key): n += int(ITEMS[id][key])
	return n
func max_hp() -> float: return 100.0 + 15.0 * (level - 1) + 10.0 * int(stat_pts["hp"]) + equip_sum("hp")
func xp_needed() -> int: return 40 + 30 * level
func attack_power() -> int: return equip_sum("atk") + 2 * level + 2 * int(stat_pts["atk"])
func defense() -> int: return equip_sum("def") + int(stat_pts["def"])

# ---------------- inventario ----------------
func add_item(id: String) -> bool:
	var i := inventory.find("")
	if i == -1: return false
	inventory[i] = id
	return true

func count_item(id: String) -> int:
	var n := 0
	for it in inventory:
		if it == id: n += 1
	return n

func remove_items(id: String, n: int):
	for i in INV_SIZE:
		if n > 0 and inventory[i] == id:
			inventory[i] = ""; n -= 1

func equip_item(idx: int):
	var id: String = inventory[idx]
	if id == "" or ITEMS[id]["type"] != "equip": return
	var slot: String = ITEMS[id]["slot"]
	inventory[idx] = equip[slot]
	equip[slot] = id

func unequip(slot: String):
	if equip[slot] != "" and add_item(equip[slot]): equip[slot] = ""

func gain_xp(n: int) -> bool:
	xp += n
	var up := false
	while xp >= xp_needed():
		xp -= xp_needed(); level += 1; up = true
	if up: hp = max_hp()
	return up

func on_kill(kind: String):
	kills += 1
	for id in quests:
		var q = QUESTS[id]
		if quests[id]["state"] == "active" and q["kind"] == "kill" and q["target"] == kind:
			quests[id]["progress"] = min(int(q["need"]), int(quests[id]["progress"]) + 1)

func quest_progress(id: String) -> int:
	var q = QUESTS[id]
	if q["kind"] == "collect": return min(int(q["need"]), count_item(q["target"]))
	return int(quests[id]["progress"])

func quest_ready(id: String) -> bool:
	return quests.has(id) and quests[id]["state"] == "active" and quest_progress(id) >= int(QUESTS[id]["need"])

func quest_available(id: String) -> bool:
	var q = QUESTS[id]
	return not quests.has(id) and (not q.has("after") or (quests.has(q["after"]) and quests[q["after"]]["state"] == "done"))

# ---------------- guardado ----------------
func save_game():
	var d := {"level": level, "xp": xp, "hp": hp, "gold": gold, "inv": inventory, "bank": bank, "equip": equip, "skills": skill_xp, "pts": stat_pts,
		"quests": quests, "has_mount": has_mount, "px": pos.x, "py": pos.y, "kills": kills}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY: return false
	level = int(d.get("level", 1)); xp = int(d.get("xp", 0)); hp = float(d.get("hp", 100)); gold = int(d.get("gold", 0))
	inventory.fill(""); bank.fill("")
	var inv = d.get("inv", []); for i in min(INV_SIZE, inv.size()): inventory[i] = str(inv[i]) if ITEMS.has(str(inv[i])) else ""
	var bk = d.get("bank", []); for i in min(BANK_SIZE, bk.size()): bank[i] = str(bk[i]) if ITEMS.has(str(bk[i])) else ""
	var eq = d.get("equip", {}); for s in SLOTS: equip[s] = str(eq.get(s, "")) if ITEMS.has(str(eq.get(s, ""))) else ""
	var sk = d.get("skills", {}); for s in SKILL_IDS: skill_xp[s] = int(sk.get(s, 0))
	var pt = d.get("pts", {}); for k in stat_pts: stat_pts[k] = int(pt.get(k, 0))
	quests = d.get("quests", {})
	has_mount = bool(d.get("has_mount", false)); kills = int(d.get("kills", 0))
	pos = Vector2(float(d.get("px", 0)), float(d.get("py", 0)))
	return true
