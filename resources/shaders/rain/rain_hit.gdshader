shader_type canvas_item;
render_mode blend_mix;

uniform sampler2DArray splash_frames : filter_nearest; 
uniform int num_frames = 1;

varying vec4 custom_data;
varying vec4 particle_color;

void vertex() {
	custom_data = INSTANCE_CUSTOM;
	particle_color = COLOR;
}

void fragment() {
	float progress = custom_data.w;
	
	if (progress == 0.0) {
		COLOR = particle_color;
	} else {
		int frame = int(progress * float(num_frames));
		frame = clamp(frame, 0, num_frames - 1);
		
		vec4 tex_color = texture(splash_frames, vec3(UV, float(frame)));
		
		COLOR = tex_color * particle_color;;
	}
}