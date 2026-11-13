shader_type canvas_item;
// Vignette: tepi layar menggelap; strength & tint diatur dari main.gd (malam hari / stat kritis).
uniform float strength = 0.3;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.05, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 0.85));
	float v = smoothstep(0.32, 0.82, d);
	COLOR = vec4(tint.rgb, v * strength);
}
