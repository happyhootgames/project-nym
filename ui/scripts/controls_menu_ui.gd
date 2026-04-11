extends Control

@export var actions_container: VBoxContainer
@export var status_label: Label
@export var reset_button: Button
@export var action_row_scene: PackedScene

var waiting_for_action: StringName = &""
var waiting_row: Control = null

func setup_view() -> void:
	_build_rows()

func _build_rows() -> void:
	for child in actions_container.get_children():
		child.queue_free()

	var first_row: Control = null
	for action_name in InputBindingsManager.REMAPPABLE_ACTIONS.keys():
		var row = action_row_scene.instantiate()
		
		var is_first = false
		if first_row == null:
			first_row = row
			is_first = true

		actions_container.add_child(row)

		row.setup(action_name, InputBindingsManager.REMAPPABLE_ACTIONS[action_name], is_first)
		row.rebind_requested.connect(_on_rebind_requested)

func _on_reset_to_default_button_pressed() -> void:
	InputBindingsManager.reset_to_defaults()
	_cancel_rebind()
	_refresh_all_rows()

func _on_rebind_requested(action_name: StringName) -> void:
	waiting_for_action = action_name
	waiting_row = _find_row_for_action(action_name)

	if waiting_row != null:
		waiting_row.set_waiting()

	status_label.text = "Press a key for: %s\nEsc to cancel" % InputBindingsManager.REMAPPABLE_ACTIONS[action_name]

func _find_row_for_action(action_name: StringName):
	for child in actions_container.get_children():
		if child.row_action_name == action_name:
			return child
	return null

func _unhandled_key_input(event: InputEvent) -> void:
	if waiting_for_action == &"":
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_ESCAPE:
		_cancel_rebind()
		get_viewport().set_input_as_handled()
		return

	InputBindingsManager.set_action_event(waiting_for_action, event)

	waiting_for_action = &""
	waiting_row = null
	_refresh_all_rows()
	_update_status_label()
	get_viewport().set_input_as_handled()

func _cancel_rebind() -> void:
	waiting_for_action = &""
	waiting_row = null
	_refresh_all_rows()
	_update_status_label()

func _update_status_label() -> void:
	status_label.text = "Select an action to rebind."

func _refresh_all_rows() -> void:
	for child in actions_container.get_children():
		if child.has_method("refresh"):
			child.refresh()
