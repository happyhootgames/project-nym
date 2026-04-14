// ============================================================================
// wind.gdshader
// À placer dans res://shaders/wind.gdshader
//
// Applique un effet de balancement sur un Sprite2D de végétation.
// Le bas du sprite est fixe (racines), le haut oscille (feuilles).
//
// Paramètres contrôlés depuis GDScript via WindComponent.gd :
//   wind_strength → amplitude du balancement (0.0 = immobile, 1.0 = fort)
//   wind_speed    → vitesse de l'oscillation
//   wind_offset   → décalage de phase (pour que chaque arbre soit désynchronisé)
// ============================================================================

shader_type canvas_item;

// ─── Paramètres exposés à GDScript ───────────────────────────────────────────

/// Amplitude du balancement en pixels (0 = pas de vent, 20 = tempête)
uniform float wind_strength : hint_range(0.0, 30.0) = 5.0;

/// Vitesse de l'oscillation (cycles par seconde)
uniform float wind_speed : hint_range(0.0, 5.0) = 1.2;

/// Décalage de phase unique par végétal (évite que tous les arbres bougent ensemble)
uniform float wind_offset : hint_range(0.0, 6.28) = 0.0;

/// Influence de la turbulence secondaire (micro-tremblements aléatoires)
uniform float turbulence : hint_range(0.0, 1.0) = 0.3;


// ─── Vertex shader ───────────────────────────────────────────────────────────
// Appelé pour chaque sommet (coin) du rectangle du sprite.
// On déplace chaque sommet horizontalement selon sa position verticale.

void vertex() {
	// UV.y va de 0.0 (haut du sprite) à 1.0 (bas du sprite).
	// On inverse pour que le facteur soit 0 en bas et 1 en haut.
	// C'est ce qui ancre les racines au sol.
	float height_factor = 1.0 - UV.y;

	// Courbe quadratique : le déplacement accélère vers le haut.
	// Sans ça, le mouvement est linéaire et moins naturel.
	height_factor = height_factor * height_factor;

	// Onde sinusoïdale principale : le balancement de fond
	float wave_main = sin(TIME * wind_speed + wind_offset);

	// Onde secondaire plus rapide : simule les micro-turbulences du vent
	float wave_turb = sin(TIME * wind_speed * 2.7 + wind_offset * 1.3) * turbulence;

	// Déplacement horizontal total
	float displacement = (wave_main + wave_turb) * wind_strength * height_factor;

	// On applique le déplacement au sommet sur l'axe X
	VERTEX.x += displacement;
}


// ─── Fragment shader ─────────────────────────────────────────────────────────
// On ne modifie pas les couleurs — on affiche le sprite normalement.

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
