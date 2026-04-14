class_name ItemData
extends Resource

# =============================================================================
# ItemData — Resource de base pour tous les items du jeu
# Crée un fichier .tres par item dans res://resources/items/
# =============================================================================

# ─── Identité ────────────────────────────────────────────────────────────────

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var category: ItemCategoryData

# ─── Économie ────────────────────────────────────────────────────────────────

## Prix d'achat chez un vendeur (en noisettes d'or).
## Mettre à 0 si cet item n'est vendu par aucun marchand.
@export var buy_price: int = 0

## Prix de vente quand le joueur revend l'item à un marchand.
## Conventionnellement 40-60% du buy_price, mais peut être 0 si non revendable.
@export var sell_price: int = 0

## Si false, le joueur ne peut pas vendre cet item (quêtes, clés, items uniques…)
@export var is_sellable: bool = true

# ─── À décommenter quand les systèmes seront prêts ───────────────────────────

#@export_multiline var description: String = ""
#@export var max_stack_size: int = 99
#@export var tags: Array[StringName] = []
#@export var placeable_scene: PackedScene


# =============================================================================
# HELPERS
# =============================================================================

## Retourne true si cet item peut être acheté chez un vendeur
func is_buyable() -> bool:
	return buy_price > 0


## Retourne true si l'item peut être vendu ET a une valeur de vente
func can_be_sold() -> bool:
	return is_sellable and sell_price > 0
