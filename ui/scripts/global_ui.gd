extends CanvasLayer


# =========================================================
# REFERENCES
# =========================================================

@export var exploring_ui: Control
@export var dialogue_ui: Control
@export var inventory_ui: Control
@export var settings_ui: Control

# Future UIs — add here as they are created.
# @export var cooking_ui: Control
# @export var crafting_ui: Control
# @export var cutscene_ui: Control


# =========================================================
# STATE
# =========================================================

var _all_uis: Array[Control] = []


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	_all_uis = [exploring_ui, dialogue_ui, inventory_ui, settings_ui]

	# Use GameEventBus — UI should not know PlayerStateManager directly.
	#GameEventBus.player_state_changed.connect(_on_state_changed)
	PlayerStateManager.state_changed.connect(_on_state_changed)

	# Apply correct UI visibility for the initial state.
	_on_state_changed()


# =========================================================
# STATE ROUTING
# =========================================================

# Shows the UI panel matching the new game state.
# All panels are hidden first, then the relevant one is shown.
func _on_state_changed() -> void:
	var new_state := PlayerStateManager.get_state()
	_hide_all()

	match new_state:
		PlayerStateManager.State.EXPLORING:
			exploring_ui.visible = true

		PlayerStateManager.State.DIALOGUE:
			dialogue_ui.visible = true

		PlayerStateManager.State.INVENTORY:
			inventory_ui.visible = true
			inventory_ui.setup_view()

		PlayerStateManager.State.SETTINGS:
			settings_ui.visible = true
			settings_ui._build_binding_rows()

		# PlayerStateManager.State.COOKING:
		#     cooking_ui.visible = true
		#     cooking_ui.setup_view()

		# PlayerStateManager.State.CRAFTING:
		#     crafting_ui.visible = true
		#     crafting_ui.setup_view()

		# PlayerStateManager.State.CUTSCENE:
		#     cutscene_ui.visible = true


func _hide_all() -> void:
	for ui in _all_uis:
		ui.visible = false


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	var visible_uis := _all_uis.filter(func(ui: Control) -> bool: return ui.visible)
	print_debug("🖥️ UIRouter | state: %s | visible: %s" % [
		PlayerStateManager.get_state_as_string(),
		visible_uis.map(func(ui: Control) -> String: return ui.name),
	])
