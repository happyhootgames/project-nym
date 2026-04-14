extends Node2D

# =============================================================================
# WeatherEffects — À placer dans un CanvasLayer (layer 5 par exemple)
#
# Crée et contrôle les effets visuels de chaque météo :
#   ☀️  SUNNY  → pas d'effet
#   🌧  RAIN   → particules de pluie GPUParticles2D
#   🌫  FOG    → overlay ColorRect semi-transparent animé
#
# Setup dans l'éditeur Godot :
#   Scène principale
#   └── CanvasLayer (layer: 5)
#       └── WeatherEffects (Node2D, ce script attaché)
#
# Tous les nœuds enfants sont créés par ce script dans _ready().
# Rien à configurer dans l'éditeur.
# =============================================================================


# Durée de la transition entre deux états météo (en secondes réelles)
const TRANSITION_DURATION: float = 3.0

# Opacité maximale de l'overlay de brume (0.0 → 1.0)
const FOG_MAX_ALPHA: float = 0.35

# ─────────────────────────────────────────────
# Nœuds enfants créés dynamiquement
# ─────────────────────────────────────────────
var _rain: GPUParticles2D
var _fog_overlay: ColorRect
var _tween: Tween


# =============================================================================
# INIT — Création des nœuds et connexion aux signaux
# =============================================================================

func _ready() -> void:
	_setup_rain()
	_setup_fog()

	# Applique immédiatement la météo actuelle sans transition
	_apply_weather(WeatherManager.current_weather, false)

	# Écoute les futurs changements
	WeatherManager.weather_changed.connect(_on_weather_changed)


# =============================================================================
# SETUP — Pluie
# =============================================================================

func _setup_rain() -> void:
	_rain = GPUParticles2D.new()
	add_child(_rain)

	var vp_size: Vector2 = get_viewport().get_visible_rect().size

	# ── Position : juste au-dessus du bord supérieur de l'écran ──
	_rain.position = Vector2(vp_size.x / 2.0, -20.0)

	# ── Quantité et durée de vie des particules ──
	_rain.amount   = 450
	_rain.lifetime = 2.0

	# ── Matériau du process particle ──
	var mat := ParticleProcessMaterial.new()

	# Émission en ligne horizontale couvrant toute la largeur de l'écran
	mat.emission_shape        = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents  = Vector3(vp_size.x / 2.0 * 1.3, 1.0, 0.0)

	# Direction : légèrement inclinée à droite pour simuler un vent doux
	# Augmente le x (ex: 0.2) pour plus de diagonale
	mat.direction = Vector3(0.15, 1.0, 0.0)
	mat.spread    = 5.0

	# Vitesse : les gouttes tombent vite
	mat.initial_velocity_min = 500.0
	mat.initial_velocity_max = 700.0

	# Gravité légère (la direction gère déjà l'essentiel)
	mat.gravity = Vector3(0.0, 120.0, 0.0)

	# Taille : fine et uniforme, on ne veut pas de variation extrême
	mat.scale_min = 1.5
	mat.scale_max = 2.8

	# Couleur blanche semi-transparente — la teinte bleutée vient de la texture
	mat.color = Color(1.0, 1.0, 1.0, 0.65)

	_rain.process_material = mat

	# ── Texture : trait fin dessiné pixel par pixel ──
	# Un rectangle de 2×14px blanc qui s'efface vers le bas.
	# Bien plus fiable que GradientTexture1D qui s'affiche toujours horizontal.
	_rain.texture = _create_raindrop_texture()

	# Désactivé par défaut
	_rain.emitting = false


## Crée une petite texture ImageTexture représentant un trait de pluie :
## 2px de large, 14px de haut, blanc en haut → transparent en bas.
func _create_raindrop_texture() -> ImageTexture:
	const WIDTH  := 2
	const HEIGHT := 22

	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	for y in range(HEIGHT):
		# Alpha décroissant du haut (opaque) vers le bas (transparent)
		# Simule la traînée lumineuse d'une goutte qui tombe
		var alpha := (1.0 - float(y) / float(HEIGHT)) * 0.85

		# Teinte blanc-bleuté légère
		var col := Color(0.88, 0.93, 1.0, alpha)

		for x in range(WIDTH):
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)


# =============================================================================
# SETUP — Brume
# =============================================================================

func _setup_fog() -> void:
	_fog_overlay = ColorRect.new()
	add_child(_fog_overlay)

	var vp_size: Vector2 = get_viewport().get_visible_rect().size

	# Couvre tout l'écran
	_fog_overlay.size     = vp_size
	_fog_overlay.position = Vector2.ZERO

	# Teinte gris-bleuté très douce
	_fog_overlay.color      = Color(0.82, 0.86, 0.90, FOG_MAX_ALPHA)
	_fog_overlay.modulate.a = 0.0  # commence invisible


# =============================================================================
# SIGNAL HANDLER
# =============================================================================

func _on_weather_changed(new_weather: WeatherManager.WeatherType) -> void:
	_apply_weather(new_weather, true)


# =============================================================================
# APPLICATION DES ÉTATS
# =============================================================================

## Active les bons effets selon la météo, avec ou sans transition
func _apply_weather(weather: WeatherManager.WeatherType, animated: bool) -> void:
	# Annule un tween en cours si une nouvelle météo arrive pendant la transition
	if _tween and _tween.is_running():
		_tween.kill()

	match weather:
		WeatherManager.WeatherType.SUNNY:
			_transition_to_sunny(animated)
		WeatherManager.WeatherType.RAIN:
			_transition_to_rain(animated)
		WeatherManager.WeatherType.FOG:
			_transition_to_fog(animated)


func _transition_to_sunny(animated: bool) -> void:
	_rain.emitting = false

	if animated:
		_tween = create_tween()
		_tween.tween_property(_fog_overlay, "modulate:a", 0.0, TRANSITION_DURATION)
	else:
		_fog_overlay.modulate.a = 0.0


func _transition_to_rain(animated: bool) -> void:
	_rain.emitting = true

	# Dissout la brume si elle était active
	if animated:
		_tween = create_tween()
		_tween.tween_property(_fog_overlay, "modulate:a", 0.0, TRANSITION_DURATION)
	else:
		_fog_overlay.modulate.a = 0.0


func _transition_to_fog(animated: bool) -> void:
	_rain.emitting = false

	if animated:
		_tween = create_tween()
		_tween.tween_property(_fog_overlay, "modulate:a", 1.0, TRANSITION_DURATION)
	else:
		_fog_overlay.modulate.a = 1.0
