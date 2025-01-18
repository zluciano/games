shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// Anime-style grass blades shader using GPU instancing
// Creates individual grass blade geometry with cel-shading

uniform vec3 grass_color_tip : source_color = vec3(0.5, 0.85, 0.35);
uniform vec3 grass_color_base : source_color = vec3(0.2, 0.5, 0.15);
uniform vec3 grass_color_shadow : source_color = vec3(0.1, 0.3, 0.08);

uniform float blade_height : hint_range(0.1, 2.0) = 0.6;
uniform float blade_height_variation : hint_range(0.0, 1.0) = 0.3;
uniform float blade_width : hint_range(0.01, 0.2) = 0.05;
uniform float blade_bend : hint_range(0.0, 1.0) = 0.3;

uniform float wind_strength : hint_range(0.0, 2.0) = 0.4;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec2 wind_direction = vec2(1.0, 0.3);

uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_smoothness : hint_range(0.0, 0.2) = 0.03;

uniform float specular_strength : hint_range(0.0, 1.0) = 0.3;
uniform float specular_shininess : hint_range(1.0, 128.0) = 32.0;

varying vec3 world_position;
varying float blade_height_factor;
varying vec3 blade_normal;

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
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Get height factor (0 at base, 1 at tip)
    blade_height_factor = max(0.0, VERTEX.y / blade_height);

    // Random variation based on world position
    vec2 blade_id = floor(world_position.xz * 10.0);
    float random_height = hash(blade_id) * blade_height_variation;
    float random_bend = hash(blade_id + vec2(42.0, 17.0)) * blade_bend;

    // Wind animation
    float wind_time = TIME * wind_speed;
    vec2 wind_uv = world_position.xz * 0.15 + normalize(wind_direction) * wind_time;
    float wind_noise = fbm(wind_uv) * 2.0 - 1.0;

    // Apply wind displacement (more at tip, none at base)
    float wind_factor = blade_height_factor * blade_height_factor;
    vec3 wind_offset = vec3(
        wind_noise * wind_strength * wind_factor * wind_direction.x,
        -abs(wind_noise) * wind_strength * wind_factor * 0.2,
        wind_noise * wind_strength * wind_factor * wind_direction.y
    );

    // Natural bend
    float bend_offset = blade_height_factor * blade_height_factor * random_bend;

    VERTEX.y *= (1.0 + random_height);
    VERTEX.xz += wind_offset.xz + vec2(bend_offset, bend_offset * 0.5);
    VERTEX.y += wind_offset.y;

    // Calculate blade normal for lighting
    blade_normal = normalize(vec3(-wind_offset.x * 2.0, 1.0, -wind_offset.z * 2.0));
}

void fragment() {
    // Gradient from base to tip
    vec3 grass_color = mix(grass_color_base, grass_color_tip, blade_height_factor);

    // Add subtle variation
    float variation = noise(world_position.xz * 5.0) * 0.1;
    grass_color = mix(grass_color, grass_color * 1.1, variation);

    ALBEDO = grass_color;
    ROUGHNESS = 0.85;
    METALLIC = 0.0;
    NORMAL = blade_normal;

    // Slight transparency at tips for softer look
    ALPHA = mix(1.0, 0.9, blade_height_factor * 0.3);
    ALPHA_SCISSOR_THRESHOLD = 0.1;
}

void light() {
    // Cel-shaded lighting
    float NdotL = dot(NORMAL, LIGHT);

    // Subsurface scattering simulation for grass
    float subsurface = max(0.0, dot(-VIEW, LIGHT)) * 0.3;
    NdotL = max(NdotL, subsurface);

    float light_intensity = smoothstep(
        shadow_threshold - shadow_smoothness,
        shadow_threshold + shadow_smoothness,
        NdotL * ATTENUATION
    );

    // Two-tone cel shading
    vec3 lit_color = ALBEDO * LIGHT_COLOR;
    vec3 shadow_color = grass_color_shadow * LIGHT_COLOR * 0.6;

    vec3 diffuse = mix(shadow_color, lit_color, light_intensity);

    // Specular highlight (anime style - sharp)
    vec3 H = normalize(LIGHT + VIEW);
    float NdotH = max(0.0, dot(NORMAL, H));
    float spec = pow(NdotH, specular_shininess);
    spec = smoothstep(0.5, 0.52, spec) * specular_strength * light_intensity;

    DIFFUSE_LIGHT += diffuse + vec3(spec) * LIGHT_COLOR;
}
