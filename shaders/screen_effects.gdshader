shader_type canvas_item;

// Screen Post-Processing - Color grading and effects for Persona aesthetic

group_uniforms color_grading;
uniform float saturation : hint_range(0.0, 2.0) = 1.1;
uniform float contrast : hint_range(0.5, 2.0) = 1.05;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform vec4 color_tint : source_color = vec4(1.0, 0.98, 0.95, 1.0);

group_uniforms vignette;
uniform bool vignette_enabled = true;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.5;

group_uniforms chromatic;
uniform bool chromatic_enabled = false;
uniform float chromatic_amount : hint_range(0.0, 0.01) = 0.002;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

vec3 apply_saturation(vec3 color, float sat) {
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(grey), color, sat);
}

vec3 apply_contrast(vec3 color, float con) {
	return (color - 0.5) * con + 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Chromatic aberration
	vec3 color;
	if (chromatic_enabled) {
		vec2 offset = (uv - 0.5) * chromatic_amount;
		color.r = texture(screen_texture, uv + offset).r;
		color.g = texture(screen_texture, uv).g;
		color.b = texture(screen_texture, uv - offset).b;
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// Color grading
	color = apply_saturation(color, saturation);
	color = apply_contrast(color, contrast);
	color *= brightness;
	color *= color_tint.rgb;

	// Vignette
	if (vignette_enabled) {
		vec2 centered_uv = uv - 0.5;
		float vignette = 1.0 - dot(centered_uv, centered_uv) * vignette_intensity * 2.0;
		vignette = smoothstep(0.0, vignette_smoothness, vignette);
		color *= vignette;
	}

	COLOR = vec4(color, 1.0);
}
