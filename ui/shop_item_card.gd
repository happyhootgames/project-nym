extends Button

# =============================================================================
# ShopItemCard — Carte d'item individuelle dans la grille du vendeur
#
# Arbre de scène attendu (ShopItemCard.tscn) :
#
# ShopItemCard (Button, ce script)
# └── VBoxContainer
#     ├── TextureRect: Icon        ← icône de l'item
#     ├── Label: NameLabel         ← nom court
#     └── Label: PriceLabel        ← prix en noisettes
#
# La scène est instanciée par ShopUI pour chaque entrée du catalogue.
# =============================================================================


@export var icon_rect:    TextureRect
@export var name_label:   Label
@export var price_label:  Label


# =============================================================================
# SETUP — appelé par ShopUI après instanciation
# =============================================================================

func setup(entry: ShopItemEntry) -> void:
	if not entry or not entry.item:
		return

	icon_rect.texture = entry.item.icon
	name_label.text   = entry.item.display_name

	var price := entry.get_effective_price()
	price_label.text  = "🌰 %d" % price

	# Affichage stock limité
	if entry.stock >= 0:
		price_label.text += "\n×%d" % entry.stock


# =============================================================================
# ÉTATS VISUELS
# =============================================================================

## Grise la carte si l'item n'est pas achetable (manque d'argent ou rupture de stock)
func set_available(available: bool) -> void:
	modulate = Color(1, 1, 1, 1) if available else Color(0.5, 0.5, 0.5, 0.7)
	disabled = not available


## Met en évidence la carte sélectionnée
func set_selected(selected: bool) -> void:
	# Si tu utilises un StyleBox dans ton thème, tu peux switcher ici
	# Pour l'instant on utilise une modulation simple
	if selected:
		modulate = Color(1.2, 1.1, 0.8, 1.0)  # légère teinte dorée
	else:
		modulate = Color(1, 1, 1, 1)
