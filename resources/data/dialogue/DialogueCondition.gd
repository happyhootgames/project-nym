extends Resource
class_name DialogueCondition

enum ConditionType {
	QUEST_AVAILABLE,
	QUEST_ACTIVE,
	QUEST_READY_TO_TURN_IN,
	QUEST_COMPLETED,
	FRIENDSHIP_AT_LEAST,
	FRIENDSHIP_UNDER
}

@export var type: ConditionType
@export var quest_id: String = ""
@export var friendship_value: int = 0
