extends Resource
class_name QuestCondition

enum Type {
	FRIENDSHIP_AT_LEAST,
	FRIENDSHIP_UNDER
}

@export var type: Type
@export var friendship_value: int = 0
