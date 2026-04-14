extends Control

# =============================================================================
# ShopUI — Interface de vendeur en grille (style Stardew Valley)
#
# Arbre de scène attendu :
#
# ShopUI (Control, ce script)
# ├── PanelContainer                     ← fond du panneau
# │   └── VBoxContainer
# │       ├── HBoxContainer (header)
# │       │   ├── Label: ShopTitle
# │       │   └── HBoxContainer (wallet)
# │       │       ├── TextureRect: CoinIcon
# │       │       └── Label: WalletLabel
# │       ├── GridContainer: ItemGrid    ← les cartes d'items
# │       ├── HSeparator
# │       └── HBoxContainer (footer)
# │           ├── VBoxContainer (infos)
# │           │   ├── Label: ItemNameLabel
# │           │   └── Label: ItemPriceLabel
# │           └── Button: BuyButton
#
# Usage :
#   var shop_ui = preload("res://scenes/ui/ShopUI.tscn").instantiate()
#   shop_ui.open(entries: Array[ShopItemEntry], shop_name: String)
#   add_child(shop_ui)
# =============================================================================


## Émis quand le joueur achète un item — brancher sur l'InventoryManager
signal item_purchased(item_data: ItemData, quantity: int)

## Émis quand le joueur ferme la boutique
signal shop_closed()


# ─── Références nœuds ────────────────────────────────────────────────────────
@export var shop_name_label:      Label
@export var currency_amount_label:    Label
@export var item_grid:       GridContainer
@export var item_name_label: Label
@export var item_price_label:Label
@export var buy_button:      Button


# ─── Scène de carte item (à créer : une TextureButton avec icon + prix) ──────
@export var item_card_scene: PackedScene


# ─── État interne ─────────────────────────────────────────────────────────────
var _entries: Array[ShopItemEntry] = []
var _selected_entry: ShopItemEntry = null
var _selected_card: Control = null


# =============================================================================
# INIT
# =============================================================================

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	buy_button.disabled = true

	# Mise à jour du solde affiché à chaque changement
	WalletManager.balance_changed.connect(_update_wallet_label)
	_update_wallet_label(WalletManager.balance)

	# Fermeture avec Échap
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()


# =============================================================================
# API PUBLIQUE
# =============================================================================

## Ouvre la boutique avec un catalogue d'entrées et un nom de vendeur
func open(entries: Array[ShopItemEntry], shop_name: String = "Boutique") -> void:
	_entries = entries
	shop_name_label.text = shop_name
	_selected_entry = null
	_populate_grid()
	_update_footer(null)
	show()


## Ferme et détruit la boutique
func close() -> void:
	shop_closed.emit()
	queue_free()


# =============================================================================
# GRILLE
# =============================================================================

func _populate_grid() -> void:
	# Vide la grille avant de la re-remplir
	for child in item_grid.get_children():
		child.queue_free()

	for entry in _entries:
		if not entry.item:
			continue

		var card: Control = item_card_scene.instantiate()
		item_grid.add_child(card)

		# Configure la carte (le script ShopItemCard expose ces propriétés)
		card.setup(entry)

		# Grise la carte si rupture de stock ou prix trop élevé
		var affordable := WalletManager.can_afford(entry.get_effective_price())
		var in_stock   := entry.is_in_stock()
		card.set_available(affordable and in_stock)

		# Sélection au clic
		card.pressed.connect(_on_card_selected.bind(entry, card))


# =============================================================================
# SÉLECTION ET FOOTER
# =============================================================================

func _on_card_selected(entry: ShopItemEntry, card: Control) -> void:
	# Déselectionne la carte précédente
	if _selected_card and is_instance_valid(_selected_card):
		_selected_card.set_selected(false)

	_selected_entry = entry
	_selected_card  = card
	card.set_selected(true)

	_update_footer(entry)


func _update_footer(entry: ShopItemEntry) -> void:
	if entry == null or not entry.item:
		item_name_label.text  = ""
		item_price_label.text = ""
		buy_button.disabled   = true
		return

	var price     := entry.get_effective_price()
	var in_stock  := entry.is_in_stock()
	var affordable:= WalletManager.can_afford(price)

	item_name_label.text  = entry.item.display_name
	# Affiche le stock si limité
	var stock_text := "" if entry.stock == -1 else "  (×%d)" % entry.stock
	item_price_label.text = "🌰 %d noisettes%s" % [price, stock_text]

	buy_button.disabled = not (in_stock and affordable)


# =============================================================================
# ACHAT
# =============================================================================

func _on_buy_pressed() -> void:
	if not _selected_entry or not _selected_entry.item:
		return

	var price := _selected_entry.get_effective_price()

	# Double vérification (le bouton peut être désactivé mais on sécurise)
	if not WalletManager.can_afford(price):
		return
	if not _selected_entry.is_in_stock():
		return

	# Transaction
	WalletManager.spend(price)
	_selected_entry.consume_one()

	# Signal vers l'inventaire
	item_purchased.emit(_selected_entry.item, 1)

	# Rafraîchit la grille (stock et affordabilité peuvent avoir changé)
	_populate_grid()
	_update_footer(_selected_entry)


# =============================================================================
# WALLET LABEL
# =============================================================================

func _update_wallet_label(new_balance: int) -> void:
	currency_amount_label.text = "🌰 %d" % new_balance

	# Rafraîchit aussi les cartes si la boutique est ouverte
	if is_visible_in_tree():
		_populate_grid()
		if _selected_entry:
			_update_footer(_selected_entry)
