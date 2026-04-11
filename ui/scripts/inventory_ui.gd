extends Control

@export var slot_scene: PackedScene
@export var grid_container: GridContainer

var first_slot: InventorySlotUI

func setup_view() -> void:
	clear_grid()

	var inventory_dict: Dictionary = InventoryManager.inventory
	var entries: Array = []

	for item in inventory_dict.keys():
		var quantity: int = inventory_dict[item]
		if item == null or quantity <= 0:
			continue

		entries.append({
			"item": item,
			"quantity": quantity
		})

	## tri optionnel pour un affichage stable
	#entries.sort_custom(_sort_entries)

	for entry in entries:
		var slot: InventorySlotUI = slot_scene.instantiate()
		grid_container.add_child(slot)
		if first_slot == null:
			first_slot = slot
		slot.setup(entry["item"], entry["quantity"])
	if first_slot != null:
		first_slot.grab_focus(false)

func clear_grid() -> void:
	first_slot = null
	for child in grid_container.get_children():
		child.queue_free()
