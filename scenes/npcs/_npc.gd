extends CharacterBody2D

@export var name_label_y_offset: float = -300.0

@export var npc_data: NPCData
@export var sprite_2d: Sprite2D
@export var name_anchor: Marker2D
@export var name_label: Label
var has_quests_to_give: bool = false
var has_quests_to_receive: bool = false

func _ready() -> void:
	QuestManager.quest_status_updated.connect(_on_quests_update)
	_apply_npc_data()
	

func _apply_npc_data() -> void:
	if npc_data == null:
		return
	if sprite_2d and npc_data.sprite:
		sprite_2d.texture = npc_data.sprite
	refresh_label()

func interact() -> void:
	DialogueManager.start_dialogue_for_npc(npc_data)

func _on_quests_update() -> void:
	has_quests_to_give = QuestManager.has_available_quest_for_giver(npc_data)
	has_quests_to_receive = QuestManager.has_quest_to_turn_in_for_receiver(npc_data)
	refresh_label()

func refresh_label() -> void:
	var label_name: String = npc_data.show_name
	if has_quests_to_give and not has_quests_to_receive:
		label_name = "!"
	elif not has_quests_to_give and has_quests_to_receive:
		label_name = "?"
	name_label.text = label_name
	name_label.position = Vector2(-name_label.size.x * 0.6, name_label.position.y)
