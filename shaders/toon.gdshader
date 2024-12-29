shader_type spatial;
render_mode unshaded;

// Toon/Cel Shader - Persona/Guilty Gear style anime shading
// UNSHADED MODE: Full artist control, no engine lighting
// Features: Two-tone shadows, specular highlights, rim lighting

group_uniforms base;
uniform vec4 albedo_color : source_color = vec4(0.95, 0.85, 0.8, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;

group_uniforms shading;
uniform vec4 shadow_tint : source_color = vec4(0.69, 0.5, 0.38, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.75;
uniform vec3 light_direction = vec3(0.5, 0.8, 0.3);
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.03;
uniform float vertical_shadow_bias : hint_range(-1.0, 1.0) = 0.2;
uniform float shadow_saturation : hint_range(0.0, 2.0) = 1.2;

group_uniforms specular;
uniform bool specular_enabled = true;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform float specular_size : hint_range(0.0, 1.0) = 0.15;
uniform float specular_intensity : hint_range(0.0, 2.0) = 0.6;
uniform float specular_smoothness : hint_range(0.0, 0.3) = 0.05;

group_uniforms rim;
uniform bool rim_enabled = true;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.9, 1.0);
uniform float rim_width : hint_range(1.0, 16.0) = 4.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.25;
uniform bool rim_in_shadow = true;

group_uniforms outline;
uniform bool outline_enabled = false;
uniform vec4 outline_color : source_color = vec4(0.08, 0.05, 0.1, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

varying vec3 world_normal;
varying vec3 world_position;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	vec3 base_color = albedo_color.rgb * tex_color.rgb;

	// Light and view directions
	vec3 light_dir = normalize(light_direction);
	vec3 view_dir = normalize(VIEW);
	vec3 half_dir = normalize(light_dir + view_dir);

	// Basic lighting calculation
	float NdotL = dot(world_normal, light_dir);
	float NdotH = dot(world_normal, half_dir);
	float NdotV = dot(world_normal, view_dir);

	// Vertical shadow bias (shadows on downward-facing areas)
	float vertical_factor = world_normal.y - vertical_shadow_bias;
	float combined_light = (NdotL + vertical_factor) * 0.5;

	// Cel-shading with soft edge
	float lit = smoothstep(-shadow_softness, shadow_softness, combined_light);

	// Shadow color with saturation boost
	vec3 raw_shadow = base_color * shadow_tint.rgb;
	float shadow_luma = dot(raw_shadow, vec3(0.299, 0.587, 0.114));
	vec3 saturated_shadow = mix(vec3(shadow_luma), raw_shadow, shadow_saturation);
	vec3 shadow_color = saturated_shadow * shadow_strength;

	// Base shading
	vec3 final_color = mix(shadow_color, base_color, lit);

	// Anime-style specular highlight (hard-edged)
	if (specular_enabled) {
		float spec_threshold = 1.0 - specular_size;
		float spec = smoothstep(spec_threshold - specular_smoothness, spec_threshold + specular_smoothness, NdotH);
		spec *= lit; // Only show specular in lit areas
		final_color = mix(final_color, specular_color.rgb, spec * specular_intensity);
	}

	// Rim lighting
	if (rim_enabled) {
		float rim_factor = 1.0 - max(NdotV, 0.0);
		rim_factor = pow(rim_factor, rim_width);

		// Optionally show rim in shadow areas too (backlight effect)
		float rim_mask = rim_in_shadow ? 1.0 : lit;
		final_color += rim_color.rgb * rim_factor * rim_intensity * rim_mask;
	}

	ALBEDO = final_color;
}
