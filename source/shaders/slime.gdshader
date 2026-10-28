shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;
// เยลลี่ใส ๆ มันวาว แบบสไลม์เกมเดิม (ฟ้า→น้ำเงิน) กระพริบขาวแดงตอนโดนตี

uniform vec3 top_col : source_color = vec3(0.62, 0.86, 1.0);
uniform vec3 deep_col : source_color = vec3(0.10, 0.32, 0.85);
uniform float hurt = 0.0;
uniform float alpha_base = 0.82;

varying vec3 lpos;

void vertex() {
    lpos = VERTEX;
}

void fragment() {
    float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
    float up = clamp(lpos.y * 1.2 + 0.4, 0.0, 1.0);
    vec3 c = mix(deep_col, top_col, up);
    c = mix(c, vec3(1.0, 0.55, 0.55), hurt);
    ALBEDO = c * 0.9;
    ROUGHNESS = 0.08;
    METALLIC = 0.0;
    SPECULAR = 0.9;
    CLEARCOAT = 1.0;
    CLEARCOAT_ROUGHNESS = 0.05;
    BACKLIGHT = c * 0.6;
    RIM = 0.4;
    RIM_TINT = 0.6;
    EMISSION = c * (0.03 + fres * 0.25) + vec3(hurt * 0.4);
    ALPHA = clamp(alpha_base + fres * 0.18, 0.0, 1.0);
}
