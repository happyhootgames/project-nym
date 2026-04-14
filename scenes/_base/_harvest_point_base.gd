extends StaticBody2D
class_name HarvestPointBase

@export var wind_component: WindComponent
@export var harvest_interactable: HarvestInteractable

func _ready() -> void:
	var is_impacted_by_wind = false
	#match harvest_interactable.harvest_point_data.type:
		#HarvestPointData.HarvestPointType.BUSH:
			#is_impacted_by_wind = true
		#HarvestPointData.HarvestPointType.TREE:
			#is_impacted_by_wind = true
		#HarvestPointData.HarvestPointType.FLOWER:
			#is_impacted_by_wind = true
	wind_component.impacted_by_wind = is_impacted_by_wind
