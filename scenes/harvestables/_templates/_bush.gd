extends StaticBody2D
class_name Bush

@export var harvest_component: HarvestComponent

func interact() -> void:
	harvest_component.interact()
