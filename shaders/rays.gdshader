shader_type canvas_item;

uniform float intensity = 0.15;

void fragment() {
	vec2 p = UV;
	float a = p.x * 1.2 + p.y * 0.7;
	float r = pow(max(0.0, sin(a * 14.0 + sin(a * 4.0 + TIME * 0.25) * 2.0)), 10.0);
	r = floor(r * 4.0) / 4.0;
	COLOR = vec4(1.0, 0.96, 0.78, r * intensity * (1.0 - p.y));
}
