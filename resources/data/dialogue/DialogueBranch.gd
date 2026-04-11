class_name DialogueBranch
extends Resource

@export var id: String = ""
@export var start_node_id: String = ""
@export var nodes: Array[DialogueNode] = []

func get_node(node_id: String) -> DialogueNode:
	for node in nodes:
		if node.id == node_id:
			return node
	return null
