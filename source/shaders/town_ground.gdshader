shader_type spatial;
// พื้นในเมือง: แผนที่ช่อง (R=ถนนหิน G=พื้นหินอ่อนวิหาร B=ลานดินฝึก) ช่องละ 2 เมตร
uniform sampler2D tilemap : filter_nearest;
uniform vec2 map_size = vec2(44.0, 34.0);
uniform vec2 origin = vec2(-44.0, -34.0);
uniform float tile = 2.0;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 grass_a : source_color = vec3(0.26, 0.45, 0.14);
uniform vec3 grass_b : source_color = vec3(0.45, 0.6, 0.2);
uniform vec3 stone_a : source_color = vec3(0.42, 0.40, 0.37);
uniform vec3 stone_b : source_color = vec3(0.56, 0.52, 0.46);
uniform vec3 marble : source_color = vec3(0.66, 0.64, 0.6);
uniform vec3 dirt : source_color = vec3(0.55, 0.42, 0.28);
varying vec3 wpos;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex(){ wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	vec2 t = (wpos.xz - origin) / tile;
	vec4 m = texture(tilemap, (floor(t) + 0.5) / map_size);
	float n1 = texture(noise_tex, wpos.xz * 0.03).r;
	float n3 = texture(noise_tex, wpos.xz * 0.5).r;
	vec3 g = mix(grass_a, grass_b, smoothstep(0.3, 0.75, n1)) * (0.85 + 0.3 * n3);
	// หินปูถนน: อิฐเรียงสลับแถว ขนาดราว 0.5 x 0.35 เมตร
	vec2 b = wpos.xz * vec2(2.0, 2.9);
	float row = floor(b.y);
	b.x += mod(row, 2.0) * 0.5;
	vec2 cell = floor(b);
	vec2 f = fract(b);
	float edge = min(min(f.x, 1.0 - f.x) * 1.6, min(f.y, 1.0 - f.y) * 1.2);
	float mortar = smoothstep(0.02, 0.09, edge);
	vec3 st = mix(stone_a, stone_b, hash(cell)) * (0.88 + 0.24 * n3);
	st = mix(st * 0.45, st, mortar);
	// หินอ่อนลายตาราง 2 เมตร
	vec2 mc = floor(wpos.xz / 2.0);
	vec2 mf = fract(wpos.xz / 2.0);
	float medge = smoothstep(0.0, 0.03, min(min(mf.x, 1.0 - mf.x), min(mf.y, 1.0 - mf.y)));
	vec3 mb = marble * (mod(mc.x + mc.y, 2.0) < 0.5 ? 1.0 : 0.9) * (0.95 + 0.1 * n3);
	mb = mix(mb * 0.75, mb, medge);
	vec3 c = g;
	c = mix(c, st, m.r);
	c = mix(c, mb, m.g);
	c = mix(c, dirt * (0.85 + 0.3 * n3), m.b);
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.35, m.g);
	SPECULAR = mix(0.2, 0.6, m.g);
}
