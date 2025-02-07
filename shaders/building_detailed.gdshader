shader_type spatial;
render_mode unshaded;

// Detailed Building Shader with Procedural Windows and Trim
// Creates stylized architecture without texture files

group_uniforms base;
uniform vec4 wall_color : source_color = vec4(0.95, 0.93, 0.88, 1.0);
uniform vec4 wall_shadow : source_color = vec4(0.72, 0.68, 0.62, 1.0);

group_uniforms windows;
uniform bool windows_enabled = true;
uniform vec4 window_color : source_color = vec4(0.2, 0.3, 0.5, 1.0);
uniform vec4 window_frame_color : source_color = vec4(0.4, 0.35, 0.3, 1.0);
uniform float window_rows : hint_range(1.0, 10.0) = 3.0;
uniform float window_columns : hint_range(1.0, 20.0) = 6.0;
uniform float window_width : hint_range(0.1, 0.8) = 0.6;
uniform float window_height : hint_range(0.1, 0.8) = 0.7;
uniform float window_frame_thickness : hint_range(0.01, 0.2) = 0.08;

group_uniforms trim;
uniform bool trim_enabled = true;
uniform vec4 trim_color : source_color = vec4(0.85, 0.82, 0.75, 1.0);
uniform float trim_width : hint_range(0.01, 0.2) = 0.05;
uniform float floor_height : hint_range(0.1, 0.5) = 0.33;

group_uniforms lighting;
uniform vec3 light_direction = vec3(0.5, 0.7, 0.3);
uniform float shadow_softness : hint_range(0.0, 0.3) = 0.05;
uniform float ambient_occlusion : hint_range(0.0, 1.0) = 0.3;

group_uniforms detail;
uniform float brick_scale : hint_range(0.0, 50.0) = 0.0;
uniform vec4 brick_color : source_color = vec4(0.88, 0.85, 0.8, 1.0);
uniform float brick_mortar : hint_range(0.01, 0.1) = 0.03;

varying vec3 world_position;
varying vec3 world_normal;
varying vec3 local_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	local_position = VERTEX;
}

float rectangle(vec2 uv, vec2 center, vec2 size) {
	vec2 d = abs(uv - center) - size * 0.5;
	return 1.0 - step(0.0, max(d.x, d.y));
}

float rectangle_outline(vec2 uv, vec2 center, vec2 size, float thickness) {
	float outer = rectangle(uv, center, size + vec2(thickness));
	float inner = rectangle(uv, center, size - vec2(thickness));
	return outer - inner;
}

void fragment() {
	// Determine which face we're on based on normal
	bool is_front_back = abs(world_normal.z) > 0.5;
	bool is_left_right = abs(world_normal.x) > 0.5;
	bool is_top_bottom = abs(world_normal.y) > 0.5;

	// Create UV based on face orientation
	vec2 face_uv;
	if (is_front_back) {
		face_uv = vec2(local_position.x, local_position.y);
	} else if (is_left_right) {
		face_uv = vec2(local_position.z, local_position.y);
	} else {
		face_uv = vec2(local_position.x, local_position.z);
	}

	// Normalize UV to 0-1 range (assuming standard box mesh centered at origin)
	face_uv = face_uv + 0.5;

	// Start with wall color
	vec3 base_color = wall_color.rgb;
	float detail_mask = 0.0;

	// Brick pattern (if enabled)
	if (brick_scale > 0.0 && !is_top_bottom) {
		vec2 brick_uv = face_uv * brick_scale;
		vec2 brick_id = floor(brick_uv);
		vec2 brick_local = fract(brick_uv);

		// Offset every other row
		if (mod(brick_id.y, 2.0) > 0.5) {
			brick_local.x = fract(brick_local.x + 0.5);
		}

		// Mortar lines
		float mortar_h = step(brick_local.y, brick_mortar) + step(1.0 - brick_mortar, brick_local.y);
		float mortar_v = step(brick_local.x, brick_mortar) + step(1.0 - brick_mortar, brick_local.x);
		float mortar = max(mortar_h, mortar_v);

		base_color = mix(brick_color.rgb, wall_color.rgb, mortar);
	}

	// Windows (only on vertical faces)
	if (windows_enabled && !is_top_bottom) {
		// Grid of windows
		vec2 window_grid = vec2(window_columns, window_rows);
		vec2 cell_uv = fract(face_uv * window_grid);
		vec2 cell_id = floor(face_uv * window_grid);

		// Window in each cell
		float window_mask = rectangle(cell_uv, vec2(0.5), vec2(window_width, window_height));
		float frame_mask = rectangle_outline(cell_uv, vec2(0.5), vec2(window_width, window_height), window_frame_thickness);

		// Apply window
		if (frame_mask > 0.5) {
			base_color = window_frame_color.rgb;
			detail_mask = 1.0;
		} else if (window_mask > 0.5) {
			base_color = window_color.rgb;
			// Window reflection/highlight
			float reflection = smoothstep(0.3, 0.7, cell_uv.y) * 0.3;
			base_color += vec3(reflection);
			detail_mask = 1.0;
		}
	}

	// Floor trim lines (horizontal bands)
	if (trim_enabled && !is_top_bottom) {
		float floor_line = fract(face_uv.y / floor_height);
		float trim_mask = step(floor_line, trim_width) + step(1.0 - trim_width, floor_line);
		if (trim_mask > 0.5) {
			base_color = trim_color.rgb;
		}
	}

	// Cel-shading
	vec3 light_dir = normalize(light_direction);
	float NdotL = dot(world_normal, light_dir);
	float lit = smoothstep(-shadow_softness, shadow_softness, NdotL);

	// Shadow color
	vec3 shadow_col = mix(wall_shadow.rgb, base_color * 0.7, detail_mask);
	vec3 final_color = mix(shadow_col, base_color, lit);

	// Edge ambient occlusion (darker at edges of faces)
	if (!is_top_bottom) {
		float edge_ao = smoothstep(0.0, 0.1, face_uv.x) * smoothstep(1.0, 0.9, face_uv.x);
		edge_ao *= smoothstep(0.0, 0.1, face_uv.y) * smoothstep(1.0, 0.9, face_uv.y);
		final_color *= mix(1.0 - ambient_occlusion, 1.0, edge_ao);
	}

	ALBEDO = final_color;
}
