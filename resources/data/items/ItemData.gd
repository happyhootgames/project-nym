class_name ItemData
extends Resource

@export var id: StringName = &""
@export var display_name: String
@export var icon: Texture2D
@export var category: ItemCategoryData
#@export_multiline var description: String = ""
#@export var max_stack_size: int = 99
#@export var sell_value: int = 0
#@export var tags: Array[StringName] = []
#@export var placeable_scene: PackedScene
