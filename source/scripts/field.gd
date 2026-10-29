extends Node3D
## ทุ่งหญ้า (นอกประตูตะวันตก) + ระบบต่อสู้: สไลม์ Lv1-5, ของดรอป, ตัวเลขดาเมจ, แถบเลือด/มานา/EXP
## กติกาตามเกมเดิม: สไลม์สูงสุด 16 ตัว เกิดใหม่ทุก 6 วิ · ดรอปเจล 1-2 + เหรียญ 1-3(+เลเวล/2) · EXP = 5×เลเวล

const MAX_SLIMES := 16

var town
var slimes: Array = []
var extra: Array = []   # มอนในเหมือง (mine.gd) ใช้ระบบตี/สกิล/ยิงร่วมกับสไลม์
var resp_t := 5.0
var shadow_tex: Texture2D
var drops: Array = []
var floaters: Array = []
var atk_id := 0
var coin_mesh: Mesh
var gel_mesh: Mesh
var coin_mat: StandardMaterial3D
var gel_mat: StandardMaterial3D

# HUD
var cl: CanvasLayer
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var xp_bar: ProgressBar
var hp_txt: Label
var mp_txt: Label
var lv_txt: Label
var bag_txt: Label
var msg: Label
var msg_t := 0.0
var atk_btn: Button
var death_panel: PanelContainer
var hud_card: PanelContainer
var hud_box: VBoxContainer
var bars: Array = []
var _hud_tick := 0.0

func setup(t) -> void:
    town = t
    var g := Gradient.new()
    g.set_color(0, Color(1, 1, 1, 1))
    g.set_color(1, Color(1, 1, 1, 0))
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.fill = GradientTexture2D.FILL_RADIAL
    gt.fill_from = Vector2(0.5, 0.5)
    gt.fill_to = Vector2(1.0, 0.5)
    shadow_tex = gt
    var cm := CylinderMesh.new()
    cm.top_radius = 0.16
    cm.bottom_radius = 0.16
    cm.height = 0.05
    cm.radial_segments = 16
    coin_mesh = cm
    coin_mat = StandardMaterial3D.new()
    coin_mat.albedo_color = Color(1.0, 0.8, 0.25)
    coin_mat.metallic = 1.0
    coin_mat.roughness = 0.25
    coin_mat.emission_enabled = true
    coin_mat.emission = Color(0.5, 0.35, 0.0)
    var gm := SphereMesh.new()
    gm.radius = 0.15
    gm.height = 0.24
    gel_mesh = gm
    gel_mat = StandardMaterial3D.new()
    gel_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.85)
    gel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    gel_mat.roughness = 0.05
    gel_mat.emission_enabled = true
    gel_mat.emission = Color(0.1, 0.3, 0.6)
    _build_decor()
    for i in 16:
        spawn()
    _build_hud()

func in_field(x: float, z: float) -> bool:
    return town.in_field_rect(x, z, 0.0) and x < -46.0

## เลเวลสไลม์ตามช่อง x เหมือนเกม 2D: ceil((W - tx) / 12) จำกัด 1-5
func lv_at(x: float) -> int:
    var tx: int = town.ftile_at(x, 0.0).x
    return clampi(int(ceil(float(town.FW - tx) / 12.0)), 1, 5)

func spawn() -> void:
    for i in 200:
        var tx := randi_range(2, town.FW - 3)
        var ty := randi_range(2, town.FH - 3)
        if town.ftile(tx, ty) != town.F_GRASS:
            continue
        if Vector2(tx - 6, ty - 6).length() <= 8.0:
            continue
        var p: Vector3 = town.fw(tx + 0.5, ty + 0.5)
        if Vector2(p.x - town.player.position.x, p.z - town.player.position.z).length() < 12.5:
            continue
        var s := Node3D.new()
        s.set_script(preload("res://scripts/slime.gd"))
        add_child(s)
        s.setup(self, lv_at(p.x), Vector3(p.x, town.ground_y(p.x, p.z), p.z))
        slimes.append(s)
        return

# ---------- ฉากทุ่งหญ้า (ผังจากเกม 2D) ----------
var pickups: Array = []
var pick_t := 0.0
const PICK_MAX := 34
var stone_mesh: Mesh
var stick_mesh: Mesh
var stone_mat: StandardMaterial3D
var stick_mat: StandardMaterial3D
var portal_pos := Vector3.ZERO
var dungeon_pos := Vector3.ZERO
var warp_pos := Vector3.ZERO
var portal_disc: MeshInstance3D
var crystals: Array = []

func _build_decor() -> void:
    _build_ground_mesh()
    _build_water()
    _build_trees()
    _build_grass_flowers()
    _build_portal()
    _build_dungeon_gate()
    _build_warp()
    var sign_p: Vector3 = town.fw(57.0, 19.6)
    var wood: Material = town.M(Color(0.45, 0.3, 0.18), 0.9)
    town.box(self, Vector3(0.2, 2.2, 0.2), sign_p + Vector3(0, 1.1, 0), wood)
    town.box(self, Vector3(2.4, 0.9, 0.15), sign_p + Vector3(0, 2.0, 0), wood)
    town.label3d("ทุ่งหญ้า\nสไลม์ Lv.1-5 (ยิ่งไปทางตะวันตกยิ่งเก่ง)", sign_p + Vector3(0, 3.4, 0), 30)
    stone_mesh = SphereMesh.new()
    (stone_mesh as SphereMesh).radius = 0.32
    (stone_mesh as SphereMesh).height = 0.38
    (stone_mesh as SphereMesh).radial_segments = 7
    (stone_mesh as SphereMesh).rings = 4
    stone_mat = StandardMaterial3D.new()
    stone_mat.albedo_color = Color(0.68, 0.69, 0.72)
    stone_mat.roughness = 0.9
    stick_mesh = CylinderMesh.new()
    (stick_mesh as CylinderMesh).top_radius = 0.06
    (stick_mesh as CylinderMesh).bottom_radius = 0.08
    (stick_mesh as CylinderMesh).height = 1.1
    (stick_mesh as CylinderMesh).radial_segments = 6
    stick_mat = StandardMaterial3D.new()
    stick_mat.albedo_color = Color(0.55, 0.36, 0.18)
    stick_mat.roughness = 0.9
    for i in PICK_MAX:
        _add_pickup()

