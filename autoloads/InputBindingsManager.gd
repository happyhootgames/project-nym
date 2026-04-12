extends Node


# =========================================================
# CONFIGURATION
# =========================================================

# True = bindings by physical position (AZERTY/QWERTY agnostic).
# False = bindings by character (layout-dependent).
const USE_PHYSICAL_KEYS := true

# Actions exposed in the settings UI for rebinding.
# Key = action name, Value = display label.
const REMAPPABLE_ACTIONS := {
	"move_up":    "Haut",
	"move_down":  "Bas",
	"move_left":  "Gauche",
	"move_right": "Droite",
	"interact":   "Interagir",
	"inventory":  "Inventaire",
	"sprint":     "Sprint",
	"jump":       "Sauter",
	"dash":       "Dash",
}

# Default keyboard bindings — single source of truth.
# jump uses Space (next_dialogue removed — choices always handle dialogue flow).
# dash uses X — distinct from sprint (Shift) and interact (F).
const DEFAULT_KEYBOARD_BINDINGS := {
	"move_up":           KEY_W,
	"move_down":         KEY_S,
	"move_left":         KEY_A,
	"move_right":        KEY_D,
	"interact":          KEY_F,
	"inventory":         KEY_I,
	"sprint":            KEY_SHIFT,
	"open_menu_settings": KEY_ESCAPE,
	"jump":              KEY_SPACE,
	"dash":              KEY_X,
}

# Default joypad bindings — not rebindable, defined here for completeness.
const DEFAULT_JOYPAD_BINDINGS := {
	"interact":          [{"type": "joypad_button", "button": JOY_BUTTON_A}],
	"sprint":            [{"type": "joypad_button", "button": JOY_BUTTON_RIGHT_SHOULDER}],
	"inventory":         [{"type": "joypad_button", "button": JOY_BUTTON_Y}],
	"open_menu_settings":[{"type": "joypad_button", "button": JOY_BUTTON_START}],
	"ui_cancel":         [{"type": "joypad_button", "button": JOY_BUTTON_B}],
	"ui_accept":         [{"type": "joypad_button", "button": JOY_BUTTON_A}],
	"ui_select":         [{"type": "joypad_button", "button": JOY_BUTTON_A}],
	"jump":              [{"type": "joypad_button", "button": JOY_BUTTON_A}],
	"dash":              [{"type": "joypad_axis",   "axis":   JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}],
	"move_left":  [
		{"type": "joypad_axis",   "axis": JOY_AXIS_LEFT_X, "value": -1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_LEFT},
	],
	"move_right": [
		{"type": "joypad_axis",   "axis": JOY_AXIS_LEFT_X, "value": 1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_RIGHT},
	],
	"move_up": [
		{"type": "joypad_axis",   "axis": JOY_AXIS_LEFT_Y, "value": -1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_UP},
	],
	"move_down": [
		{"type": "joypad_axis",   "axis": JOY_AXIS_LEFT_Y, "value": 1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_DOWN},
	],
}


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	# Apply defaults first, then overlay any saved rebindings.
	#apply_default_bindings()
	SaveManager.data_loaded.connect(_load_bindings)


# =========================================================
# APPLY DEFAULTS
# =========================================================

# Resets all keyboard and joypad bindings to their defaults.
# Called on startup and exposed as "Reset controls" in the settings UI.
func apply_default_bindings() -> void:
	_apply_default_keyboard_bindings()
	_apply_default_joypad_bindings()


func _apply_default_keyboard_bindings() -> void:
	for action in DEFAULT_KEYBOARD_BINDINGS.keys():
		_ensure_action_exists(action)
		_clear_keyboard_events(action)
		InputMap.action_add_event(action, _make_key_event(DEFAULT_KEYBOARD_BINDINGS[action]))


func _apply_default_joypad_bindings() -> void:
	for action in DEFAULT_JOYPAD_BINDINGS.keys():
		_ensure_action_exists(action)
		for binding in DEFAULT_JOYPAD_BINDINGS[action]:
			var event := _make_joypad_event(binding)
			if event != null:
				InputMap.action_add_event(action, event)


# =========================================================
# REBIND (keyboard only)
# =========================================================

# Rebinds an action to a new key from a raw InputEventKey (e.g. captured via UI).
# Creates a clean copy to avoid side effects from the captured event.
func rebind_action(action: StringName, captured_event: InputEventKey) -> void:
	if not InputMap.has_action(action):
		push_warning("InputBindingsManager: action not found: %s" % action)
		return

	var clean_event := InputEventKey.new()
	clean_event.physical_keycode = captured_event.physical_keycode if USE_PHYSICAL_KEYS else 0
	clean_event.keycode          = 0 if USE_PHYSICAL_KEYS else captured_event.keycode
	clean_event.shift_pressed    = captured_event.shift_pressed
	clean_event.alt_pressed      = captured_event.alt_pressed
	clean_event.ctrl_pressed     = captured_event.ctrl_pressed
	clean_event.meta_pressed     = captured_event.meta_pressed
	clean_event.pressed          = false
	clean_event.echo             = false

	_clear_keyboard_events(action)
	InputMap.action_add_event(action, clean_event)

	_save_bindings()
	_debug()


