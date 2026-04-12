extends Node


# =========================================================
# STATE
# =========================================================

var current_npc_data: NPCData = null
var current_dialogue_data: DialogueData = null
var current_branch: DialogueBranch = null
var current_node: DialogueNode = null


# =========================================================
# PUBLIC API
# =========================================================

# Finds the best dialogue entry for the given NPC and starts the conversation.
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

	current_node = current_branch.get_start_node()
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
	GameEventBus.show_dialogue_node.emit(current_node, current_npc_data)
	GameEventBus.camera_zoom.emit(true)


# Called when the player clicks a choice button.
func choice_clicked(choice: DialogueChoice) -> void:
	if choice == null:
		return
	execute_actions(choice.actions)


# Ends the current dialogue and restores previous game state.
func end_dialogue() -> void:
	_clear_current_dialogue()
	GameEventBus.end_dialogue.emit()
	PlayerStateManager.go_back()
	Input.flush_buffered_events()
	GameEventBus.camera_zoom.emit(false)


# =========================================================
# ACTIONS
# =========================================================

# Executes all actions attached to a choice, in order.
func execute_actions(actions: Array[DialogueActionData]) -> void:
	var npc_data := current_npc_data
	for action in actions:
		if action == null:
			continue
		_execute_action(action, npc_data)


func _execute_action(action: DialogueActionData, npc_data: NPCData) -> void:
	match action.type:

		DialogueActionData.Type.NEXT:
			if action.next_node == null:
				push_warning("DialogueManager: NEXT action has no next_node")
				end_dialogue()
				return
			current_node = action.next_node
			# Deferred so the current button signal finishes before the UI updates.
			GameEventBus.show_dialogue_node.emit.call_deferred(current_node, current_npc_data)

		DialogueActionData.Type.CLOSE_DIALOGUE:
			end_dialogue()

		DialogueActionData.Type.ACCEPT_QUEST:
			if not QuestManager.accept_quest(action.quest_id):
				_go_to_error_node_if_possible(action)

		DialogueActionData.Type.TURN_IN_QUEST:
			if not QuestManager.turn_in_quest(action.quest_id):
				_go_to_error_node_if_possible(action)

		DialogueActionData.Type.INCREMENT_FRIENDSHIP:
			if npc_data == null:
				push_warning("DialogueManager: INCREMENT_FRIENDSHIP with null npc_data")
				return
			FriendshipManager.increment_friendship_for(npc_data, action.increment_friendship_amount)

		DialogueActionData.Type.RECEIVE_ITEM_STACKS_FROM_NPC:
			InventoryManager.add_item_stacks(action.item_stacks)

		DialogueActionData.Type.GIVE_ITEM_STACKS_TO_NPC:
			if not InventoryManager.has_enough_item_data(action.item_data, action.int_value):
				_go_to_error_node_if_possible(action)
				return
			InventoryManager.remove_item_stacks(action.item_stacks)

		_:
			push_warning("DialogueManager: unknown action type '%s'" % str(action.type))


# Navigates to the error node of an action if one is set, otherwise does nothing.
func _go_to_error_node_if_possible(action: DialogueActionData) -> void:
	if action.error_node == null:
		return
	current_node = action.error_node
	GameEventBus.show_dialogue_node.emit(current_node, current_npc_data)


# =========================================================
# DIALOGUE SELECTION
# =========================================================

# Returns the most specific and highest priority valid entry for this NPC.
# Specificity = number of conditions. Ties broken by priority field.
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

			# More specific entries take priority.
			if a_conditions != b_conditions:
				return a_conditions > b_conditions

			# Tiebreak by explicit priority field.
			return a.priority > b.priority
		)

	return valid_entries[0]


# Returns true only if every condition in the entry is met.
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
# INTERNAL STATE
# =========================================================

func _clear_current_dialogue() -> void:
	current_npc_data = null
	current_dialogue_data = null
	current_branch = null
	current_node = null


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	var state := {
		"npc": current_npc_data.id if current_npc_data else &"null",
		"branch": current_branch.id if current_branch else &"null",
		"node": current_node.id if current_node else &"null",
		"node_text_key": current_node.translation_key if current_node else &"null",
	}
	print_debug("💬 DialogueManager | ", state)
