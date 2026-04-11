extends Node

signal friendship_updated

var friendships: Dictionary = {}

func _ready() -> void:
	SaveManager.data_loaded.connect(load_data)

func get_friendship_level(npc_data: NPCData) -> int:
	if friendships.has(npc_data.npc_id):
		var level :int = friendships[npc_data.npc_id]
		if level == null:
			return 0
		else:
			return level
	else:
		friendships[npc_data.npc_id] = 0
		return 0

func increment_friendship_for(npc_data: NPCData, quantity: int) -> void:
	if not friendships.has(npc_data.npc_id):
		friendships[npc_data.npc_id] = 0
	friendships[npc_data.npc_id] = friendships[npc_data.npc_id]+quantity
	friendship_updated.emit()
	_debug()

func save_data() -> Dictionary:
	return friendships

func load_data() -> void:
	friendships = SaveManager.data["friendships"]
	print("============================================")
	_debug()

func _debug() -> void:
	print("💕 FRIENDSHIP\n",JSON.stringify(friendships, '\t'))
