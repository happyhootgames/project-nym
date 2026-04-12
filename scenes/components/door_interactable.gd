class_name DoorInteractable
extends Interactable

# Pas besoin de parent_node_path — on remonte dans l'arbre
func interact() -> void:
	var door := get_parent() as Node2D
	if door == null:
		return
	door.interact()
