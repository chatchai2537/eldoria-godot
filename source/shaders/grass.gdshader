shader_type spatial;
render_mode cull_disabled;
uniform vec3 base_col : source_color = vec3(0.1, 0.22, 0.05);
uniform vec3 tip_col : source_color = vec3(0.45, 0.6, 0.18);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float wind = 1.0;
varying float hgt;
varying vec3 tint;
void vertex() {
	hgt = VERTEX.y;
	tint = COLOR.rgb;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = texture(noise_tex, wp.xz * 0.015 + vec2(TIME * 0.06, TIME * 0.035)).r;
	float b = (sin(TIME * 2.2 + wp.x * 0.35 + wp.z * 0.25) * 0.12 + (gust - 0.4) * 0.9) * VERTEX.y * VERTEX.y * wind;
	VERTEX.x += b;
	VERTEX.z += b * 0.6;
	NORMAL = vec3(0.0, 1.0, 0.0);
}
void fragment() {
	float t = clamp(hgt / 1.0, 0.0, 1.0);
	ALBEDO = mix(base_col, tip_col, t) * tint;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
	BACKLIGHT = vec3(0.35, 0.45, 0.12) * t;
}
