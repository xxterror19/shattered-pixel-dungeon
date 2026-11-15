extends Node
# Estado global: estadisticas, inventario, misiones, habilidades, guardado.

const INV_SIZE := 35
const SAVE_PATH := "user://save3d.json"

# wtype: sword/staff; col: color de la hoja u orbe; icon: indice en icons.png
const ITEMS := {
	"espada_madera": {"name": "Espada de madera", "type": "weapon", "wtype": "sword", "atk": 4, "icon": 0, "price": 10, "col": "b99a6a", "desc": "Espada. Ataque +4"},
	"espada_hierro": {"name": "Espada de hierro", "type": "weapon", "wtype": "sword", "atk": 10, "icon": 1, "price": 60, "col": "d8dcea", "desc": "Espada. Ataque +10"},
	"espada_acero": {"name": "Espada de acero", "type": "weapon", "wtype": "sword", "atk": 16, "icon": 20, "price": 160, "col": "bfd0f0", "desc": "Espada. Ataque +16"},
	"espada_llamas": {"name": "Espada de llamas", "type": "weapon", "wtype": "sword", "atk": 26, "icon": 12, "price": 500, "col": "ff8c28", "desc": "Espada. Ataque +26"},
	"espada_hielo": {"name": "Hoja glacial", "type": "weapon", "wtype": "sword", "atk": 38, "icon": 13, "price": 900, "col": "8fe0ff", "desc": "Espada. Ataque +38"},
	"baston_aprendiz": {"name": "Baston de aprendiz", "type": "weapon", "wtype": "staff", "atk": 9, "icon": 3, "price": 70, "col": "5aa8ff", "desc": "Baston. Hechizos. Ataque +9"},
	"baston_rayo": {"name": "Baston del rayo", "type": "weapon", "wtype": "staff", "atk": 20, "icon": 14, "price": 260, "col": "ff5040", "desc": "Baston. Ataque +20"},
	"baston_arcano": {"name": "Baston arcano", "type": "weapon", "wtype": "staff", "atk": 34, "icon": 15, "price": 700, "col": "c060ff", "desc": "Baston. Ataque +34"},
	"armadura_cuero": {"name": "Armadura de cuero", "type": "armor", "def": 3, "icon": 4, "price": 40, "col": "9c6a3c", "desc": "Defensa +3"},
	"armadura_hierro": {"name": "Armadura de hierro", "type": "armor", "def": 8, "icon": 5, "price": 180, "col": "9aa2b4", "desc": "Defensa +8"},
	"armadura_runica": {"name": "Armadura runica", "type": "armor", "def": 15, "icon": 16, "price": 520, "col": "8c50c8", "desc": "Defensa +15"},
	"pocion": {"name": "Pocion de vida", "type": "potion", "heal": 60, "icon": 6, "price": 15, "desc": "Cura 60 de vida"},
	"carne": {"name": "Carne", "type": "potion", "heal": 30, "icon": 9, "price": 6, "desc": "Cura 30 de vida"},
	"hueso": {"name": "Hueso", "type": "misc", "icon": 7, "price": 2, "desc": "Material de esqueleto"},
	"colmillo": {"name": "Colmillo", "type": "misc", "icon": 17, "price": 4, "desc": "Material de lobo"},
	"polvo": {"name": "Polvo arcano", "type": "misc", "icon": 18, "price": 6, "desc": "Material de murcielago"},
	"corona": {"name": "Corona real", "type": "misc", "icon": 19, "price": 200, "desc": "Trofeo de jefe. Se vende bien"},
	"escama": {"name": "Escama de dragon", "type": "misc", "icon": 21, "price": 400, "desc": "Trofeo de jefe"},
}

