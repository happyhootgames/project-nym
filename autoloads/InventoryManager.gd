extends Node


# =========================================================
# SIGNALS
# =========================================================

signal inventory_updated


# =========================================================
# STATE
# =========================================================

var inventory: Dictionary = {}


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	SaveManager.data_loaded.connect(load_data)


# =========================================================
# ADD
# =========================================================

# Adds multiple item stacks to the inventory at once.
func add_item_stacks(item_stacks: Array[ItemStack]) -> void:
	for stack in item_stacks:
		add_item_stack(stack)


func add_item_stack(item_stack: ItemStack) -> void:
	add_item_data(item_stack.item_data, item_stack.quantity)


# Adds a quantity of an item. Creates the entry if it does not exist yet.
func add_item_data(item_data: ItemData, quantity: int) -> void:
	var is_new_item := not inventory.has(item_data)

	if is_new_item:
		inventory[item_data] = quantity
	else:
		inventory[item_data] += quantity

	# Notify journal when an item is seen for the first time.
	#if is_new_item:
		#GameEventBus.journal_entry_added.emit(item_data.category, item_data.id)

	inventory_updated.emit()


# =========================================================
# REMOVE
# =========================================================

# Removes multiple item stacks from the inventory at once.
func remove_item_stacks(item_stacks: Array[ItemStack]) -> void:
	for stack in item_stacks:
		remove_item_stack(stack)


func remove_item_stack(item_stack: ItemStack) -> void:
	remove_item_data(item_stack.item_data, item_stack.quantity)


# Removes a quantity of an item. Clamps to 0 — never goes negative.
func remove_item_data(item_data: ItemData, quantity: int) -> void:
	if not inventory.has(item_data):
		push_warning("InventoryManager: tried to remove item not in inventory: %s" % item_data.id)
		return
	inventory[item_data] = max(inventory[item_data] - quantity, 0)
	inventory_updated.emit()


# =========================================================
# CHECKS
# =========================================================

# Returns true only if every stack in the array is available in sufficient quantity.
func has_enough_item_stacks(item_stacks: Array[ItemStack]) -> bool:
	for stack in item_stacks:
		if not has_enough_item_stack(stack):
			return false
	return true


func has_enough_item_stack(item_stack: ItemStack) -> bool:
	return has_enough_item_data(item_stack.item_data, item_stack.quantity)


func has_enough_item_data(item_data: ItemData, quantity: int) -> bool:
	return inventory.get(item_data, 0) >= quantity


# =========================================================
# HELPERS
# =========================================================

# Returns the current quantity of an item. Returns 0 if not in inventory.
func get_quantity_of(item_data: ItemData) -> int:
	return inventory.get(item_data, 0)


# =========================================================
# SAVE / LOAD
# =========================================================

# Serializes inventory using resource paths as stable string keys.
func save_data() -> Dictionary:
	var serialized: Dictionary = {}
	for item: ItemData in inventory.keys():
		if item == null or item.resource_path.is_empty():
			continue
		serialized[item.resource_path] = inventory[item]
	return serialized


# Restores inventory by reloading each ItemData resource from its saved path.
func load_data() -> void:
	inventory.clear()

	var saved: Dictionary = SaveManager.data.get("inventory", {})

	for path in saved.keys():
		var item := ResourceLoader.load(path) as ItemData
		if item == null:
			push_warning("InventoryManager: failed to load item at path: %s" % path)
			continue
		inventory[item] = int(saved[path])

	_debug()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	var readable := {}
	for item: ItemData in inventory.keys():
		readable[item.resource_path.get_file()] = inventory[item]
	print_debug("🎒 InventoryManager | ", readable)
