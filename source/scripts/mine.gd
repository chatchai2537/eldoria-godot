extends Node3D
## เหมือง 5 แห่งผ่านประตูมิติ (js/031-core.js ZONES · genZone · zMine · enterZone · mobKill)
## แผนที่ 62×44 ช่อง (fix ขยายจาก 46×34) · วางไกลทางตะวันออก x = 3000 + ลำดับ×200 · ช่องละ 2 หน่วย

const Mob = preload("res://scripts/mob.gd")
const Items = preload("res://scripts/items.gd")
const ZW := 62
const ZH := 44
const TS := 2.0
const WALL_H := 3.2
const FL := 0
const WL := 1

const ZONES := [
    {"id": "iron", "n": "เหมืองเหล็กร้าง", "lv": [5, 20], "ores": [["iron", 0.55], ["stone", 0.45]], "raw": "iron", "ing": "ingot", "dark": true,
        "pal": {"fl": ["#5c4b3a", "#544434", "#4d3e30"], "top": "#3e352d", "face": "#2a231d", "vd": "#0f0c09"},
        "mobs": [["beetle", "ด้วงหินสนิม", ["#7a5a3a", "#4a3020", "#ff9a4a"]], ["bat", "ค้างคาวเหมือง", ["#5a4a5a", "#2e2430", "#ffd84a"]], ["golem", "โกเลมดินเหนียว", ["#8a6a4a", "#5a422c", "#ffb04a"]]],
        "boss": {"f": "golem", "n": "ราชาโกเลมสนิม", "lv": 25, "c": ["#8a5a3a", "#4a2a18", "#ff6a2a"]}},
    {"id": "copper", "n": "ถ้ำทองแดงลาวา", "lv": [20, 40], "ores": [["copper", 0.55], ["iron", 0.3], ["stone", 0.15]], "raw": "copper", "ing": "ingCu", "dark": true,
        "pal": {"fl": ["#5a3328", "#512d23", "#48281f"], "top": "#3a2119", "face": "#24140e", "vd": "#0d0604"},
        "mobs": [["bat", "ค้างคาวไฟ", ["#a8402a", "#5a1a10", "#ffd84a"]], ["wolf", "หมาป่าสำริด", ["#b8743a", "#6a3a18", "#ffcf5a"]], ["wisp", "ภูตเปลวไฟ", ["#ff9a3a", "#ff4a1a", "#fff2a8"]]],
        "boss": {"f": "beetle", "n": "ด้วงยักษ์หลอมทองแดง", "lv": 45, "c": ["#d0702a", "#6a2a10", "#ffe14a"]}},
    {"id": "silver", "n": "ยอดเขาเงินหิมะ", "lv": [40, 60], "ores": [["silver", 0.5], ["copper", 0.3], ["iron", 0.2]], "raw": "silver", "ing": "ingAg", "dark": false,
        "pal": {"fl": ["#cfdbe7", "#c3d1df", "#b8c8d8"], "top": "#8fa5bd", "face": "#5f738d", "vd": "#1c2532"},
        "mobs": [["wolf", "หมาป่าหิมะ", ["#e8eef6", "#9aaac0", "#7fe0ff"]], ["wisp", "ภูตน้ำแข็ง", ["#bfe8ff", "#5ab4ff", "#ffffff"]], ["golem", "โกเลมน้ำแข็ง", ["#a8d0ec", "#5a86aa", "#c8f4ff"]]],
        "boss": {"f": "wolf", "n": "ราชาหมาป่าน้ำแข็ง", "lv": 65, "c": ["#f2f8ff", "#7a90b0", "#4ac8ff"]}},
    {"id": "gold", "n": "หุบเขาทองคำ", "lv": [60, 80], "ores": [["gold", 0.5], ["silver", 0.3], ["copper", 0.2]], "raw": "gold", "ing": "ingAu", "dark": false,
        "pal": {"fl": ["#d7b26a", "#cfa95e", "#c7a055"], "top": "#a8783a", "face": "#7a5226", "vd": "#2a1c0c"},
        "mobs": [["beetle", "สการับทองคำ", ["#e0b030", "#7a5410", "#7affea"]], ["wisp", "ภูตพายุทราย", ["#f0d090", "#c08a3a", "#fff6c8"]], ["wolf", "หมาป่าทะเลทราย", ["#c89a5a", "#7a5426", "#ff6a4a"]]],
        "boss": {"f": "golem", "n": "ฟาโรห์โกเลมทองคำ", "lv": 85, "c": ["#f2c230", "#8a6010", "#4affd8"]}},
    {"id": "diamond", "n": "ห้วงลึกเพชรนิรันดร์", "lv": [80, 100], "ores": [["diamond", 0.45], ["gold", 0.3], ["silver", 0.25]], "raw": "gem", "ing": "ingDm", "dark": true,
        "pal": {"fl": ["#2f2542", "#2a213b", "#251d35"], "top": "#1e1731", "face": "#130e22", "vd": "#06040b"},
        "mobs": [["bat", "ค้างคาวเงา", ["#4a3a6a", "#1e1430", "#ff4ad8"]], ["golem", "โกเลมคริสตัล", ["#7ad8f0", "#3a6a9a", "#e8fbff"]], ["wisp", "ภูตห้วงลึก", ["#b07aff", "#5a2aaa", "#f4e8ff"]]],
        "boss": {"f": "dragon", "n": "มังกรคริสตัลแห่งห้วงลึก", "lv": 100, "c": ["#7ad8f0", "#2a3a7a", "#f0a8ff"]}},
]

