extends Control
class_name QuestFollowupItemUI

@export var quest_name_label: Label
@export var quest_status_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup(quest: QuestInstance) -> void:
	quest_name_label.text = quest.quest_data.title
	if quest.status == QuestInstance.Status.READY_TO_TURN_IN:
		quest_status_label.text = "Retourne voir "+quest.quest_data.receiver_npc.display_name
	else:
		var objectives: String = ""
		for stack in quest.quest_data.required_items:
			var quantity_in_inventory := InventoryManager.get_quantity_of(stack.item_data)
			if quantity_in_inventory > stack.quantity:
				objectives += stack.item_data.display_name + " " + str(stack.quantity) +"/"+ str(stack.quantity)
			else:
				objectives += stack.item_data.display_name + " " + str(quantity_in_inventory) +"/"+ str(stack.quantity)
			objectives += "\n"
		quest_status_label.text = objectives
