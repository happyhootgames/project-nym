extends Control

signal rebind_requested(action_name: StringName)

@export var action_label: Label
@export var rebind_button: Button

var row_action_name: StringName

func setup(action_name: StringName, display_name: String, is_first: bool) -> void:
	row_action_name = action_name
	action_label.text = display_name
	refresh()
	if is_first:
		grab_focus(false)

func refresh() -> void:
	rebind_button.text = InputBindingsManager.get_action_keyboard_label(row_action_name)


func _on_rebind_button_pressed() -> void:
	rebind_requested.emit(row_action_name)

func set_waiting() -> void:
	rebind_button.text = "..."
