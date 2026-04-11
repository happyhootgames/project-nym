extends Resource
class_name DialogueNode

@export var id: String = ""
@export_multiline var text: String = ""
@export var has_choices: bool = false
@export var choices: Array[DialogueChoice] = []
@export var actions: Array[DialogueActionData] = []
