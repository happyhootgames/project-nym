class_name NPCData
extends Resource

@export var id: StringName = &""
@export var name_key: StringName = &""   # ex: &"NPC_VIVI_NAME" → npcs.csv
@export var display_name: String = ""    # fallback éditeur pendant le dev
@export var sprite: Texture2D
@export var dialogue: DialogueData
