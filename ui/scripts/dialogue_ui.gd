extends Control

@export var talking_texture_rect: TextureRect
@export var talking_name_label: Label
@export var dialogue_line_label: RichTextLabel
@export var choices_container: VBoxContainer

func _ready() -> void:
	# Receive node data directly from the signal — no DialogueManager reference needed
	GameEventBus.show_dialogue_node.connect(_on_show_dialogue_node)

func _on_show_dialogue_node(node: DialogueNode, npc_data: NPCData) -> void:
	# Update NPC portrait and name
	talking_texture_rect.texture = npc_data.sprite
	talking_name_label.text = tr(npc_data.name_key)
	
	# Display translated dialogue text
	dialogue_line_label.text = tr(node.translation_key)
	
	# Always show choices — there is always at least a "Leave" choice
	_generate_choices(node.choices)

func _generate_choices(choices: Array[DialogueChoice]) -> void:
	_clear_choices()
	
	var first_button: Button = null
	
	for choice in choices:
		var button := Button.new()
		
		# Use translated text
		button.text = tr(choice.translation_key)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_choice_clicked.bind(choice))
		
		choices_container.add_child(button)
		
		if first_button == null:
			first_button = button
	
	# Focus first button for gamepad/keyboard navigation
	if first_button != null:
		first_button.grab_focus()

func _clear_choices() -> void:
	# Use free() for immediate removal — queue_free() leaves nodes as children
	# until the next frame, which can cause issues if _generate_choices()
	# is called in the same frame.
	for child in choices_container.get_children():
		child.queue_free()

func _on_choice_clicked(choice: DialogueChoice) -> void:
	DialogueManager.choice_clicked(choice)
