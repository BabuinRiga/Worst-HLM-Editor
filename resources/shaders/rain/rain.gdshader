shader_type particles;

uniform vec2 camera_pos;
uniform vec2 camera_size;
uniform vec2 camera_half_size_offset;
uniform vec2 wind_velocity;

uniform float drop_length = 4.0;
uniform float z_speed = 60.0;
uniform float line_width = 2.0;

uniform float splash_speed = 8.0;
uniform vec2 splash_size = vec2(16.0, 16.0);

uniform float dead_zone_radius = 200.0;

uniform vec4 exclusion_rects[100];
uniform int exclusion_count = 0;

float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0) s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0) s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

void start() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	
	float edge = 50.0;
	
	CUSTOM.x = camera_pos.x - edge + rand_from_seed(alt_seed) * (camera_size.x + edge * 2.0);
	CUSTOM.y = camera_pos.y - edge + rand_from_seed(alt_seed) * (camera_size.y + edge * 2.0);
	CUSTOM.z = 40.0 + rand_from_seed(alt_seed) * 10.0;
	
	vec2 center = camera_pos + camera_half_size_offset;
	vec2 spawn_pos = vec2(CUSTOM.x, CUSTOM.y);
	vec2 dir_from_center = spawn_pos - center;
	float dist = length(dir_from_center);
	
	if (dist < dead_zone_radius && dist > 0.0) {
		dir_from_center = normalize(dir_from_center);
		spawn_pos = center + dir_from_center * dead_zone_radius;
		CUSTOM.x = spawn_pos.x;
		CUSTOM.y = spawn_pos.y;
	}
	
	COLOR.rgb = vec3(1.0, 1.0, 1.0); 
	COLOR.a = 0.4;
	CUSTOM.w = 0.0;
}

void process() {
	if (CUSTOM.w == 0.0) {
		CUSTOM.z -= z_speed * DELTA;
		CUSTOM.x += wind_velocity.x * DELTA;
		CUSTOM.y += wind_velocity.y * DELTA;
		
		float halfw = camera_half_size_offset.x;
		float halfh = camera_half_size_offset.y;
		float vx = (CUSTOM.x - (camera_pos.x + halfw)) / (halfw == 0.0 ? 1.0 : halfw);
		float vy = (CUSTOM.y - (camera_pos.y + halfh)) / (halfh == 0.0 ? 1.0 : halfh);
		
		float sqz1 = CUSTOM.z * CUSTOM.z;
		float sqz2 = (CUSTOM.z + drop_length) * (CUSTOM.z + drop_length);
		
		vec2 p1 = vec2(CUSTOM.x + vx * sqz1, CUSTOM.y + vy * sqz1);
		vec2 p2 = vec2(CUSTOM.x + vx * sqz2, CUSTOM.y + vy * sqz2);
		vec2 p1_pixel = floor(p1);
		vec2 p2_pixel = floor(p2);
		
		bool hit = false;
		if (CUSTOM.z < 0.0) {
			hit = true;
		} else {
			for (int i = 0; i < 16; i++) {
				if (i >= exclusion_count) break;
				vec4 r = exclusion_rects[i];
				if (CUSTOM.x >= r.x && CUSTOM.x <= r.z && CUSTOM.y >= r.y && CUSTOM.y <= r.w) {
					hit = true;
					break;
				}
			}
		}
		
		if (hit) {
			CUSTOM.w = 0.001;
			CUSTOM.xy = p1_pixel;
		} else {
			vec2 diff = p2_pixel - p1_pixel;
			float len = length(diff);
			if (len > 0.001) {
				vec2 dir = diff / len;
				vec2 right = vec2(-dir.y, dir.x);
				TRANSFORM[0].xy = right * line_width;
				TRANSFORM[1].xy = dir * len;
			} else {
				TRANSFORM[0].xy = vec2(line_width, 0.0);
				TRANSFORM[1].xy = vec2(0.0, 0.001);
			}
			TRANSFORM[3].xy = p1_pixel;
			COLOR.a = 0.4;
		}
	}
	
	if (CUSTOM.w > 0.0) {
		CUSTOM.w += DELTA * splash_speed;
		
		if (CUSTOM.w >= 1.0) {
			ACTIVE = false;
		} else {
			TRANSFORM[0].xy = vec2(splash_size.x, 0.0);
			TRANSFORM[1].xy = vec2(0.0, splash_size.y);
			
			TRANSFORM[3].xy = CUSTOM.xy - vec2(0.0, splash_size.y / 2.0);
			
			COLOR.a = mix(1.0, 0.0, CUSTOM.w * CUSTOM.w); 
		}
	}
	
	TRANSFORM[3].z = 0.0;
}