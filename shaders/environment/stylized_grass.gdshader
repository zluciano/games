shader_type spatial;
render_mode cull_disabled;

// Stylized anime grass shader
// Cel-shaded grass with wind animation

uniform vec3 grass_color_light : source_color = vec3(0.45, 0.75, 0.35);
uniform vec3 grass_color_dark : source_color = vec3(0.25, 0.55, 0.2);
uniform vec3 grass_color_shadow : source_color = vec3(0.15, 0.35, 0.12);

// Wind settings
uniform float wind_strength : hint_range(0.0, 2.0) = 0.3;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec2 wind_direction = vec2(1.0, 0.5);

// Cel shading
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.4;
uniform float shadow_smoothness : hint_range(0.0, 0.5) = 0.05;

// Pattern
uniform float pattern_scale : hint_range(0.1, 10.0) = 2.0;
uniform float pattern_strength : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_pos;
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
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;

    // Wind animation based on world position
    float wind_time = TIME * wind_speed;
    vec2 wind_uv = world_pos.xz * 0.1 + wind_direction * wind_time;
    float wind_noise = noise(wind_uv) * 2.0 - 1.0;

    // Only affect top of grass (based on vertex height in local space)
    float height_factor = max(0.0, VERTEX.y);

    // Apply wind displacement
    VERTEX.x += wind_noise * wind_strength * height_factor;
    VERTEX.z += wind_noise * wind_strength * height_factor * 0.5;
}

void fragment() {
    // Base grass pattern
    vec2 pattern_uv = world_pos.xz * pattern_scale;
    float pattern = noise(pattern_uv);

    // Mix between light and dark grass based on pattern
    vec3 base_color = mix(grass_color_dark, grass_color_light, pattern * pattern_strength + (1.0 - pattern_strength) * 0.5);

    ALBEDO = base_color;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}

void light() {
    // Cel-shaded lighting
    float NdotL = dot(NORMAL, LIGHT);
    float light_intensity = smoothstep(shadow_threshold - shadow_smoothness, shadow_threshold + shadow_smoothness, NdotL * ATTENUATION);

    // Two-tone shading
    vec3 lit_color = ALBEDO * LIGHT_COLOR;
    vec3 shadow_color = grass_color_shadow * LIGHT_COLOR * 0.5;

    DIFFUSE_LIGHT += mix(shadow_color, lit_color, light_intensity);
}