func _vcolor(x: float, z: float) -> Color:
    # r = ทางดิน · g = ทราย (ใช้กับ terrain.gdshader)
    var pr := 0.0
    var sd := 0.0
    for o in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(-0.5, 0.5), Vector2(0.5, 0.5)]:
        var t: Vector2i = town.ftile_at(x + o.x, z + o.y)
        var k: int = town.ftile(t.x, t.y)
        if town.fpath.has(t.y * town.FW + t.x):
            pr += 0.25
        if k == town.F_SAND or k == town.F_WATER:
            sd += 0.25
    return Color(pr, sd, 0.0)

func _build_ground_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var step := 1.0
    var nx := int(town.FW * town.TS / step)
    var nz := int(town.FH * town.TS / step)
    var vs := []
    for zi in nz + 1:
        for xi in nx + 1:
            var x: float = town.FX0 + xi * step
            var z: float = town.FZ0 + zi * step
            vs.append([Vector3(x, town.fh(x, z), z), _vcolor(x, z)])
    for zi in nz:
        for xi in nx:
            var i0 := zi * (nx + 1) + xi
            for qi in [i0, i0 + 1, i0 + nx + 1, i0 + 1, i0 + nx + 2, i0 + nx + 1]:
                st.set_color(vs[qi][1])
                st.add_vertex(vs[qi][0])
    st.index()
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    var mat := ShaderMaterial.new()
    mat.shader = load("res://shaders/terrain.gdshader")
    mat.set_shader_parameter("noise_tex", town.noise_tex)
    mi.material_override = mat
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)

func _build_water() -> void:
    var pm := PlaneMesh.new()
    pm.size = Vector2(town.FW * town.TS, town.FH * town.TS)
    var w := MeshInstance3D.new()
    w.mesh = pm
    w.material_override = town._water_mat()
    w.position = Vector3(town.FX0 + town.FW, -0.42, town.FZ0 + town.FH)
    w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(w)

# ---------- ต้นไม้ + ตัดไม้ (js/016-core.js hitTree · fix149 งอกใหม่ 100-140 วิ) ----------
const TREE_HP := [2, 3, 5, 8]
const TREE_WOOD := [1, 2, 3, 5]
const TREE_SC := [0.5, 0.7, 0.9, 1.1]
var trees: Array = []          # {tx,ty,sz,hp,max,wood,alive,border,regrow,parts:[[mm,idx,xf],...],pos,shadow}
var tree_at := {}              # ty*FW+tx -> tree
var falling: Array = []
var stump_mesh: Mesh
var stump_mat: StandardMaterial3D
var apple_mesh: Mesh
var apple_mat: StandardMaterial3D
var wood_mesh: Mesh
var wood_mat: StandardMaterial3D

func _build_trees() -> void:
    var cm := CylinderMesh.new()
    cm.top_radius = 0.6
    cm.bottom_radius = 1.0
    cm.height = 1.0
    cm.radial_segments = 7
    var blob := SphereMesh.new()
    blob.radius = 1.0
    blob.height = 2.0
    blob.radial_segments = 12 if not town.is_mobile else 8
    blob.rings = 7 if not town.is_mobile else 4
    var bark := StandardMaterial3D.new()
    bark.vertex_color_use_as_albedo = true
    bark.roughness = 0.95
    var leaf: Material = town._foliage(0.25)
    var q := QuadMesh.new()
    q.size = Vector2(1, 1)
    q.orientation = PlaneMesh.FACE_Y
    var shm := StandardMaterial3D.new()
    shm.albedo_texture = shadow_tex
    shm.vertex_color_use_as_albedo = true
    shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    # รวบรวมชิ้นส่วนต่อก้อนพื้นที่ (32 หน่วย) เหมือน town._mm_chunks แต่จำตำแหน่งไว้ซ่อนตอนต้นไม้ล้ม
    var chunks := {}
    var n_blobs := 4 if not town.is_mobile else 3
    for t in town.FD.trees:
        var tx := int(t[0])
        var ty := int(t[1])
        var sz := int(t[2])
        var sc: float = TREE_SC[sz] * 1.25
        var p: Vector3 = town.fw(tx + 0.5 + randf_range(-0.15, 0.15), ty + 0.5 + randf_range(-0.15, 0.15))
        p.y = town.ground_y(p.x, p.z)
        var tr := {"tx": tx, "ty": ty, "sz": sz, "hp": TREE_HP[sz], "max": TREE_HP[sz], "wood": TREE_WOOD[sz], "alive": true,
            "border": tx == 0 or ty == 0 or tx == town.FW - 1 or ty == town.FH - 1, "regrow": -1.0, "parts": [], "pos": p, "sc": sc}
        var key := Vector2i(floori(p.x / 32.0), floori(p.z / 32.0))
        if not chunks.has(key):
            chunks[key] = {"t": [[], []], "b": [[], []], "s": [[], []], "refs": []}
        var ch: Dictionary = chunks[key]
        var hue := randf_range(0.27, 0.33)
        var g := Color.from_hsv(hue, randf_range(0.55, 0.7), randf_range(0.42, 0.55))
        ch.t[0].append(town._xf(p + Vector3(0, 1.2 * sc, 0), Vector3(0.28 * sc, 2.4 * sc, 0.28 * sc), randf() * TAU))
        ch.t[1].append(Color(0.36, 0.25, 0.15))
        ch.refs.append([tr, "t", ch.t[0].size() - 1])
        for k in n_blobs:
            var off := Vector3(randf_range(-0.7, 0.7), randf_range(0.0, 0.9) + (0.6 if k == 2 else 0.0), randf_range(-0.7, 0.7)) * sc
            var r := randf_range(1.0, 1.35) * sc
            ch.b[0].append(town._xf(p + Vector3(0, 3.0 * sc, 0) + off, Vector3(r, r * 0.88, r), randf() * TAU))
            ch.b[1].append(g.lightened(randf_range(-0.06, 0.1)))
            ch.refs.append([tr, "b", ch.b[0].size() - 1])
        ch.s[0].append(town._xf(Vector3(p.x + 0.5, p.y + 0.04, p.z + 0.4), Vector3(2.6 * sc, 1, 2.6 * sc), 0.0))
        ch.s[1].append(Color(0, 0, 0, 0.32))
        ch.refs.append([tr, "s", ch.s[0].size() - 1])
        trees.append(tr)
        tree_at[ty * town.FW + tx] = tr
    for ch in chunks.values():
        var mms := {"t": _mm_one(cm, ch.t[0], ch.t[1], bark, true), "b": _mm_one(blob, ch.b[0], ch.b[1], leaf, true), "s": _mm_one(q, ch.s[0], ch.s[1], shm, false)}
        for ref in ch.refs:
            var mm: MultiMesh = mms[ref[1]]
            ref[0].parts.append([mm, ref[2], mm.get_instance_transform(ref[2])])
    var sm := CylinderMesh.new()
    sm.top_radius = 0.32
    sm.bottom_radius = 0.42
    sm.height = 0.35
    sm.radial_segments = 8
    stump_mesh = sm
    stump_mat = StandardMaterial3D.new()
    stump_mat.albedo_color = Color(0.45, 0.32, 0.2)
    var am := SphereMesh.new()
    am.radius = 0.16
    am.height = 0.3
    apple_mesh = am
    apple_mat = StandardMaterial3D.new()
    apple_mat.albedo_color = Color(0.85, 0.12, 0.12)
    apple_mat.roughness = 0.35
    var wm := CylinderMesh.new()
    wm.top_radius = 0.1
    wm.bottom_radius = 0.1
    wm.height = 0.55
    wm.radial_segments = 7
    wood_mesh = wm
    wood_mat = StandardMaterial3D.new()
    wood_mat.albedo_color = Color(0.62, 0.42, 0.22)

