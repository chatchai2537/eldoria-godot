shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform vec3 deep : source_color = vec3(0.04, 0.20, 0.28);
uniform vec3 shallow : source_color = vec3(0.22, 0.55, 0.55);
uniform float alpha = 0.86;
uniform float wave = 0.06;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (sin(TIME * 1.3 + wpos.x * 0.45) + cos(TIME * 1.1 + wpos.z * 0.5)) * wave;
}
void fragment() {
	float n = texture(noise_tex, wpos.xz * 0.06 + vec2(TIME * 0.02, TIME * 0.013)).r;
	float n2 = texture(noise_tex, wpos.xz * 0.11 - vec2(TIME * 0.017, -TIME * 0.008)).r;
	NORMAL_MAP = normalize(vec3(n - 0.5, n2 - 0.5, 0.6)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.7;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(deep, shallow, 0.35 + fr * 0.5 + (n - 0.5) * 0.2);
	ROUGHNESS = 0.04;
	METALLIC = 0.1;
	SPECULAR = 0.9;
	ALPHA = mix(alpha, 1.0, fr);
}