const QUESTS := {
	"mina": {"giver": "Bayu", "title": "Limpiar la mina", "text": "Los esqueletos invaden las rocas. Derrota a 5.", "kind": "kill", "target": "skeleton", "need": 5, "gold": 60, "xp": 80, "item": "espada_hierro"},
	"limos": {"giver": "Bayu", "title": "Plaga de limos", "text": "Elimina 8 limos del bosque.", "kind": "kill", "target": "slime", "need": 8, "gold": 80, "xp": 100, "item": "armadura_cuero", "after": "mina"},
	"rey_esq": {"giver": "Bayu", "title": "El Rey Esqueleto", "text": "Un rey no-muerto manda a los esqueletos desde las ruinas del este. Acaba con el.", "kind": "boss", "target": "rey_esqueleto", "need": 1, "gold": 400, "xp": 500, "item": "espada_acero", "after": "limos"},
	"elite": {"giver": "Bayu", "title": "Limpieza total", "text": "Derrota a 15 esqueletos mas.", "kind": "kill", "target": "skeleton", "need": 15, "gold": 250, "xp": 350, "item": "armadura_hierro", "after": "rey_esq"},
	"huesos": {"giver": "Mara", "title": "Huesos para la curandera", "text": "Necesito 3 huesos para mis remedios.", "kind": "collect", "target": "hueso", "need": 3, "gold": 30, "xp": 50, "item": "pocion"},
	"colmillos": {"giver": "Mara", "title": "Colmillos de lobo", "text": "Traeme 4 colmillos de lobo.", "kind": "collect", "target": "colmillo", "need": 4, "gold": 60, "xp": 90, "item": "baston_aprendiz", "after": "huesos"},
	"bats": {"giver": "Mara", "title": "Noche de murcielagos", "text": "Los murcielagos asustan a los enfermos. Derrota a 6.", "kind": "kill", "target": "bat", "need": 6, "gold": 120, "xp": 160, "item": "pocion", "after": "colmillos"},
	"slime_rey": {"giver": "Mara", "title": "El Rey Limo", "text": "Un limo gigante crece en el bosque del suroeste. Hay que detenerlo.", "kind": "boss", "target": "slime_rey", "need": 1, "gold": 350, "xp": 450, "item": "baston_rayo", "after": "bats"},
	"lobos": {"giver": "Toro", "title": "Lobos en el ganado", "text": "Derrota a 5 lobos y te dare un caballo.", "kind": "kill", "target": "wolf", "need": 5, "gold": 100, "xp": 150, "mount": true},
	"caza": {"giver": "Toro", "title": "Gran cacería", "text": "Derrota a 12 lobos mas.", "kind": "kill", "target": "wolf", "need": 12, "gold": 220, "xp": 300, "item": "carne", "after": "lobos"},
	"polvo": {"giver": "Elda", "title": "Polvo arcano", "text": "Junta 5 polvos arcanos de murcielago para mis runas.", "kind": "collect", "target": "polvo", "need": 5, "gold": 150, "xp": 200, "item": "armadura_runica", "after": "colmillos"},
	"dragon": {"giver": "Elda", "title": "El Dragon de Ceniza", "text": "El dragon duerme en las tierras del sureste. Si lo derrotas, la region sera libre.", "kind": "boss", "target": "dragon", "need": 1, "gold": 1500, "xp": 1500, "item": "espada_hielo", "after": "polvo"},
}

# habilidades segun el arma equipada
const SKILLS := {
	"sword": [
		{"id": "dash", "name": "Embestida", "level": 1, "cd": 4.0},
		{"id": "spin", "name": "Torbellino", "level": 3, "cd": 7.0},
		{"id": "slam", "name": "Impacto", "level": 5, "cd": 10.0},
	],
	"staff": [
		{"id": "fire", "name": "Fuego", "level": 1, "cd": 3.0},
		{"id": "bolt", "name": "Rayo", "level": 3, "cd": 6.0},
		{"id": "nova", "name": "Hielo", "level": 5, "cd": 10.0},
	],
}
const HEAL := {"id": "heal", "name": "Curar", "level": 2, "cd": 12.0}

var level := 1
var xp := 0
var hp := 100.0
var gold := 0
var inventory: Array = []
var weapon := "espada_madera"
var armor := ""
var quests := {}
var has_mount := false
var mounted := false
var pos := Vector3.ZERO
var kills := 0
var bosses_dead := {}   # id -> tiempo (segundos de juego) en que reaparece

func _ready():
	inventory.resize(INV_SIZE)
	inventory.fill("")

func weapon_type() -> String:
	return str(ITEMS[weapon]["wtype"]) if weapon != "" else "sword"

func skill_for(slot: int) -> Dictionary:
	return SKILLS[weapon_type()][slot]

func max_hp() -> float: return 100.0 + 15.0 * (level - 1)
func xp_needed() -> int: return 40 + 30 * level
func attack_power() -> int: return (int(ITEMS[weapon]["atk"]) if weapon != "" else 1) + 2 * level
func defense() -> int: return int(ITEMS[armor]["def"]) if armor != "" else 0

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
			inventory[i] = ""
			n -= 1

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
		if quests[id]["state"] == "active" and (q["kind"] == "kill" or q["kind"] == "boss") and q["target"] == kind:
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

func save_game():
	var d := {"level": level, "xp": xp, "hp": hp, "gold": gold, "inv": inventory, "weapon": weapon, "armor": armor,
		"quests": quests, "has_mount": has_mount, "px": pos.x, "py": pos.y, "pz": pos.z, "kills": kills}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY: return false
	level = int(d.get("level", 1)); xp = int(d.get("xp", 0)); hp = float(d.get("hp", 100)); gold = int(d.get("gold", 0))
	var inv = d.get("inv", [])
	inventory.fill("")
	for i in min(INV_SIZE, inv.size()): inventory[i] = str(inv[i])
	weapon = str(d.get("weapon", "espada_madera")); armor = str(d.get("armor", ""))
	if weapon != "" and not ITEMS.has(weapon): weapon = "espada_madera"
	if armor != "" and not ITEMS.has(armor): armor = ""
	quests = d.get("quests", {})
	has_mount = bool(d.get("has_mount", false)); kills = int(d.get("kills", 0))
	pos = Vector3(float(d.get("px", 0)), float(d.get("py", 0)), float(d.get("pz", 0)))
	return true
