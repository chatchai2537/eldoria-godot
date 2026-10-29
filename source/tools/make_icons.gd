extends SceneTree
## สร้างไอคอนไอเท็มจากโมเดล 3D (ชิ้นส่วน KayKit + รูปทรง) → assets/icons/<id>.png (96×96 พื้นโปร่งใส)
## เจ้าของสั่ง: ใช้โมเดล 3D เท่านั้น ห้ามภาพที่ AI วาด · รัน: xvfb-run godot --path source --rendering-driver opengl3 --script res://tools/make_icons.gd
const ItemModels = preload("res://scripts/item_model_kit.gd")
const Items = preload("res://scripts/items.gd")
const Steed = preload("res://scripts/steed.gd")
const TIER_COL := [Color("#9a9da5"), Color("#aab4c5"), Color("#d98443"), Color("#cfd7e6"), Color("#f2c230"), Color("#5ec8ff"),
    Color("#5a8a3a"), Color("#2a9a7a"), Color("#a8d8f0"), Color("#e0b030"), Color("#c81a2a"), Color("#5a3a8a")]
const LBC := [["#5a8a3a", "#9aff6a"], ["#2a9a7a", "#6affc8"], ["#a8c8e0", "#bfe8ff"], ["#e0b030", "#ffe880"], ["#c81a2a", "#ffc040"], ["#3a2a5a", "#b07aff"]]
const OUT := "res://assets/icons/"

var vp: SubViewport
var cam: Camera3D
var holder: Node3D
var glbs := {}

func _initialize() -> void:
    call_deferred("_run")

