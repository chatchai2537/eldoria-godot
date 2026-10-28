shader_type spatial;
render_mode unshaded, cull_disabled;
// วงประตูมิติหมุนวน สีม่วง-ขาว เหมือนเกม 2D
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) { discard; }
	float a = atan(p.y, p.x);
	float sw = sin(a * 3.0 + r * 9.0 - TIME * 3.0) * 0.5 + 0.5;
	vec3 inner = vec3(0.95, 0.88, 1.0);
	vec3 mid = vec3(0.68, 0.43, 1.0);
	vec3 outer = vec3(0.27, 0.12, 0.55);
	vec3 c = mix(inner, mid, smoothstep(0.0, 0.45, r));
	c = mix(c, outer, smoothstep(0.45, 1.0, r));
	c += vec3(0.25, 0.2, 0.35) * sw * (1.0 - r);
	ALBEDO = c;
	EMISSION = c * 0.8;
}
