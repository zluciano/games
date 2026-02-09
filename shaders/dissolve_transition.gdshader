shader_type canvas_item;

uniform sampler2D mask_texture;
uniform float threshold : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	float mask_value = texture(mask_texture, UV).r;
	if (mask_value < threshold) {
		COLOR = fade_color;
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
