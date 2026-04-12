extends Node2D
class_name Door

@export var parent_house: House

func interact() -> void:
	if parent_house.is_inside:
		parent_house.exit_house()
	else:
		parent_house.enter_house()
