extends Node3D
## สไลม์ทุ่งหญ้า — กติกาเดียวกับเกมเดิม (js/017-core.js)
## กระโดดเป็นรอบ 0.9 วิ · ไล่ผู้เล่นเมื่อใกล้ (170px) · ชนแล้วตี (คูลดาวน์ 1.2 วิ)
## เลือด = 2 + เลเวล · ตีแรง = 4 + (เลเวล-1)×2

const K := 2.0 / 32.0  # พิกเซลเกมเดิม -> หน่วยโลก 3D (1 ช่อง = 32px = 2 หน่วย)
static var _meshes := {}
static var _eye_material: StandardMaterial3D
static var _shine_material: StandardMaterial3D
static var _blush_material: StandardMaterial3D

static func _sphere(key: String, r: float, h: float, segments: int, rings: int) -> SphereMesh:
    if not _meshes.has(key):
        var mesh := SphereMesh.new()
        mesh.radius = r
        mesh.height = h
        mesh.radial_segments = segments
        mesh.rings = rings
        _meshes[key] = mesh
    return _meshes[key]

## ตัวสไลม์ทรงหยดน้ำ (0.24): ก้นแบนย้วยออกข้าง มีจุกบนหัวโค้งไปด้านหลัง
## จุดกึ่งกลางอยู่ที่ (0,0,0) สูง h กว้างครึ่งหนึ่ง w ลึกครึ่งหนึ่ง d — เครื่องมือต้นแบบ: tools/make_slime.py
static func _drop(key: String, w: float, h: float, d: float, nu: int, nv: int) -> ArrayMesh:
    if _meshes.has(key):
        return _meshes[key]
    var raw := PackedVector3Array()
    var ymin := INF
    var ymax := -INF
    var xmax := 0.0
    var zmax := 0.0
    for j in nv + 1:
        var v := float(j) / nv * PI
        var hh := (1.0 - cos(v)) * 0.5
        var y := hh
        if hh < 0.5:
            y = max(0.5 - (0.5 - hh) * 0.55, 0.0)
        var r := pow(sin(v), 0.6) * (1.0 + 0.12 * pow(1.0 - hh, 2.0))
        var tip := smoothstep(0.86, 1.0, hh)
        r *= 1.0 - 0.5 * tip
        y += 0.16 * pow(tip, 1.6)
        var zoff := -0.10 * tip * tip
        for i in nu:
            var u := float(i) / nu * TAU
            var p := Vector3(r * cos(u) * 0.62, y * 1.12, r * sin(u) * 0.58 + zoff)
            raw.append(p)
            ymin = min(ymin, p.y)
            ymax = max(ymax, p.y)
            xmax = max(xmax, abs(p.x))
            zmax = max(zmax, p.z)
    var verts := PackedVector3Array()
    verts.resize(raw.size())
    for k in raw.size():
        var p := raw[k]
        verts[k] = Vector3(p.x / xmax * w, ((p.y - ymin) / (ymax - ymin) - 0.5) * h, p.z / zmax * d)
    var idx := PackedInt32Array()
    for j in nv:
        for i in nu:
            var a := j * nu + i
            var b := j * nu + (i + 1) % nu
            var c := a + nu
            var e := b + nu
            for n in [a, b, c, b, e, c]:
                idx.append(n)
    var nrm := PackedVector3Array()
    nrm.resize(verts.size())
    for ti in range(0, idx.size(), 3):
        var fn := (verts[idx[ti + 2]] - verts[idx[ti]]).cross(verts[idx[ti + 1]] - verts[idx[ti]])
        for q in 3:
            nrm[idx[ti + q]] += fn
    for k in nrm.size():
        nrm[k] = nrm[k].normalized()
    for i in nu:  # ขั้วล่าง/บน ให้ผิวเรียบ
        nrm[i] = Vector3.DOWN
        nrm[nv * nu + i] = Vector3.UP
    var arr := []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = verts
    arr[Mesh.ARRAY_NORMAL] = nrm
    arr[Mesh.ARRAY_INDEX] = idx
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
    _meshes[key] = mesh
    return mesh

var field
var lv := 1
var hp := 3
var max_hp := 3
var t := 0.0
var dx := 0.0
var dz := 0.0
var hurt := 0.0
var cool := 0.0
var last_atk := -1
var dead := false
var die_t := 0.0
var stun_t := 0.0   # มึนงงจากสกิล

var body: MeshInstance3D
var mat: ShaderMaterial
var vis: Node3D
var shadow: MeshInstance3D
var bar_bg: MeshInstance3D
var bar: MeshInstance3D
var lbl: Label3D
var radius := 0.6
var blood := Color(0.4, 0.72, 1.0)   # สีเมือกที่กระเด็นตอนโดนตี (fx.blood)

