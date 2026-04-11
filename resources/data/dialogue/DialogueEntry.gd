extends Resource
class_name DialogueEntry

@export var id: String = ""
@export var priority: int = 0
@export var branch: DialogueBranch
@export var conditions: Array[DialogueCondition] = []
