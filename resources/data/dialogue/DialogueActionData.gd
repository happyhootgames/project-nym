extends Resource
class_name DialogueActionData

enum Type {
	NEXT,
	CLOSE_DIALOGUE,
	ACCEPT_QUEST,
	TURN_IN_QUEST,
	INCREMENT_FRIENDSHIP,
	RECEIVE_ITEM_FROM_NPC,
	GIVE_ITEM_TO_NPC
}

@export var type: Type = Type.NEXT

@export var int_value: int = 0
@export var string_value: String = ""

@export var item_data: ItemData
@export var quest_id: String = ""

@export var next_node: DialogueNode
@export var error_node: DialogueNode
