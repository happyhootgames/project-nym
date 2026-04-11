extends Control

@export var quest_item_scene: PackedScene
@export var quests_container: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	QuestManager.quest_status_updated.connect(_on_quests_updated)
	build_quests()

func build_quests() -> void:
	clear_quests()
	var quests: Array[QuestInstance] = []
	var tracked_quest = QuestManager.get_tracked_quest();
	if tracked_quest != null:
		quests.append(tracked_quest)
		for quest in quests:
			var slot: QuestFollowupItemUI = quest_item_scene.instantiate()
			slot.setup(quest)
			quests_container.add_child(slot)

func clear_quests() -> void:
	for child in quests_container.get_children():
		child.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_quests_updated() -> void:
	print("SIGNAL QUESTS UPDATED")
	build_quests()
