class_name HarvestInteractable
extends Interactable


# =========================================================
# EXPORTS
# =========================================================

@export var harvest_point_data: HarvestPointData
@export var _respawn_timer: Timer


# =========================================================
# STATE
# =========================================================

var _is_harvested: bool = false


# =========================================================
# INTERACTION
# =========================================================

# Harvests all loot items and despawns the point.
# Blocked if already harvested and waiting for respawn.
func interact() -> void:
	if _is_harvested:
		return

	InventoryManager.add_item_stacks(harvest_point_data.loot_items)
	_despawn()


# =========================================================
# SPAWN / DESPAWN
# =========================================================

# Hides the harvest point and starts the respawn countdown.
# The parent being hidden automatically removes this Area2D
# from the player's interactable detection pool.
func _despawn() -> void:
	_is_harvested = true
	get_parent().hide()
	_respawn_timer.start(harvest_point_data.respawn_time_in_seconds)


func _on_respawn_timer_timeout() -> void:
	_is_harvested = false
	get_parent().show()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("🌿 HarvestInteractable | harvested: %s | data: %s" % [
		_is_harvested,
		harvest_point_data.resource_path.get_file() if harvest_point_data else "null",
	])
