shader_type canvas_item;

// Anime/Persona style post-processing shader
// Enhanced with edge detection, color grading, and film grain

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Color grading
uniform float saturation : hint_range(0.0, 2.0) = 1.3;
uniform float contrast : hint_range(0.5, 2.0) = 1.15;
uniform float brightness : hint_range(-0.5, 0.5) = 0.05;
uniform vec3 color_tint : source_color = vec3(1.0, 0.98, 0.95);

// Vignette
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

// Color curve adjustments
uniform float shadow_boost : hint_range(0.0, 1.0) = 0.1;
uniform float highlight_boost : hint_range(0.0, 1.0) = 0.15;

// Bloom
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float bloom_intensity : hint_range(0.0, 1.0) = 0.2;

// Edge enhancement
uniform float edge_strength : hint_range(0.0, 2.0) = 0.3;
uniform float edge_threshold : hint_range(0.0, 0.5) = 0.1;

// Film grain
uniform float grain_amount : hint_range(0.0, 0.1) = 0.02;

vec3 adjust_saturation(vec3 color, float sat) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(luma), color, sat);
}

vec3 adjust_contrast(vec3 color, float cont) {
    return (color - 0.5) * cont + 0.5;
}

vec3 color_grade(vec3 color) {
    // Boost shadows with cool tint (anime shadow style)
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 shadow_tint = vec3(0.9, 0.95, 1.05); // Cool blue shadows
    vec3 highlight_tint = vec3(1.05, 1.0, 0.95); // Warm highlights

    // Apply shadow boost with cool tint
    color = mix(color, color * shadow_tint, (1.0 - luma) * shadow_boost);

    // Apply highlight boost with warm tint
    color = mix(color, color * highlight_tint + highlight_boost * 0.5, smoothstep(0.5, 1.0, luma));

    return color;
}

float vignette(vec2 uv) {
    vec2 center = uv - 0.5;
    float dist = length(center);
    return 1.0 - smoothstep(vignette_softness, vignette_softness + 0.3, dist * vignette_intensity * 2.0);
}

float get_edge(vec2 uv, vec2 pixel_size) {
    // Sobel edge detection
    float tl = dot(texture(SCREEN_TEXTURE, uv + vec2(-1, -1) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float t  = dot(texture(SCREEN_TEXTURE, uv + vec2( 0, -1) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float tr = dot(texture(SCREEN_TEXTURE, uv + vec2( 1, -1) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float l  = dot(texture(SCREEN_TEXTURE, uv + vec2(-1,  0) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float r  = dot(texture(SCREEN_TEXTURE, uv + vec2( 1,  0) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float bl = dot(texture(SCREEN_TEXTURE, uv + vec2(-1,  1) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float b  = dot(texture(SCREEN_TEXTURE, uv + vec2( 0,  1) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));
    float br = dot(texture(SCREEN_TEXTURE, uv + vec2( 1,  1) * pixel_size).rgb, vec3(0.299, 0.587, 0.114));

    float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;

    return sqrt(gx*gx + gy*gy);
}

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));

    vec4 screen_color = texture(SCREEN_TEXTURE, uv);
    vec3 color = screen_color.rgb;

    // Apply color grading first
    color = color_grade(color);

    // Adjust saturation
    color = adjust_saturation(color, saturation);

    // Adjust contrast
    color = adjust_contrast(color, contrast);

    // Apply brightness
    color += brightness;

    // Apply color tint
    color *= color_tint;

    // Edge enhancement (subtle darkening at edges)
    float edge = get_edge(uv, pixel_size);
    float edge_mask = smoothstep(edge_threshold, edge_threshold + 0.1, edge);
    color = mix(color, color * (1.0 - edge_strength * 0.5), edge_mask);

    // Simple bloom effect
    float bloom_mask = smoothstep(bloom_threshold, 1.0, dot(color, vec3(0.299, 0.587, 0.114)));
    color += color * bloom_mask * bloom_intensity;

    // Apply vignette
    color *= vignette(uv);

    // Film grain (subtle)
    float grain = random(uv + fract(TIME * 0.1)) * grain_amount;
    color += grain - grain_amount * 0.5;

    // Clamp to valid range
    color = clamp(color, 0.0, 1.0);

    COLOR = vec4(color, 1.0);
}
