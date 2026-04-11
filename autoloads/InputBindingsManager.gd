extends Node

const USE_PHYSICAL_KEYS := true

const DEFAULT_KEYBOARD_BINDINGS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_F,
	"inventory": KEY_I,
	"next_dialogue": KEY_SPACE,
	"sprint": KEY_SHIFT,
	"open_menu_settings": KEY_ESCAPE
}

const DEFAULT_JOYPAD_BINDINGS := {
	"interact": [
		{"type": "joypad_button", "button": JOY_BUTTON_A},
	],
	"sprint": [
		{"type": "joypad_button", "button": JOY_BUTTON_RIGHT_SHOULDER},
	],
	"inventory": [
		{"type": "joypad_button", "button": JOY_BUTTON_Y},
	],
	"open_menu_settings": [
		{"type": "joypad_button", "button": JOY_BUTTON_START},
	],
	"ui_cancel": [
		{"type": "joypad_button", "button": JOY_BUTTON_B},
	],
	"ui_accept": [
		{"type": "joypad_button", "button": JOY_BUTTON_A},
	],
	"ui_select": [
		{"type": "joypad_button", "button": JOY_BUTTON_A},
	],
	"move_left": [
		{"type": "joypad_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_LEFT},
	],
	"move_right": [
		{"type": "joypad_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_RIGHT},
	],
	"move_up": [
		{"type": "joypad_axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_UP},
	],
	"move_down": [
		{"type": "joypad_axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0},
		{"type": "joypad_button", "button": JOY_BUTTON_DPAD_DOWN},
	],
	"jump": [
		{"type": "joypad_button", "button": JOY_BUTTON_A},
	],
	"dash": [
		{"type": "joypad_button", "button": JOY_AXIS_TRIGGER_RIGHT},
	]
}

const REMAPPABLE_ACTIONS := {
	"move_up": "Haut",
	"move_down": "Bas",
	"move_left": "Gauche",
	"move_right": "Droite",
	"interact": "Interagir",
	"inventory": "Inventaire",
	"sprint": "Sprint",
}

# ========================================================
# ========================= INIT =========================
# ========================================================

# Appelé au démarrage du jeu.
# Initialise les bindings clavier à partir du dictionnaire DEFAULT_KEYBOARD_BINDINGS.
# Cela écrase les bindings clavier existants pour ces actions.
func _ready() -> void:
	pass
	#apply_default_bindings()

func apply_default_bindings() -> void:
	apply_default_keyboard_bindings()
	apply_default_joypad_bindings()

# Applique les bindings définis dans DEFAULT_KEYBOARD_BINDINGS.
# Pour chaque action :
# - s'assure que l'action existe dans InputMap
# - supprime tous les bindings clavier existants
# - ajoute le binding clavier par défaut
#
# Source unique de vérité pour la configuration initiale.
func apply_default_keyboard_bindings() -> void:
	for action in DEFAULT_KEYBOARD_BINDINGS.keys():
		_ensure_action_exists(action)
		_clear_keyboard_events(action)

		var event := _make_key_event(DEFAULT_KEYBOARD_BINDINGS[action])
		InputMap.action_add_event(action, event)

func apply_default_joypad_bindings() -> void:
	for action in DEFAULT_JOYPAD_BINDINGS.keys():
		_ensure_action_exists(action)

		for binding in DEFAULT_JOYPAD_BINDINGS[action]:
			var event := _make_extra_event(binding)
			if event != null:
				InputMap.action_add_event(action, event)

func _make_extra_event(binding: Dictionary) -> InputEvent:
	match binding.get("type", ""):
		"mouse_button":
			var event := InputEventMouseButton.new()
			event.button_index = binding.get("button", MOUSE_BUTTON_LEFT)
			return event

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



# ========================================================
# ======================= REBIND =========================
# ========================================================

# Remplace le binding clavier d'une action avec une nouvelle touche.
#
# Paramètres :
# - action : nom de l'action InputMap
# - new_keycode : constante KEY_* (ex: KEY_F)
#
# Fonctionnement :
# - supprime les anciens bindings clavier de l'action
# - crée un nouvel InputEventKey propre
# - l'ajoute à l'InputMap
#
# Note : ne gère pas les conflits entre actions.
func rebind_action(action: StringName, new_keycode: Key) -> void:
	if not InputMap.has_action(action):
		push_warning("InputBindings: action introuvable : %s" % action)
		return

	_clear_keyboard_events(action)

	var event := _make_key_event(new_keycode)
	InputMap.action_add_event(action, event)

# Réinitialise tous les bindings gérés par cet autoload
# en réappliquant DEFAULT_KEYBOARD_BINDINGS.
# Utile pour un bouton "Reset contrôles".
func reset_to_defaults() -> void:
	apply_default_bindings()

# Assigne une action à partir d'un InputEventKey existant (ex: capturé via UI).
#
# Fonctionnement :
# - crée une copie "propre" de l'événement (évite effets de bord)
# - copie uniquement les propriétés utiles :
#   - keycode OU physical_keycode (selon config)
#   - modificateurs (shift, ctrl, etc.)
# - force pressed = false et echo = false
# - remplace les bindings clavier existants pour l'action
#
# Cas d’usage :
# - rebind dynamique depuis un menu de configuration
func set_action_event(action: StringName, event: InputEventKey) -> void:
	if not InputMap.has_action(action):
		push_warning("InputBindings: action introuvable : %s" % action)
		return

	var clean_event := InputEventKey.new()

	if USE_PHYSICAL_KEYS:
		clean_event.physical_keycode = event.physical_keycode
	else:
		clean_event.keycode = event.keycode

	clean_event.shift_pressed = event.shift_pressed
	clean_event.alt_pressed = event.alt_pressed
	clean_event.ctrl_pressed = event.ctrl_pressed
	clean_event.meta_pressed = event.meta_pressed
	clean_event.pressed = false
	clean_event.echo = false

	_clear_keyboard_events(action)
	InputMap.action_add_event(action, clean_event)

# Retourne une représentation texte de la touche associée à une action.
#
# Exemple : "W", "E", "Space"
#
# Priorité :
# - physical_keycode (si utilisé)
# - sinon keycode
#
# Retourne "Non assigné" si aucun binding clavier trouvé.
#
# Utilisé pour afficher les contrôles dans l'UI.
func get_action_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "Non assigné"

	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey

			if key_event.physical_keycode != 0:
				return key_event.as_text_physical_keycode()
			elif key_event.keycode != 0:
				return key_event.as_text_keycode()

	return "Non assigné"

# Retourne le premier InputEventKey associé à une action.
#
# Utile pour :
# - inspection avancée
# - comparaison
# - debug
#
# Retourne null si aucun binding clavier n'existe.
func get_bound_key_event(action: StringName) -> InputEventKey:
	if not InputMap.has_action(action):
		return null

	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event as InputEventKey

	return null

# Vérifie si une touche est déjà utilisée par une autre action.
#
# Paramètres :
# - key_event : touche à tester
# - exclude_action : action à ignorer (utile pendant un rebind)
#
# Retour :
# - nom de l'action en conflit si trouvée
# - "" sinon
#
# Permet de gérer les conflits de touches dans l'UI.
func is_key_already_used(key_event: InputEventKey, exclude_action: StringName = &"") -> StringName:
	for action in InputMap.get_actions():
		if action == exclude_action:
			continue

		for existing_event in InputMap.action_get_events(action):
			if existing_event is InputEventKey and _key_events_match(existing_event, key_event):
				return action

	return &""



# ========================================================
# ======================== UTILS =========================
# ========================================================

# Vérifie que l'action existe dans InputMap.
# Si elle n'existe pas, elle est créée.
#
# Sécurité pour éviter les erreurs si une action est absente.
func _ensure_action_exists(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

# Supprime tous les InputEventKey associés à une action.
#
# Important :
# - ne supprime PAS les autres types d'inputs (manette, souris)
#
# Utilisé avant d'appliquer un nouveau binding clavier.
func _clear_keyboard_events(action: StringName) -> void:
	var events := InputMap.action_get_events(action)

	for event in events:
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)

# Crée un InputEventKey propre à partir d'une constante KEY_*.
#
# Selon USE_PHYSICAL_KEYS :
# - assigne physical_keycode (recommandé pour jeux)
# - OU keycode (layout clavier)
#
# Initialise :
# - pressed = false
# - echo = false
#
# Méthode utilitaire interne.
func _make_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()

	if USE_PHYSICAL_KEYS:
		event.physical_keycode = keycode
	else:
		event.keycode = keycode

	event.pressed = false
	event.echo = false
	return event

# Compare deux InputEventKey pour vérifier s'ils représentent la même touche.
#
# Compare :
# - keycode
# - physical_keycode
# - modificateurs (shift, ctrl, alt, meta)
#
# Utilisé pour détecter les conflits de touches.
func _key_events_match(a: InputEventKey, b: InputEventKey) -> bool:
	return (
		a.keycode == b.keycode
		and a.physical_keycode == b.physical_keycode
		and a.shift_pressed == b.shift_pressed
		and a.alt_pressed == b.alt_pressed
		and a.ctrl_pressed == b.ctrl_pressed
		and a.meta_pressed == b.meta_pressed
	)


func get_action_keyboard_label(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey

			if key_event.physical_keycode != 0:
				return OS.get_keycode_string(key_event.physical_keycode)
			elif key_event.keycode != 0:
				return OS.get_keycode_string(key_event.keycode)

	return ""
