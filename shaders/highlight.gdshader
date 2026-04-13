// ============================================================================
// outline.gdshader
// À placer dans res://shaders/outline.gdshader
//
// Dessine un contour coloré autour des pixels opaques d'un sprite.
// Utilisé par Interactable pour mettre en avant l'objet le plus proche.
//
// Principe : pour chaque pixel TRANSPARENT du sprite, on regarde si un
// de ses 8 voisins est OPAQUE. Si oui → on dessine la couleur du contour.
// L'intérieur du sprite est laissé transparent (le sprite original est dessous).
// ============================================================================

shader_type canvas_item;

/// Couleur et épaisseur du contour
uniform vec4  outline_color : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform float outline_width : hint_range(0.5, 6.0) = 2.0;

/// Animation de pulsation (0.0 = statique, 1.0 = pulsation visible)
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed    : hint_range(0.0, 5.0) = 2.5;


void fragment() {
	// Taille d'un pixel en coordonnées UV
	vec2 pixel_size = outline_width / vec2(textureSize(TEXTURE, 0));

	// Échantillonne le pixel courant
	vec4 current = texture(TEXTURE, UV);

	// Si le pixel courant est déjà opaque → on ne dessine rien
	// (on veut un contour, pas un remplissage)
	if (current.a > 0.1) { 
		COLOR = current;
		} else {

		// Vérifie les 8 voisins autour du pixel courant
		float neighbor_alpha = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				if (x == 0 && y == 0) continue;
				vec2 offset = vec2(float(x), float(y)) * pixel_size;
				neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + offset).a);
			}
		}

		// Si au moins un voisin est opaque → ce pixel fait partie du contour
		if (neighbor_alpha > 0.1) {
			// Pulsation douce (modifie l'alpha du contour)
			float pulse = 1.0 - pulse_strength * (0.5 + 0.5 * sin(TIME * pulse_speed));
			COLOR = vec4(outline_color.rgb, outline_color.a * pulse);
		} else {
			COLOR = vec4(0.0);
		}
	}
}
