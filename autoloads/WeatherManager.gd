extends Node

# =============================================================================
# WeatherManager — Autoload singleton
# Gère la météo courante, sa durée aléatoire et les transitions.
# Les rituels des esprits peuvent forcer une météo temporairement.
#
# États disponibles pour l'instant : SUNNY, RAIN, FOG
# (WIND et STORM seront ajoutés plus tard sans changer l'architecture)
# =============================================================================


## Emis à chaque changement de météo
signal weather_changed(new_weather: WeatherType)


enum WeatherType { SUNNY, RAIN, FOG }


# -----------------------------------------------------------------------------
# Configuration des durées par météo (en heures in-game)
# -----------------------------------------------------------------------------
const WEATHER_DURATIONS := {
	WeatherType.SUNNY: { "min": 3, "max": 8 },
	WeatherType.RAIN:  { "min": 1, "max": 4 },
	WeatherType.FOG:   { "min": 2, "max": 5 },
}

# Poids de probabilité pour la sélection aléatoire (plus c'est élevé, plus c'est fréquent)
# Le soleil est dominant pour rester dans une ambiance cozy
const WEATHER_WEIGHTS := {
	WeatherType.SUNNY: 50,
	WeatherType.RAIN:  30,
	WeatherType.FOG:   20,
}


# -----------------------------------------------------------------------------
# État interne
# -----------------------------------------------------------------------------
var current_weather: WeatherType = WeatherType.SUNNY

## Heures in-game restantes avant le prochain changement de météo
var _hours_remaining: int = 0

## True quand un rituel est actif — empêche le changement aléatoire
var _is_forced: bool = false


# =============================================================================
# INIT
# =============================================================================

func _ready() -> void:
	# Écoute l'horloge in-game — la météo évolue heure par heure
	TimeManager.hour_changed.connect(_on_hour_changed)

	# Démarre avec du soleil
	_set_weather(WeatherType.SUNNY)


# =============================================================================
# TICK HORAIRE
# =============================================================================

func _on_hour_changed(_hour: int) -> void:
	_hours_remaining -= 1

	if _hours_remaining <= 0:
		# Si un rituel était actif, il est maintenant terminé
		if _is_forced:
			_is_forced = false

		_pick_next_weather()


# =============================================================================
# SÉLECTION ALÉATOIRE
# =============================================================================

## Choisit la prochaine météo par tirage pondéré, en excluant la météo actuelle
func _pick_next_weather() -> void:
	# Calcule le poids total sans la météo actuelle
	var total_weight := 0
	for type: WeatherType in WeatherType.values():
		if type != current_weather:
			total_weight += WEATHER_WEIGHTS[type]

	# Tirage au sort
	var roll := randi() % total_weight
	var cumulative := 0

	for type: WeatherType in WeatherType.values():
		if type == current_weather:
			continue
		cumulative += WEATHER_WEIGHTS[type]
		if roll < cumulative:
			_set_weather(type)
			return


## Applique une météo et tire sa durée aléatoirement
func _set_weather(weather: WeatherType) -> void:
	current_weather = weather

	var range_data: Dictionary = WEATHER_DURATIONS[weather]
	_hours_remaining = randi_range(range_data["min"], range_data["max"])

	weather_changed.emit(current_weather)


# =============================================================================
# API PUBLIQUE — Rituels des esprits
# =============================================================================

## Force une météo spécifique pour une durée donnée (appel depuis le système de rituels)
## Exemple : WeatherManager.force_weather(WeatherManager.WeatherType.RAIN, 2)
func force_weather(weather: WeatherType, duration_hours: int) -> void:
	_is_forced = true
	_hours_remaining = duration_hours

	# On ne passe pas par _set_weather pour ne pas retirer le flag _is_forced
	current_weather = weather
	weather_changed.emit(current_weather)


## Retourne le nom lisible de la météo courante (pour l'UI)
func get_weather_label() -> String:
	match current_weather:
		WeatherType.SUNNY: return "Ensoleillé"
		WeatherType.RAIN:  return "Pluie"
		WeatherType.FOG:   return "Brume"
	return "Inconnu"


## Retourne true si un rituel est actif en ce moment
func is_weather_forced() -> bool:
	return _is_forced
