extends Control

@export var talking_texture_rect: TextureRect
@export var talking_name_label: Label
@export var dialogue_line_label: RichTextLabel
@export var choices_container: VBoxContainer
@export var next_label: Label

func _ready() -> void:
	UIEvents.show_dialogue_node.connect(show_dialogue_node)

func show_dialogue_node() -> void:
	talking_texture_rect.texture = DialogueManager.current_npc_data.sprite
	talking_name_label.text = DialogueManager.current_npc_data.show_name
	dialogue_line_label.text = DialogueManager.current_node.text
	if DialogueManager.current_node.has_choices:
		choices_container.visible = true
		next_label.visible = false
		generate_choices(DialogueManager.current_node.choices)
	else:
		choices_container.visible = false
		next_label.visible = true
		

func generate_choices(choices: Array[DialogueChoice]) -> void:
	_clear_choices()

	var first_new_button: Button = null

	for choice in choices:
		var button := Button.new()

		# Show player response text
		button.text = choice.text

		# Fill width
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Connect click
		button.pressed.connect(choice_clicked.bind(choice))

		choices_container.add_child(button)

		# Save first created button
		if first_new_button == null:
			first_new_button = button

	# Focus first new button
	if first_new_button != null:
		first_new_button.grab_focus()

func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

func choice_clicked(choice: DialogueChoice) -> void:
	print(choice.text)
	DialogueManager.choice_clicked(choice)
