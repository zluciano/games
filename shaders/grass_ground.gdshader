shader_type spatial;
render_mode unshaded;

// Stylized Ground Shader - Cel-shaded grass for Persona/Guilty Gear style

group_uniforms colors;
uniform vec4 base_color : source_color = vec4(0.486, 0.702, 0.259, 1.0);  // Vibrant grass #7CB342
uniform vec4 shadow_color : source_color = vec4(0.306, 0.478, 0.157, 1.0);  // Rich shadow #4E7A28
uniform vec3 light_direction = vec3(0.5, 0.8, 0.3);

varying vec3 world_normal;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Manual cel-shading (artist-controlled, not engine lighting)
	vec3 light_dir = normalize(light_direction);
	float NdotL = dot(world_normal, light_dir);
	float lit = step(0.0, NdotL);

	// Two-color system: lit = base_color, shadow = shadow_color
	vec3 final_color = mix(shadow_color.rgb, base_color.rgb, lit);

	// Output through ALBEDO (unshaded mode outputs this directly)
	ALBEDO = final_color;
}