func _mm_one(mesh: Mesh, xs: Array, cs: Array, mat: Material, shadows: bool) -> MultiMesh:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true
    mm.mesh = mesh
    mm.instance_count = xs.size()
    for i in xs.size():
        mm.set_instance_transform(i, xs[i])
        mm.set_instance_color(i, cs[i])
    var mi := MultiMeshInstance3D.new()
    mi.multimesh = mm
    mi.material_override = mat
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)
    return mm

func _tree_show(tr: Dictionary, on: bool) -> void:
    for part in tr.parts:
        var mm: MultiMesh = part[0]
        mm.set_instance_transform(int(part[1]), part[2] if on else Transform3D().scaled(Vector3.ZERO))

## ต้นไม้ที่อยู่ข้างหน้าผู้เล่น (ใช้ขวานฟัน)
func tree_in_front(p) -> Variant:
    var fwd := Vector3(sin(p.heading), 0, cos(p.heading))
    var best = null
    var bd := 2.7
    for c in [p.position + fwd * 1.2, p.position]:
        var t: Vector2i = town.ftile_at(c.x, c.z)
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                var tr = tree_at.get((t.y + dy) * town.FW + t.x + dx)
                if tr == null or not tr.alive:
                    continue
                var d := Vector2(tr.pos.x - p.position.x, tr.pos.z - p.position.z).length()
                var dirv := Vector2(tr.pos.x - p.position.x, tr.pos.z - p.position.z).normalized()
                if d < bd and dirv.dot(Vector2(fwd.x, fwd.z)) > 0.2:
                    bd = d
                    best = tr
    return best

## ฟันต้นไม้ 1 ครั้ง (เรียกตอนกดตีแล้วไม่มีสไลม์ใกล้ ๆ) · คืน true ถ้าเป็นการฟันต้นไม้
func try_chop(p) -> bool:
    var tr = tree_in_front(p)
    if tr == null:
        return false
    if tr.border:
        say_msg("ต้นไม้ขอบทุ่งตัดไม่ได้")
        return true
    if p.best_tool("axe").is_empty():
        say_msg("ต้นไม้ต้องใช้ขวาน — ซื้อขวานหินที่ร้านอาวุธลุงเหล็ก")
        return true
    var dm: int = p.axe_dmg()
    tr.hp -= dm
    float_text("-%d" % dm, tr.pos + Vector3(0, 2.2, 0), Color(0.75, 1.0, 0.6), 0.9)
    if tr.hp <= 0:
        tr.alive = false
        tr.regrow = randf_range(100.0, 140.0)
        _tree_show(tr, false)
        town.fastar.set_point_solid(Vector2i(tr.tx, tr.ty), false)
        town.f_cut[tr.ty * town.FW + tr.tx] = true
        var dirx := 1.0 if p.position.x < tr.pos.x else -1.0
        falling.append({"tr": tr, "t": 0.0, "dir": dirx, "node": _falling_tree(tr), "landed": false})
        var st := MeshInstance3D.new()
        st.mesh = stump_mesh
        st.material_override = stump_mat
        st.position = tr.pos + Vector3(0, 0.17, 0)
        st.scale = Vector3.ONE * tr.sc
        add_child(st)
        tr["stump"] = st
        say_msg("ต้นไม้กำลังล้ม!")
    else:
        say_msg("ฟันต้นไม้ เหลืออีก %d ที" % int(ceil(float(tr.hp) / dm)))
    return true

