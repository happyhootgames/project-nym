class_name NPC
extends CharacterBody2D


# =========================================================
# EXPORTS
# =========================================================

@export var npc_data: NPCData
@export var sprite_2d: Sprite2D
@export var name_anchor: Marker2D
@export var name_label: Label


# =========================================================
# STATE
# =========================================================

var has_quests_to_give: bool = false
var has_quests_to_receive: bool = false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	QuestManager.quest_status_updated.connect(_on_quests_updated)
	_apply_npc_data()


# =========================================================
# SETUP
# =========================================================

# Applies sprite and label from NPCData. Called once on ready.
func _apply_npc_data() -> void:
	if npc_data == null:
		return

	if sprite_2d and npc_data.sprite:
		sprite_2d.texture = npc_data.sprite
		_align_sprite_to_floor()

	refresh_label()


# Offsets the sprite so its bottom edge sits at the node origin (y = 0).
# This makes CollisionShape placement intuitive — origin = feet.
func _align_sprite_to_floor() -> void:
	if sprite_2d.texture == null:
		return

	var texture_height := float(sprite_2d.texture.get_height())

	# centered = true  → sprite draws centered, bottom at +height/2 → shift up by half.
	# centered = false → top-left at origin, bottom at +height → shift up by full height.
	sprite_2d.offset.y = -texture_height / 2.0 if sprite_2d.centered else -texture_height


# =========================================================
# LABEL
# =========================================================

# Updates the name label to reflect quest availability.
# ! = quest to give, ? = quest to turn in, name = no active quest.
func refresh_label() -> void:
	if npc_data == null:
		return

	if has_quests_to_give and not has_quests_to_receive:
		name_label.text = "!"
	elif has_quests_to_receive and not has_quests_to_give:
		name_label.text = "?"
	else:
		name_label.text = tr(npc_data.name_key) if npc_data.name_key != &"" else npc_data.display_name

	# Re-center label horizontally after text change — size updates after text is set.
	name_label.position.x = -name_label.size.x * 0.5


# =========================================================
# EVENTS
# =========================================================

func _on_quests_updated() -> void:
	has_quests_to_give = QuestManager.has_available_quest_for_giver(npc_data)
	has_quests_to_receive = QuestManager.has_quest_to_turn_in_for_receiver(npc_data)
	refresh_label()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("🐾 NPC | id: %s | quests_to_give: %s | quests_to_receive: %s" % [
		npc_data.id if npc_data else "null",
		has_quests_to_give,
		has_quests_to_receive,
	])
