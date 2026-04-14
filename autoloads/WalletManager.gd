extends Node

# =============================================================================
# WalletManager — Autoload singleton
# Gère la monnaie du joueur : les noisettes d'or.
#
# Enregistrer dans Project > Autoloads sous le nom "WalletManager"
# =============================================================================


## Émis à chaque changement de solde (achat, vente, récompense)
signal balance_changed(new_balance: int)


# Clé utilisée dans le fichier de sauvegarde global
const SAVE_KEY := "wallet_balance"

## Solde de départ au début d'une nouvelle partie
const STARTING_BALANCE: int = 50


# ─── État ────────────────────────────────────────────────────────────────────

var balance: int = STARTING_BALANCE : set = _set_balance


# =============================================================================
# SETTERS — toute modification passe ici pour émettre le signal
# =============================================================================

func _set_balance(value: int) -> void:
	balance = max(0, value)  # le solde ne peut pas être négatif
	balance_changed.emit(balance)


# =============================================================================
# API PUBLIQUE
# =============================================================================

## Ajoute des noisettes (récompense, vente, exploration)
func add(amount: int) -> void:
	if amount <= 0:
		push_warning("WalletManager.add() appelé avec une valeur <= 0 : %d" % amount)
		return
	balance += amount


## Dépense des noisettes. Retourne false si le solde est insuffisant.
## Toujours vérifier avec can_afford() avant d'appeler spend().
func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	balance -= amount
	return true


## Retourne true si le joueur peut se payer ce montant
func can_afford(amount: int) -> bool:
	return balance >= amount


# =============================================================================
# SAVE / LOAD — à brancher sur ton système de sauvegarde global
# =============================================================================

## Retourne le dictionnaire à inclure dans ta sauvegarde globale
func get_save_data() -> Dictionary:
	return { SAVE_KEY: balance }


## Charge depuis le dictionnaire de sauvegarde globale
func load_save_data(data: Dictionary) -> void:
	balance = data.get(SAVE_KEY, STARTING_BALANCE)
