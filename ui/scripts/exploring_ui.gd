extends Control

@export var helper_label: Label

func _ready() -> void:
	GameEventBus.show_input_helper.connect(show_input_helper)
	GameEventBus.hide_input_helper.connect(hide_input_helper)

func show_input_helper(action_name: String) -> void:
	var key = InputBindingsManager.get_action_label(action_name)
	if PlayerStateManager.is_exploring():
		helper_label.text = "Press "+key
		helper_label.visible = true

func hide_input_helper() -> void:
	helper_label.visible = false