func _mat(c: Color, rough: float = 0.5, emit: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(c.r, c.g, c.b, alpha)
    m.roughness = rough
    m.metallic = 0.0
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emit
    return m

func _mesh(parent: Node3D, mesh: Mesh, c: Color, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, emit: float = 0.0, alpha: float = 1.0, rough: float = 0.5) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = _mat(c, rough, emit, alpha)
    mi.position = pos
    mi.rotation = rot
    mi.scale = scl
    parent.add_child(mi)
    return mi

func _box(s: Vector3) -> BoxMesh:
    var b := BoxMesh.new()
    b.size = s
    return b

func _sph(r: float, h: float = -1.0) -> SphereMesh:
    var m := SphereMesh.new()
    m.radius = r
    m.height = r * 2.0 if h < 0.0 else h
    m.radial_segments = 24
    m.rings = 12
    return m

func _cyl(rt: float, rb: float, h: float, seg: int = 20) -> CylinderMesh:
    var m := CylinderMesh.new()
    m.top_radius = rt
    m.bottom_radius = rb
    m.height = h
    m.radial_segments = seg
    return m

func _torus(ri: float, ro: float) -> TorusMesh:
    var t := TorusMesh.new()
    t.inner_radius = ri
    t.outer_radius = ro
    t.rings = 24
    t.ring_segments = 12
    return t

## ชิ้นส่วนจาก KayKit (ดาบ หมวก โล่ คทา หน้าไม้ ขวาน แก้วเบียร์)
func _kay(parent: Node3D, file: String, item: String, tint: Color, mix: float = 0.6) -> Node3D:
    if not glbs.has(file):
        glbs[file] = load("res://assets/chars/%s.glb" % file)
    var inst: Node = glbs[file].instantiate()
    var sk := inst.get_node("Rig/Skeleton3D")
    var found: MeshInstance3D = null
    for c in sk.get_children():
        if c is BoneAttachment3D:
            for m in c.get_children():
                if String(m.name) == item:
                    found = m
    var dup: MeshInstance3D = found.duplicate()
    inst.free()
    dup.transform = Transform3D.IDENTITY
    for si in dup.mesh.get_surface_count():
        var base: Material = dup.mesh.surface_get_material(si)
        if base is StandardMaterial3D:
            var mt: StandardMaterial3D = base.duplicate()
            mt.albedo_color = Color(1, 1, 1).lerp(tint, mix)
            mt.metallic = 0.3
            mt.roughness = 0.4
            dup.set_surface_override_material(si, mt)
    parent.add_child(dup)
    return dup

func _rock(n: Node3D, c: Color, cry: Color = Color(0, 0, 0, 0)) -> void:
    _mesh(n, _sph(0.5, 0.75), c, Vector3.ZERO, Vector3(0.2, 0.4, 0.1), Vector3(1.1, 1, 0.95), 0.0, 1.0, 0.9)
    if cry.a > 0.0:
        for k in 3:
            var a := k * 2.1
            _mesh(n, _cyl(0.0, 0.14, 0.55, 5), cry, Vector3(cos(a) * 0.18, 0.38, sin(a) * 0.18), Vector3(cos(a) * 0.5, 0, sin(a) * 0.5), Vector3.ONE, 0.4)

func _ingot(n: Node3D, c: Color) -> void:
    _mesh(n, _cyl(0.32, 0.42, 0.28, 4), c, Vector3.ZERO, Vector3(0.55, PI / 4.0 + 0.35, 0), Vector3(1.6, 1.3, 0.9), 0.15, 1.0, 0.3)

func _fish(n: Node3D, c: Color) -> void:
    _mesh(n, _sph(0.3), c, Vector3.ZERO, Vector3.ZERO, Vector3(1.8, 0.9, 0.6))
    _mesh(n, _cyl(0.0, 0.3, 0.4, 3), c.darkened(0.2), Vector3(-0.62, 0, 0), Vector3(0, 0, PI / 2.0), Vector3(1, 1, 0.25))
    _mesh(n, _sph(0.05), Color(0.05, 0.05, 0.05), Vector3(0.38, 0.08, 0.16))

func _bottle(n: Node3D, c: Color, alpha: float = 1.0) -> void:
    _mesh(n, _sph(0.32), c, Vector3(0, -0.12, 0), Vector3.ZERO, Vector3.ONE, 0.3, alpha)
    _mesh(n, _cyl(0.1, 0.12, 0.3), c, Vector3(0, 0.28, 0), Vector3.ZERO, Vector3.ONE, 0.3, alpha)
    _mesh(n, _cyl(0.11, 0.11, 0.1), Color(0.55, 0.38, 0.2), Vector3(0, 0.47, 0))

func build(id: String) -> Node3D:
    var model_id = {"gem":"diamond", "sword0":"sword", "staff0":"staff", "bow0":"bow", "axe0":"axe", "pick0":"pick", "hp":"hpp", "mp":"mpp"}.get(id, id)
    if ItemModels.IDS.has(model_id):
        var visual = ItemModels.instance(model_id)
        if model_id == "bow": visual.rotation.x = 0.85
        if model_id == "coin": visual.rotation.x = 1.1
        return visual
    var n := Node3D.new()
    if Items.is_gear(id):
        var k := Items.gear_kind(id)
        var tc: Color = TIER_COL[Items.gear_tier(id)]
        match k:
            "sword":
                _kay(n, "Knight", "1H_Sword", tc).rotation = Vector3(0, 0, -0.8)
            "staff":
                _kay(n, "Mage", "2H_Staff", tc).rotation = Vector3(0, 0, -0.8)
            "bow":
                _kay(n, "Rogue", "1H_Crossbow", tc).rotation = Vector3(0.5, 0.3, 0.4)
            "axe":
                _kay(n, "Barbarian", "1H_Axe", tc).rotation = Vector3(0, 0, -0.6)
            "pick":
                _mesh(n, _cyl(0.04, 0.04, 1.1), Color(0.5, 0.33, 0.18), Vector3.ZERO, Vector3(0, 0, -0.6))
                _mesh(n, _cyl(0.02, 0.08, 0.9), tc, Vector3(0.28, 0.4, 0), Vector3(0, 0, -0.6 + PI / 2.0), Vector3.ONE, 0.1, 1.0, 0.3)
            "helm":
                _kay(n, "Knight", "Knight_Helmet", tc).rotation = Vector3(0.2, 0.6, 0)
            "arm":
                _kay(n, "Knight", "Round_Shield", tc).rotation = Vector3(0.2, 1.2, 0)
            "chest":
                _mesh(n, _box(Vector3(0.8, 0.85, 0.35)), tc, Vector3.ZERO, Vector3(0, 0.4, 0), Vector3.ONE, 0.1, 1.0, 0.3)
                for sx in [-0.5, 0.5]:
                    _mesh(n, _sph(0.2), tc.darkened(0.1), Vector3(sx, 0.35, 0), Vector3.ZERO, Vector3(1, 0.7, 1), 0.1, 1.0, 0.3)
            "pants":
                for sx in [-0.17, 0.17]:
                    _mesh(n, _box(Vector3(0.28, 0.75, 0.3)), tc, Vector3(sx, -0.15, 0), Vector3(0, 0.4, 0), Vector3.ONE, 0.1, 1.0, 0.3)
                _mesh(n, _box(Vector3(0.65, 0.22, 0.32)), tc.darkened(0.2), Vector3(0, 0.3, 0), Vector3(0, 0.4, 0), Vector3.ONE, 0.1, 1.0, 0.3)
            "neck":
                _mesh(n, _torus(0.42, 0.47), tc, Vector3.ZERO, Vector3(1.2, 0, 0), Vector3.ONE, 0.1, 1.0, 0.3)
                _mesh(n, _sph(0.12), Color(0.9, 0.2, 0.35), Vector3(0, -0.42, 0.15), Vector3.ZERO, Vector3.ONE, 0.5)
            "ring":
                _mesh(n, _torus(0.25, 0.33), tc, Vector3.ZERO, Vector3(1.0, 0, 0.3), Vector3.ONE, 0.1, 1.0, 0.3)
                _mesh(n, _sph(0.13), Color(0.4, 0.8, 1.0), Vector3(0, 0.3, 0.05), Vector3.ZERO, Vector3.ONE, 0.6)
        return n
    if id.begins_with("m_"):
        var mn: Node3D = Steed.build_mount(id.substr(2))
        mn.rotation.y = 0.9
        return mn
    if id.begins_with("p_"):
        var pn: Node3D = Steed.build_pet(id.substr(2))
        pn.rotation.y = 0.7
        return pn
    if id.begins_with("lbm"):
        var cc: Array = LBC[int(id.substr(3))]
        _mesh(n, _cyl(0.48, 0.48, 0.14, 6), Color(cc[0]), Vector3.ZERO, Vector3(1.25, 0, 0), Vector3.ONE, 0.2, 1.0, 0.3)
        _mesh(n, _cyl(0.3, 0.3, 0.16, 6), Color(cc[1]), Vector3(0, 0.03, 0.02), Vector3(1.25, 0, 0), Vector3.ONE, 1.2, 1.0, 0.3)
        _mesh(n, _sph(0.12), Color(1, 1, 1), Vector3(0, 0.06, 0.12), Vector3.ZERO, Vector3.ONE, 1.5)
        return n
    match id:
        "gel":
            _mesh(n, _sph(0.42), Color(0.4, 0.75, 1.0), Vector3.ZERO, Vector3.ZERO, Vector3(1.2, 0.7, 1.2), 0.3, 0.85, 0.15)
        "stone":
            _rock(n, Color(0.6, 0.6, 0.63))
        "coal":
            _rock(n, Color(0.15, 0.14, 0.15))
        "wood":
            _mesh(n, _cyl(0.22, 0.22, 1.0), Color(0.5, 0.33, 0.18), Vector3.ZERO, Vector3(0, 0, PI / 2.0 - 0.3))
            _mesh(n, _cyl(0.2, 0.2, 1.01), Color(0.85, 0.7, 0.45), Vector3.ZERO, Vector3(0, 0, PI / 2.0 - 0.3), Vector3(0.9, 1, 0.9))
        "iron":
            _rock(n, Color(0.5, 0.48, 0.47), Color(0.78, 0.59, 0.47))
        "copper":
            _rock(n, Color(0.5, 0.45, 0.42), Color(0.94, 0.59, 0.31))
        "silver":
            _rock(n, Color(0.5, 0.5, 0.55), Color(0.88, 0.92, 1.0))
        "gold":
            _rock(n, Color(0.5, 0.47, 0.42), Color(1.0, 0.84, 0.31))
        "gem":
            _mesh(n, _sph(0.4, 0.8), Color(0.67, 0.92, 1.0), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.8, 0.9, 0.05)
        "ingSt":
            _ingot(n, Color(0.65, 0.65, 0.68))
        "ingot":
            _ingot(n, Color(0.72, 0.75, 0.8))
        "ingCu":
            _ingot(n, Color(0.9, 0.55, 0.3))
        "ingAg":
            _ingot(n, Color(0.9, 0.93, 1.0))
        "ingAu":
            _ingot(n, Color(1.0, 0.82, 0.3))
        "ingDm":
            _ingot(n, Color(0.55, 0.88, 1.0))
        "rod", "rod2":
            _mesh(n, _cyl(0.03, 0.05, 1.4), Color(0.55, 0.36, 0.18) if id == "rod" else Color(0.65, 0.68, 0.75), Vector3.ZERO, Vector3(0, 0, -0.7))
            _mesh(n, _sph(0.09), Color(1.0, 0.3, 0.25), Vector3(0.45, -0.45, 0))
        "carp":
            _fish(n, Color("#c8b070"))
        "tilapia":
            _fish(n, Color("#a8b4bc"))
        "catfish":
            _fish(n, Color("#6a6458"))
        "salmon":
            _fish(n, Color("#ff9a7a"))
        "goldfish":
            _fish(n, Color("#ffe14a"))
        "dragon":
            _fish(n, Color("#7fe0ff"))
        "estone":
            _mesh(n, _cyl(0.0, 0.35, 0.5, 6), Color(0.35, 0.75, 1.0), Vector3(0, 0.2, 0), Vector3.ZERO, Vector3.ONE, 0.8)
            _mesh(n, _cyl(0.35, 0.0, 0.5, 6), Color(0.25, 0.6, 1.0), Vector3(0, -0.3, 0), Vector3.ZERO, Vector3.ONE, 0.8)
        "bless":
            _mesh(n, _cyl(0.0, 0.35, 0.5, 6), Color(1.0, 0.85, 0.3), Vector3(0, 0.2, 0), Vector3.ZERO, Vector3.ONE, 0.8)
            _mesh(n, _cyl(0.35, 0.0, 0.5, 6), Color(0.95, 0.7, 0.15), Vector3(0, -0.3, 0), Vector3.ZERO, Vector3.ONE, 0.8)
        "bone":
            _mesh(n, _cyl(0.07, 0.07, 0.9), Color(0.92, 0.9, 0.82), Vector3.ZERO, Vector3(0, 0, -0.8))
            for e in [-1.0, 1.0]:
                _mesh(n, _sph(0.13), Color(0.92, 0.9, 0.82), Vector3(e * 0.31, e * 0.32, 0.06))
                _mesh(n, _sph(0.13), Color(0.92, 0.9, 0.82), Vector3(e * 0.36, e * 0.25, -0.08))
        "rag":
            _mesh(n, _box(Vector3(0.8, 0.08, 0.6)), Color(0.45, 0.5, 0.35), Vector3.ZERO, Vector3(0.6, 0.3, 0.2))
        "pelt":
            _mesh(n, _box(Vector3(0.9, 0.08, 0.6)), Color(0.55, 0.42, 0.3), Vector3.ZERO, Vector3(0.6, 0.3, 0.2))
        "wing":
            _mesh(n, _cyl(0.0, 0.5, 0.05, 3), Color(0.45, 0.35, 0.5), Vector3.ZERO, Vector3(1.2, 0.3, 0), Vector3(1.4, 1, 0.8))
        "shell":
            _mesh(n, _sph(0.4, 0.4), Color(0.55, 0.4, 0.25), Vector3.ZERO, Vector3(0.3, 0, 0), Vector3(1.2, 1, 1), 0.0, 1.0, 0.4)
        "core":
            _mesh(n, _sph(0.38), Color(0.6, 0.58, 0.52), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.0, 1.0, 0.8)
            _mesh(n, _sph(0.15), Color(1.0, 0.7, 0.3), Vector3(0, 0, 0.3), Vector3.ZERO, Vector3.ONE, 1.5)
        "dust":
            for k in 7:
                var a := k * 0.9
                _mesh(n, _sph(0.08 + (k % 3) * 0.03), Color(0.9, 0.85, 1.0), Vector3(cos(a) * 0.3, sin(a * 1.7) * 0.25, sin(a) * 0.2), Vector3.ZERO, Vector3.ONE, 1.2)
        "scale":
            _mesh(n, _cyl(0.4, 0.4, 0.06, 6), Color(0.3, 0.8, 0.65), Vector3.ZERO, Vector3(1.2, 0, 0.2), Vector3.ONE, 0.3, 1.0, 0.3)
        "hpp", "hp":
            _bottle(n, Color(0.9, 0.2, 0.25))
        "mpp", "mp":
            _bottle(n, Color(0.25, 0.45, 1.0))
        "bottle":
            _bottle(n, Color(0.8, 0.9, 0.95), 0.5)
        "phoenix":
            _mesh(n, _cyl(0.0, 0.25, 1.0, 4), Color(1.0, 0.5, 0.15), Vector3.ZERO, Vector3(0, 0.3, -0.6), Vector3(1, 1, 0.25), 0.8)
            _mesh(n, _cyl(0.0, 0.15, 0.7, 4), Color(1.0, 0.85, 0.3), Vector3(0.06, 0.05, 0.02), Vector3(0, 0.3, -0.6), Vector3(1, 1, 0.3), 0.6)
        "scroll":
            _mesh(n, _cyl(0.17, 0.17, 0.9), Color(0.92, 0.85, 0.68), Vector3.ZERO, Vector3(0, 0, PI / 2.0 - 0.3))
            _mesh(n, _cyl(0.18, 0.18, 0.12), Color(0.8, 0.15, 0.15), Vector3.ZERO, Vector3(0, 0, PI / 2.0 - 0.3))
        "apple", "f_apple":
            _mesh(n, _sph(0.38), Color(0.85, 0.12, 0.12), Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.9, 1), 0.0, 1.0, 0.3)
            _mesh(n, _cyl(0.03, 0.03, 0.2), Color(0.4, 0.25, 0.1), Vector3(0, 0.42, 0))
            _mesh(n, _sph(0.1), Color(0.3, 0.7, 0.2), Vector3(0.1, 0.45, 0), Vector3.ZERO, Vector3(1.5, 0.4, 0.8))
        "bread", "f_bread":
            _mesh(n, _sph(0.4), Color(0.85, 0.6, 0.3), Vector3.ZERO, Vector3(0, 0.4, 0), Vector3(1.4, 0.7, 0.9), 0.0, 1.0, 0.8)
        "f_carrot":
            _mesh(n, _cyl(0.18, 0.0, 0.9), Color(1.0, 0.5, 0.1), Vector3.ZERO, Vector3(0, 0, -0.6))
            _mesh(n, _cyl(0.0, 0.12, 0.3), Color(0.3, 0.7, 0.2), Vector3(-0.3, 0.42, 0), Vector3(0, 0, -0.6))
        "f_cabbage":
            _mesh(n, _sph(0.42), Color(0.45, 0.8, 0.35), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.0, 1.0, 0.7)
        "f_corn":
            _mesh(n, _sph(0.2, 0.9), Color(1.0, 0.85, 0.25), Vector3.ZERO, Vector3(0, 0, -0.5))
            _mesh(n, _cyl(0.0, 0.2, 0.8, 4), Color(0.4, 0.7, 0.25), Vector3(0.1, -0.05, 0.08), Vector3(0, 0, -0.5), Vector3(1, 1, 0.4))
        "f_orange":
            _mesh(n, _sph(0.38), Color(1.0, 0.55, 0.1), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.0, 1.0, 0.6)
        "f_grape":
            for k in 9:
                var r := 0.13
                _mesh(n, _sph(r), Color(0.5, 0.2, 0.6), Vector3(((k % 3) - 1) * 0.18 + (0.09 if k / 3 == 1 else 0.0), 0.25 - (k / 3) * 0.2, 0))
        "f_banana":
            _mesh(n, _sph(0.15, 0.9), Color(1.0, 0.9, 0.3), Vector3(-0.1, 0, 0), Vector3(0, 0, -0.9))
            _mesh(n, _sph(0.15, 0.9), Color(1.0, 0.88, 0.3), Vector3(0.12, -0.05, 0.05), Vector3(0, 0, -0.6))
        "f_pie":
            _mesh(n, _cyl(0.45, 0.4, 0.2), Color(0.8, 0.55, 0.3), Vector3.ZERO, Vector3(0.4, 0, 0))
        "f_cake":
            _mesh(n, _cyl(0.4, 0.4, 0.45), Color(1.0, 0.85, 0.9), Vector3.ZERO, Vector3(0.35, 0, 0))
            _mesh(n, _sph(0.08), Color(0.9, 0.1, 0.2), Vector3(0, 0.3, 0.05))
        "f_pumpkin":
            _mesh(n, _sph(0.42), Color(1.0, 0.55, 0.1), Vector3.ZERO, Vector3.ZERO, Vector3(1.2, 0.85, 1.2), 0.0, 1.0, 0.7)
            _mesh(n, _cyl(0.05, 0.06, 0.2), Color(0.35, 0.5, 0.2), Vector3(0, 0.4, 0))
        "f_honey":
            _mesh(n, _cyl(0.3, 0.3, 0.55), Color(1.0, 0.75, 0.15), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.3, 0.9, 0.2)
            _mesh(n, _cyl(0.32, 0.32, 0.1), Color(0.55, 0.35, 0.2), Vector3(0, 0.32, 0))
        "beer":
            _kay(n, "Barbarian", "Mug", Color(1, 1, 1), 0.0)
        "soup":
            _mesh(n, _cyl(0.45, 0.3, 0.3), Color(0.6, 0.4, 0.25), Vector3.ZERO, Vector3(0.4, 0, 0))
            _mesh(n, _cyl(0.4, 0.4, 0.02), Color(0.9, 0.6, 0.2), Vector3(0, 0.14, 0.05), Vector3(0.4, 0, 0))
        "rest":
            _mesh(n, _box(Vector3(0.9, 0.25, 0.6)), Color(0.75, 0.82, 0.95), Vector3.ZERO, Vector3(0.4, 0.4, 0))
            _mesh(n, _box(Vector3(0.3, 0.12, 0.45)), Color(1, 1, 1), Vector3(-0.3, 0.18, 0), Vector3(0.4, 0.4, 0))
        "skill":
            _mesh(n, _sph(0.38), Color(0.65, 0.45, 1.0), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 1.5)
        _:
            _mesh(n, _sph(0.35), Color(0.7, 0.7, 0.7))
    return n

