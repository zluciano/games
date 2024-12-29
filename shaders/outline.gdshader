shader_type spatial;
render_mode unshaded, cull_front;

// Outline Shader - Inverted hull method for anime-style outlines
// Apply as second material on mesh or use Next Pass

uniform vec4 outline_color : source_color = vec4(0.1, 0.1, 0.18, 1.0);  // Deep navy (#1A1A2E)
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Expand vertices along normals
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
