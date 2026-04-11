extends Node

const QUEST_DATABASE_PATH := "res://resources/quests/quest_database.tres"

var quest_database: QuestDatabase
var quests_by_id: Dictionary = {}
var tracked_quest: QuestInstance = null

signal quest_status_updated

# =========================================================
# Init
# =========================================================

func _ready() -> void:
	_load_database()
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	FriendshipManager.friendship_updated.connect(_on_friendship_updated)
	SaveManager.data_loaded.connect(load_data)

func _load_database() -> void:
	quest_database = load(QUEST_DATABASE_PATH) as QuestDatabase

	if quest_database == null:
		push_error("QuestManager: failed to load QuestDatabase at path: %s" % QUEST_DATABASE_PATH)
		return

# =========================================================
# Quest state changes
# =========================================================

func accept_quest(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	if quest == null:
		return false

	if quest.status != QuestInstance.Status.AVAILABLE:
		return false

	quest.status = QuestInstance.Status.ACTIVE
	tracked_quest = quest

	refresh_quests_status()
	return true


func turn_in_quest(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	if quest == null:
		return false

	if quest.status != QuestInstance.Status.READY_TO_TURN_IN:
		return false

	if not can_turn_in_quest(quest):
		return false

	InventoryManager.remove_item_stacks(quest.quest_data.required_items)
	InventoryManager.add_item_stacks(quest.quest_data.reward_items)

	quest.status = QuestInstance.Status.COMPLETED

	if tracked_quest == quest:
		tracked_quest = null

	refresh_quests_status()
	return true


func check_if_quest_is_available(quest_id: String) -> bool:
	var quest: QuestInstance = _get_quest(quest_id)
	return _check_if_quest_is_available(quest)


func _check_if_quest_is_available(quest: QuestInstance) -> bool:
	if quest == null:
		return false

	if quest.status != QuestInstance.Status.LOCKED and quest.status != QuestInstance.Status.AVAILABLE:
		return false

	var conditions := quest.quest_data.unlock_conditions
	for condition in conditions:
		if not check_unlock_condition(condition, quest):
			return false

	return true


func check_unlock_condition(condition: QuestCondition, quest: QuestInstance) -> bool:
	match condition.type:
		QuestCondition.Type.FRIENDSHIP_AT_LEAST:
			return FriendshipManager.get_friendship_level(quest.quest_data.giver_npc) >= condition.friendship_value
		QuestCondition.Type.FRIENDSHIP_UNDER:
			return FriendshipManager.get_friendship_level(quest.quest_data.giver_npc) < condition.friendship_value
		_:
			return false


func refresh_quests_status() -> void:
	for quest in quests_by_id.values():
		_update_quest_state(quest)

	# Safety: tracked quest may no longer be valid
	if tracked_quest != null and tracked_quest.status == QuestInstance.Status.COMPLETED:
		tracked_quest = null

	quest_status_updated.emit()


func _update_quest_state(quest: QuestInstance) -> void:
	if quest == null:
		return

	match quest.status:
		QuestInstance.Status.LOCKED:
			if _check_if_quest_is_available(quest):
				quest.status = QuestInstance.Status.AVAILABLE

		QuestInstance.Status.AVAILABLE:
			if not _check_if_quest_is_available(quest):
				quest.status = QuestInstance.Status.LOCKED

		QuestInstance.Status.ACTIVE:
			if can_turn_in_quest(quest):
				quest.status = QuestInstance.Status.READY_TO_TURN_IN

		QuestInstance.Status.READY_TO_TURN_IN:
			if not can_turn_in_quest(quest):
				quest.status = QuestInstance.Status.ACTIVE

# =========================================================
# Tracking
# =========================================================

func track_quest(quest_id: String) -> void:
	var quest := _get_quest(quest_id)
	_track_quest(quest)

func _track_quest(quest: QuestInstance) -> void:
	if quest == null:
		return

	if quest.status != QuestInstance.Status.COMPLETED:
		tracked_quest = quest

func untrack_quest() -> void:
	tracked_quest = null

# =========================================================
# NPC helpers
# =========================================================

func get_available_quests_for_giver(npc_data: NPCData) -> Array[QuestInstance]:
	var result: Array[QuestInstance] = []

	for quest in quests_by_id.values():
		if quest.quest_data.giver_npc == npc_data and quest.status == QuestInstance.Status.AVAILABLE:
			result.append(quest)

	return result


func get_receiver_quests(npc_data: NPCData) -> Array[QuestInstance]:
	var result: Array[QuestInstance] = []

	for quest in quests_by_id.values():
		if quest.quest_data.receiver_npc != npc_data:
			continue

		if quest.status == QuestInstance.Status.ACTIVE or quest.status == QuestInstance.Status.READY_TO_TURN_IN:
			result.append(quest)

	return result


func has_available_quest_for_giver(npc_data: NPCData) -> bool:
	return not get_available_quests_for_giver(npc_data).is_empty()


func has_quest_to_turn_in_for_receiver(npc_data: NPCData) -> bool:
	for quest in get_receiver_quests(npc_data):
		if quest.status == QuestInstance.Status.READY_TO_TURN_IN:
			return true
	return false


func has_quest_in_progress_for_receiver(npc_data: NPCData) -> bool:
	for quest in get_receiver_quests(npc_data):
		if quest.status == QuestInstance.Status.ACTIVE:
			return true
	return false

# =========================================================
# Checks
# =========================================================

func has_quest(quest_id: String) -> bool:
	return quests_by_id.has(quest_id)


func is_quest_available(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	return quest != null and quest.status == QuestInstance.Status.AVAILABLE


func is_quest_active(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	return quest != null and quest.status == QuestInstance.Status.ACTIVE


func is_quest_ready_to_turn_in(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	return quest != null and quest.status == QuestInstance.Status.READY_TO_TURN_IN


func is_quest_completed(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	return quest != null and quest.status == QuestInstance.Status.COMPLETED


func can_turn_in_quest(quest: QuestInstance) -> bool:
	if quest == null:
		return false

	return InventoryManager.has_enough_item_stacks(quest.quest_data.required_items)


func get_tracked_quest() -> QuestInstance:
	return tracked_quest

# =========================================================
# Events
# =========================================================

func _on_inventory_updated() -> void:
	refresh_quests_status()

func _on_friendship_updated() -> void:
	refresh_quests_status()

# =========================================================
# Utils
# =========================================================

func _debug_quests_state() -> Dictionary:
	var result := {}

	for quest_id in quests_by_id.keys():
		var quest: QuestInstance = quests_by_id[quest_id]
		result[quest_id] = {
			"title": quest.quest_data.title,
			"status": QuestInstance.Status.keys()[quest.status],
			"tracked": tracked_quest == quest
		}

	return result


func _get_quest(quest_id: String) -> QuestInstance:
	return quests_by_id.get(quest_id) as QuestInstance

# =========================================================
# Save / Load
# =========================================================

func save_data() -> Dictionary:
	var serialized_quests := {}

	for quest_id in quests_by_id.keys():
		var quest: QuestInstance = quests_by_id[quest_id]
		if quest == null:
			continue

		serialized_quests[quest_id] = {
			"status": quest.status,
			"tracked": tracked_quest == quest
		}

	return {
		"quests": serialized_quests
	}


func load_data() -> void:
	var saved_quests: Dictionary = {}

	# Read save safely
	if SaveManager.data.has("quests"):
		var raw_data = SaveManager.data["quests"]

		# Accept both formats:
		# old format: SaveManager.data["quests"] = { ...quests... }
		# new format: SaveManager.data["quests"] = { "quests": { ... } }
		if raw_data is Dictionary and raw_data.has("quests"):
			saved_quests = raw_data["quests"]
		elif raw_data is Dictionary:
			saved_quests = raw_data

	_build_quest_instances(saved_quests)
	refresh_quests_status()

	print("============================================")
	_debug()


func _build_quest_instances(saved_quests: Dictionary) -> void:
	quests_by_id.clear()
	tracked_quest = null

	if quest_database == null:
		return

	for quest_data in quest_database.quests:
		if quest_data == null:
			continue

		if quest_data.id.is_empty():
			push_warning("QuestManager: skipped quest with empty id")
			continue

		if quests_by_id.has(quest_data.id):
			push_warning("QuestManager: duplicate quest id '%s'" % quest_data.id)
			continue

		var instance := QuestInstance.new(quest_data)

		# Default state for new quests not found in save
		if _check_if_quest_is_available(instance):
			instance.status = QuestInstance.Status.AVAILABLE
		else:
			instance.status = QuestInstance.Status.LOCKED

		# Apply saved data only if this quest still exists in database
		if saved_quests.has(quest_data.id):
			var saved_entry = saved_quests[quest_data.id]

			if saved_entry is Dictionary:
				# Restore status if valid
				if saved_entry.has("status"):
					var saved_status = int(saved_entry["status"])
					if saved_status >= 0 and saved_status < QuestInstance.Status.size():
						instance.status = saved_status

				# Restore tracking after instance is stored
				if saved_entry.get("tracked", true):
					tracked_quest = instance

		quests_by_id[quest_data.id] = instance

	# If tracked quest points to a completed one, remove tracking
	if tracked_quest != null and tracked_quest.status == QuestInstance.Status.COMPLETED:
		tracked_quest = null


func _debug() -> void:
	print("⭐ QUESTS\n", JSON.stringify(_debug_quests_state(), "\t"))
	if tracked_quest != null:
		print("Tracked: ",tracked_quest.quest_data.id)
	else:
		print("Tracked: none")
