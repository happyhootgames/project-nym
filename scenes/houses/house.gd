class_name House
extends Node2D


# =========================================================
# SIGNALS
# =========================================================

# Emitted when the player enters or exits this house.
signal is_inside_a_house(inside: bool)


# =========================================================
# EXPORTS
# =========================================================

@export var outside_sprite: Sprite2D
@export var inside_sprite: Sprite2D

# Collision shapes that are only active when the player is inside.
@export var interior_collisions: Array[CollisionShape2D]


# =========================================================
# STATE
# =========================================================

var is_inside: bool = false


# =========================================================
# PUBLIC API
# =========================================================

func enter_house() -> void:
	if is_inside:
		return

	is_inside = true
	outside_sprite.visible = false
	_set_interior_collisions(true)
	is_inside_a_house.emit(true)
	GameEventBus.camera_zoom.emit(true)


func exit_house() -> void:
	if not is_inside:
		return

	is_inside = false
	outside_sprite.visible = true
	_set_interior_collisions(false)
	is_inside_a_house.emit(false)
	GameEventBus.camera_zoom.emit(false)


# =========================================================
# INTERNAL
# =========================================================

# Enables or disables all interior collision shapes.
# Uses set_deferred to avoid modifying physics state mid-frame.
func _set_interior_collisions(enabled: bool) -> void:
	for collision in interior_collisions:
		collision.process_mode = Node.PROCESS_MODE_INHERIT
		collision.set_deferred("disabled", not enabled)


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("🏠 House | is_inside: %s" % is_inside)
