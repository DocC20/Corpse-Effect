shader_type canvas_item;

uniform float strength = 0.3;
uniform float grain = 0.04;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 0.8);
	float v = smoothstep(0.3, 0.75, length(d) * 1.3);
	float n = hash(floor(UV * vec2(320.0, 180.0)) + floor(TIME * 10.0));
	COLOR = vec4(tint.rgb, clamp(v * strength + n * grain, 0.0, 1.0));
}
