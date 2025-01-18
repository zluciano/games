shader_type spatial;
render_mode unshaded;

// Stylized Grass Floor Shader
// Creates anime-style grass with visual wave movement and blade patterns

group_uniforms colors;
uniform vec4 grass_bright : source_color = vec4(0.52, 0.78, 0.32, 1.0);
uniform vec4 grass_mid : source_color = vec4(0.38, 0.62, 0.25, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.25, 0.45, 0.18, 1.0);
uniform vec4 grass_shadow : source_color = vec4(0.18, 0.35, 0.12, 1.0);

group_uniforms lighting;
uniform vec3 light_direction = vec3(0.5, 0.7, 0.3);
uniform float shadow_softness : hint_range(0.0, 0.3) = 0.08;

group_uniforms wind;
uniform float wind_speed : hint_range(0.0, 3.0) = 0.8;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float wave_scale : hint_range(0.01, 0.2) = 0.08;
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.4;

group_uniforms pattern;
uniform float blade_scale : hint_range(5.0, 50.0) = 20.0;
uniform float blade_sharpness : hint_range(0.0, 1.0) = 0.6;
uniform float color_variation : hint_range(0.0, 0.5) = 0.15;

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

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// Voronoi for grass blade clusters
float voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float min_dist = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash(i + neighbor) * vec2(0.8, 0.8) + vec2(0.1);
			float dist = length(neighbor + point - f);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = world_position.xz;

	// Animated wind waves
	float time = TIME * wind_speed;
	vec2 wind_uv = uv * wave_scale + normalize(wind_direction) * time;
	float wind_wave = sin(wind_uv.x * 6.0 + wind_uv.y * 4.0) * 0.5 + 0.5;
	wind_wave += sin(wind_uv.x * 3.0 - wind_uv.y * 5.0 + time * 0.7) * 0.3;
	wind_wave = wind_wave * wave_intensity;

	// Grass blade pattern using voronoi
	float blades = voronoi(uv * blade_scale);
	blades = smoothstep(0.0, 0.3 + (1.0 - blade_sharpness) * 0.4, blades);

	// Color variation noise
	float variation = fbm(uv * 8.0) * color_variation;

	// Combine for base grass color (3-tone)
	float grass_tone = blades + wind_wave * 0.3 + variation;

	vec3 base_color;
	if (grass_tone < 0.33) {
		base_color = mix(grass_dark.rgb, grass_mid.rgb, grass_tone * 3.0);
	} else if (grass_tone < 0.66) {
		base_color = mix(grass_mid.rgb, grass_bright.rgb, (grass_tone - 0.33) * 3.0);
	} else {
		base_color = grass_bright.rgb + vec3(0.05) * (grass_tone - 0.66) * 3.0;
	}

	// Add shimmer on wind waves (highlights)
	float shimmer = pow(wind_wave, 2.0) * 0.15;
	base_color += vec3(shimmer * 0.8, shimmer, shimmer * 0.5);

	// Cel-shading based on light direction
	vec3 light_dir = normalize(light_direction);
	float NdotL = dot(world_normal, light_dir);
	float lit = smoothstep(-shadow_softness, shadow_softness, NdotL);

	// Final color with shadow
	vec3 final_color = mix(grass_shadow.rgb, base_color, lit);

	ALBEDO = final_color;
}
