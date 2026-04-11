extends CanvasLayer

@export var exploring_ui: Control
@export var dialogue_ui: Control
@export var inventory_ui: Control
@export var controls_menu_ui: Control

var _all_uis: Array[Control] = []

func _ready() -> void:
	PlayerStateManager.state_changed.connect(handle_state_change)
	_all_uis.append(exploring_ui)
	_all_uis.append(dialogue_ui)
	_all_uis.append(inventory_ui)
	_all_uis.append(controls_menu_ui)
	handle_state_change()

func handle_state_change() -> void:
	_hide_all_ui()
	if PlayerStateManager.is_exploring() or PlayerStateManager.is_in_menu_wheel():
		exploring_ui.visible = true
	elif PlayerStateManager.is_in_dialogue():
		dialogue_ui.visible = true
	elif PlayerStateManager.is_in_inventory():
		inventory_ui.visible = true
		inventory_ui.setup_view()
	elif PlayerStateManager.is_in_settings():
		controls_menu_ui.visible = true
		controls_menu_ui.setup_view()

func _hide_all_ui() -> void:
	for ui in _all_uis:
		ui.visible = false
