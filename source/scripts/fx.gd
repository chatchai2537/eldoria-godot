extends Node3D
## เอฟเฟกต์การต่อสู้/วาป (เจ้าของสั่ง 29 ต.ค.: เอฟเฟคโดนตี · เลือด · ท่าสกิล · วาป)
## อนุภาคทำเอง (ไม่ใช้ GPUParticles — มือถือ gl_compatibility) · จำกัดจำนวนพร้อมกัน · ใช้เมชร่วมกัน
## hit() ประกาย+วงแสงตรงจุดโดน · blood() หยดเลือดกระเด็นตกพื้นเป็นคราบ · slash() รอยดาบ · cast() วงเวทใต้เท้าตอนร่ายสกิล
## shock() คลื่นกระแทกสกิลวงกว้าง · trail() หางกระสุน · death() มอนแตก · warp() เสาแสงวาป + จอสว่างวาบ · dust() ฝุ่นตอนกลิ้ง

const MAX_P := 140        # อนุภาคพร้อมกันสูงสุด (มือถือ)
const MAX_SPLAT := 24     # คราบเลือดบนพื้น

var town
var parts: Array = []     # {n, v, l, l0, g, s0, ground}
var fades: Array = []     # {n, mat, t, l, grow, a0, spin}
var splats: Array = []
var _sph: SphereMesh
var _box: BoxMesh
var _disc: CylinderMesh
var _ring: TorusMesh
var _mats := {}
var flash: ColorRect

func setup(t) -> void:
    town = t
    _sph = SphereMesh.new()
    _sph.radius = 0.5
    _sph.height = 1.0
    _sph.radial_segments = 6
    _sph.rings = 3
    _box = BoxMesh.new()
    _box.size = Vector3.ONE
    _disc = CylinderMesh.new()
    _disc.top_radius = 1.0
    _disc.bottom_radius = 1.0
    _disc.height = 0.02
    _disc.radial_segments = 20
    _ring = TorusMesh.new()
    _ring.inner_radius = 0.86
    _ring.outer_radius = 1.0
    _ring.rings = 28
    _ring.ring_segments = 4

func build_ui(cl: CanvasLayer) -> void:
    flash = ColorRect.new()
    flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1, 1, 1, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cl.add_child(flash)

## วัสดุอนุภาค: สีทึบเรืองแสง (ใช้ร่วมกันตามสี)
func _pmat(c: Color, glow: float) -> StandardMaterial3D:
    var key := "%s_%.1f" % [c.to_html(false), glow]
    if not _mats.has(key):
        var m := StandardMaterial3D.new()
        m.albedo_color = c
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glow > 0.0 else BaseMaterial3D.SHADING_MODE_PER_PIXEL
        m.roughness = 0.5
        _mats[key] = m
    return _mats[key]

