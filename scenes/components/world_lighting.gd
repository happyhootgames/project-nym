extends CanvasModulate
class_name WorldLighting

# =============================================================================
# WorldLighting — Script à placer sur un nœud CanvasModulate dans ta scène
#
# Écoute TimeManager et fait une transition douce entre les couleurs
# de chaque phase. Toute la scène est teintée par ce nœud.
#
# Setup dans l'éditeur :
#   - Ajoute un nœud CanvasModulate à ta scène (enfant direct du root)
#   - Attache ce script dessus
#   - Le nœud doit être APRÈS les TilemapLayers dans l'arbre pour tout teinter
# =============================================================================


# -----------------------------------------------------------------------------
# Palette de couleurs par phase
# Ajuste ces couleurs selon l'ambiance artistique de Stir & Bloom
# (inspirations : Carson Ellis, Tukoni — tons naturels et chauds)
# -----------------------------------------------------------------------------
const PHASE_COLORS: Dictionary = {
	TimeManager.DayPhase.MORNING: Color(1.00, 0.97, 0.91),  # Touche de jaune très légère / aurore douce
	TimeManager.DayPhase.DAY:     Color(1.0, 1.0, 0.98, 0.0),  # Blanc neutre / lumière naturelle
	TimeManager.DayPhase.EVENING: Color(1.00, 0.88, 0.75),  # Orangé très subtil / heure dorée
	TimeManager.DayPhase.NIGHT:   Color(0.55, 0.60, 0.75),  # Bleu nuit doux, pas trop sombre
}

## Durée de la transition entre deux phases, en secondes réelles
@export var transition_duration: float = 4.0

# -----------------------------------------------------------------------------
# État interne de la transition
# -----------------------------------------------------------------------------
var _start_color:  Color = Color.WHITE
var _target_color: Color = Color.WHITE
var _progress:     float = 1.0  # 1.0 = transition terminée, pas d'interpolation en cours


# =============================================================================
# INIT
# =============================================================================

func _ready() -> void:
	# Initialise la couleur directement selon la phase actuelle (sans transition)
	color = PHASE_COLORS[TimeManager.current_phase]
	_target_color = color
	_start_color  = color

	# Écoute les changements de phase
	TimeManager.day_phase_changed.connect(_on_phase_changed)


# =============================================================================
# LOOP — interpolation douce entre deux couleurs
# =============================================================================

func _process(delta: float) -> void:
	# Si la transition est déjà terminée, rien à faire
	if _progress >= 1.0:
		return

	_progress = minf(_progress + delta / transition_duration, 1.0)

	# Interpolation linéaire entre la couleur de départ et la cible
	# (utilise smoothstep pour un fondu plus organique)
	color = _start_color.lerp(_target_color, ease(_progress, -2.0))


# =============================================================================
# SIGNAL HANDLER
# =============================================================================

func _on_phase_changed(new_phase: TimeManager.DayPhase) -> void:
	# Démarre une nouvelle transition depuis la couleur courante
	_start_color  = color
	_target_color = PHASE_COLORS[new_phase]
	_progress     = 0.0