## แร่ (js/015-core.js OREK): req = ระดับที่ขุดแร่ขั้นต่ำ · hp = จำนวนครั้ง (ดาเมจที่ขุด 1+(ระดับ>>1)) · cnt = ได้กี่ก้อน
const OREK := {
    "stone": {"n": "หินธรรมดา", "req": 0, "hp": 6, "drop": "stone", "cnt": [1, 2], "xp": 2, "c": Color(0.75, 0.77, 0.8)},
    "iron": {"n": "แร่เหล็ก", "req": 0, "hp": 7, "drop": "iron", "cnt": [1, 2], "xp": 3, "c": Color(0.78, 0.59, 0.47)},
    "copper": {"n": "แร่ทองแดง", "req": 1, "hp": 8, "drop": "copper", "cnt": [1, 2], "xp": 4, "c": Color(0.94, 0.59, 0.31)},
    "silver": {"n": "แร่เงิน", "req": 2, "hp": 10, "drop": "silver", "cnt": [1, 2], "xp": 7, "c": Color(0.88, 0.92, 1.0)},
    "gold": {"n": "แร่ทอง", "req": 3, "hp": 12, "drop": "gold", "cnt": [1, 2], "xp": 12, "c": Color(1.0, 0.84, 0.31)},
    "diamond": {"n": "แร่เพชร", "req": 4, "hp": 14, "drop": "gem", "cnt": [2, 3], "xp": 20, "c": Color(0.67, 0.92, 1.0)},
}
const PICK_NAMES := ["ที่ขุดแร่หิน", "ที่ขุดแร่เหล็ก", "ที่ขุดแร่ทองแดง", "ที่ขุดแร่เงิน", "ที่ขุดแร่ทอง", "ที่ขุดแร่เพชร"]

var town
var cur := -1
var data := {}          # zi -> {m, ores, ore_at, floor, ent, arena, root, mm}
var mobs: Array = []
var shots: Array = []
var spawn_t := 2.0
var boss = null
var boss_t := 0.1
var exit_ring: MeshInstance3D

func setup(t) -> void:
    town = t

func origin(zi: int) -> Vector3:
    return Vector3(3000.0 + zi * 200.0, 0.0, 0.0)

func tile_w(zi: int, x: float, y: float) -> Vector3:
    return origin(zi) + Vector3(x * TS + TS * 0.5, 0.0, y * TS + TS * 0.5)

func _tile(wx: float, wz: float) -> Vector2i:
    var o := origin(cur)
    return Vector2i(int(floor((wx - o.x) / TS)), int(floor((wz - o.z) / TS)))

## เดินได้ไหม (ผนัง + ก้อนแร่ที่ยังไม่แตก ขวางทาง เหมือน zHit)
func blocked(wx: float, wz: float) -> bool:
    if cur < 0:
        return true
    var d: Dictionary = data[cur]
    var t := _tile(wx, wz)
    if t.x < 0 or t.y < 0 or t.x >= ZW or t.y >= ZH:
        return true
    if d.m[t.y * ZW + t.x] != FL:
        return true
    var o = d.ore_at.get(t.y * ZW + t.x)
    return o != null and o.alive

func blocked_at(wx: float, wz: float, r: float) -> bool:
    for c in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
        if blocked(wx + c.x, wz + c.y):
            return true
    return false

# ---------- สร้างแผนที่ (genZone) ----------
var _rng := RandomNumberGenerator.new()

func _h(x: int, y: int, s: int) -> float:
    var n := (x * 374761393 + y * 668265263 + s * 982451653) & 0x7fffffff
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
    return float(n % 100000) / 100000.0

## value noise แบบ vn() ของเกม 2D
func _vn(x: float, y: float, s: int) -> float:
    var xi := int(floor(x))
    var yi := int(floor(y))
    var fx := x - xi
    var fy := y - yi
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    var a := lerpf(_h(xi, yi, s), _h(xi + 1, yi, s), fx)
    var b := lerpf(_h(xi, yi + 1, s), _h(xi + 1, yi + 1, s), fx)
    return lerpf(a, b, fy)

