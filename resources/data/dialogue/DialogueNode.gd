extends Resource
class_name DialogueNode

@export var id: StringName = &""
@export var translation_key: StringName = &""   # ex: &"VIVI_INTRO_01"
@export_multiline var text: String = ""          # texte FR — fallback éditeur
@export var choices: Array[DialogueChoice] = []  # toujours au moins un choix

# Returns translated text, falling back to raw text during development.
func get_text() -> String:
	if translation_key != &"":
		return tr(translation_key)
	return text
