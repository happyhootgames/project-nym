extends Node


# =========================================================
# SIGNALS
# =========================================================

signal quest_status_updated


# =========================================================
# CONSTANTS
# =========================================================

const QUEST_DATABASE_PATH := "res://resources/quests/quest_database.tres"


# =========================================================
# STATE
# =========================================================

var quest_database: QuestDatabase
var quests_by_id: Dictionary = {}
var tracked_quest: QuestInstance = null


# =========================================================
# LIFECYCLE
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


# =========================================================
# QUEST STATE CHANGES
# =========================================================

# Accepts an available quest and starts tracking it. Returns false if not possible.
func accept_quest(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	if quest == null or quest.status != QuestInstance.Status.AVAILABLE:
		return false

	quest.status = QuestInstance.Status.ACTIVE
	tracked_quest = quest
	refresh_quests_status()
	return true


# Completes a quest, removes required items, and grants rewards. Returns false if not possible.
func turn_in_quest(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	if quest == null or quest.status != QuestInstance.Status.READY_TO_TURN_IN:
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


# Re-evaluates the status of every quest and emits quest_status_updated.
func refresh_quests_status() -> void:
	for quest in quests_by_id.values():
		_update_quest_state(quest)

	# Safety: clear tracked quest if it was just completed.
	if tracked_quest != null and tracked_quest.status == QuestInstance.Status.COMPLETED:
		tracked_quest = null

	quest_status_updated.emit()


# Transitions a single quest to its correct status based on current game state.
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
# AVAILABILITY CHECKS
# =========================================================

func check_if_quest_is_available(quest_id: String) -> bool:
	return _check_if_quest_is_available(_get_quest(quest_id))


# Returns true only if the quest is in a lockable state and all conditions pass.
func _check_if_quest_is_available(quest: QuestInstance) -> bool:
	if quest == null:
		return false

	if quest.status != QuestInstance.Status.LOCKED \
	and quest.status != QuestInstance.Status.AVAILABLE:
		return false

	for condition in quest.quest_data.unlock_conditions:
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


# =========================================================
# STATUS CHECKS
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

# Returns true if the player has all required items to complete this quest.
func can_turn_in_quest(quest: QuestInstance) -> bool:
	if quest == null:
		return false
	return InventoryManager.has_enough_item_stacks(quest.quest_data.required_items)


# =========================================================
# TRACKING
# =========================================================

func track_quest(quest_id: String) -> void:
	_track_quest(_get_quest(quest_id))

func _track_quest(quest: QuestInstance) -> void:
	if quest == null or quest.status == QuestInstance.Status.COMPLETED:
		return
	tracked_quest = quest

func untrack_quest() -> void:
	tracked_quest = null

func get_tracked_quest() -> QuestInstance:
	return tracked_quest


# =========================================================
# NPC HELPERS
# =========================================================

# Returns all quests available to be given by this NPC.
func get_available_quests_for_giver(npc_data: NPCData) -> Array[QuestInstance]:
	var result: Array[QuestInstance] = []
	for quest in quests_by_id.values():
		if quest.quest_data.giver_npc == npc_data \
		and quest.status == QuestInstance.Status.AVAILABLE:
			result.append(quest)
	return result


# Returns all active or ready-to-turn-in quests for this receiver NPC.
func get_receiver_quests(npc_data: NPCData) -> Array[QuestInstance]:
	var result: Array[QuestInstance] = []
	for quest in quests_by_id.values():
		if quest.quest_data.receiver_npc != npc_data:
			continue
		if quest.status == QuestInstance.Status.ACTIVE \
		or quest.status == QuestInstance.Status.READY_TO_TURN_IN:
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
# EVENTS
# =========================================================

func _on_inventory_updated() -> void:
	refresh_quests_status()

func _on_friendship_updated() -> void:
	refresh_quests_status()


# =========================================================
# SAVE / LOAD
# =========================================================

func save_data() -> Dictionary:
	var serialized: Dictionary = {}
	for quest_id in quests_by_id.keys():
		var quest: QuestInstance = quests_by_id[quest_id]
		if quest == null:
			continue
		serialized[quest_id] = {
			"status": quest.status,
			"tracked": tracked_quest == quest
		}
	return { "quests": serialized }


func load_data() -> void:
	if quest_database == null:
		_load_database()

	var saved_quests: Dictionary = {}
	var raw_data = SaveManager.data.get("quests", {})

	# Accept both save formats for backwards compatibility.
	if raw_data is Dictionary and raw_data.has("quests"):
		saved_quests = raw_data["quests"]
	elif raw_data is Dictionary:
		saved_quests = raw_data

	_build_quest_instances(saved_quests)
	refresh_quests_status()
	_debug()


# Rebuilds all QuestInstances from the database, then applies saved state on top.
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

		# Compute default status for quests not present in the save file.
		instance.status = QuestInstance.Status.AVAILABLE \
			if _check_if_quest_is_available(instance) \
			else QuestInstance.Status.LOCKED

		# Overlay saved state if this quest exists in the save file.
		if saved_quests.has(quest_data.id):
			var entry = saved_quests[quest_data.id]
			if entry is Dictionary:
				if entry.has("status"):
					var saved_status := int(entry["status"])
					if saved_status >= 0 and saved_status < QuestInstance.Status.size():
						instance.status = saved_status as QuestInstance.Status
				if entry.get("tracked", false):
					tracked_quest = instance

		quests_by_id[quest_data.id] = instance

	# Clear tracking if the tracked quest was already completed.
	if tracked_quest != null and tracked_quest.status == QuestInstance.Status.COMPLETED:
		tracked_quest = null


# =========================================================
# UTILS
# =========================================================

func _get_quest(quest_id: String) -> QuestInstance:
	return quests_by_id.get(quest_id) as QuestInstance


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	var state := {}
	for quest_id in quests_by_id.keys():
		var quest: QuestInstance = quests_by_id[quest_id]
		state[quest_id] = {
			"status": QuestInstance.Status.keys()[quest.status],
			"tracked": tracked_quest == quest
		}
	print_debug("⭐ QuestManager | tracked: %s | quests: %s" % [
		tracked_quest.quest_data.id if tracked_quest else "none",
		state
	])
