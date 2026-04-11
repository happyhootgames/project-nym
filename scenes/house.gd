extends Node2D
class_name House

signal is_inside_a_house(bool)

@export var outside_sprite: Sprite2D
@export var inside_sprite: Sprite2D
@export var interior_collisions: Array[CollisionShape2D]
#@export var animation_player: AnimationPlayer

var is_inside: bool = false

func enter_house() -> void:
	if is_inside:
		return
	is_inside = true
	outside_sprite.visible = false
	set_collisions_enabled(interior_collisions, true)
	is_inside_a_house.emit(true)
	UIEvents.camera_zoom.emit(true)

func exit_house() -> void:
	if not is_inside:
		return
	is_inside = false
	outside_sprite.visible = true
	set_collisions_enabled(interior_collisions, false)
	is_inside_a_house.emit(false)
	UIEvents.camera_zoom.emit(false)

func set_collisions_enabled(collisions: Array[CollisionShape2D], enabled: bool) -> void:
	for collision in collisions:
		collision.process_mode = Node.PROCESS_MODE_INHERIT
		collision.set_deferred("disabled", not enabled)

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("interact"):
		#if is_inside:
			#exit_house()
		#else:
			#enter_house()

#var player_in_range: bool = false
#
#func _on_door_interaction_body_entered(body: Node2D) -> void:
		#player_in_range = true
#
#func _on_door_interaction_body_exited(body: Node2D) -> void:
		#player_in_range = false
