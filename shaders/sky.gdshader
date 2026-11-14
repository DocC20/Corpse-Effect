shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.45, 0.72, 0.95, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.98, 0.88, 0.7, 1.0);
uniform float bands = 45.0;
uniform float stars = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float y = floor(UV.y * bands) / bands;
	vec4 col = mix(top_color, bottom_color, y);
	vec2 px = floor(UV * vec2(640.0, 180.0));
	float h = hash(px);
	float twinkle = 0.6 + 0.4 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
	float star = step(0.9975, h) * (1.0 - UV.y * 1.2) * twinkle * stars;
	col.rgb += vec3(0.75, 0.82, 1.0) * max(star, 0.0);
	COLOR = col;
}
