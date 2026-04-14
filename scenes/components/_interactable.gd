@tool
class_name Interactable
extends Area2D

# =============================================================================
# Interactable — Area2D placée en enfant d'un nœud possédant un CanvasGroup frère.
#
# Structure attendue :
#   ParentNode (Node2D)
#   ├── CanvasGroup          ← reçoit le shader de contour (material null par défaut)
#   │   └── Sprite2D         ← wind.gdshader ici, intact
#   └── Interactable         ← ce script (Area2D)
#
# Quand highlight() est appelé :
#   → on applique outline.gdshader sur le CanvasGroup
#   → le shader voit le sprite DÉJÀ déplacé par le vent → parfaite sync
#
# Quand unhighlight() est appelé :
#   → on retire le material du CanvasGroup (material = null)
# =============================================================================


@export var prompt_text: String = "Interagir"

## Couleur du contour — personnalisable par type d'interactable
@export var highlight_color: Color = Color(1.0, 0.95, 0.6, 1.0)

## Épaisseur du contour en pixels
@export var highlight_width: float = 2.0

@export var sprite: Sprite2D


# ─── Chemin du shader ─────────────────────────────────────────────────────────
const HIGHLIGHT_SHADER_PATH := "res://shaders/highlight.gdshader"

# ─── État interne ─────────────────────────────────────────────────────────────
#var _canvas_group: CanvasGroup = null
var _highlight_material: ShaderMaterial = null


# =============================================================================
# INIT
# =============================================================================

func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(7, true)
	collision_mask = 0

	if Engine.is_editor_hint():
		return

	##_canvas_group = _find_sibling_canvas_group()
	#if not _canvas_group:
		#push_warning("Interactable '%s' : aucun CanvasGroup frère trouvé." % name)
		#return

	# Le fit_margin ajoute du padding autour des enfants du CanvasGroup.
	# Sans ça, le contour est découpé au bord exact du sprite.
	#sprite.fit_margin = highlight_width + 2.0

	# Prépare le matériau à l'avance (évite un délai au premier highlight)
	_highlight_material = ShaderMaterial.new()
	_highlight_material.shader = load(HIGHLIGHT_SHADER_PATH)
	_highlight_material.set_shader_parameter("highlight_color", highlight_color)
	_highlight_material.set_shader_parameter("highlight_width", highlight_width)


### Cherche un CanvasGroup parmi les frères (enfants du même parent)
#func _find_sibling_canvas_group() -> CanvasGroup:
	#var parent := get_parent()
	#if not parent:
		#return null
	#for child in parent.get_children():
		#if child is CanvasGroup:
			#return child
	#return null


# =============================================================================
# HIGHLIGHT
# =============================================================================

## Active le contour — appelé par le Player quand c'est le plus proche
func highlight() -> void:
	#if not _canvas_group:
		#return
	sprite.material = _highlight_material


## Désactive le contour
func unhighlight() -> void:
	#if not _canvas_group:
		#return
	sprite.material = null
