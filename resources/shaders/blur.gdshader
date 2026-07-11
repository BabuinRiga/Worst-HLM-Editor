shader_type canvas_item;

uniform sampler2D sprite_texture : repeat_disable, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 10.0) = 2.0;
uniform vec4  tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool  dither_enable = true;
uniform float dither_amount : hint_range(0.0, 1.0) = 0.5;

const int SAMPLES = 32;
const int LOD = 2;
const int sLOD = 1 << LOD;

float gold_noise(vec2 uv) {
	const float PHI = 1.6180339887498;
	return fract(tan(distance(uv * PHI, uv)) * uv.x);
}
float gaussian_w(vec2 d, float sigma) {
	return exp(-0.5 * dot(d / sigma, d / sigma));
}

vec4 gaussian_blur(sampler2D sp, vec2 uv, vec2 px, float strength) {
	const float sigma = float(SAMPLES) * 0.25;
	const int   s     = SAMPLES / sLOD;
	
	float jitter = dither_enable
		? (gold_noise(uv * 7919.0) - 0.5) * dither_amount
		: 0.0;
	
	vec4  color  = vec4(0.0);
	float weight = 0.0;
	
	for (int i = 0; i < s * s; i++) {
		vec2 d = vec2(float(i % s), float(i / s)) * float(sLOD)
			- float(SAMPLES) * 0.5
			+ jitter * float(sLOD);
		
		float w  = gaussian_w(d, sigma);
		color += textureLod(sp, uv + px * d * strength, float(LOD)) * w;
		weight += w;
	}
	
	return color / weight;
}

void fragment() {
	vec2 uv = UV;
	vec2 px = 1.0 / vec2(textureSize(sprite_texture, 0));
	
	COLOR = gaussian_blur(sprite_texture, uv, px, blur_strength) * tint;
}