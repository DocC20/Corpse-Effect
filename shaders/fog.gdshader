shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(1.0);
uniform float density = 0.3;
uniform float speed = 0.015;
uniform float scale = 3.0;
uniform float height = 0.5;
uniform vec2 res = vec2(160.0, 90.0);
uniform float steps = 6.0;
uniform int octaves = 4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		if (k >= octaves) {
			break;
		}
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 q = floor(UV * res) / res;
	vec2 uv = q * vec2(scale * 1.8, scale);
	uv.x += TIME * speed * scale;
	uv.y += sin(TIME * 0.2) * 0.1;
	float n = fbm(uv);
	float band = smoothstep(height - 0.25, 1.0, q.y);
	float a = fog_color.a * density * smoothstep(0.35, 0.8, n) * band;
	a = floor(a * steps) / steps;
	COLOR = vec4(fog_color.rgb, a);
}
