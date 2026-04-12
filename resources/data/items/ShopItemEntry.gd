class_name ShopItemEntry
extends Resource

# =============================================================================
# ShopItemEntry — Resource légère définissant une entrée dans le catalogue
# d'un vendeur. Crée un .tres par vendeur dans res://resources/shops/
#
# Exemple de structure pour un vendeur :
#   ShopData.tres
#     entries:
#       [0] ShopItemEntry (Champignon, stock: -1, buy_price_override: 0)
#       [1] ShopItemEntry (Graine de fleur, stock: 5, buy_price_override: 30)
# =============================================================================


## L'item vendu — doit pointer vers un ItemData.tres
@export var item: ItemData

## Stock disponible. -1 = illimité (réapprovisionne chaque jour in-game)
@export var stock: int = -1

## Si > 0, écrase le buy_price défini dans l'ItemData.
## Utile pour qu'un vendeur vende moins cher ou plus cher que la valeur de base.
@export var buy_price_override: int = 0


# =============================================================================
# HELPERS
# =============================================================================

## Retourne le prix d'achat effectif (override prioritaire sur l'ItemData)
func get_effective_price() -> int:
	if buy_price_override > 0:
		return buy_price_override
	return item.buy_price if item else 0


## Retourne true si cet item est encore en stock
func is_in_stock() -> bool:
	return stock == -1 or stock > 0


## Décrémente le stock après un achat (ne fait rien si stock illimité)
func consume_one() -> void:
	if stock > 0:
		stock -= 1
