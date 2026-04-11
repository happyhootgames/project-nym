extends Node

var current_npc_data: NPCData = null
var current_dialogue_data: DialogueData = null
var current_branch: DialogueBranch = null
var current_node: DialogueNode = null


# =========================================================
# Public API
# =========================================================

func start_dialogue_for_npc(npc_data: NPCData) -> void:
	_clear_current_dialogue()

	if npc_data == null:
		push_warning("DialogueManager: start_dialogue_for_npc called with null npc_data")
		return

	current_npc_data = npc_data
	current_dialogue_data = npc_data.dialogue

	if current_dialogue_data == null:
		push_warning("DialogueManager: no DialogueData for npc '%s'" % npc_data.id)
		_clear_current_dialogue()
		return

	var best_entry := _get_best_dialogue_entry(current_dialogue_data, npc_data)
	if best_entry == null:
		push_warning("DialogueManager: no valid DialogueEntry for npc '%s'" % npc_data.id)
		_clear_current_dialogue()
		return

	current_branch = best_entry.branch
	if current_branch == null:
		push_warning("DialogueManager: DialogueEntry '%s' has no branch" % best_entry.id)
		_clear_current_dialogue()
		return

	current_node = current_branch.get_node(current_branch.start_node_id)
	if current_node == null:
		push_warning(
			"DialogueManager: start node '%s' not found in branch '%s'" % [
				current_branch.start_node_id,
				current_branch.id
			]
		)
		_clear_current_dialogue()
		return

	PlayerStateManager.set_state(PlayerStateManager.State.DIALOGUE)
	UIEvents.show_dialogue_node.emit()
	UIEvents.camera_zoom.emit(true)


func next_line() -> void:
	if current_node == null:
		return

	# Wait for player choice
	if current_node.has_choices:
		return

	# No action = end
	if current_node.actions.is_empty():
		end_dialogue()
		return

	execute_actions(current_node.actions)


func choice_clicked(choice: DialogueChoice) -> void:
	if choice == null:
		return

	execute_actions(choice.actions)


func end_dialogue() -> void:
	_clear_current_dialogue()
	UIEvents.end_dialogue.emit()
	PlayerStateManager.reset()
	Input.flush_buffered_events()
	UIEvents.camera_zoom.emit(false)


# =========================================================
# Actions
# =========================================================

func execute_actions(actions: Array[DialogueActionData]) -> void:
	var npc_data := current_npc_data

	for action in actions:
		if action == null:
			continue
		_execute_action(action, npc_data)


func _execute_action(action: DialogueActionData, npc_data: NPCData) -> bool:
	print("⭕ ACTION: ",DialogueActionData.Type.keys()[action.type]," ",action.quest_id)
	match action.type:

		DialogueActionData.Type.NEXT:
			if action.next_node == null:
				push_warning("DialogueManager: NEXT action has no next_node")
				end_dialogue()
				return true

			current_node = action.next_node
			UIEvents.show_dialogue_node.emit()
			return true

		DialogueActionData.Type.CLOSE_DIALOGUE:
			end_dialogue()
			return true

		DialogueActionData.Type.ACCEPT_QUEST:
			var success := QuestManager.accept_quest(action.quest_id)

			if not success:
				return _go_to_error_node_if_possible(action)

			return false

		DialogueActionData.Type.TURN_IN_QUEST:
			var success := QuestManager.turn_in_quest(action.quest_id)

			if not success:
				return _go_to_error_node_if_possible(action)

			return false

		DialogueActionData.Type.INCREMENT_FRIENDSHIP:
			if npc_data == null:
				push_warning("DialogueManager: INCREMENT_FRIENDSHIP with null current_npc_data")
				return false

			FriendshipManager.increment_friendship_for(npc_data, action.int_value)
			return false

		DialogueActionData.Type.RECEIVE_ITEM_FROM_NPC:
			if action.item_data == null:
				push_warning("DialogueManager: RECEIVE_ITEM_FROM_NPC with null item_data")
				return false

			if action.int_value <= 0:
				push_warning("DialogueManager: RECEIVE_ITEM_FROM_NPC with invalid quantity %d" % action.int_value)
				return false

			InventoryManager.add_item_data(action.item_data, action.int_value)
			return false

		DialogueActionData.Type.GIVE_ITEM_TO_NPC:
			if action.item_data == null:
				push_warning("DialogueManager: GIVE_ITEM_TO_NPC with null item_data")
				return _go_to_error_node_if_possible(action)

			if action.int_value <= 0:
				push_warning("DialogueManager: GIVE_ITEM_TO_NPC with invalid quantity %d" % action.int_value)
				return _go_to_error_node_if_possible(action)

			if not InventoryManager.has_item_data(action.item_data, action.int_value):
				return _go_to_error_node_if_possible(action)

			InventoryManager.remove_item_data(action.item_data, action.int_value)
			return false

		_:
			push_warning("DialogueManager: unknown action type '%s'" % str(action.type))
			return false


func _go_to_error_node_if_possible(action: DialogueActionData) -> bool:
	if action.error_node != null:
		current_node = action.error_node
		UIEvents.show_dialogue_node.emit()
		return true

	return false


# =========================================================
# Dialogue selection
# =========================================================

func _get_best_dialogue_entry(dialogue_data: DialogueData, npc_data: NPCData) -> DialogueEntry:
	if dialogue_data == null:
		return null

	var valid_entries: Array[DialogueEntry] = []

	for entry in dialogue_data.entries:
		if entry == null:
			continue
		if _are_entry_conditions_met(entry, npc_data):
			valid_entries.append(entry)

	if valid_entries.is_empty():
		return null

	if valid_entries.size() >= 2:
		valid_entries.sort_custom(func(a: DialogueEntry, b: DialogueEntry) -> bool:
			var a_conditions := a.conditions.size() if a.conditions != null else 0
			var b_conditions := b.conditions.size() if b.conditions != null else 0

			# More specific first
			if a_conditions != b_conditions:
				return a_conditions > b_conditions

			# Higher priority first
			return a.priority > b.priority
		)

	return valid_entries[0]


func _are_entry_conditions_met(entry: DialogueEntry, npc_data: NPCData) -> bool:
	if entry == null:
		return false

	for condition in entry.conditions:
		if condition == null:
			continue

		if not _is_condition_met(condition, npc_data):
			return false

	return true


func _is_condition_met(condition: DialogueCondition, npc_data: NPCData) -> bool:
	match condition.type:
		DialogueCondition.ConditionType.FRIENDSHIP_AT_LEAST:
			return FriendshipManager.get_friendship_level(npc_data) >= condition.friendship_value

		DialogueCondition.ConditionType.FRIENDSHIP_UNDER:
			return FriendshipManager.get_friendship_level(npc_data) < condition.friendship_value

		DialogueCondition.ConditionType.QUEST_AVAILABLE:
			return QuestManager.is_quest_available(condition.quest_id)

		DialogueCondition.ConditionType.QUEST_ACTIVE:
			return QuestManager.is_quest_active(condition.quest_id)

		DialogueCondition.ConditionType.QUEST_READY_TO_TURN_IN:
			return QuestManager.is_quest_ready_to_turn_in(condition.quest_id)

		DialogueCondition.ConditionType.QUEST_COMPLETED:
			return QuestManager.is_quest_completed(condition.quest_id)

		_:
			push_warning("DialogueManager: unknown condition type '%s'" % str(condition.type))
			return false


# =========================================================
# Internal state
# =========================================================

func _clear_current_dialogue() -> void:
	current_npc_data = null
	current_dialogue_data = null
	current_branch = null
	current_node = null
