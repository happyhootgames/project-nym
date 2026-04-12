@tool
class_name Interactable
extends Area2D

# Text displayed in the interaction prompt ("Talk", "Harvest", "Cook"...)
@export var prompt_text: String = "Interagir"

func _ready() -> void:
	# Force this Area2D onto the interactable layer (layer 7) only.
	# Clears all other layers first to avoid misconfiguration in child scenes.
	collision_layer = 0
	set_collision_layer_value(7, true)
	
	# Interactables don't need to detect anything themselves — reset mask.
	collision_mask = 0
