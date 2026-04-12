extends Node


# =========================================================
# SIGNALS
# =========================================================

signal state_changed


# =========================================================
# STATE
# =========================================================

enum State {
	EXPLORING,
	DIALOGUE,
	INVENTORY,
	SETTINGS,
	COOKING,   # Cooking mini-game — blocks all movement
	CRAFTING,  # Craft interface — similar to cooking
	CUTSCENE,  # Major spirit revelations
}

var _current_state: State = State.EXPLORING
var _previous_state: State = State.EXPLORING


# =========================================================
# PUBLIC API
# =========================================================

func get_state() -> State:
	return _current_state


# Sets a new state and stores the previous one for go_back().
func set_state(new_state: State) -> void:
	if _current_state == new_state:
		return
	_previous_state = _current_state
	_current_state = new_state
	state_changed.emit()
	#GameEventBus.player_state_changed.emit(new_state)
	
	_debug()


# Returns to the previous state — used by ui_cancel and end_dialogue.
func go_back() -> void:
	set_state(_previous_state)


# =========================================================
# HELPERS
# =========================================================

func is_exploring() -> bool:
	return _current_state == State.EXPLORING

func is_in_dialogue() -> bool:
	return _current_state == State.DIALOGUE

func is_in_inventory() -> bool:
	return _current_state == State.INVENTORY

func is_in_settings() -> bool:
	return _current_state == State.SETTINGS

func is_cooking() -> bool:
	return _current_state == State.COOKING

func is_crafting() -> bool:
	return _current_state == State.CRAFTING

func is_in_cutscene() -> bool:
	return _current_state == State.CUTSCENE


# =========================================================
# DEBUG
# =========================================================

# Returns the current state name as a readable string.
func get_state_as_string() -> String:
	return State.keys()[_current_state]


func _debug() -> void:
	print_debug("🛠️ PlayerStateManager | %s → %s" % [
		State.keys()[_previous_state],
		State.keys()[_current_state]
	])
