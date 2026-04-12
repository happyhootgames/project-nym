extends Resource
class_name DialogueActionData

enum Type {
	NEXT,
	CLOSE_DIALOGUE,
	ACCEPT_QUEST,
	TURN_IN_QUEST,
	INCREMENT_FRIENDSHIP,
	RECEIVE_ITEM_STACKS_FROM_NPC,
	GIVE_ITEM_STACKS_TO_NPC
}

@export var type: Type = Type.NEXT

@export var item_stacks: Array[ItemStack]
@export var quest_id: StringName = &""
@export var increment_friendship_amount: int

@export var next_node: DialogueNode
@export var error_node: DialogueNode
