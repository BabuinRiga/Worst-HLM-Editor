shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.69, 0.0, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.0, 0.85, 0.85, 1.0);

uniform float speed = 1.2;
uniform float wave_amplitude = 0.4;
uniform float softness = 0.6;

void fragment() {
	float y = UV.y;
	float wave = sin(TIME * speed) * wave_amplitude;
	float mix_factor = (y - 0.5) + wave;
	mix_factor = smoothstep(-softness, softness, mix_factor);
	COLOR = mix(top_color, bottom_color, mix_factor);
}