shader_type sky;

// Anime-style gradient sky shader
// Creates smooth gradients with stylized colors typical of anime backgrounds

uniform vec3 sky_top_color : source_color = vec3(0.2, 0.5, 0.95);
uniform vec3 sky_horizon_color : source_color = vec3(0.7, 0.85, 1.0);
uniform vec3 sky_bottom_color : source_color = vec3(0.9, 0.95, 1.0);

uniform float horizon_height : hint_range(-1.0, 1.0) = 0.0;
uniform float gradient_sharpness : hint_range(0.1, 5.0) = 1.5;

// Sun settings
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform float sun_size : hint_range(0.0, 0.5) = 0.05;
uniform float sun_glow : hint_range(0.0, 1.0) = 0.3;

// Cloud-like atmosphere bands (stylized)
uniform float atmosphere_bands : hint_range(0.0, 1.0) = 0.1;
uniform float band_frequency : hint_range(1.0, 20.0) = 5.0;

void sky() {
    // Get the vertical position (-1 to 1)
    float y = EYEDIR.y;

    // Create smooth gradient
    float horizon_blend = smoothstep(-0.5, 0.5, (y - horizon_height) * gradient_sharpness);
    float bottom_blend = smoothstep(-0.3, 0.1, y);

    // Mix colors based on height
    vec3 sky_color = mix(sky_bottom_color, sky_horizon_color, bottom_blend);
    sky_color = mix(sky_color, sky_top_color, horizon_blend);

    // Add stylized atmosphere bands (subtle horizontal lines like in anime)
    float band = sin(y * band_frequency * 10.0) * 0.5 + 0.5;
    band = smoothstep(0.4, 0.6, band);
    sky_color = mix(sky_color, sky_color * 1.05, band * atmosphere_bands);

    // Add sun glow
    vec3 sun_dir = LIGHT0_DIRECTION;
    float sun_dot = dot(EYEDIR, sun_dir);
    float sun_disc = smoothstep(1.0 - sun_size, 1.0 - sun_size * 0.5, sun_dot);
    float sun_glow_factor = smoothstep(0.7, 1.0, sun_dot) * sun_glow;

    sky_color = mix(sky_color, sun_color, sun_disc);
    sky_color += sun_color * sun_glow_factor * 0.3;

    // Slightly boost saturation for anime look
    float luma = dot(sky_color, vec3(0.299, 0.587, 0.114));
    sky_color = mix(vec3(luma), sky_color, 1.2);

    COLOR = vec3(sky_color);
}