func _falling_tree(tr: Dictionary) -> Node3D:
    var root := Node3D.new()
    root.position = tr.pos
    add_child(root)
    var sc: float = tr.sc
    var trunk := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.17 * sc
    cm.bottom_radius = 0.28 * sc
    cm.height = 2.4 * sc
    trunk.mesh = cm
    trunk.material_override = town.M(Color(0.36, 0.25, 0.15), 0.95)
    trunk.position.y = 1.2 * sc
    root.add_child(trunk)
    var leaf := MeshInstance3D.new()
    var sp := SphereMesh.new()
    sp.radius = 1.3 * sc
    sp.height = 2.3 * sc
    leaf.mesh = sp
    leaf.material_override = town.M(Color(0.3, 0.5, 0.2), 0.9)
    leaf.position.y = 3.2 * sc
    root.add_child(leaf)
    return root

func _update_trees(delta: float) -> void:
    var p = town.player
    for i in range(falling.size() - 1, -1, -1):
        var f: Dictionary = falling[i]
        f.t += delta
        var node: Node3D = f.node
        var u: float = min(f.t / 1.1, 1.0)
        node.rotation.z = -f.dir * u * u * PI * 0.5
        if not f.landed and f.t >= 1.1:
            f.landed = true
            var tr: Dictionary = f.tr
            var ex: Vector3 = tr.pos + Vector3(f.dir * 3.8 * tr.sc, 0, 0)
            for k in int(tr.wood):
                _drop("wood", ex + Vector3(randf_range(-0.7, 0.7), 0, randf_range(-0.4, 0.4)))
            if randf() < 0.3 + tr.wood * 0.05:
                _drop("apple", ex)
            say_msg("ต้นไม้ล้มแล้ว! ได้ไม้ +%d" % int(tr.wood))
        if f.t > 2.3:
            node.queue_free()
            falling.remove_at(i)
    for tr in trees:
        if tr.alive or tr.border:
            continue
        tr.regrow -= delta
        if tr.regrow > 0.0:
            continue
        if Vector2(p.position.x - tr.pos.x, p.position.z - tr.pos.z).length() < 3.0:
            tr.regrow = 3.0
            continue
        tr.alive = true
        tr.hp = tr.max
        _tree_show(tr, true)
        town.fastar.set_point_solid(Vector2i(tr.tx, tr.ty), true)
        town.f_cut.erase(tr.ty * town.FW + tr.tx)
        if tr.has("stump"):
            (tr.stump as Node).queue_free()
            tr.erase("stump")

func _grass_tiles() -> Array:
    var out := []
    for y in town.FH:
        for x in town.FW:
            if town.ftile(x, y) == town.F_GRASS and not town.fpath.has(y * town.FW + x):
                out.append(Vector2i(x, y))
    return out

func _build_grass_flowers() -> void:
    var tiles := _grass_tiles()
    # กอหญ้า: 1 ชิ้น = 6 ใบ (ดูแน่นขึ้นโดยจำนวนชิ้นเท่าเดิม)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for b in 6:
        var a := b * TAU / 6.0 + randf() * 0.5
        var r := randf_range(0.05, 0.22)
        var o := Vector3(cos(a) * r, 0, sin(a) * r)
        var hh := randf_range(0.55, 0.95)
        var lean := Vector3(cos(a), 0, sin(a)) * 0.12
        var side := Vector3(-sin(a), 0, cos(a)) * 0.05
        var pts := [o - side, o + side, o + lean * 0.5 + Vector3(0, hh * 0.5, 0) - side * 0.6, o + lean * 0.5 + Vector3(0, hh * 0.5, 0) + side * 0.6, o + lean + Vector3(0, hh, 0)]
        for tri in [[0, 1, 2], [1, 3, 2], [2, 3, 4]]:
            for idx in tri:
                st.set_normal(Vector3.UP)
                st.add_vertex(pts[idx])
    var clump := st.commit()
    var gx := []
    var gc := []
    var n_clumps := 2600 if town.is_mobile else 22000
    for i in n_clumps:
        var t: Vector2i = tiles[randi() % tiles.size()]
        var x: float = town.FX0 + (t.x + randf()) * town.TS
        var z: float = town.FZ0 + (t.y + randf()) * town.TS
        var s := randf_range(0.7, 1.2)
        gx.append(town._xf(Vector3(x, town.ground_y(x, z), z), Vector3(s, s * randf_range(0.8, 1.2), s), randf() * TAU))
        gc.append(Color(1, 1, 1).lerp(Color(1.2, 1.12, 0.75), randf() * 0.5))
    var gm := ShaderMaterial.new()
    gm.shader = load("res://shaders/grass.gdshader")
    gm.set_shader_parameter("noise_tex", town.noise_tex)
    gm.set_shader_parameter("base_col", Color(0.16, 0.34, 0.08))
    gm.set_shader_parameter("tip_col", Color(0.52, 0.72, 0.24))
    town._mm_chunks(clump, gx, gc, gm, false)
    # ดอกไม้ป่าเป็นกลุ่ม ๆ
    var fx := []
    var fc := []
    var cols := [Color(1, 0.92, 0.35), Color(1, 1, 1), Color(0.98, 0.5, 0.72), Color(0.62, 0.62, 1.0), Color(1, 0.55, 0.3)]
    var n_patch := 90 if town.is_mobile else 260
    for i in n_patch:
        var t2: Vector2i = tiles[randi() % tiles.size()]
        var cx: float = town.FX0 + (t2.x + 0.5) * town.TS
        var cz: float = town.FZ0 + (t2.y + 0.5) * town.TS
        var col: Color = cols[randi() % cols.size()]
        for k in 7:
            var x2 := cx + randf_range(-1.1, 1.1)
            var z2 := cz + randf_range(-1.1, 1.1)
            if town.blocked(x2, z2):
                continue
            var s2 := randf_range(0.8, 1.3)
            fx.append(town._xf(Vector3(x2, town.ground_y(x2, z2) + 0.32 * s2, z2), Vector3(s2, s2 * 0.7, s2), randf() * TAU))
            fc.append(col.lightened(randf_range(-0.05, 0.1)))
    var fm := SphereMesh.new()
    fm.radius = 0.1
    fm.height = 0.14
    fm.radial_segments = 6
    fm.rings = 3
    var fmat := StandardMaterial3D.new()
    fmat.vertex_color_use_as_albedo = true
    fmat.roughness = 0.7
    town._mm_chunks(fm, fx, fc, fmat, false)

