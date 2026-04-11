extends Node

signal state_changed

enum State {
	EXPLORING,
	DIALOGUE,
	INVENTORY,
	MENU_WHEEL,
	SETTINGS
}

var _current_state: State = State.EXPLORING



func get_state() -> State:
	return _current_state

func get_state_as_string() -> String:
	for key in State.keys():
		if State[key] == _current_state:
			return key
	return "UNKNOWN"

func set_state(new_state: State) -> void:
	if _current_state == new_state:
		return

	_current_state = new_state
	state_changed.emit()
	_debug()

func reset() -> void:
	set_state(State.EXPLORING)

# ========================================================
# ======================== HELPERS =======================
# ========================================================

func is_exploring() -> bool:
	return _current_state == State.EXPLORING

func is_in_dialogue() -> bool:
	return _current_state == State.DIALOGUE

func is_in_inventory() -> bool:
	return _current_state == State.INVENTORY

func is_in_menu_wheel() -> bool:
	return _current_state == State.MENU_WHEEL

func is_in_settings() -> bool:
	return _current_state == State.SETTINGS

func _debug() -> void:
	print("🛠️ NEW STATE: ",get_state_as_string())