func gen(zi: int) -> Dictionary:
    if data.has(zi):
        return data[zi]
    var Zd: Dictionary = ZONES[zi]
    _rng.seed = 9137 * (zi + 1)
    var m := PackedByteArray()
    m.resize(ZW * ZH)
    for y in ZH:
        for x in ZW:
            var b := x < 2 or y < 2 or x >= ZW - 2 or y >= ZH - 2
            var n := _vn(x / 5.2 + zi * 31, y / 5.2 + zi * 17, zi) * 0.7 + _vn(x / 2.2 + zi * 7, y / 2.2 + 3, zi + 50) * 0.3
            m[y * ZW + x] = WL if (b or n > 0.6) else FL
    var path := {}
    var cx := ZW >> 1
    var ent := Vector2i(cx, ZH - 5)
    var arena := Vector2i(cx, 9)
    _carve(m, ent.x, ent.y, 4)
    _carve(m, arena.x, arena.y, 7)
    _walk(m, path, ent.x, ent.y - 3, arena.x, arena.y + 6, 1, true)
    for i in 6:
        _walk(m, path, _rng.randi_range(5, ZW - 6), _rng.randi_range(5, ZH - 6), ent.x + _rng.randi_range(-3, 3), ent.y - 4 - _rng.randi_range(0, 12), 1, false)
    for i in 4:
        _walk(m, path, ent.x, ent.y - 2, 4 if _rng.randf() < 0.5 else ZW - 5, 8 + int(_rng.randf() * (ZH - 16)), 1, false)
    # ตัดพื้นที่ที่เดินไปไม่ถึงให้เป็นหิน
    var seen := PackedByteArray()
    seen.resize(ZW * ZH)
    var q := [ent.y * ZW + ent.x]
    seen[q[0]] = 1
    while not q.is_empty():
        var i: int = q.pop_back()
        var x := i % ZW
        var y := i / ZW
        for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var j: int = (y + dd.y) * ZW + x + dd.x
            if seen[j] == 0 and m[j] == FL:
                seen[j] = 1
                q.append(j)
    var floor_t := []
    for y in ZH:
        for x in ZW:
            var i := y * ZW + x
            if m[i] == FL and seen[i] == 0:
                m[i] = WL
            elif m[i] == FL:
                floor_t.append(Vector2i(x, y))
    # แร่
    var ores := []
    var ore_at := {}
    var wsum := 0.0
    for o in Zd.ores:
        wsum += float(o[1])
    var want := int(round(44.0 * ZW * ZH / 1564.0))
    var g := 0
    while ores.size() < want and g < 9000:
        g += 1
        var tt: Vector2i = floor_t[int(_rng.randf() * floor_t.size())]
        var key := tt.y * ZW + tt.x
        if path.has(key) or Vector2(tt - ent).length() < 6 or Vector2(tt - arena).length() < 9 or ore_at.has(key):
            continue
        var nb := 0
        for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            if m[(tt.y + dd.y) * ZW + tt.x + dd.x] == WL:
                nb += 1
        if nb >= 3:
            continue
        var r := _rng.randf() * wsum
        var kd := str(Zd.ores[0][0])
        for o in Zd.ores:
            if r < float(o[1]):
                kd = str(o[0])
                break
            r -= float(o[1])
        var K: Dictionary = OREK[kd]
        var ore := {"tx": tt.x, "ty": tt.y, "kind": kd, "hp": int(K.hp), "max": int(K.hp), "alive": true, "regen": 0.0, "shake": 0.0, "i": -1}
        ores.append(ore)
        ore_at[key] = ore
    var d := {"m": m, "ores": ores, "ore_at": ore_at, "floor": floor_t, "ent": ent, "arena": arena, "root": null, "mm": {}}
    data[zi] = d
    return d

func _carve(m: PackedByteArray, x: int, y: int, r: int) -> void:
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            var xx := x + dx
            var yy := y + dy
            if xx > 1 and yy > 1 and xx < ZW - 2 and yy < ZH - 2 and dx * dx + dy * dy <= r * r + 1:
                m[yy * ZW + xx] = FL

func _walk(m: PackedByteArray, path: Dictionary, x: int, y: int, tx: int, ty: int, w: int, mark: bool) -> void:
    var g := 0
    while (abs(x - tx) > 1 or abs(y - ty) > 1) and g < 900:
        g += 1
        if _rng.randf() < 0.62:
            if _rng.randf() < 0.5:
                x += signi(tx - x)
            else:
                y += signi(ty - y)
        else:
            if _rng.randf() < 0.5:
                x += -1 if _rng.randf() < 0.5 else 1
            else:
                y += -1 if _rng.randf() < 0.5 else 1
        x = clampi(x, 3, ZW - 4)
        y = clampi(y, 3, ZH - 4)
        _carve(m, x, y, w)
        if mark:
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    path[(y + dy) * ZW + x + dx] = true

