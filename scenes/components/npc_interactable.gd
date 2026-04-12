@tool
class_name NPCInteractable
extends Interactable

# Pas besoin de parent_node_path — on remonte dans l'arbre
func interact() -> void:
	var npc := get_parent() as NPC
	if npc == null:
		return
	DialogueManager.start_dialogue_for_npc(npc.npc_data)
