extends Node


# =========================================================
# SIGNALS
# =========================================================

signal friendship_updated


# =========================================================
# STATE
# =========================================================

var friendships: Dictionary = {}


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	SaveManager.data_loaded.connect(load_data)


# =========================================================
# PUBLIC API
# =========================================================

# Returns the current friendship level for a given NPC. Defaults to 0.
func get_friendship_level(npc_data: NPCData) -> int:
	return friendships.get(npc_data.id, 0)


# Adds quantity points to the friendship level of the given NPC.
func increment_friendship_for(npc_data: NPCData, quantity: int) -> void:
	friendships[npc_data.id] = get_friendship_level(npc_data) + quantity
	friendship_updated.emit()
	_debug()


# =========================================================
# SAVE / LOAD
# =========================================================

func save_data() -> Dictionary:
	return friendships


func load_data() -> void:
	friendships = SaveManager.data.get("friendships", {})
	_debug()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("💕 FriendshipManager | ", friendships)
