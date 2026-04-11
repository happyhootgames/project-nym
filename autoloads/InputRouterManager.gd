extends Node

signal player_interact

func _unhandled_input(event: InputEvent) -> void:

	if not _is_valid_pressed_event(event):
		return

	if event.is_action_pressed("interact"):
		_route_interact()
	#elif event.is_action_pressed("next_dialogue"):
		#if PlayerStateManager.is_in_dialogue():
			#DialogueManager.next_line()
	elif event.is_action_pressed("inventory"):
		if PlayerStateManager.is_in_inventory():
			PlayerStateManager.reset()
		else:
			PlayerStateManager.set_state(PlayerStateManager.State.INVENTORY)
	elif event.is_action_pressed("open_menu_settings") and PlayerStateManager.is_exploring():
		PlayerStateManager.set_state(PlayerStateManager.State.SETTINGS)
	elif event.is_action_pressed("open_menu_settings") and PlayerStateManager.is_in_settings():
		PlayerStateManager.reset()
	elif event.is_action_pressed("ui_cancel"):
		if not PlayerStateManager.is_in_dialogue():
			PlayerStateManager.reset()
	elif event.is_action_pressed("save_game"):
		SaveManager.save_game()
	else:
		return

	get_viewport().set_input_as_handled()


# ========================================================
# ======================== ROUTES ========================
# ========================================================

func _route_interact() -> void:
	if PlayerStateManager.is_exploring():
		player_interact.emit()
	elif PlayerStateManager.is_in_dialogue():
		DialogueManager.next_line()


func _is_valid_pressed_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo

	if event is InputEventMouseButton:
		return event.pressed

	if event is InputEventJoypadButton:
		return event.pressed

	return false
