extends Node
# Estado global: estadisticas, inventario, misiones, guardado y base de datos de objetos.

const INV_SIZE := 35
const SAVE_PATH := "user://save.json"

# icon = indice en icons.png
const ITEMS := {
	"espada_madera": {"name": "Espada de madera", "type": "weapon", "atk": 4, "icon": 0, "price": 10, "desc": "Ataque +4"},
	"espada_hierro": {"name": "Espada de hierro", "type": "weapon", "atk": 10, "icon": 1, "price": 60, "desc": "Ataque +10"},
	"hacha": {"name": "Hacha de guerra", "type": "weapon", "atk": 16, "icon": 2, "price": 150, "desc": "Ataque +16"},
	"baston": {"name": "Baston arcano", "type": "weapon", "atk": 22, "icon": 3, "price": 300, "desc": "Ataque +22"},
	"armadura_cuero": {"name": "Armadura de cuero", "type": "armor", "def": 3, "icon": 4, "price": 40, "desc": "Defensa +3"},
	"armadura_hierro": {"name": "Armadura de hierro", "type": "armor", "def": 8, "icon": 5, "price": 180, "desc": "Defensa +8"},
	"pocion": {"name": "Pocion de vida", "type": "potion", "heal": 50, "icon": 6, "price": 15, "desc": "Cura 50 de vida"},
	"hueso": {"name": "Hueso", "type": "misc", "icon": 7, "price": 2, "desc": "Material de esqueleto"},
	"carne": {"name": "Carne", "type": "potion", "heal": 25, "icon": 9, "price": 6, "desc": "Cura 25 de vida"},
}

const QUESTS := {
	"mina": {"giver": "Bayu", "title": "Limpiar la mina", "text": "Los esqueletos invaden la mina. Derrota a 5.", "kind": "kill", "target": "skeleton", "need": 5, "gold": 60, "xp": 80, "item": "espada_hierro"},
	"huesos": {"giver": "Mara", "title": "Huesos para la curandera", "text": "Necesito 3 huesos para mis remedios.", "kind": "collect", "target": "hueso", "need": 3, "gold": 30, "xp": 50, "item": "pocion"},
	"buitres": {"giver": "Toro", "title": "Caza de buitres", "text": "Los buitres asustan al ganado. Derrota a 4 y te dare un caballo.", "kind": "kill", "target": "vulture", "need": 4, "gold": 100, "xp": 150, "mount": true},
	"limos": {"giver": "Bayu", "title": "Plaga de limos", "text": "Elimina 8 limos del bosque.", "kind": "kill", "target": "slime", "need": 8, "gold": 80, "xp": 100, "item": "armadura_cuero", "after": "mina"},
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
var weapon := "espada_madera"
var armor := ""
var quests := {}   # id -> {"state": "active"/"done", "progress": n}
var has_mount := false
var mounted := false
var pos := Vector2.ZERO
var kills := 0

func _ready():
	inventory.resize(INV_SIZE)
	inventory.fill("")

func max_hp() -> float: return 100.0 + 15.0 * (level - 1)
func xp_needed() -> int: return 40 + 30 * level
func attack_power() -> int: return int(ITEMS[weapon]["atk"]) + 2 * level if weapon != "" else 2 * level
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
		if quests[id]["state"] == "active" and q["kind"] == "kill" and q["target"] == kind:
			quests[id]["progress"] = min(int(q["need"]), int(quests[id]["progress"]) + 1)

func quest_progress(id: String) -> int:
	var q = QUESTS[id]
	if q["kind"] == "collect": return min(int(q["need"]), count_item(q["target"]))
	return int(quests[id]["progress"])

func quest_ready(id: String) -> bool:
	return quests.has(id) and quests[id]["state"] == "active" and quest_progress(id) >= int(QUESTS[id]["need"])

func save_game():
	var d := {"level": level, "xp": xp, "hp": hp, "gold": gold, "inv": inventory, "weapon": weapon, "armor": armor,
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
	var inv = d.get("inv", [])
	inventory.fill("")
	for i in min(INV_SIZE, inv.size()): inventory[i] = str(inv[i])
	weapon = str(d.get("weapon", "espada_madera")); armor = str(d.get("armor", ""))
	quests = d.get("quests", {})
	has_mount = bool(d.get("has_mount", false)); kills = int(d.get("kills", 0))
	pos = Vector2(float(d.get("px", 0)), float(d.get("py", 0)))
	return true
