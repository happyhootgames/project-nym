# quest_instance.gd
extends RefCounted
class_name QuestInstance

enum Status {
	LOCKED,
	AVAILABLE,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED
}

var quest_data: QuestData
var status: Status = Status.LOCKED

func _init(data: QuestData) -> void:
	quest_data = data