## วัสดุโปร่งแสง (ของชิ้นเดียว · จางลงเอง)
func _amat(c: Color, a: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.no_depth_test = false
    m.albedo_color = Color(c.r, c.g, c.b, a)
    return m

func _part(pos: Vector3, v: Vector3, c: Color, size: float, life: float, grav: float = 14.0, glow: float = 1.0, mesh: Mesh = null, ground: bool = false) -> void:
    if parts.size() >= MAX_P:
        var o: Dictionary = parts.pop_front()
        if is_instance_valid(o.n):
            o.n.queue_free()
    var n := MeshInstance3D.new()
    n.mesh = mesh if mesh != null else _sph
    n.material_override = _pmat(c, glow)
    n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    n.position = pos
    n.scale = Vector3.ONE * size
    add_child(n)
    parts.append({"n": n, "v": v, "l": life, "l0": life, "g": grav, "s0": size, "ground": ground, "c": c})

func _fade(n: MeshInstance3D, mat: StandardMaterial3D, life: float, grow: float, spin: float = 0.0) -> void:
    n.material_override = mat
    n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(n)
    fades.append({"n": n, "mat": mat, "t": 0.0, "l": life, "grow": grow, "a0": mat.albedo_color.a, "s0": n.scale, "spin": spin})

func _gy(x: float, z: float) -> float:
    if town.mine != null and town.mine.cur >= 0:
        return 0.0
    if town.room != "":
        return 0.0
    return town.ground_y(x, z)

# ---------- เอฟเฟกต์ ----------
## จุดโดนตี: วงแสงขาววาบ + ประกาย (คริ = ใหญ่ สีทอง)
func hit(pos: Vector3, from: Vector3, crit: bool = false) -> void:
    var c := Color(1.0, 0.85, 0.35) if crit else Color(1.0, 0.95, 0.8)
    var fl := MeshInstance3D.new()
    fl.mesh = _sph
    fl.position = pos
    fl.scale = Vector3.ONE * (0.8 if crit else 0.55)
    _fade(fl, _amat(c, 0.9), 0.16, 3.5 if crit else 2.6)
    var away := Vector3(pos.x - from.x, 0, pos.z - from.z).normalized()
    for i in (10 if crit else 6):
        var d := (away * 1.2 + Vector3(randf_range(-1, 1), randf_range(0.2, 1.4), randf_range(-1, 1))).normalized()
        _part(pos, d * randf_range(5.0, 9.0), c, randf_range(0.08, 0.13), randf_range(0.2, 0.35), 8.0, 1.0, _box)
    # วงกระแทกหันหน้าหาผู้ตี
    var rg := MeshInstance3D.new()
    rg.mesh = _ring
    rg.position = pos
    rg.scale = Vector3.ONE * 0.25
    if away.length() > 0.1:
        rg.look_at_from_position(pos, pos + away, Vector3.UP if abs(away.y) < 0.9 else Vector3.FORWARD)
        rg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
    _fade(rg, _amat(c, 0.8), 0.2, 6.0 if crit else 4.5)

## เลือด/ของเหลวกระเด็น · ตกถึงพื้นทิ้งคราบ (สีตามชนิดมอน)
func blood(pos: Vector3, from: Vector3, c: Color, n: int = 8) -> void:
    var away := Vector3(pos.x - from.x, 0, pos.z - from.z).normalized()
    for i in n:
        var d := away * randf_range(1.5, 4.0) + Vector3(randf_range(-1.6, 1.6), randf_range(2.0, 5.0), randf_range(-1.6, 1.6))
        _part(pos, d, c, randf_range(0.07, 0.14), 1.2, 18.0, 0.0, _sph, true)

func _splat(pos: Vector3, c: Color) -> void:
    if splats.size() >= MAX_SPLAT:
        var o: Dictionary = splats.pop_front()
        if is_instance_valid(o.n):
            o.n.queue_free()
    var n := MeshInstance3D.new()
    n.mesh = _disc
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(c.r * 0.7, c.g * 0.7, c.b * 0.7, 0.85)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.roughness = 0.3
    n.material_override = m
    n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var r := randf_range(0.15, 0.32)
    n.scale = Vector3(r, 1, r * randf_range(0.6, 1.0))
    n.rotation.y = randf() * TAU
    n.position = Vector3(pos.x, _gy(pos.x, pos.z) + 0.03, pos.z)
    add_child(n)
    splats.append({"n": n, "m": m, "t": 4.0})

## รอยดาบหน้าตัวผู้เล่น (ครึ่งวงโค้ง จางเร็ว)
func slash(p, col: Color = Color(1.0, 1.0, 0.95), big: bool = false) -> void:
    var rg := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 1.25 if not big else 2.1
    tm.outer_radius = 1.5 if not big else 2.5
    tm.rings = 24
    tm.ring_segments = 3
    rg.mesh = tm
    rg.position = p.position + Vector3(0, 1.05, 0) + Vector3(sin(p.heading), 0, cos(p.heading)) * 0.5
    rg.rotation = Vector3(randf_range(-0.35, 0.35), p.heading, randf_range(-0.3, 0.3))
    rg.scale = Vector3(1, 0.08, 1)
    _fade(rg, _amat(col, 0.75), 0.22, 0.35, 9.0)

## วงเวทใต้เท้า + แสงที่มือ ตอนร่ายสกิล
func cast(p, col: Color) -> void:
    var d := MeshInstance3D.new()
    d.mesh = _ring
    d.position = Vector3(p.position.x, _gy(p.position.x, p.position.z) + 0.06, p.position.z)
    d.scale = Vector3(1.6, 0.05, 1.6)
    _fade(d, _amat(col, 0.9), 0.55, 0.4, 3.0)
    var d2 := MeshInstance3D.new()
    d2.mesh = _disc
    d2.position = d.position
    d2.scale = Vector3(1.4, 1, 1.4)
    _fade(d2, _amat(col, 0.25), 0.55, 0.3)
    for i in 10:
        var a := i * TAU / 10.0
        _part(p.position + Vector3(cos(a) * 1.3, 0.1, sin(a) * 1.3), Vector3(-cos(a) * 0.8, randf_range(2.5, 4.0), -sin(a) * 0.8), col, 0.08, 0.5, -1.0, 1.0)

## คลื่นกระแทกสกิลวงกว้าง: วงแหวนขยาย + แผ่นแสง + เศษพื้น
func shock(at: Vector3, radius: float, col: Color) -> void:
    var gy := _gy(at.x, at.z)
    var rg := MeshInstance3D.new()
    rg.mesh = _ring
    rg.position = Vector3(at.x, gy + 0.15, at.z)
    rg.scale = Vector3(radius * 0.3, 0.12, radius * 0.3)
    _fade(rg, _amat(col, 0.95), 0.35, 2.4)
    var dk := MeshInstance3D.new()
    dk.mesh = _disc
    dk.position = Vector3(at.x, gy + 0.08, at.z)
    dk.scale = Vector3(radius, 1, radius)
    _fade(dk, _amat(col, 0.35), 0.3, 0.1)
    var col_b := MeshInstance3D.new()
    col_b.mesh = _sph
    col_b.position = Vector3(at.x, gy + 0.5, at.z)
    col_b.scale = Vector3(radius * 0.5, 0.6, radius * 0.5)
    _fade(col_b, _amat(col, 0.5), 0.22, 1.6)
    for i in int(clamp(radius * 5.0, 8.0, 20.0)):
        var a := randf() * TAU
        var r := randf_range(0.3, radius)
        _part(Vector3(at.x + cos(a) * r, gy + 0.2, at.z + sin(a) * r), Vector3(cos(a) * 2.0, randf_range(3.0, 6.5), sin(a) * 2.0), col.lerp(Color(1, 1, 1), 0.3), randf_range(0.07, 0.13), randf_range(0.35, 0.6), 14.0, 1.0, _box)

## หางกระสุน (เรียกทุกเฟรมของกระสุน)
func trail(pos: Vector3, col: Color) -> void:
    if parts.size() > MAX_P - 20:
        return
    _part(pos + Vector3(randf_range(-0.08, 0.08), randf_range(-0.08, 0.08), randf_range(-0.08, 0.08)), Vector3(0, 0.6, 0), col, randf_range(0.08, 0.14), 0.25, 0.0, 1.0)

## มอนตาย: แตกเป็นชิ้น + วงแสง
func death(pos: Vector3, c: Color, big: bool = false) -> void:
    var k := 2.0 if big else 1.0
    for i in int(12 * k):
        var d := Vector3(randf_range(-1, 1), randf_range(0.4, 1.6), randf_range(-1, 1)).normalized()
        _part(pos + Vector3(0, 0.5, 0), d * randf_range(3.0, 6.5) * k, c, randf_range(0.1, 0.2) * k, randf_range(0.5, 0.9), 16.0, 0.0, _box, true)
    var fl := MeshInstance3D.new()
    fl.mesh = _sph
    fl.position = pos + Vector3(0, 0.6, 0)
    fl.scale = Vector3.ONE * 0.6 * k
    _fade(fl, _amat(Color(1, 1, 1), 0.7), 0.25, 2.5)

## วาป: เสาแสง + วงแหวนพื้น + ประกายลอยขึ้น + จอวาบ
func warp(pos: Vector3, col: Color = Color(0.7, 0.55, 1.0), screen: bool = true) -> void:
    var gy := _gy(pos.x, pos.z)
    var b := Vector3(pos.x, gy, pos.z)
    var pil := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.9
    cm.bottom_radius = 1.2
    cm.height = 9.0
    cm.radial_segments = 16
    cm.cap_top = false
    cm.cap_bottom = false
    pil.mesh = cm
    pil.position = b + Vector3(0, 4.5, 0)
    _fade(pil, _amat(col, 0.55), 0.9, -0.6, 2.0)
    var core := MeshInstance3D.new()
    var cm2 := CylinderMesh.new()
    cm2.top_radius = 0.35
    cm2.bottom_radius = 0.5
    cm2.height = 9.0
    cm2.radial_segments = 10
    cm2.cap_top = false
    cm2.cap_bottom = false
    core.mesh = cm2
    core.position = pil.position
    _fade(core, _amat(Color(1, 1, 1), 0.7), 0.7, -0.7)
    for r in [1.0, 1.8]:
        var rg := MeshInstance3D.new()
        rg.mesh = _ring
        rg.position = b + Vector3(0, 0.08, 0)
        rg.scale = Vector3(r, 0.05, r)
        _fade(rg, _amat(col, 0.9), 0.8, 1.6, 2.5)
    for i in 26:
        var a := randf() * TAU
        var r2 := randf_range(0.2, 1.3)
        _part(b + Vector3(cos(a) * r2, randf_range(0.1, 1.5), sin(a) * r2), Vector3(cos(a + 1.5) * 1.2, randf_range(4.0, 8.0), sin(a + 1.5) * 1.2), col.lerp(Color(1, 1, 1), randf() * 0.6), randf_range(0.06, 0.12), randf_range(0.6, 1.1), -1.5, 1.0)
    if screen and flash != null:
        flash.color = Color(col.r * 0.6 + 0.4, col.g * 0.6 + 0.4, col.b * 0.6 + 0.4, 0.45)
        var tw := create_tween()
        tw.tween_property(flash, "color:a", 0.0, 0.45)
    if town.get("sfx") != null:
        town.sfx.play("warp", -4.0)

## ฝุ่นตอนกลิ้ง/วิ่งแรง
func dust(pos: Vector3, n: int = 3) -> void:
    var gy := _gy(pos.x, pos.z)
    for i in n:
        _part(Vector3(pos.x + randf_range(-0.3, 0.3), gy + 0.15, pos.z + randf_range(-0.3, 0.3)), Vector3(randf_range(-1, 1), randf_range(0.6, 1.6), randf_range(-1, 1)), Color(0.78, 0.72, 0.6), randf_range(0.14, 0.24), 0.45, 1.0, 0.0)

func _process(delta: float) -> void:
    for i in range(parts.size() - 1, -1, -1):
        var q: Dictionary = parts[i]
        var n: MeshInstance3D = q.n
        q.l -= delta
        if q.l <= 0.0 or not is_instance_valid(n):
            if is_instance_valid(n):
                n.queue_free()
            parts.remove_at(i)
            continue
        var v: Vector3 = q.v
        v.y -= q.g * delta
        q.v = v
        n.position += v * delta
        if q.ground:
            var gy := _gy(n.position.x, n.position.z)
            if n.position.y <= gy + 0.05 and v.y < 0.0:
                if randf() < 0.35:
                    _splat(n.position, q.c)
                n.queue_free()
                parts.remove_at(i)
                continue
        n.scale = Vector3.ONE * q.s0 * clampf(q.l / (q.l0 * 0.5), 0.0, 1.0)
    for i in range(fades.size() - 1, -1, -1):
        var f: Dictionary = fades[i]
        var n2: MeshInstance3D = f.n
        f.t += delta
        if f.t >= f.l or not is_instance_valid(n2):
            if is_instance_valid(n2):
                n2.queue_free()
            fades.remove_at(i)
            continue
        var u: float = f.t / f.l
        var s0: Vector3 = f.s0
        var g: float = 1.0 + f.grow * u
        # ของแบน (วงแหวน/แผ่น) ไม่ขยายแนวตั้ง · เสาแสง (grow ติดลบ) หดแค่ด้านข้าง
        var gyv: float = s0.y if (s0.y < 0.2 or f.grow < 0.0) else s0.y * g
        n2.scale = Vector3(s0.x * g, gyv, s0.z * g)
        if f.spin != 0.0:
            n2.rotate_object_local(Vector3.UP, f.spin * delta)
        var c: Color = f.mat.albedo_color
        c.a = f.a0 * (1.0 - u)
        f.mat.albedo_color = c
    for i in range(splats.size() - 1, -1, -1):
        var s: Dictionary = splats[i]
        s.t -= delta
        if s.t <= 1.0:
            var c2: Color = s.m.albedo_color
            c2.a = max(0.0, 0.85 * s.t)
            s.m.albedo_color = c2
        if s.t <= 0.0:
            if is_instance_valid(s.n):
                s.n.queue_free()
            splats.remove_at(i)
