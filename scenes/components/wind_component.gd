extends Node2D
class_name WindComponent

# =============================================================================
# WindComponent — Composant réutilisable à ajouter sur n'importe quel végétal
#
# Usage dans l'éditeur :
#   Arbre (Node2D)
#   ├── Sprite2D         ← le sprite de l'arbre
#   └── WindComponent    ← ce script attaché comme enfant
#
# Le composant :
#   1. Applique automatiquement wind.gdshader sur le Sprite2D parent
#   2. Écoute WeatherManager pour ajuster la force du vent selon la météo
#   3. Désynchronise chaque végétal avec un offset aléatoire
# =============================================================================


# ─── Configuration dans l'inspecteur ─────────────────────────────────────────
@export var impacted_by_wind: bool = true
## Multiplicateur local de sensibilité au vent.
## 1.0 = normal, 0.5 = végétal très rigide (gros tronc), 2.0 = très souple (fleur)
@export var flexibility: float = 1.0

## Vitesse de transition quand la météo change (en secondes réelles)
@export var transition_speed: float = 3.0

@export var sprite: Sprite2D


# ─── Force de vent cible par météo (en pixels de déplacement max) ─────────────
## Ajuste ces valeurs pour calibrer l'intensité globale
const WIND_STRENGTH_BY_WEATHER := {
	WeatherManager.WeatherType.SUNNY: 3.0,   # brise légère même par beau temps
	WeatherManager.WeatherType.RAIN:  10.0,  # vent modéré sous la pluie
	WeatherManager.WeatherType.FOG:   1.5,   # quasi immobile dans la brume
	# WIND et STORM seront ajoutés ici plus tard
}

const WIND_SPEED_BY_WEATHER := {
	WeatherManager.WeatherType.SUNNY: 0.8,
	WeatherManager.WeatherType.RAIN:  1.8,
	WeatherManager.WeatherType.FOG:   0.4,
}


# ─── État interne ─────────────────────────────────────────────────────────────
var _material: ShaderMaterial
const WIND_SHADER_PATH := "res://shaders/wind.gdshader"

var _current_strength: float = 0.0
var _target_strength:  float = 0.0
var _current_speed:    float = 1.0
var _target_speed:     float = 1.0


# =============================================================================
# INIT
# =============================================================================

func _ready() -> void:
	if impacted_by_wind:
		_apply_shader()
		_set_random_offset()
		_apply_weather(WeatherManager.current_weather)

		WeatherManager.weather_changed.connect(_on_weather_changed)


func _apply_shader() -> void:
	# Crée un ShaderMaterial unique par sprite (sinon tous partagent les mêmes params)
	_material = ShaderMaterial.new()
	_material.shader = load(WIND_SHADER_PATH)
	sprite.material = _material


func _set_random_offset() -> void:
	# Chaque végétal a un offset de phase aléatoire → ils ne bougent pas en rythme
	# (comme une vraie forêt, pas un ballet synchronisé)
	var offset := randf_range(0.0, TAU)  # TAU = 2π, une période complète
	_material.set_shader_parameter("wind_offset", offset)


# =============================================================================
# PROCESS — interpolation douce vers la cible
# =============================================================================

func _process(delta: float) -> void:
	if impacted_by_wind:
		# Transition progressive entre l'ancienne et la nouvelle force de vent
		# (évite le changement brutal quand la météo change)
		var lerp_factor := minf(delta * (1.0 / transition_speed) * 3.0, 1.0)

		_current_strength = lerpf(_current_strength, _target_strength, lerp_factor)
		_current_speed    = lerpf(_current_speed,    _target_speed,    lerp_factor)

		# Applique au shader (× flexibility pour les végétaux plus ou moins souples)
		_material.set_shader_parameter("wind_strength", _current_strength * flexibility)
		_material.set_shader_parameter("wind_speed",    _current_speed)


# =============================================================================
# MÉTÉO
# =============================================================================

func _on_weather_changed(new_weather: WeatherManager.WeatherType) -> void:
	_apply_weather(new_weather)


func _apply_weather(weather: WeatherManager.WeatherType) -> void:
	# Récupère les valeurs cibles, avec fallback si la météo n'est pas encore définie
	_target_strength = WIND_STRENGTH_BY_WEATHER.get(weather, 3.0)
	_target_speed    = WIND_SPEED_BY_WEATHER.get(weather, 1.0)