func setup(f, level: int, pos: Vector3) -> void:
    field = f
    lv = level
    hp = 2 + lv
    max_hp = hp
    t = randf() * 0.9
    position = pos
    radius = 0.55 + lv * 0.04
    vis = Node3D.new()
    add_child(vis)
    body = MeshInstance3D.new()
    var mob: bool = field.town.is_mobile
    var bw := radius * 1.12   # กว้างครึ่งหนึ่ง
    var bh := radius * 1.75   # สูง
    var bd := radius * 1.05   # ลึกครึ่งหนึ่ง
    body.mesh = _drop("drop_%d_%s" % [lv, mob], bw, bh, bd, 24 if mob else 40, 14 if mob else 24)
    mat = ShaderMaterial.new()
    mat.shader = preload("res://shaders/slime.gdshader")
    var tint: Color = [Color(0.4, 0.72, 1.0), Color(0.45, 0.95, 0.55), Color(1.0, 0.85, 0.3), Color(1.0, 0.5, 0.3), Color(0.8, 0.45, 1.0)][clampi(lv - 1, 0, 4)]
    var deep: Color = [Color(0.04, 0.2, 0.75), Color(0.04, 0.45, 0.2), Color(0.75, 0.45, 0.0), Color(0.7, 0.15, 0.05), Color(0.4, 0.08, 0.65)][clampi(lv - 1, 0, 4)]
    mat.set_shader_parameter("top_col", tint)
    blood = tint
    mat.set_shader_parameter("deep_col", deep)
    body.material_override = mat
    body.position.y = bh * 0.5
    vis.add_child(body)
    # หน้า: ตาโต + ประกายแสง 2 จุด + แก้มชมพู + ปาก (ตำแหน่งวัดจากผิวทรงหยดน้ำ)
    if _eye_material == null:
        _eye_material = StandardMaterial3D.new()
        _eye_material.albedo_color = Color(0.03, 0.05, 0.14)
        _eye_material.roughness = 0.1
        _shine_material = StandardMaterial3D.new()
        _shine_material.albedo_color = Color(1, 1, 1)
        _shine_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        _blush_material = StandardMaterial3D.new()
        _blush_material.albedo_color = Color(1.0, 0.55, 0.72)
        _blush_material.roughness = 0.6
    var eye_y := bh * 0.47
    for sx in [-1.0, 1.0]:
        var e := MeshInstance3D.new()
        e.mesh = _sphere("eye_%d" % lv, radius * 0.15, radius * 0.44, 10, 6)
        e.material_override = _eye_material
        e.position = Vector3(sx * bw * 0.234, eye_y, bd * 0.86)
        e.scale = Vector3(1, 1, 0.6)
        vis.add_child(e)
        var hl := MeshInstance3D.new()
        hl.mesh = _sphere("shine_%d" % lv, radius * 0.045, radius * 0.1, 8, 4)
        hl.material_override = _shine_material
        hl.position = e.position + Vector3(radius * 0.04, radius * 0.08, radius * 0.08)
        vis.add_child(hl)
        var hl2 := MeshInstance3D.new()
        hl2.mesh = _sphere("shine2_%d" % lv, radius * 0.02, radius * 0.04, 6, 3)
        hl2.material_override = _shine_material
        hl2.position = e.position + Vector3(-radius * 0.03, -radius * 0.07, radius * 0.08)
        vis.add_child(hl2)
        var ck := MeshInstance3D.new()
        ck.mesh = _sphere("blush_%d" % lv, radius * 0.1, radius * 0.1, 10, 5)
        ck.material_override = _blush_material
        ck.position = Vector3(sx * bw * 0.468, bh * 0.355, bd * 0.86)
        ck.scale = Vector3(1, 0.5, 0.35)
        vis.add_child(ck)
    var mo := MeshInstance3D.new()
    mo.mesh = _sphere("mouth_%d" % lv, radius * 0.075, radius * 0.075, 10, 5)
    mo.material_override = _eye_material
    mo.position = Vector3(0, bh * 0.346, bd * 0.985)
    mo.scale = Vector3(1, 0.5, 0.35)
    vis.add_child(mo)
    shadow = MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(radius * 2.2, radius * 2.2)
    q.orientation = PlaneMesh.FACE_Y
    shadow.mesh = q
    var shm := StandardMaterial3D.new()
    shm.albedo_texture = field.shadow_tex
    shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    shm.albedo_color = Color(0, 0, 0, 0.45)
    shadow.material_override = shm
    shadow.position.y = 0.03
    shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(shadow)
    lbl = Label3D.new()
    lbl.text = "สไลม์ Lv.%d" % lv
    lbl.font = field.town.font
    lbl.font_size = 34
    lbl.pixel_size = 0.01
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.outline_size = 8
    lbl.modulate = Color(0.85, 0.95, 1.0)
    lbl.position.y = radius * 2.0 + 0.55
    lbl.no_depth_test = false
    add_child(lbl)
    bar_bg = _bar(Color(0.1, 0.05, 0.05), 1.1, 0.0)
    bar = _bar(Color(0.9, 0.2, 0.2), 1.06, 0.002)
    bar_bg.visible = false
    bar.visible = false