func _fit(n: Node3D) -> void:
    var aabb := AABB()
    var first := true
    for mi in n.find_children("*", "MeshInstance3D", true, false):
        var a: AABB = (mi as MeshInstance3D).get_aabb()
        var xf: Transform3D = (mi as Node3D).global_transform if mi.is_inside_tree() else (mi as Node3D).transform
        a = xf * a
        aabb = a if first else aabb.merge(a)
        first = false
    var sz: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
    if sz > 0.0:
        n.scale = Vector3.ONE * (1.25 / sz)
        n.position = -aabb.get_center() * n.scale.x

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    vp = SubViewport.new()
    vp.size = Vector2i(128, 128)
    vp.transparent_bg = true
    vp.own_world_3d = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_CLEAR_COLOR
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(1, 1, 1)
    e.ambient_light_energy = 0.55
    env.environment = e
    vp.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(-0.9, 0.6, 0)
    sun.light_energy = 1.25
    vp.add_child(sun)
    cam = Camera3D.new()
    cam.position = Vector3(0, 0.55, 2.6)
    cam.fov = 35.0
    vp.add_child(cam)
    cam.look_at(Vector3.ZERO)
    var ids := []
    for k in Items.ITEM.keys():
        ids.append(str(k))
    for k in Items.KIND_ORDER:
        for t in Items.TNAMES.size():
            var gid := "%s%d" % [k, t]
            if Items.is_gear(gid) and not ids.has(gid):
                ids.append(gid)
    for k in ["hp", "mp", "beer", "soup", "rest", "skill"]:
        ids.append(k)
    for k in Steed.MOUNT_ORDER:
        ids.append("m_" + k)
    for k in Steed.PET_ORDER:
        ids.append("p_" + k)
    if OS.get_cmdline_user_args().has("--item-models-only"):
        ids = ["sword0", "staff0", "bow0", "axe0", "pick0", "hpp", "mpp", "hp", "mp", "scroll", "wood", "stone", "iron", "copper", "silver", "gold", "gem", "gel"]
    var n_ok := 0
    for id in ids:
        if holder != null:
            holder.queue_free()
        holder = Node3D.new()
        vp.add_child(holder)
        var item := build(id)
        holder.add_child(item)
        await process_frame
        _fit(item)
        holder.rotation = Vector3(0, 0.0, 0)
        await process_frame
        await process_frame
        var img: Image = vp.get_texture().get_image()
        img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
        img.save_png(ProjectSettings.globalize_path(OUT + id + ".png"))
        n_ok += 1
    print("ICONS ", n_ok)
    quit()
