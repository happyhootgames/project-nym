extends Resource
class_name HarvestPointData

enum HarvestPointType {
	BUSH,
	TREE,
	FLOWER,
	DEPOSIT
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var type: HarvestPointType
@export var loot_items: Array[ItemStack] = []
@export var respawn_time_in_seconds: int = 5
