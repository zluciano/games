shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled;

// Post-Process Outline Shader
// Creates anime-style black outlines around all objects using depth and normal edge detection

group_uniforms outline;
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.5, 4.0) = 1.5;
uniform float depth_threshold : hint_range(0.0, 2.0) = 0.15;
uniform float normal_threshold : hint_range(0.0, 2.0) = 0.4;
uniform float depth_normal_blend : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float scale = outline_thickness;
	float half_scale_floor = floor(scale * 0.5);
	float half_scale_ceil = ceil(scale * 0.5);

	vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;

	// Sample positions for Roberts Cross edge detection
	vec2 bottom_left_UV = uv + vec2(-pixel_size.x, pixel_size.y) * half_scale_floor;
	vec2 top_right_UV = uv + vec2(pixel_size.x, -pixel_size.y) * half_scale_ceil;
	vec2 bottom_right_UV = uv + vec2(pixel_size.x * half_scale_ceil, pixel_size.y * half_scale_floor);
	vec2 top_left_UV = uv + vec2(-pixel_size.x * half_scale_floor, -pixel_size.y * half_scale_ceil);

	// Sample normals
	vec3 normal0 = texture(NORMAL_TEXTURE, bottom_left_UV).rgb;
	vec3 normal1 = texture(NORMAL_TEXTURE, top_right_UV).rgb;
	vec3 normal2 = texture(NORMAL_TEXTURE, bottom_right_UV).rgb;
	vec3 normal3 = texture(NORMAL_TEXTURE, top_left_UV).rgb;

	// Normal edge detection
	vec3 normal_diff_0 = normal1 - normal0;
	vec3 normal_diff_1 = normal3 - normal2;
	float edge_normal = sqrt(dot(normal_diff_0, normal_diff_0) + dot(normal_diff_1, normal_diff_1));
	edge_normal = edge_normal > normal_threshold ? 1.0 : 0.0;

	// Sample depth
	float depth0 = texture(DEPTH_TEXTURE, bottom_left_UV).r;
	float depth1 = texture(DEPTH_TEXTURE, top_right_UV).r;
	float depth2 = texture(DEPTH_TEXTURE, bottom_right_UV).r;
	float depth3 = texture(DEPTH_TEXTURE, top_left_UV).r;

	// Depth edge detection
	float depth_diff_0 = depth1 - depth0;
	float depth_diff_1 = depth3 - depth2;
	float edge_depth = sqrt(pow(depth_diff_0, 2) + pow(depth_diff_1, 2)) * 100.0;

	// Adjust threshold based on depth (thinner lines for distant objects)
	float adjusted_threshold = depth_threshold * depth0 * (1.0 + depth_normal_blend);
	edge_depth = edge_depth > adjusted_threshold ? 1.0 : 0.0;

	// Combine edge detection methods
	float edge = max(edge_depth, edge_normal);

	// Get original screen color
	vec3 screen_color = texture(SCREEN_TEXTURE, uv).rgb;

	// Apply outline
	ALBEDO = mix(screen_color, edge_color.rgb, edge * edge_color.a);
}
