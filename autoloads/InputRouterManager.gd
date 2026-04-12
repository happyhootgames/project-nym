extends Node


# =========================================================
# SIGNALS
# =========================================================

# Emitted when the player triggers an interact action while exploring.
signal player_interact


# =========================================================
# INPUT HANDLING
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if not _is_valid_pressed_event(event) and not _is_valid_released_event(event):
		return

	# All other inputs require a clean press event.
	if not _is_valid_pressed_event(event):
		return

	_handle_gameplay_input(event)


func _handle_gameplay_input(event: InputEvent) -> void:

	if event.is_action_pressed("interact"):
		_route_interact()

	elif event.is_action_pressed("inventory"):
		if PlayerStateManager.is_in_inventory():
			PlayerStateManager.go_back()
		else:
			PlayerStateManager.set_state(PlayerStateManager.State.INVENTORY)

	elif event.is_action_pressed("open_menu_settings"):
		if PlayerStateManager.is_exploring():
			PlayerStateManager.set_state(PlayerStateManager.State.SETTINGS)
		elif PlayerStateManager.is_in_settings():
			PlayerStateManager.go_back()

	elif event.is_action_pressed("ui_cancel"):
		# Dialogue exit is handled by DialogueChoice — not by ui_cancel.
		if not PlayerStateManager.is_in_dialogue():
			PlayerStateManager.go_back()

	elif event.is_action_pressed("save_game"):
		SaveManager.save_game()

	else:
		return

	get_viewport().set_input_as_handled()


# =========================================================
# ROUTES
# =========================================================

# Dispatches the interact action based on the current game state.
func _route_interact() -> void:
	if PlayerStateManager.is_exploring():
		player_interact.emit()


# =========================================================
# INPUT VALIDATION
# =========================================================

# Returns true for any actionable press event (excludes key repeat).
func _is_valid_pressed_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return true
	return false


# Returns true for any actionable release event (excludes key repeat).
func _is_valid_released_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return not event.pressed and not event.echo
	if event is InputEventMouseButton:
		return not event.pressed
	if event is InputEventJoypadButton:
		return not event.pressed
	if event is InputEventJoypadMotion:
		return true
	return false
