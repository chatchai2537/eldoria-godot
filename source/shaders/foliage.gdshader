shader_type spatial;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float sway = 0.25;
varying vec3 tint;
varying vec3 wpos;
void vertex() {
	tint = COLOR.rgb;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(VERTEX.y + 0.5, 0.0);
	float s = sin(TIME * 1.4 + wp.x * 0.2 + wp.z * 0.17) * sway * h * 0.15;
	VERTEX.x += s;
	VERTEX.z += s * 0.7;
	wpos = wp;
}
void fragment() {
	float n = texture(noise_tex, wpos.xz * 0.35 + wpos.y * 0.2).r;
	float luma = dot(tint, vec3(0.21, 0.72, 0.07));
	ALBEDO = mix(tint, vec3(luma), 0.16) * (0.78 + 0.24 * n);
	ROUGHNESS = 0.8;
	SPECULAR = 0.25;
	BACKLIGHT = tint * 0.12;
}