func _build_portal() -> void:
    var pt: Array = town.FD.portal
    portal_pos = town.fw(float(pt[0]) + 0.5, float(pt[1]) + 0.5)
    var stone: Material = town.M(Color(0.55, 0.56, 0.6), 0.9)
    var dark: Material = town.M(Color(0.36, 0.37, 0.42), 0.9)
    town.cyl(self, 2.8, 2.95, 0.3, portal_pos + Vector3(0, 0.15, 0), dark, 28)
    town.cyl(self, 2.6, 2.6, 0.36, portal_pos + Vector3(0, 0.2, 0), stone, 28)
    portal_disc = MeshInstance3D.new()
    var dm := QuadMesh.new()
    dm.size = Vector2(3.9, 3.9)
    dm.orientation = PlaneMesh.FACE_Y
    portal_disc.mesh = dm
    var sm := ShaderMaterial.new()
    sm.shader = load("res://shaders/portal.gdshader")
    portal_disc.material_override = sm
    portal_disc.position = portal_pos + Vector3(0, 0.42, 0)
    portal_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(portal_disc)
    var ccols := [Color(0.75, 0.55, 1.0), Color(0.5, 0.88, 1.0), Color(1.0, 0.85, 0.3), Color(1.0, 0.55, 0.55)]
    for i in 4:
        var a := i * TAU / 4.0 + PI / 4.0
        var pp := portal_pos + Vector3(cos(a) * 2.75, 0, sin(a) * 2.75)
        town.box(self, Vector3(0.62, 1.7, 0.62), pp + Vector3(0, 0.85, 0), stone)
        town.box(self, Vector3(0.74, 0.22, 0.74), pp + Vector3(0, 1.75, 0), dark)
        var c := MeshInstance3D.new()
        var pm := PrismMesh.new()
        pm.size = Vector3(0.4, 0.55, 0.4)
        c.mesh = pm
        c.material_override = town.M(ccols[i], 0.2, 2.2)
        c.position = pp + Vector3(0, 2.5, 0)
        add_child(c)
        crystals.append(c)
    town.label3d("ประตูมิติ", portal_pos + Vector3(0, 3.6, 0), 34, Color(0.9, 0.8, 1.0))

func _build_dungeon_gate() -> void:
    # ช่อง DOOR (x 53-57, y 0-3) มุมขวาบนของทุ่ง = ทางลงดันเจี้ยน
    dungeon_pos = town.fw(55.5, 3.2)
    var rock: Material = town.M(Color(0.42, 0.42, 0.45), 0.95)
    var dark: Material = town.M(Color(0.05, 0.05, 0.07), 1.0)
    var c: Vector3 = town.fw(55.5, 2.0)
    town.box(self, Vector3(10.0, 5.0, 7.0), c + Vector3(0, 2.4, -0.5), rock)
    town.box(self, Vector3(6.0, 3.6, 5.0), c + Vector3(0, 6.0, -1.0), rock, Vector3(0, 0.3, 0))
    town.box(self, Vector3(3.0, 3.2, 0.3), Vector3(c.x, 1.6, town.FZ0 + 4 * town.TS - 0.6), dark)
    var arch: Material = town.M(Color(0.55, 0.52, 0.48), 0.9)
    town.box(self, Vector3(0.6, 3.8, 0.6), Vector3(c.x - 1.8, 1.9, town.FZ0 + 8.0 - 0.3), arch)
    town.box(self, Vector3(0.6, 3.8, 0.6), Vector3(c.x + 1.8, 1.9, town.FZ0 + 8.0 - 0.3), arch)
    town.box(self, Vector3(4.4, 0.6, 0.7), Vector3(c.x, 3.9, town.FZ0 + 8.0 - 0.3), arch)
    town.label3d("ประตูดันเจี้ยน", Vector3(c.x, 5.0, town.FZ0 + 8.0), 36)

func _build_warp() -> void:
    var w: Array = town.FD.warp
    warp_pos = town.fw(float(w[0]) + 0.5, float(w[1]) + 0.5)
    town.cyl(self, 0.9, 1.0, 0.25, warp_pos + Vector3(0, 0.12, 0), town.M(Color(0.5, 0.5, 0.55), 0.9), 16)
    var c := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(0.6, 1.4, 0.6)
    c.mesh = pm
    c.material_override = town.M(Color(0.45, 0.85, 1.0), 0.15, 2.0)
    c.position = warp_pos + Vector3(0, 1.3, 0)
    add_child(c)
    crystals.append(c)

