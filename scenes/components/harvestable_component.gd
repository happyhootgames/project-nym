extends Node2D
class_name HarvestComponent

@export var harvestable_node: HarvestableNode
@export var loot_items: Array [ItemData]
@export var collision_shape: CollisionShape2D

@onready var respawn_timer: Timer = $RespawnTimer

func interact() -> void:
	harvest();

func harvest() -> void:
	for loot_item in loot_items:
		InventoryManager.add_item_data(loot_item, 1)
	despawn()

func despawn() -> void:
	get_parent().hide()
	collision_shape.set_deferred("disabled", true)
	respawn_timer.start(harvestable_node.respawn_time_in_seconds)

func respawn() -> void:
	get_parent().show()
	collision_shape.set_deferred("disabled", false)
