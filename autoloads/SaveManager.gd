extends Node

const SAVE_PATH := "res://savegame.json"

signal data_loaded

var player: Player = null
const EXPECTED_KEYS = [
	"player",
	"inventory",
	"friendships",
	"quests"
]
var data: Dictionary = {}

func _ready() -> void:
	load_game()

# Save all game data
func save_game() -> bool:
	
	print("🔥 SAVING... 🔥")
	

	# Save player if found
	data["player"] = player.save_data()
	data["inventory"] = InventoryManager.save_data()
	data["friendships"] = FriendshipManager.save_data()
	data["quests"] = QuestManager.save_data()

	## Save all persistent nodes
	#for node in get_tree().get_nodes_in_group("persist"):
		#if node.has_method("data"):
			#data["persist_nodes"].append({
				#"scene_path": node.scene_file_path,
				#"parent_path": str(node.get_parent().get_path()),
				#"node_path": str(node.get_path()),
				#"data": node.save_data()
			#})

	# Convert dictionary to JSON string
	var json_string := JSON.stringify(data, "\t")

	# Open file in write mode
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: cannot open file")
		return false

	# Write JSON
	file.store_string(json_string)
	print("🔥 SAVED 🔥\n",json_string)
	return true


# Load all game data
func load_game() -> void:
	# Check if save exists
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("No save file found")
	if FileAccess.file_exists(SAVE_PATH):
		# Open file in read mode
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file == null:
			push_error("Load failed: cannot open file")

		# Read file content
		var json_text := file.get_as_text()

		# Parse JSON
		var parsed = JSON.parse_string(json_text)
		if parsed == null:
			push_error("Load failed: invalid JSON")

		data = parsed
	for key in EXPECTED_KEYS:
			if not data.has(key):
				data[key] = {}
	
	print(JSON.stringify(data,"\t"))
	data_loaded.emit()

	## Load persistent nodes
	#if data.has("persist_nodes"):
		#for entry in data["persist_nodes"]:
			#var node_path = NodePath(entry["node_path"])
#
			## If node already exists, load directly
			#if has_node(node_path):
				#var existing_node = get_node(node_path)
				#if existing_node.has_method("load_data"):
					#existing_node.load_data(entry["data"])



func register_player(node: Player) -> void:
	player = node