func _add_pickup() -> void:
    for i in 300:
        var tx := randi_range(1, town.FW - 2)
        var ty := randi_range(1, town.FH - 2)
        if town.ftile(tx, ty) != town.F_GRASS:
            continue
        var pt: Array = town.FD.portal
        if Vector2(tx - int(pt[0]), ty - int(pt[1])).length() <= 3.0:
            continue
        var ok := true
        for q in pickups:
            if q.tx == tx and q.ty == ty:
                ok = false
        if not ok:
            continue
        var p: Vector3 = town.fw(tx + randf_range(0.25, 0.75), ty + randf_range(0.35, 0.75))
        if Vector2(p.x - town.player.position.x, p.z - town.player.position.z).length() < 13.0 and town.player.position.x < town.OX:
            continue
        var k := "stone" if randf() < 0.5 else "stick"
        var m := MeshInstance3D.new()
        if k == "stone":
            m.mesh = stone_mesh
            m.material_override = stone_mat
            m.scale = Vector3(1.0, randf_range(0.6, 0.8), randf_range(0.8, 1.1))
            m.position = Vector3(p.x, town.ground_y(p.x, p.z) + 0.1, p.z)
        else:
            m.mesh = stick_mesh
            m.material_override = stick_mat
            m.rotation = Vector3(PI / 2.0, randf() * TAU, 0)
            m.position = Vector3(p.x, town.ground_y(p.x, p.z) + 0.08, p.z)
        m.rotation.y = randf() * TAU
        add_child(m)
        pickups.append({"tx": tx, "ty": ty, "k": k, "n": m})
        return

func _update_world(delta: float) -> void:
    _update_trees(delta)
    _update_projectiles(delta)
    var p = town.player
    for i in range(pickups.size() - 1, -1, -1):
        var q: Dictionary = pickups[i]
        var n: MeshInstance3D = q.n
        if abs(n.position.x - p.position.x) < 0.95 and abs(n.position.z - p.position.z) < 0.85 and not p.dead:
            if q.k == "stone":
                p.stone += 1
                float_text("+1 หิน", n.position + Vector3(0, 1.0, 0), Color(0.85, 0.88, 0.95), 0.75)
            else:
                p.wood += 1
                float_text("+1 ไม้", n.position + Vector3(0, 1.0, 0), Color(0.95, 0.8, 0.55), 0.75)
            n.queue_free()
            pickups.remove_at(i)
    pick_t -= delta
    if pickups.size() < PICK_MAX and pick_t <= 0.0:
        _add_pickup()
        pick_t = 8.0
    var tt := Time.get_ticks_msec() / 1000.0
    for i in crystals.size():
        var c: MeshInstance3D = crystals[i]
        c.rotation.y = tt * 1.2 + i
        c.position.y += sin(tt * 2.0 + i) * 0.004
    if portal_disc != null:
        portal_disc.rotation.y = tt * 0.8
    var near := ""
    if p.position.distance_to(portal_pos) < 3.4:
        near = "ประตูมิติ — กดตีเพื่อเลือกแผนที่ขุดแร่ (เหมือง 5 แห่ง)"
    elif p.position.distance_to(dungeon_pos) < 4.0:
        near = "ประตูดันเจี้ยนร้อยชั้น · เร็ว ๆ นี้"
    elif p.position.distance_to(warp_pos) < 2.2:
        near = "หินวาร์ป · เร็ว ๆ นี้"
    if near != "":
        town.prompt.text = near

func near_portal(p) -> bool:
    return p.position.distance_to(portal_pos) < 3.4

# ---------- การโจมตีของผู้เล่น (เรียกทุกเฟรมในช่วงดาบฟัน) ----------
func new_attack() -> int:
    atk_id += 1
    return atk_id

func _targets() -> Array:
    return slimes + extra if not extra.is_empty() else slimes

func melee(p, spin: bool, id: int) -> void:
    var fwd := Vector3(sin(p.heading), 0, cos(p.heading))
    var c: Vector3 = p.position if spin else p.position + fwd * 1.4
    var r := 2.3 if spin else 1.45
    for s in _targets():
        if not is_instance_valid(s) or s.dead or s.last_atk == id:
            continue
        var d := Vector2(s.position.x - c.x, s.position.z - c.z).length()
        if d < r + s.radius * 0.6:
            s.last_atk = id
            hit_slime(s, p, 1.0)

## ดาเมจหนึ่งครั้ง (ใช้ร่วม: ฟัน · สกิล · ยิงไกล)
func hit_slime(s, p, mult: float) -> void:
    var cr: bool = randf() < p.crit_rate()
    var dm: int = max(1, int(round(p.atk() * mult * randf_range(0.9, 1.1) * (1.8 if cr else 1.0))))
    s.take_hit(dm, p.position)
    float_text(("คริ! " if cr else "") + str(dm), s.position + Vector3(0, s.radius * 2.0 + 0.4, 0), Color(1.0, 0.85, 0.3) if cr else Color(1, 1, 1), 1.4 if cr else 1.0)
    if s.dead:
        if s.has_method("killed_by"):
            s.killed_by()
        else:
            _killed(s)

## สกิลฟันรอบตัว
func aoe(p, radius: float, mult: float) -> int:
    var n := 0
    for s in _targets():
        if not is_instance_valid(s) or s.dead:
            continue
        if Vector2(s.position.x - p.position.x, s.position.z - p.position.z).length() < radius + s.radius * 0.6:
            hit_slime(s, p, mult)
            n += 1
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = radius * 0.85
    tm.outer_radius = radius
    ring.mesh = tm
    ring.material_override = town.M(Color(0.7, 0.9, 1.0), 0.3, 2.0)
    ring.position = p.position + Vector3(0, 0.3, 0)
    ring.scale = Vector3(1, 0.15, 1)
    add_child(ring)
    projectiles.append({"n": ring, "fx": true, "t": 0.0})
    return n

