extends Node


# =========================================================
# SIGNALS
# =========================================================

signal data_loaded


# =========================================================
# CONSTANTS
# =========================================================

const SAVE_PATH := "user://savegame.json"

# All top-level keys expected in the save file.
# Any missing key is initialized to {} on load — handles first launch,
# corrupted saves, and new keys added in future updates.
const EXPECTED_KEYS := [
	"player",
	"inventory",
	"friendships",
	"quests",
	"settings",
]


# =========================================================
# STATE
# =========================================================

var data: Dictionary = {}
var player: Player = null


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	# Deferred so all autoloads and scene nodes have finished _ready()
	# before data_loaded is emitted — prevents missed signal connections.
	load_game.call_deferred()


# =========================================================
# SAVE
# =========================================================

# Collects data from all systems and writes it to disk.
# Returns false if the file could not be opened.
func save_game() -> bool:
	data["player"]      = player.save_data()
	data["inventory"]   = InventoryManager.save_data()
	data["friendships"] = FriendshipManager.save_data()
	data["quests"]      = QuestManager.save_data()

	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("SaveManager: cannot open file for writing at %s" % SAVE_PATH)
		return false

	file.store_string(json_string)
	return true


# =========================================================
# LOAD
# =========================================================

# Entry point for loading. Always emits data_loaded — even on first launch.
func load_game() -> void:
	data = {}

	if FileAccess.file_exists(SAVE_PATH):
		_load_from_file()

	_apply_defaults()
	data_loaded.emit()
	_debug()


# Reads and parses the save file into data.
# On any failure, data stays empty and _apply_defaults() takes over.
func _load_from_file() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open file for reading at %s" % SAVE_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("SaveManager: invalid JSON — starting fresh")
		return

	data = parsed


# Ensures all expected top-level keys exist, filling gaps with empty dicts.
func _apply_defaults() -> void:
	for key in EXPECTED_KEYS:
		if not data.has(key):
			data[key] = {}


# =========================================================
# REGISTRATION
# =========================================================

# Called by the Player node in _ready() to register itself for saving.
func register_player(node: Player) -> void:
	player = node


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("💾 SaveManager | keys loaded: %s | file exists: %s" % [
		data.keys(),
		FileAccess.file_exists(SAVE_PATH)
	])