func _bar(c: Color, w: float, z: float) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(w, 0.12)
    m.mesh = q
    var bm := StandardMaterial3D.new()
    bm.albedo_color = c
    bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    bm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    bm.no_depth_test = true
    bm.render_priority = 2 if z > 0 else 1
    m.material_override = bm
    m.position.y = radius * 2.0 + 0.25
    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(m)
    return m

## แถบเลือดหันหาจอ (billboard) ไม่สนค่า scale → ย่อความกว้างเมชเองแล้วชิดซ้าย
func _bar_frac(f: float) -> void:
    var q: QuadMesh = bar.mesh
    var w: float = bar.get_meta("w", q.size.x)
    bar.set_meta("w", w)
    q.size.x = max(0.001, w * f)
    q.center_offset.x = -w * (1.0 - f) * 0.5

func take_hit(dmg: int, _from: Vector3) -> void:
    hp -= dmg
    hurt = 0.25
    bar_bg.visible = true
    bar.visible = true
    var f: float = clamp(float(hp) / max_hp, 0.0, 1.0)
    _bar_frac(f)
    if hp <= 0:
        dead = true
        die_t = 0.45

func _process(delta: float) -> void:
    if dead:
        die_t -= delta
        var s: float = max(die_t / 0.45, 0.0)
        vis.scale = Vector3(1.0 + (1.0 - s) * 0.8, s, 1.0 + (1.0 - s) * 0.8)
        mat.set_shader_parameter("alpha_base", 0.82 * s)
        lbl.visible = false
        bar.visible = false
        bar_bg.visible = false
        if die_t <= 0.0:
            queue_free()
        return
    if stun_t > 0.0:
        stun_t -= delta
        hurt = max(0.0, hurt - delta)
        mat.set_shader_parameter("hurt", hurt / 0.25)
        vis.rotation.z = sin(stun_t * 25.0) * 0.1
        return
    vis.rotation.z = 0.0
    var p: Node3D = field.town.player
    var prev := fmod(t, 0.9)
    t += delta
    var cyc := fmod(t, 0.9)
    var to := Vector3(p.position.x - position.x, 0, p.position.z - position.z)
    var dist := to.length()
    if cyc < prev:
        if dist < 14.0 and field.town.get("sfx") != null:
            field.town.sfx.at("slime_hop", position, -10.0, 0.12, 90)
        if dist < 170.0 * K and not p.dead:
            dx = to.x / max(dist, 0.01)
            dz = to.z / max(dist, 0.01)
        elif randf() < 0.7:
            var a := randf() * TAU
            dx = cos(a)
            dz = sin(a)
        else:
            dx = 0.0
            dz = 0.0
    if cyc >= 0.3 and cyc < 0.7:
        _mv(dx * 70.0 * K * delta, dz * 70.0 * K * delta)
    hurt = max(0.0, hurt - delta)
    cool = max(0.0, cool - delta)
    if p.iframe <= 0.0 and not p.dead and cyc >= 0.3 and cool <= 0.0 and hurt <= 0.0 and dist < 1.35:
        cool = 1.2
        p.hurt_by(self)
    # ท่าทาง: ยุบ -> เด้งขึ้น -> ลงพื้น (เหมือน drawSlime เดิม)
    var sy := 1.0
    var z := 0.0
    if cyc < 0.3:
        sy = 1.0 - 0.22 * (cyc / 0.3)
    elif cyc < 0.7:
        var u := (cyc - 0.3) / 0.4
        z = sin(u * PI) * 16.0 * K
        sy = 1.0 + 0.16 * sin(u * PI)
    else:
        var u2: float = min(1.0, (cyc - 0.7) / 0.2)
        sy = 0.78 + 0.22 * u2
    var sx := 1.0 + (1.0 - sy) * 0.9
    vis.scale = Vector3(sx, sy, sx)
    vis.position.y = z
    var k := 1.0 - z / (50.0 * K)
    shadow.scale = Vector3(k, 1, k)
    if dx != 0.0 or dz != 0.0:
        vis.rotation.y = lerp_angle(vis.rotation.y, atan2(dx, dz), min(1.0, delta * 6.0))
    mat.set_shader_parameter("hurt", hurt / 0.25)
    position.y = field.town.ground_y(position.x, position.z)

func _mv(mx: float, mz: float) -> void:
    if not field.town.blocked(position.x + mx, position.z) and field.in_field(position.x + mx, position.z):
        position.x += mx
    if not field.town.blocked(position.x, position.z + mz) and field.in_field(position.x, position.z + mz):
        position.z += mz
