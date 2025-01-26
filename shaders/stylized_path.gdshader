shader_type spatial;
render_mode unshaded;

// Stylized Stone Path Shader
// Creates anime-style cobblestone/brick path

group_uniforms colors;
uniform vec4 stone_light : source_color = vec4(0.72, 0.68, 0.62, 1.0);
uniform vec4 stone_mid : source_color = vec4(0.58, 0.55, 0.5, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.45, 0.42, 0.38, 1.0);
uniform vec4 stone_shadow : source_color = vec4(0.35, 0.32, 0.28, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.4, 0.38, 0.35, 1.0);

group_uniforms pattern;
uniform float stone_scale : hint_range(0.5, 5.0) = 1.5;
uniform float mortar_width : hint_range(0.02, 0.15) = 0.06;
uniform float stone_variation : hint_range(0.0, 0.3) = 0.12;

group_uniforms lighting;
uniform vec3 light_direction = vec3(0.5, 0.7, 0.3);
uniform float shadow_softness : hint_range(0.0, 0.3) = 0.08;

varying vec3 world_position;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = world_position.xz * stone_scale;

	// Brick pattern
	vec2 brick_uv = uv;
	vec2 brick_id = floor(brick_uv);

	// Offset every other row
	if (mod(brick_id.y, 2.0) > 0.5) {
		brick_uv.x += 0.5;
		brick_id = floor(brick_uv);
	}

	vec2 brick_local = fract(brick_uv);

	// Mortar lines
	float mortar_h = step(brick_local.y, mortar_width) + step(1.0 - mortar_width, brick_local.y);
	float mortar_v = step(brick_local.x, mortar_width) + step(1.0 - mortar_width, brick_local.x);
	float is_mortar = max(mortar_h, mortar_v);

	// Per-stone variation
	float stone_noise = hash(brick_id) * stone_variation;
	float detail_noise = noise(uv * 8.0) * 0.1;

	// Stone color (3-tone based on variation)
	float tone = stone_noise + detail_noise;
	vec3 base_color;
	if (is_mortar > 0.5) {
		base_color = mortar_color.rgb;
	} else if (tone < 0.33) {
		base_color = mix(stone_dark.rgb, stone_mid.rgb, tone * 3.0);
	} else if (tone < 0.66) {
		base_color = mix(stone_mid.rgb, stone_light.rgb, (tone - 0.33) * 3.0);
	} else {
		base_color = stone_light.rgb;
	}

	// Cel-shading
	vec3 light_dir = normalize(light_direction);
	float NdotL = dot(world_normal, light_dir);
	float lit = smoothstep(-shadow_softness, shadow_softness, NdotL);

	vec3 final_color = mix(stone_shadow.rgb, base_color, lit);

	ALBEDO = final_color;
}
