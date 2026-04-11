extends Node

var inventory: Dictionary

signal inventory_updated

func _ready() -> void:
	SaveManager.data_loaded.connect(load_data)

# ADD

func add_item_stacks(item_stacks: Array[ItemStack]) -> void:
	for stack in item_stacks:
		add_item_stack(stack)

func add_item_stack(item_stack: ItemStack) -> void:
	add_item_data(item_stack.item_data, item_stack.quantity)

func add_item_data(item_data: ItemData, quantity: int) -> void:
	if inventory.has(item_data):
		inventory[item_data] += quantity
	else:
		inventory[item_data] = quantity
	inventory_updated.emit()

# REMOVE

func remove_item_stacks(item_stacks: Array[ItemStack]) -> void:
	for stack in item_stacks:
		remove_item_stack(stack)

func remove_item_stack(item_stack: ItemStack) -> void:
	remove_item_data(item_stack.item_data, item_stack.quantity)
	
func remove_item_data(item_data: ItemData, quantity: int) -> void:
	inventory[item_data] -= quantity
	if inventory[item_data] < 0:
		inventory[item_data] = 0
	inventory_updated.emit()

# CHECKS

func has_enough_item_stacks(item_stacks: Array[ItemStack]) -> bool:
	for stack in item_stacks:
		if not has_enough_item_stack(stack):
			return false
	return true
	
func has_enough_item_stack(item_stack: ItemStack) -> bool:
	return has_enough_item_data(item_stack.item_data, item_stack.quantity)

func has_enough_item_data(item_data: ItemData, quantity: int) -> bool:
	if inventory.has(item_data):
		return inventory[item_data] >= quantity
	else:
		return false

# HELPERS

func get_quantity_of(item_data: ItemData) -> int:
	if inventory.has(item_data):
		return inventory[item_data]
	else:
		return 0


# SAVE

func save_data() -> Dictionary:
	var serialized_inventory: Dictionary = {}

	for item: ItemData in inventory.keys():
		# Skip invalid resources
		if item == null or item.resource_path.is_empty():
			continue

		serialized_inventory[item.resource_path] = inventory[item]

	return serialized_inventory


func load_data() -> void:
	inventory.clear()

	if not SaveManager.data.has("inventory"):
		return

	var saved_inventory: Dictionary = SaveManager.data["inventory"]

	for path in saved_inventory.keys():
		var item: ItemData = ResourceLoader.load(path) as ItemData

		# Skip invalid or missing resources
		if item == null:
			push_warning("InventoryManager: failed to load item at path: %s" % path)
			continue

		inventory[item] = int(saved_inventory[path])

	print("============================================")
	_debug()

func _debug() -> void:
	print("🎒 INVENTORY\n",JSON.stringify(inventory,'\t'))