# Resets all bindings to defaults and clears saved rebindings.
func reset_to_defaults() -> void:
	apply_default_bindings()
	_save_bindings()
	_debug()


# =========================================================
# CONFLICT DETECTION
# =========================================================

# Returns the name of the action already using this key, or &"" if none.
# Pass exclude_action to ignore the action currently being rebound.
func get_conflicting_action(key_event: InputEventKey, exclude_action: StringName = &"") -> StringName:
	for action in InputMap.get_actions():
		if action == exclude_action:
			continue
		for existing_event in InputMap.action_get_events(action):
			if existing_event is InputEventKey and _key_events_match(existing_event, key_event):
				return action
	return &""


# =========================================================
# LABEL HELPERS
# =========================================================

# Returns a human-readable label for the keyboard binding of an action.
# Example: "W", "Space", "X".
# Returns "Non assigné" if no keyboard binding exists.
func get_action_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "Non assigné"

	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.physical_keycode != 0:
				return OS.get_keycode_string(key_event.physical_keycode)
			elif key_event.keycode != 0:
				return OS.get_keycode_string(key_event.keycode)

	return "Non assigné"


# Returns the bound InputEventKey for an action, or null if none.
# Useful for the rebind UI to display the current binding.
func get_bound_key_event(action: StringName) -> InputEventKey:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event as InputEventKey
	return null


# =========================================================
# SAVE / LOAD
# =========================================================

# Persists current keyboard bindings for all remappable actions.
# Stored under SaveManager.data["settings"]["bindings"].
func _save_bindings() -> void:
	var bindings := {}
	for action in REMAPPABLE_ACTIONS.keys():
		var key_event := get_bound_key_event(action)
		if key_event == null:
			continue
		# Store physical keycode as int — layout-agnostic and JSON-serializable.
		bindings[action] = int(key_event.physical_keycode) if USE_PHYSICAL_KEYS \
			else int(key_event.keycode)

	SaveManager.data["settings"]["bindings"] = bindings
	SaveManager.save_game()


# Restores saved keyboard bindings on top of the defaults.
# Silently skips unknown or invalid entries.
func _load_bindings() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	var bindings: Dictionary = settings.get("bindings", {})

	for action in bindings.keys():
		if not REMAPPABLE_ACTIONS.has(action):
			continue

		var keycode := int(bindings[action]) as Key
		if keycode == KEY_NONE:
			continue

		_clear_keyboard_events(action)
		InputMap.action_add_event(action, _make_key_event(keycode))

	_debug()


# =========================================================
# INTERNAL UTILS
# =========================================================

# Creates an InputEventKey from a KEY_* constant.
func _make_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	if USE_PHYSICAL_KEYS:
		event.physical_keycode = keycode
	else:
		event.keycode = keycode
	event.pressed = false
	event.echo = false
	return event


# Creates a joypad InputEvent from a binding dictionary.
func _make_joypad_event(binding: Dictionary) -> InputEvent:
	match binding.get("type", ""):
		"joypad_button":
			var event := InputEventJoypadButton.new()
			event.button_index = binding.get("button", JOY_BUTTON_A)
			return event
		"joypad_axis":
			var event := InputEventJoypadMotion.new()
			event.axis = binding.get("axis", JOY_AXIS_LEFT_X)
			event.axis_value = binding.get("value", 1.0)
			return event
		_:
			return null


# Removes all keyboard events for an action, leaving joypad bindings intact.
func _clear_keyboard_events(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)


# Creates the action in InputMap if it does not already exist.
func _ensure_action_exists(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


# Returns true if two key events represent the same physical key and modifiers.
func _key_events_match(a: InputEventKey, b: InputEventKey) -> bool:
	return a.keycode          == b.keycode \
		and a.physical_keycode == b.physical_keycode \
		and a.shift_pressed    == b.shift_pressed \
		and a.alt_pressed      == b.alt_pressed \
		and a.ctrl_pressed     == b.ctrl_pressed \
		and a.meta_pressed     == b.meta_pressed


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	var readable := {}
	for action in REMAPPABLE_ACTIONS.keys():
		readable[action] = get_action_label(action)
	print_debug("⌨️ InputBindingsManager | %s" % readable)
