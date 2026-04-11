extends Control

@export var helper_label: Label

func _ready() -> void:
	UIEvents.show_input_helper.connect(show_input_helper)
	UIEvents.hide_input_helper.connect(hide_input_helper)

func show_input_helper(action: String, key: String) -> void:
	if PlayerStateManager.is_exploring():
		helper_label.text = "%s %s" % [action, key]
		helper_label.visible = true

func hide_input_helper() -> void:
	helper_label.visible = false
