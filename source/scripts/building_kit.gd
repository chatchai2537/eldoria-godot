extends RefCounted
## ชุดประกอบอาคาร: รวมกล่อง/ปริซึม/ทรงกระบอกทั้งหลังเป็น mesh เดียวต่อวัสดุ
## - draw call น้อยกว่าสร้าง MeshInstance ทีละชิ้น (สำคัญบนมือถือ)
## - UV ตามขนาดจริง (เมตร) ลาย texture จึงไม่ยืดตามขนาดกล่อง
## ใช้: var k := BuildingKit.new(); k.box(mat, size, pos, rot); ... ; k.commit(parent)

const UV_PER_M := 1.0 / 6.0   # วัสดุใช้ uv1_scale 3 → ลายซ้ำทุก 2 เมตร

var _st := {}    # material -> SurfaceTool
var _order := []

func _tool(m: Material) -> SurfaceTool:
    if not _st.has(m):
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        _st[m] = st
        _order.append(m)
    return _st[m]

static func _uv(p: Vector3, n: Vector3) -> Vector2:
    var a := n.abs()
    if a.y >= a.x and a.y >= a.z:
        return Vector2(p.x, p.z) * UV_PER_M
    if a.x >= a.z:
        return Vector2(p.z, -p.y) * UV_PER_M
    return Vector2(p.x, -p.y) * UV_PER_M

## สามเหลี่ยมหน้าเดียว — จัดลำดับจุดให้หน้าหันออกตาม n เอง (Godot: ตามเข็มนาฬิกา = ด้านหน้า)
func tri(m: Material, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
    if (b - a).cross(c - a).dot(n) > 0.0:
        var t := b
        b = c
        c = t
    var st := _tool(m)
    for p in [a, b, c]:
        st.set_normal(n)
        st.set_uv(_uv(p, n))
        st.add_vertex(p)

func quad(m: Material, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
    tri(m, a, b, c, n)
    tri(m, a, c, d, n)

## กล่อง: size, จุดกลาง pos, หมุน rot (ออยเลอร์ YXZ แบบ Node3D)
func box(m: Material, size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
    var b := Basis.from_euler(rot)
    var hx := b.x * size.x * 0.5
    var hy := b.y * size.y * 0.5
    var hz := b.z * size.z * 0.5
    var dirs := [[hx, hy, hz], [-hx, hy, -hz], [hy, hz, hx], [-hy, hz, -hx], [hz, hx, hy], [-hz, hx, -hy]]
    for f in dirs:
        var c: Vector3 = pos + f[0]
        var u: Vector3 = f[1]
        var v: Vector3 = f[2]
        quad(m, c - u - v, c + u - v, c + u + v, c - u + v, f[0].normalized())

## ปริซึมสามเหลี่ยม (จั่ว): กว้าง w ตามแกน X ของมัน, สูง h, ยาว d ตามแกน Z, ฐานอยู่ที่ pos
func prism(m: Material, w: float, h: float, d: float, pos: Vector3, rot_y: float = 0.0) -> void:
    var b := Basis(Vector3.UP, rot_y)
    var l := b * Vector3(-w * 0.5, 0, 0)
    var r := b * Vector3(w * 0.5, 0, 0)
    var t := b * Vector3(0, h, 0)
    var f := b * Vector3(0, 0, d * 0.5)
    var nf := f.normalized()
    tri(m, pos + l + f, pos + r + f, pos + t + f, nf)
    tri(m, pos + l - f, pos + r - f, pos + t - f, -nf)
    var nl := (b * Vector3(-h, w * 0.5, 0)).normalized()
    var nr := (b * Vector3(h, w * 0.5, 0)).normalized()
    quad(m, pos + l + f, pos + t + f, pos + t - f, pos + l - f, nl)
    quad(m, pos + r + f, pos + t + f, pos + t - f, pos + r - f, nr)

## ทรงกระบอก/กรวย ตั้งตรงแกน Y (rt=0 ได้กรวย) · arc < TAU ได้ครึ่งวง (ใช้ทำซุ้มโค้ง)
func cyl(m: Material, rt: float, rb: float, h: float, pos: Vector3, seg: int = 12, rot: Vector3 = Vector3.ZERO, arc: float = TAU, caps: bool = true) -> void:
    var b := Basis.from_euler(rot)
    var up := b * Vector3(0, h * 0.5, 0)
    var slope: float = (rb - rt) / max(h, 0.001)
    for i in seg:
        var a0 := arc * i / seg
        var a1 := arc * (i + 1) / seg
        var d0 := b * Vector3(cos(a0), 0, sin(a0))
        var d1 := b * Vector3(cos(a1), 0, sin(a1))
        var nm := (b * Vector3(cos((a0 + a1) * 0.5), slope, sin((a0 + a1) * 0.5))).normalized()
        quad(m, pos - up + d0 * rb, pos - up + d1 * rb, pos + up + d1 * rt, pos + up + d0 * rt, nm)
        if caps:
            if rt > 0.0:
                tri(m, pos + up, pos + up + d0 * rt, pos + up + d1 * rt, b.y)
            tri(m, pos - up, pos - up + d0 * rb, pos - up + d1 * rb, -b.y)

func commit(parent: Node3D, shadows: bool = true) -> void:
    for m in _order:
        var st: SurfaceTool = _st[m]
        var mi := MeshInstance3D.new()
        mi.mesh = st.commit()
        mi.material_override = m
        if not shadows:
            mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(mi)
    _st.clear()
    _order.clear()
