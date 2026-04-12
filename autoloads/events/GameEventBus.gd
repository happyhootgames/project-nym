extends Node

signal show_input_helper(action_name: String)
signal hide_input_helper

signal show_dialogue_node(node: DialogueNode, npc_data: NPCData)
signal end_dialogue

signal camera_zoom(is_zooming: bool)

func _ready() -> void:
	if OS.is_debug_build():
		_connect_debug_logger()

func _connect_debug_logger() -> void:
	for sig_info in get_signal_list():
		var sig_name: String = sig_info["name"]
		var arg_count: int = sig_info["args"].size()

		# Build a lambda matching the signal's arity.
		# The lambda ignores the signal arguments — we only care about the name.
		var callable: Callable
		match arg_count:
			0: callable = func(): _log(sig_name)
			1: callable = func(_a): _log(sig_name)
			2: callable = func(_a, _b): _log(sig_name)
			3: callable = func(_a, _b, _c): _log(sig_name)
			_: callable = func(): _log(sig_name)

		connect(sig_name, callable)

func _log(sig_name: String) -> void:
	print("📡 [GameEventBus] → %s" % sig_name)
	
#
## =========================================================
## UI — HELPERS & FEEDBACK
## =========================================================
#signal show_input_helper(action_name: String)
#signal hide_input_helper
#signal show_notification(text: String)
#
## =========================================================
## UI — DIALOGUE & MENUS
## =========================================================
#signal show_dialogue_node
#signal end_dialogue
#signal show_menu_wheel(show: bool)
#signal confirm_choice_in_menu_wheel
#
## =========================================================
## UI — CAMERA
## =========================================================
#signal camera_zoom(is_zooming: bool)
#
## =========================================================
## PLAYER — ÉTAT & MOUVEMENTS
## =========================================================
#signal player_state_changed(new_state: int)
#signal stamina_changed(current: float, max: float)
#
## =========================================================
## WORLD — TEMPS & MÉTÉO
## =========================================================
#signal time_changed(hour: int)
#signal day_changed(day: int)
#signal weather_changed(new_weather: StringName)
#
## =========================================================
## CUISINE & CRAFT
## =========================================================
#signal recipe_discovered(recipe_id: StringName)
#signal dish_cooked(dish_id: StringName)
#signal item_crafted(item_id: StringName)
#
## =========================================================
## ESPRITS
## =========================================================
#signal minor_spirit_discovered(spirit_id: StringName)
#signal minor_spirit_friendship_changed(spirit_id: StringName, level: int)
#signal major_spirit_awakened(spirit_id: StringName)
#
## =========================================================
## INVENTAIRE & ÉCONOMIE
## =========================================================
#signal inventory_changed
#signal gold_changed(new_amount: int)
#signal item_collected(item_id: StringName, quantity: int)
#
## =========================================================
## PROGRESSION & COLLECTIONS
## =========================================================
#signal journal_entry_added(category: StringName, entry_id: StringName)
#signal quest_updated(quest_id: StringName)