## ยิงไปข้างหน้า (ลูกไฟ · ลูกเวทคทา · ลูกธนู) ชนสไลม์ตัวแรก
var projectiles: Array = []
func shoot(p, spec: Dictionary, mult: float) -> void:
    var dir := Vector3(sin(p.heading), 0, cos(p.heading))
    var m := MeshInstance3D.new()
    var kind := str(spec.get("kind", "bolt"))
    if kind == "arrow":
        var cm := CylinderMesh.new()
        cm.top_radius = 0.03
        cm.bottom_radius = 0.03
        cm.height = 0.9
        m.mesh = cm
        m.material_override = town.M(Color(0.85, 0.75, 0.55), 0.6)
        m.rotation = Vector3(PI / 2.0, p.heading, 0)
    else:
        var sm := SphereMesh.new()
        sm.radius = 0.28 if kind == "fire" else 0.2
        sm.height = sm.radius * 2.0
        m.mesh = sm
        m.material_override = town.M(Color(1.0, 0.45, 0.1) if kind == "fire" else Color(0.55, 0.75, 1.0), 0.3, 3.0)
    m.position = p.position + Vector3(0, 1.1, 0) + dir * 0.8
    add_child(m)
    projectiles.append({"n": m, "dir": dir, "speed": float(spec.speed), "left": float(spec.range), "mult": mult, "p": p})

func _update_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        var q: Dictionary = projectiles[i]
        var n: MeshInstance3D = q.n
        if q.get("fx", false):
            q.t += delta
            n.scale = Vector3(1.0 + q.t * 2.0, 0.15, 1.0 + q.t * 2.0)
            if q.t > 0.3:
                n.queue_free()
                projectiles.remove_at(i)
            continue
        var step: float = q.speed * delta
        n.position += q.dir * step
        q.left -= step
        var hit = null
        for s in _targets():
            if is_instance_valid(s) and not s.dead and Vector2(s.position.x - n.position.x, s.position.z - n.position.z).length() < s.radius + 0.35:
                hit = s
                break
        if hit != null:
            hit_slime(hit, q.p, q.mult)
        if hit != null or q.left <= 0.0:
            n.queue_free()
            projectiles.remove_at(i)

func _killed(s) -> void:
    say_msg("สไลม์แตก!")
    var n := 1 + (1 if randf() < 0.4 else 0)
    var c: int = 1 + randi() % 3 + (s.lv >> 1)
    for i in n:
        _drop("gel", s.position)
    for i in c:
        _drop("coin", s.position)
    town.player.gain_xp(5 * s.lv)

func nearest_slime(pos: Vector3, maxd: float):
    var best = null
    var bd := maxd
    for s in _targets():
        if not is_instance_valid(s) or s.dead:
            continue
        var d := Vector2(s.position.x - pos.x, s.position.z - pos.z).length()
        if d < bd:
            bd = d
            best = s
    return best

func slime_at(screen: Vector2):
    var best = null
    var bd := 55.0
    for s in _targets():
        if not is_instance_valid(s) or s.dead or not town.cam.is_position_in_frustum(s.global_position):
            continue
        var sp: Vector2 = town.cam.unproject_position(s.global_position + Vector3(0, s.radius, 0))
        var d := sp.distance_to(screen)
        if d < bd:
            bd = d
            best = s
    return best

# ---------- ของดรอป ----------
func _drop(kind: String, at: Vector3) -> void:
    var m := MeshInstance3D.new()
    match kind:
        "coin":
            m.mesh = coin_mesh
            m.material_override = coin_mat
        "wood":
            m.mesh = wood_mesh
            m.material_override = wood_mat
            m.rotation.x = PI / 2.0
        "apple":
            m.mesh = apple_mesh
            m.material_override = apple_mat
        _:
            m.mesh = gel_mesh
            m.material_override = gel_mat
    m.position = at + Vector3(0, 0.6, 0)
    add_child(m)
    var a := randf() * TAU
    drops.append({"n": m, "k": kind, "v": Vector3(cos(a) * randf_range(1.5, 3.0), randf_range(4.0, 6.0), sin(a) * randf_range(1.5, 3.0)), "t": 0.0})

func float_text(t: String, at: Vector3, c: Color, sc: float = 1.0) -> void:
    var l := Label3D.new()
    l.text = t
    l.font = town.font_b
    l.font_size = int(54 * sc)
    l.pixel_size = 0.01
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.no_depth_test = true
    l.outline_size = 12
    l.outline_modulate = Color(0, 0, 0, 0.9)
    l.modulate = c
    l.position = at
    l.render_priority = 5
    add_child(l)
    floaters.append({"n": l, "t": 0.0})

# ---------- HUD ต่อสู้ ----------
func _bar(col: Color, w: float) -> ProgressBar:
    var b := ProgressBar.new()
    b.show_percentage = false
    b.custom_minimum_size = Vector2(w, 10)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.025, 0.04, 0.06, 0.94)
    bg.set_corner_radius_all(5)
    bg.border_color = Color(0.42, 0.48, 0.51, 0.45)
    bg.set_border_width_all(1)
    var fg := StyleBoxFlat.new()
    fg.bg_color = col
    fg.set_corner_radius_all(4)
    b.add_theme_stylebox_override("background", bg)
    b.add_theme_stylebox_override("fill", fg)
    return b

func _text(sz: int, col: Color = Color(1, 1, 1)) -> Label:
    var l := Label.new()
    l.add_theme_font_override("font", town.font_b)
    l.add_theme_font_size_override("font_size", sz)
    l.add_theme_color_override("font_color", col)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    l.add_theme_constant_override("outline_size", 1)
    return l