# ---------- ภาพ 3D ----------
func _vc_mat() -> StandardMaterial3D:
    var mt := StandardMaterial3D.new()
    mt.vertex_color_use_as_albedo = true
    mt.roughness = 0.9
    return mt

func _build(zi: int) -> void:
    var d: Dictionary = data[zi]
    var Zd: Dictionary = ZONES[zi]
    var pal: Dictionary = Zd.pal
    var root := Node3D.new()
    add_child(root)
    d.root = root
    var o := origin(zi)
    # พื้น: แผ่นละช่อง สีสลับตามโซน (MultiMesh เดียว)
    var fm := BoxMesh.new()
    fm.size = Vector3(TS, 0.1, TS)
    var fmm := MultiMesh.new()
    fmm.transform_format = MultiMesh.TRANSFORM_3D
    fmm.use_colors = true
    fmm.mesh = fm
    fmm.instance_count = d.floor.size()
    for i in d.floor.size():
        var t: Vector2i = d.floor[i]
        fmm.set_instance_transform(i, Transform3D(Basis(), tile_w(zi, t.x, t.y) + Vector3(0, -0.05, 0)))
        # สีพื้นเปลี่ยนแบบนุ่ม ๆ ตาม noise (ไม่เป็นตารางหมากรุก)
        var nv := _vn(t.x / 4.0, t.y / 4.0, zi + 21)
        var c0 := Color.html(str(pal.fl[0]))
        var c2 := Color.html(str(pal.fl[2]))
        fmm.set_instance_color(i, c0.lerp(c2, nv).darkened(_h(t.x, t.y, zi + 7) * 0.04))
    var fmi := MultiMeshInstance3D.new()
    fmi.multimesh = fmm
    fmi.material_override = _vc_mat()
    root.add_child(fmi)
    # ผนังหิน: กล่องสูงเฉพาะช่องที่ติดพื้น (ที่เหลือเป็นหลังคาหินเรียบ)
    var walls := []
    for y in ZH:
        for x in ZW:
            if d.m[y * ZW + x] != WL:
                continue
            walls.append(Vector2i(x, y))
    var wm := BoxMesh.new()
    wm.size = Vector3(TS, WALL_H, TS)
    var wmm := MultiMesh.new()
    wmm.transform_format = MultiMesh.TRANSFORM_3D
    wmm.use_colors = true
    wmm.mesh = wm
    wmm.instance_count = walls.size()
    var top := Color.html(str(pal.top))
    var face := Color.html(str(pal.face))
    for i in walls.size():
        var t: Vector2i = walls[i]
        var hh := _h(t.x, t.y, zi + 3)
        var edge := false
        for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var nx: int = t.x + dd.x
            var ny: int = t.y + dd.y
            if nx >= 0 and ny >= 0 and nx < ZW and ny < ZH and d.m[ny * ZW + nx] == FL:
                edge = true
        var hy := WALL_H * (0.85 + hh * 0.35) if edge else WALL_H
        # ผนังขอบ: หมุน/ขยายนิดหน่อยให้ดูเป็นหินไม่ใช่กล่องเรียงตาราง
        var b := Basis().scaled(Vector3(1.0, hy / WALL_H, 1.0))
        if edge:
            var sx := 1.08 + _h(t.x, t.y, zi + 9) * 0.22
            b = Basis(Vector3.UP, (hh - 0.5) * 0.9) * Basis().scaled(Vector3(sx, hy / WALL_H, sx))
        wmm.set_instance_transform(i, Transform3D(b, tile_w(zi, t.x, t.y) + Vector3(0, hy * 0.5, 0)))
        wmm.set_instance_color(i, face.lerp(top, 0.35 + hh * 0.4) if edge else top.darkened(hh * 0.15))
    var wmi := MultiMeshInstance3D.new()
    wmi.multimesh = wmm
    wmi.material_override = _vc_mat()
    root.add_child(wmi)
    # หินรอบนอกแผนที่ (ไม่ให้เห็นที่ว่าง)
    var W := ZW * TS
    var H := ZH * TS
    var om: Material = town.M(top.darkened(0.2), 0.95)
    town.box(root, Vector3(W + 200, WALL_H, 100), o + Vector3(W / 2, WALL_H / 2, -50), om)
    town.box(root, Vector3(W + 200, WALL_H, 100), o + Vector3(W / 2, WALL_H / 2, H + 50), om)
    town.box(root, Vector3(100, WALL_H, H), o + Vector3(-50, WALL_H / 2, H / 2), om)
    town.box(root, Vector3(100, WALL_H, H), o + Vector3(W + 50, WALL_H / 2, H / 2), om)
    # ก้อนแร่: MultiMesh ต่อชนิด (หิน + ผลึกสีแร่)
    var rock := SphereMesh.new()
    rock.radius = 0.85
    rock.height = 1.3
    rock.radial_segments = 7
    rock.rings = 4
    var cry := CylinderMesh.new()
    cry.top_radius = 0.0
    cry.bottom_radius = 0.3
    cry.height = 1.25
    cry.radial_segments = 4
    var kinds := {}
    for ore in d.ores:
        kinds[ore.kind] = (kinds.get(ore.kind, []) as Array) + [ore]
    for kd in kinds:
        var list: Array = kinds[kd]
        var rmm := MultiMesh.new()
        rmm.transform_format = MultiMesh.TRANSFORM_3D
        rmm.mesh = rock
        rmm.instance_count = list.size()
        var cmm := MultiMesh.new()
        cmm.transform_format = MultiMesh.TRANSFORM_3D
        cmm.mesh = cry
        cmm.instance_count = list.size() * 3
        for i in list.size():
            var ore: Dictionary = list[i]
            ore.i = i
            ore.xf = []
            var p := tile_w(zi, ore.tx, ore.ty)
            var a := _h(ore.tx, ore.ty, 11) * TAU
            var rx := Transform3D(Basis(Vector3.UP, a), p + Vector3(0, 0.35, 0))
            rmm.set_instance_transform(i, rx)
            ore.xf.append(rx)
            for k in 3:
                var ang := a + k * 2.1
                var tilt := Basis(Vector3.UP, ang) * Basis(Vector3.RIGHT, 0.45)
                var cx := Transform3D(tilt, p + Vector3(cos(ang) * 0.3, 0.85 + k * 0.05, sin(ang) * 0.3))
                cmm.set_instance_transform(i * 3 + k, cx)
                ore.xf.append(cx)
        var rmi := MultiMeshInstance3D.new()
        rmi.multimesh = rmm
        rmi.material_override = town.M(Color(0.5, 0.5, 0.53).lerp(OREK[kd].c, 0.3), 0.9)
        root.add_child(rmi)
        var cmi := MultiMeshInstance3D.new()
        cmi.multimesh = cmm
        var oc: Color = OREK[kd].c
        cmi.material_override = town.M(oc, 0.25, 1.2 if kd in ["diamond", "gold", "silver"] else 0.5)
        root.add_child(cmi)
        d.mm[kd] = [rmm, cmm]
    # วงบอส + วงเวททางออก
    var ar := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 8.6
    tm.outer_radius = 9.0
    tm.rings = 48
    ar.mesh = tm
    ar.material_override = town.M(Color(0.7, 0.12, 0.12), 0.6, 0.8)
    ar.position = tile_w(zi, d.arena.x, d.arena.y) + Vector3(0, 0.05, 0)
    ar.scale = Vector3(1, 0.05, 0.73)
    root.add_child(ar)
    var ex := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 1.3
    cm.bottom_radius = 1.3
    cm.height = 0.06
    cm.radial_segments = 24
    ex.mesh = cm
    ex.material_override = town.M(Color(0.65, 0.45, 1.0), 0.3, 2.2)
    ex.position = exit_pos(zi) + Vector3(0, 0.04, 0)
    root.add_child(ex)
    var lab: Label3D = town.label3d("วงเวทกลับทุ่งหญ้า", exit_pos(zi) + Vector3(0, 1.6, 0), 34)
    lab.reparent(root)
    var bl: Label3D = town.label3d("ลานบอส: " + str(Zd.boss.n), tile_w(zi, d.arena.x, d.arena.y - 6) + Vector3(0, 2.0, 0), 38, Color(1.0, 0.6, 0.5))
    bl.reparent(root)

