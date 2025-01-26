shader_type spatial;
render_mode specular_toon, depth_draw_always;

// Stylized Water Shader - Anime-style water for fountains and ponds

group_uniforms water_color;
uniform vec4 shallow_color : source_color = vec4(0.3, 0.7, 0.9, 0.8);
uniform vec4 deep_color : source_color = vec4(0.1, 0.4, 0.7, 0.95);
uniform float color_depth_factor : hint_range(0.0, 5.0) = 1.0;

group_uniforms waves;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.5;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;

group_uniforms foam;
uniform bool foam_enabled = true;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.7;

group_uniforms surface;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Gentle wave animation
	float wave = sin(world_pos.x * wave_frequency + TIME * wave_speed) *
				 cos(world_pos.z * wave_frequency * 0.7 + TIME * wave_speed * 0.8);
	VERTEX.y += wave * wave_strength;

	// Update normal for wave
	float wave_dx = cos(world_pos.x * wave_frequency + TIME * wave_speed) * wave_frequency * wave_strength;
	float wave_dz = -sin(world_pos.z * wave_frequency * 0.7 + TIME * wave_speed * 0.8) * wave_frequency * 0.7 * wave_strength;
	NORMAL = normalize(vec3(-wave_dx, 1.0, -wave_dz));
}

void fragment() {
	// Depth-based color (fake for now - based on UV distance from center)
	float depth_fake = length(UV - 0.5) * 2.0;
	vec4 water_color = mix(deep_color, shallow_color, depth_fake * color_depth_factor);

	// Animated foam pattern
	vec3 foam = vec3(0.0);
	if (foam_enabled) {
		float foam_pattern = sin(world_pos.x * 15.0 + TIME) * sin(world_pos.z * 15.0 + TIME * 0.7);
		foam_pattern = step(foam_threshold, foam_pattern * 0.5 + 0.5);
		foam = foam_color.rgb * foam_pattern * foam_color.a;
	}

	ALBEDO = water_color.rgb + foam;
	ALPHA = water_color.a;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.5;
}