func _build_hud() -> void:
    cl = CanvasLayer.new()
    add_child(cl)
    var box := VBoxContainer.new()
    hud_box = box
    hud_card = PanelContainer.new()
    hud_card.position = Vector2(16, 96)
    var card := StyleBoxFlat.new()
    card.bg_color = Color(0.035, 0.055, 0.075, 0.9)
    card.border_color = Color(0.62, 0.55, 0.37, 0.65)
    card.set_border_width_all(1)
    card.set_corner_radius_all(10)
    card.content_margin_left = 10
    card.content_margin_right = 10
    card.content_margin_top = 8
    card.content_margin_bottom = 8
    hud_card.add_theme_stylebox_override("panel", card)
    cl.add_child(hud_card)
    box.add_theme_constant_override("separation", 4)
    hud_card.add_child(box)
    lv_txt = _text(13, Color(0.86, 0.79, 0.61))
    box.add_child(lv_txt)
    for row in [["HP", Color(0.65, 0.24, 0.23)], ["MP", Color(0.20, 0.46, 0.64)], ["EXP", Color(0.72, 0.61, 0.34)]]:
        var hb := HBoxContainer.new()
        var tag := _text(10)
        tag.text = row[0]
        tag.custom_minimum_size = Vector2(24, 0)
        hb.add_child(tag)
        var b := _bar(row[1], 118)
        bars.append(b)
        hb.add_child(b)
        var tx := _text(10)
        hb.add_child(tx)
        box.add_child(hb)
        if row[0] == "HP":
            hp_bar = b
            hp_txt = tx
        elif row[0] == "MP":
            mp_bar = b
            mp_txt = tx
        else:
            xp_bar = b
    bag_txt = _text(11, Color(0.72, 0.78, 0.81))
    box.add_child(bag_txt)
    msg = _text(16, Color(0.91, 0.84, 0.67))
    msg.anchor_left = 0.5
    msg.anchor_right = 0.5
    msg.offset_left = -400
    msg.offset_right = 400
    msg.offset_top = 70
    msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cl.add_child(msg)
    # ปุ่มดาบ (มือถือ/เมาส์) — เหมือนปุ่ม ⚔️ ในเกมเดิม
    atk_btn = Button.new()
    atk_btn.text = "ตี (J)"
    atk_btn.add_theme_font_override("font", town.font_b)
    atk_btn.add_theme_font_size_override("font_size", 22)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.55, 0.12, 0.1, 0.85)
    sb.border_color = Color(1.0, 0.8, 0.4)
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(60)
    var sb2: StyleBoxFlat = sb.duplicate()
    sb2.bg_color = Color(0.8, 0.2, 0.15, 0.95)
    atk_btn.add_theme_stylebox_override("normal", sb)
    atk_btn.add_theme_stylebox_override("hover", sb2)
    atk_btn.add_theme_stylebox_override("pressed", sb2)
    atk_btn.anchor_left = 1.0
    atk_btn.anchor_right = 1.0
    atk_btn.anchor_top = 1.0
    atk_btn.anchor_bottom = 1.0
    atk_btn.offset_left = -150
    atk_btn.offset_right = -30
    atk_btn.offset_top = -150
    atk_btn.offset_bottom = -30
    atk_btn.focus_mode = Control.FOCUS_NONE
    atk_btn.button_down.connect(func(): town.player.set_attack_held(true))
    atk_btn.button_up.connect(func(): town.player.set_attack_held(false))
    cl.add_child(atk_btn)

func say_msg(t: String, dur: float = 2.5) -> void:
    msg.text = t
    msg_t = dur

func _update_hud() -> void:
    var p = town.player
    hp_bar.max_value = p.max_hp
    hp_bar.value = p.hp
    hp_txt.text = " %d/%d" % [round(p.hp), p.max_hp]
    mp_bar.max_value = p.max_mp
    mp_bar.value = p.mp
    mp_txt.text = " %d/%d" % [round(p.mp), p.max_mp]
    xp_bar.max_value = p.need(p.lv)
    xp_bar.value = p.xp
    lv_txt.text = "Lv.%d  ·  ATK %d  DEF %d" % [p.lv, p.atk(), p.def()]
    if town.char_btn != null:
        town.char_btn.text = ("ตัวละคร +%d" % p.sp) if p.sp > 0 else "ตัวละคร"
    bag_txt.text = "เหรียญ %d · เจล %d · หิน %d · ไม้ %d" % [p.coins, p.gel, p.stone, p.wood]

func _process(delta: float) -> void:
    _update_world(delta)
    for i in range(slimes.size() - 1, -1, -1):
        if not is_instance_valid(slimes[i]):
            slimes.remove_at(i)
    var alive := 0
    for s in slimes:
        if is_instance_valid(s) and not s.dead:
            alive += 1
    resp_t -= delta
    if alive < MAX_SLIMES and resp_t <= 0.0:
        spawn()
        resp_t = 6.0
    var p = town.player
    for i in range(drops.size() - 1, -1, -1):
        var d: Dictionary = drops[i]
        var n: MeshInstance3D = d.n
        d.t += delta
        if d.t < 0.65 or not d.has("gy"):
            d.gy = town.ground_y(n.position.x, n.position.z) + 0.15
        var gy: float = d.gy
        if d.t < 0.6:
            var v: Vector3 = d.v
            v.y -= 18.0 * delta
            n.position += v * delta
            if n.position.y < gy:
                n.position.y = gy
                v = v * Vector3(0.5, -0.35, 0.5)
            d.v = v
        else:
            var to: Vector3 = p.position + Vector3(0, 1.0, 0) - n.position
            if to.length() < 4.5 and not p.dead:
                n.position += to.normalized() * min(to.length(), (6.0 + d.t * 6.0) * delta)
                if to.length() < 0.5:
                    if d.k == "coin":
                        p.coins += 1
                    else:
                        p.inv_add(str(d.k), 1)
                    n.queue_free()
                    drops.remove_at(i)
                    continue
            else:
                n.position.y = gy + 0.12 + sin(d.t * 3.0) * 0.08
        n.rotation.y += delta * 3.0
    for i in range(floaters.size() - 1, -1, -1):
        var f: Dictionary = floaters[i]
        f.t += delta
        var l: Label3D = f.n
        l.position.y += delta * 1.6
        l.modulate.a = clamp(1.6 - f.t * 1.6, 0.0, 1.0)
        if f.t > 1.0:
            l.queue_free()
            floaters.remove_at(i)
    if msg_t > 0.0:
        msg_t -= delta
        if msg_t <= 0.0:
            msg.text = ""
    _hud_tick += delta
    if _hud_tick >= 0.1:
        _hud_tick = 0.0
        _update_hud()
