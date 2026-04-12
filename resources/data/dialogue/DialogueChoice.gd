extends Resource
class_name DialogueChoice

@export var translation_key: StringName = &""   # ex: &"CHOICE_LEAVE"
@export var text: String = ""                    # fallback éditeur
@export var actions: Array[DialogueActionData] = []

func get_text() -> String:
	if translation_key != &"":
		return tr(translation_key)
	return text
