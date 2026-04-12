extends Control


# =========================================================
# CONSTANTS
# =========================================================

# Mouse buttons blocked from being bound — too likely to be accidental.
const BLOCKED_MOUSE_BUTTONS := [
	MOUSE_BUTTON_LEFT,
	MOUSE_BUTTON_RIGHT,
]


# =========================================================
# REFERENCES
# =========================================================

# Container that holds one row per remappable action.
# Expected child structure per row: Label (action name) + Button (current binding).
@export var bindings_container: VBoxContainer
@export var reset_button: Button

# Template scene instantiated for each row.
# Must contain a Label (@export or findable by name) and a Button.
@export var binding_row_scene: PackedScene


# =========================================================
# STATE
# =========================================================

# The action currently waiting for a new input. Null when idle.
var _action_being_rebound: StringName = &""

# The button currently in "listening" state.
var _listening_button: Button = null


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	reset_button.pressed.connect(_on_reset_pressed)
	_build_binding_rows()


# =========================================================
# BUILD UI
# =========================================================

# Instantiates one row per remappable action and populates it.
func _build_binding_rows() -> void:
	for child in bindings_container.get_children():
		child.free()

	for action in InputBindingsManager.REMAPPABLE_ACTIONS.keys():
		var display_name: String = InputBindingsManager.REMAPPABLE_ACTIONS[action]
		var row: HBoxContainer = binding_row_scene.instantiate()

		# Expects the row scene to have a Label named "ActionLabel"
		# and a Button named "BindButton".
		var label := row.get_node("ActionLabel") as Label
		var button := row.get_node("BindButton") as Button

		label.text = display_name
		button.text = InputBindingsManager.get_action_label(action)

		# Capture action name in the lambda via closure.
		var action_name := action as StringName
		button.pressed.connect(func(): _start_listening(action_name, button))

		bindings_container.add_child(row)


# Refreshes all button labels to reflect current bindings.
# Called after a rebind or reset.
func _refresh_all_labels() -> void:
	var actions := InputBindingsManager.REMAPPABLE_ACTIONS.keys()
	var rows := bindings_container.get_children()

	for i in rows.size():
		if i >= actions.size():
			break
		var button := rows[i].get_node("BindButton") as Button
		button.text = InputBindingsManager.get_action_label(actions[i])


# =========================================================
# LISTENING STATE
# =========================================================

# Enters listening mode for a specific action.
# Highlights the button and waits for the next valid input.
func _start_listening(action: StringName, button: Button) -> void:
	# Cancel any previous listening session.
	if _listening_button != null:
		_stop_listening(false)

	_action_being_rebound = action
	_listening_button = button

	# Visual feedback — show the player we are waiting.
	button.text = "..."
	button.add_theme_color_override("font_color", Color.YELLOW)

	set_process_unhandled_input(true)


# Exits listening mode.
# If cancelled = true, restores the original label without rebinding.
func _stop_listening(cancelled: bool = false) -> void:
	if _listening_button != null:
		_listening_button.remove_theme_color_override("font_color")

		if cancelled:
			_listening_button.text = InputBindingsManager.get_action_label(_action_being_rebound)

	_action_being_rebound = &""
	_listening_button = null

	set_process_unhandled_input(false)


# =========================================================
# INPUT CAPTURE
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if _action_being_rebound == &"":
		return

	# Escape cancels the rebind.
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		_stop_listening(true)
		get_viewport().set_input_as_handled()
		return

	# Accept keyboard keys.
	if event is InputEventKey and event.pressed and not event.echo:
		_try_rebind(event)
		get_viewport().set_input_as_handled()
		return

	# Accept mouse side buttons only — left and right are blocked.
	if event is InputEventMouseButton and event.pressed:
		if (event as InputEventMouseButton).button_index in BLOCKED_MOUSE_BUTTONS:
			return
		_try_rebind(event)
		get_viewport().set_input_as_handled()
		return


# Attempts the rebind, handling conflicts before committing.
func _try_rebind(captured_event: InputEvent) -> void:
	var conflict := InputBindingsManager.get_conflicting_action(
		captured_event,
		_action_being_rebound
	)

	if conflict != &"":
		# Conflict found — show feedback and stay in listening mode.
		_show_conflict_feedback(conflict)
		return

	# No conflict — commit the rebind.
	InputBindingsManager.rebind_action(_action_being_rebound, captured_event)
	_stop_listening(false)
	_refresh_all_labels()


# =========================================================
# CONFLICT FEEDBACK
# =========================================================

# Briefly flashes the button red to signal a conflict.
# Does not exit listening mode — the player must choose a different key.
func _show_conflict_feedback(conflicting_action: StringName) -> void:
	if _listening_button == null:
		return

	var conflict_label: String = InputBindingsManager.REMAPPABLE_ACTIONS.get(
		conflicting_action,
		conflicting_action  # Fallback to raw action name if not in REMAPPABLE_ACTIONS
	)

	_listening_button.text = "Déjà utilisé : %s" % conflict_label
	_listening_button.add_theme_color_override("font_color", Color.RED)

	# Reset to listening state after a short delay.
	await get_tree().create_timer(1.2).timeout

	# Guard: user may have cancelled during the delay.
	if _listening_button != null:
		_listening_button.text = "..."
		_listening_button.add_theme_color_override("font_color", Color.YELLOW)


# =========================================================
# RESET
# =========================================================

func _on_reset_pressed() -> void:
	_stop_listening(true)
	InputBindingsManager.reset_to_defaults()
	_refresh_all_labels()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("🎛️ RebindUI | listening: %s | action: %s" % [
		_listening_button != null,
		_action_being_rebound,
	])
