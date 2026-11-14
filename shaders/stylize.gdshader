shader_type canvas_item;

uniform float levels = 6.0;
uniform float saturation = 1.15;
uniform float contrast = 0.88;
uniform float lift = 0.04;
uniform float wither = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 col = c.rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 dry = vec3(l) * vec3(1.18, 1.0, 0.68);
	col = mix(col, dry, wither);
	col = mix(vec3(l), col, saturation);
	col = (col - 0.5) * contrast + 0.5 + lift;
	col = floor(clamp(col, 0.0, 1.0) * levels + 0.5) / levels;
	COLOR = vec4(col, c.a);
}