func exit_pos(zi: int) -> Vector3:
    var d: Dictionary = data[zi]
    return tile_w(zi, d.ent.x, d.ent.y + 2)

func _ore_show(zi: int, ore: Dictionary, on: bool) -> void:
    var mm: Array = data[zi].mm[ore.kind]
    var zero := Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), ore.xf[0].origin)
    var rx: Transform3D = ore.xf[0]
    if not on:
        # เหลือเศษหินเตี้ย ๆ
        rx = Transform3D(rx.basis.scaled(Vector3(0.7, 0.25, 0.7)), rx.origin - Vector3(0, 0.25, 0))
    mm[0].set_instance_transform(ore.i, rx)
    for k in 3:
        mm[1].set_instance_transform(ore.i * 3 + k, ore.xf[k + 1] if on else zero)

# ---------- เข้า/ออก ----------
func open_menu() -> void:
    var p = town.player
    town.cur_shop = "portal"
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl("ประตูมิติ — เลือกแผนที่", 22, Color(0.85, 0.75, 1.0), true)))
    hv.add_child(town._lbl("Lv.ของคุณ %d · แต่ละแผนที่มีแร่ มอนสเตอร์ และบอสประจำถิ่น" % p.lv, 14, Color(0.85, 0.82, 0.74)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    for i in ZONES.size():
        var z: Dictionary = ZONES[i]
        var lo: int = z.lv[0]
        var warn := "อันตรายมาก" if p.lv < lo - 3 else ("เลเวลยังไม่ถึง" if p.lv < lo else ("ง่าย" if p.lv > int(z.lv[1]) + 5 else "เหมาะกับคุณ"))
        var ores := []
        for o in z.ores:
            ores.append(str(OREK[o[0]].n))
        var b := Button.new()
        b.text = "%s  Lv.%d-%d  · %s\nแร่: %s\nบอส: %s Lv.%d" % [z.n, lo, z.lv[1], warn, " · ".join(ores), z.boss.n, z.boss.lv]
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.add_theme_font_override("font", town.font_b)
        b.add_theme_font_size_override("font_size", 15)
        b.focus_mode = Control.FOCUS_NONE
        if p.lv < lo - 3:
            b.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
        var zi := i
        b.pressed.connect(func(): town.close_shop(); enter(zi))
        town.ui_shop_body.add_child(b)
    town.ui_shop.visible = true

func enter(zi: int) -> void:
    if cur >= 0:
        return
    gen(zi)
    if data[zi].root == null:
        _build(zi)
    data[zi].root.visible = true
    cur = zi
    var d: Dictionary = data[zi]
    var p = town.player
    p.set_path(PackedVector3Array())
    p.target_mob = null
    p.position = tile_w(zi, d.ent.x, d.ent.y - 1)
    p.heading = PI
    p.body.rotation.y = PI
    town.cam_yaw = 0.0
    spawn_t = 2.0
    boss = null
    boss_t = 0.1
    var n0 := 10 if town.is_mobile else 16
    for k in n0:
        _spawn(false)
    town._update_sky()
    var Zd: Dictionary = ZONES[zi]
    town.field.say_msg("%s (Lv.%d-%d) · บอสรออยู่ทางเหนือ · ออกได้ที่วงเวทด้านล่าง" % [Zd.n, Zd.lv[0], Zd.lv[1]], 4.0)

func leave(to_portal: bool = true) -> void:
    if cur < 0:
        return
    var zi := cur
    data[zi].root.visible = false
    cur = -1
    for m in mobs:
        if is_instance_valid(m):
            m.queue_free()
    mobs.clear()
    boss = null
    for s in shots:
        if is_instance_valid(s.n):
            s.n.queue_free()
    shots.clear()
    town.field.extra = []
    town.ui_shop.visible = false
    if to_portal:
        var p = town.player
        p.set_path(PackedVector3Array())
        p.position = town.field.portal_pos + Vector3(0, 0, 2.6)
        p.heading = 0.0
        p.body.rotation.y = 0.0
        town.field.say_msg("กลับมาที่ทุ่งหญ้าแล้ว", 2.5)
    town._update_sky()

# ---------- มอน ----------
func _spot(far: bool) -> Vector3:
    var d: Dictionary = data[cur]
    var p = town.player
    for g in 200:
        var t: Vector2i = d.floor[randi() % d.floor.size()]
        var o = d.ore_at.get(t.y * ZW + t.x)
        if o != null and o.alive:
            continue
        if Vector2(t - d.ent).length() < 9 or Vector2(t - d.arena).length() < 10:
            continue
        var w := tile_w(cur, t.x, t.y)
        if far and w.distance_to(p.position) < 320.0 / 16.0:
            continue
        return w
    return Vector3.INF

func _mk(fam: String, nm: String, col: Array, L: int, pos: Vector3, o: Dictionary) -> Node3D:
    var m := Node3D.new()
    m.set_script(Mob)
    add_child(m)
    m.setup(self, fam, nm, col, L, pos, o)
    mobs.append(m)
    town.field.extra = mobs
    return m

func _spawn(far: bool) -> void:
    var Zd: Dictionary = ZONES[cur]
    var s := _spot(far)
    if s == Vector3.INF:
        return
    var mb: Array = Zd.mobs[randi() % Zd.mobs.size()]
    var a: int = Zd.lv[0]
    var b: int = Zd.lv[1]
    var u := pow(randf(), 1.4)
    var L := int(round(a + (b - a) * u))
    _mk(str(mb[0]), str(mb[1]), mb[2], L, s, {"elite": randf() < 0.08, "span": float(L - a) / float(b - a)})

func _spawn_boss() -> void:
    var Zd: Dictionary = ZONES[cur]
    var d: Dictionary = data[cur]
    var B: Dictionary = Zd.boss
    boss = _mk(str(B.f), str(B.n), B.c, int(B.lv), tile_w(cur, d.arena.x, d.arena.y), {"boss": true})

## บอสเรียกลูกน้อง 2 ตัว (เลือดต่ำกว่า 50% และ 25%)
func summon(b) -> void:
    var Zd: Dictionary = ZONES[cur]
    for i in 2:
        var mb: Array = Zd.mobs[i % Zd.mobs.size()]
        var m := _mk(str(mb[0]), str(mb[1]), mb[2], int(Zd.lv[1]), b.position + Vector3(-2.5 if i == 0 else 2.5, 0, 1.2), {})
        m.aggro = true
        m.st = "chase"
    town.field.say_msg(b.nm + " เรียกลูกน้องมาช่วย!", 2.5)

## มอนตาย (mobKill + fix31): เหรียญ ×0.45 · ไม่ดรอปแร่/แท่งแร่ (ต้องขุดเอง) · ของเฉพาะตัว 15%
## บอส: ของเฉพาะตัว ×3 + หินเสริมพลัง 1 · EXP ×0.8
const JUNK := {"beetle": "shell", "bat": "wing", "golem": "core", "wolf": "pelt", "wisp": "dust", "dragon": "scale"}

func mob_killed(m) -> void:
    var p = town.player
    var coin := int(round((3.0 + m.lv * 1.2) * (3.0 if m.elite else 1.0) * (30.0 if m.boss else 1.0)))
    coin = int(round(coin * 0.45))
    p.coins += coin
    town.field.float_text("+%d เหรียญ" % coin, m.position + Vector3(0, 2.4 * m.sc, 0), Color(1.0, 0.85, 0.3), 1.3 if m.boss else 0.9)
    var j := str(JUNK.get(m.f, ""))
    if m.boss:
        for i in 3:
            _drop_item(j, m.position)
        _drop_item("estone", m.position)
        town.field.say_msg("ปราบ " + m.nm + " สำเร็จ! ได้หินเสริมพลัง · บอสจะกลับมาอีกใน 3 นาที", 4.0)
        boss = null
        boss_t = 180.0
    elif j != "" and randf() < 0.15:
        _drop_item(j, m.position)
    var xp: int = max(5, int(round(p.need(m.lv) / 20.0))) * (3 if m.elite else 1) * (15 if m.boss else 1)
    p.gain_xp(max(1, int(round(xp * 0.8))))

func _drop_item(kind: String, at: Vector3) -> void:
    town.field._drop(kind, at)
    var q: Dictionary = town.field.drops.back()
    var n: MeshInstance3D = q.n
    var c := Color(0.7, 0.7, 0.75)
    for k in OREK:
        if OREK[k].drop == kind:
            c = OREK[k].c
    if JUNK.values().has(kind) or kind in ["estone", "bless"]:
        var sm := SphereMesh.new()
        sm.radius = 0.2
        sm.height = 0.3
        sm.radial_segments = 6
        sm.rings = 3
        n.mesh = sm
        n.material_override = town.M({"estone": Color(0.4, 0.8, 1.0), "core": Color(0.6, 0.58, 0.52), "dust": Color(0.9, 0.85, 1.0), "scale": Color(0.4, 0.9, 0.7)}.get(kind, Color(0.75, 0.65, 0.5)), 0.4, 0.8 if kind == "estone" else 0.1)
        return
    if kind.begins_with("ing"):
        var bm := BoxMesh.new()
        bm.size = Vector3(0.5, 0.18, 0.26)
        n.mesh = bm
        c = {"ingot": Color(0.7, 0.72, 0.76), "ingCu": Color(0.9, 0.55, 0.3), "ingAg": Color(0.9, 0.93, 1.0), "ingAu": Color(1.0, 0.82, 0.3), "ingDm": Color(0.6, 0.9, 1.0)}.get(kind, c)
    else:
        n.mesh = town.field.stone_mesh
    n.material_override = town.M(c, 0.3, 0.3)

## กระสุนมอน (ภูต · บอสยิงรอบตัว)
func shoot(src, dir: Vector3, speed: float, dmg: int, life: float) -> void:
    var n := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.25
    sm.height = 0.5
    sm.radial_segments = 8
    sm.rings = 4
    n.mesh = sm
    n.material_override = town.M(Color.html(str(src.col[2])), 0.3, 3.0)
    n.position = src.position + Vector3(0, 1.0 if not src.F.get("fly", false) else 1.7, 0)
    add_child(n)
    shots.append({"n": n, "v": dir.normalized() * speed, "l": life, "dmg": dmg, "nm": src.nm})

# ---------- ขุดแร่ (zMine) ----------
func pick_tier() -> int:
    var b: Dictionary = town.player.best_tool("pick")
    return -1 if b.is_empty() else int(b.t)

func ore_in_front(p) -> Variant:
    if cur < 0:
        return null
    var d: Dictionary = data[cur]
    var fwd := Vector3(sin(p.heading), 0, cos(p.heading))
    var best = null
    var bd := 2.9
    for ore in d.ores:
        if not ore.alive:
            continue
        var w := tile_w(cur, ore.tx, ore.ty)
        var to := Vector3(w.x - p.position.x, 0, w.z - p.position.z)
        var dist := to.length()
        if dist < bd and (dist < 1.2 or to.normalized().dot(fwd) > 0.3):
            bd = dist
            best = ore
    return best

func try_mine(p) -> bool:
    var ore = ore_in_front(p)
    if ore == null:
        return false
    var K: Dictionary = OREK[ore.kind]
    var tier := pick_tier()
    var w := tile_w(cur, ore.tx, ore.ty)
    p.heading = atan2(w.x - p.position.x, w.z - p.position.z)
    p.body.rotation.y = p.heading
    if tier < 0:
        town.field.say_msg("ต้องมีที่ขุดแร่ในกระเป๋า (ซื้อที่ร้านอาวุธลุงเหล็ก)")
        return true
    if tier < int(K.req):
        ore.shake = 0.2
        town.field.say_msg("ต้องใช้" + PICK_NAMES[int(K.req)] + "ขึ้นไป จึงจะขุด" + str(K.n) + "ได้")
        return true
    var dm: int = Items.inst_stat(p.best_tool("pick"))  # 1+(ระดับ>>1)+ตีบวก/3
    ore.hp -= dm
    ore.shake = 0.3
    town.field.float_text("-%d" % dm, w + Vector3(0, 1.8, 0), Color(0.9, 0.9, 1.0), 0.8)
    if ore.hp <= 0:
        ore.alive = false
        ore.regen = 60.0
        _ore_show(cur, ore, false)
        var n := randi_range(int(K.cnt[0]), int(K.cnt[1]))
        for k in n:
            _drop_item(str(K.drop), w)
        town.field.say_msg("ขุด%sแตก! ได้%s +%d" % [K.n, Items.item_name(str(K.drop)), n])
        p.gain_xp(int(K.xp) * (1 + cur))
    else:
        town.field.say_msg("ขุด%s... ความคืบหน้า %d%%" % [K.n, int(round((1.0 - float(ore.hp) / ore.max) * 100.0))])
    return true

# ---------- ทุกเฟรม (updZone) ----------
func _process(delta: float) -> void:
    if cur < 0:
        return
    var d: Dictionary = data[cur]
    var p = town.player
    for i in range(mobs.size() - 1, -1, -1):
        if not is_instance_valid(mobs[i]) or mobs[i].dead:
            mobs.remove_at(i)
    town.field.extra = mobs
    var normal := 0
    for m in mobs:
        if not m.boss:
            normal += 1
    var cap := 12 if town.is_mobile else 20
    spawn_t -= delta
    if normal < cap and spawn_t <= 0.0:
        _spawn(true)
        spawn_t = 5.0
    if boss == null and boss_t > 0.0:
        boss_t -= delta
        if boss_t <= 0.0:
            _spawn_boss()
    for i in range(shots.size() - 1, -1, -1):
        var s: Dictionary = shots[i]
        var n: MeshInstance3D = s.n
        s.l -= delta
        n.position += s.v * delta
        var hit := Vector2(p.position.x - n.position.x, p.position.z - n.position.z).length() < 0.8
        if hit:
            p.hurt_mob(int(s.dmg), "โดนพลังเวทของ" + str(s.nm))
        if hit or s.l <= 0.0 or blocked(n.position.x, n.position.z):
            n.queue_free()
            shots.remove_at(i)
    for ore in d.ores:
        if not ore.alive:
            ore.regen -= delta
            if ore.regen <= 0.0 and tile_w(cur, ore.tx, ore.ty).distance_to(p.position) > 3.8:
                ore.alive = true
                ore.hp = ore.max
                _ore_show(cur, ore, true)
    if p.position.distance_to(exit_pos(cur)) < 1.3 and not p.dead:
        leave(true)
        return
    var Zd: Dictionary = ZONES[cur]
    town.hud.text = "%s · Lv.%d-%d" % [Zd.n, Zd.lv[0], Zd.lv[1]]
    var o = ore_in_front(p)
    if o != null:
        var K: Dictionary = OREK[o.kind]
        town.prompt.text = "%s — กดตีเพื่อขุด%s" % [K.n, ("" if pick_tier() >= int(K.req) else " (ต้องใช้" + PICK_NAMES[int(K.req)] + ")")]
    elif p.position.distance_to(exit_pos(cur)) < 4.0:
        town.prompt.text = "เดินเข้าวงเวทเพื่อกลับทุ่งหญ้า"
    else:
        town.prompt.text = ""
