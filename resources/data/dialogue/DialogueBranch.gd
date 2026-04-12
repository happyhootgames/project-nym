@tool
class_name DialogueBranch
extends Resource

@export var id: StringName = &""
@export var start_node_id: StringName = &""
@export var nodes: Array[DialogueNode] = []

# Returns the designated start node, falling back to nodes[0] if unset.
func get_start_node() -> DialogueNode:
	if start_node_id != &"":
		var found := get_node(start_node_id)
		if found != null:
			return found
		push_warning("DialogueBranch '%s': start_node_id '%s' not found, falling back to nodes[0]" % [id, start_node_id])
	
	if nodes.is_empty():
		push_error("DialogueBranch '%s': has no nodes" % id)
		return null
	
	return nodes[0]

# Finds a node by ID in O(n) — acceptable for dialogue node counts.
func get_node(node_id: StringName) -> DialogueNode:
	for node in nodes:
		if node.id == node_id:
			return node
	return null

func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint() and start_node_id != &"":
		if get_node(start_node_id) == null:
			push_warning("DialogueBranch '%s': start_node_id '%s' doesn't match any node" % [id, start_node_id])
