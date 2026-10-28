shader_type spatial;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 grass_a : source_color = vec3(0.17, 0.25, 0.13);
uniform vec3 grass_b : source_color = vec3(0.32, 0.40, 0.23);
uniform vec3 dirt : source_color = vec3(0.43, 0.35, 0.25);
uniform vec3 rock : source_color = vec3(0.46, 0.45, 0.42);
uniform vec3 sand : source_color = vec3(0.72, 0.64, 0.45);
varying vec3 wpos;
varying vec3 wnorm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float n1 = texture(noise_tex, wpos.xz * 0.012).r;
	float n2 = texture(noise_tex, wpos.xz * 0.07).r;
	float n3 = texture(noise_tex, wpos.xz * 0.45).r;
	vec3 g = mix(grass_a, grass_b, smoothstep(0.3, 0.75, n1));
	g = mix(g, g * vec3(1.08, 0.95, 0.7), smoothstep(0.55, 0.8, n2) * 0.5);
	g *= 0.82 + 0.32 * n3;
	float slope = 1.0 - clamp(wnorm.y, 0.0, 1.0);
	vec3 c = mix(g, rock * (0.75 + 0.45 * n2), smoothstep(0.22, 0.42, slope + (n3 - 0.5) * 0.1));
	float path = COLOR.r + (n2 - 0.5) * 0.35;
	c = mix(c, dirt * (0.8 + 0.35 * n3), smoothstep(0.35, 0.65, path));
	c = mix(c, sand * (0.9 + 0.2 * n3), clamp(COLOR.g, 0.0, 1.0));
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
