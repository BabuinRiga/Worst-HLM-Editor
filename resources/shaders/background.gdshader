shader_type canvas_item;
uniform vec4 bg_color : source_color = vec4(1.0, 0.0, 1.0, 1.0);

void fragment() {
	COLOR = mix(bg_color, vec4(0.0, 0.0, 0.0, 1.0), UV.y);
}