extends Resource
class_name QuestData

@export var id: String = ""
@export var title: String = ""
@export_multiline() var description: String = ""
@export var giver_npc: NPCData
@export var receiver_npc: NPCData
@export var unlock_conditions: Array[QuestCondition] = []

@export var required_items: Array[ItemStack] = []
@export var reward_items: Array[ItemStack] = []
@export var increment_friendship_amount: int = 0

@export var auto_track: bool = true
