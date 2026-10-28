extends Node3D
## หุ่นตัวละครแบบหัวสี่เหลี่ยม ข้อต่อแขนขาแยกชิ้น (ใช้ทั้งผู้เล่นและ NPC)

var root: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var ph := 0.0

func _m(c: Color, r: float = 0.75) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = r
    return m

func _b(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var bm := BoxMesh.new()
    bm.size = size
    var mi := MeshInstance3D.new()
    mi.mesh = bm
    mi.material_override = mat
    mi.position = pos
    parent.add_child(mi)
    return mi

func build(o: Dictionary) -> void:
    var skin := _m(o.get("skin", Color(0.93, 0.76, 0.6)), 0.6)
    var shirt := _m(o.get("shirt", Color(0.25, 0.35, 0.7)))
    var pants := _m(o.get("pants", Color(0.22, 0.18, 0.15)))
    var hair := _m(o.get("hair", Color(0.25, 0.16, 0.1)))
    var boots := _m(Color(0.25, 0.16, 0.1))
    var sc: float = o.get("scale", 1.0)
    root = Node3D.new()
    root.scale = Vector3.ONE * sc
    add_child(root)
    leg_l = Node3D.new()
    leg_r = Node3D.new()
    for pr in [[leg_l, -0.17], [leg_r, 0.17]]:
        var pv: Node3D = pr[0]
        pv.position = Vector3(pr[1], 0.78, 0)
        _b(pv, Vector3(0.26, 0.62, 0.28), Vector3(0, -0.3, 0), pants)
        _b(pv, Vector3(0.3, 0.2, 0.4), Vector3(0, -0.68, 0.05), boots)
        root.add_child(pv)
    torso = Node3D.new()
    torso.position = Vector3(0, 0.78, 0)
    root.add_child(torso)
    _b(torso, Vector3(0.66, 0.72, 0.38), Vector3(0, 0.38, 0), shirt)
    _b(torso, Vector3(0.7, 0.1, 0.42), Vector3(0, 0.06, 0), _m(Color(0.35, 0.22, 0.12)))
    _b(torso, Vector3(0.16, 0.12, 0.05), Vector3(0, 0.06, 0.22), _m(Color(0.85, 0.7, 0.3), 0.3))
    if o.get("robe", false):
        _b(torso, Vector3(0.72, 0.8, 0.44), Vector3(0, -0.3, 0), shirt)
    head = Node3D.new()
    head.position = Vector3(0, 0.78, 0)
    torso.add_child(head)
    _b(head, Vector3(0.56, 0.56, 0.52), Vector3(0, 0.28, 0), skin)
    _b(head, Vector3(0.6, 0.2, 0.56), Vector3(0, 0.5, -0.02), hair)
    _b(head, Vector3(0.6, 0.44, 0.14), Vector3(0, 0.3, -0.24), hair)
    var eye := _m(Color(0.08, 0.08, 0.1), 0.3)
    for sx in [-0.12, 0.12]:
        _b(head, Vector3(0.08, 0.1, 0.03), Vector3(sx, 0.3, 0.265), eye)
    _b(head, Vector3(0.14, 0.03, 0.02), Vector3(0, 0.16, 0.265), _m(Color(0.6, 0.3, 0.3)))
    if o.get("helmet", false):
        _b(head, Vector3(0.64, 0.3, 0.6), Vector3(0, 0.52, 0), _m(Color(0.7, 0.72, 0.76), 0.35))
        _b(head, Vector3(0.08, 0.3, 0.5), Vector3(0, 0.72, 0), _m(Color(0.8, 0.15, 0.15)))
    if o.get("hat", Color(0, 0, 0, 0)).a > 0.0:
        _b(head, Vector3(0.82, 0.08, 0.82), Vector3(0, 0.58, 0), _m(o.hat))
        _b(head, Vector3(0.5, 0.28, 0.5), Vector3(0, 0.74, 0), _m(o.hat))
    arm_l = Node3D.new()
    arm_r = Node3D.new()
    for pr in [[arm_l, -0.43], [arm_r, 0.43]]:
        var pv2: Node3D = pr[0]
        pv2.position = Vector3(pr[1], 0.68, 0)
        _b(pv2, Vector3(0.2, 0.36, 0.24), Vector3(0, -0.16, 0), shirt)
        _b(pv2, Vector3(0.18, 0.3, 0.2), Vector3(0, -0.48, 0), skin)
        torso.add_child(pv2)
    if o.get("sword", false):
        var sw := _b(torso, Vector3(0.08, 1.1, 0.04), Vector3(0.1, 0.4, -0.24), _m(Color(0.82, 0.84, 0.88), 0.3))
        sw.rotation.z = 0.5
        var hilt := _b(torso, Vector3(0.3, 0.06, 0.08), Vector3(-0.15, 0.9, -0.24), _m(Color(0.85, 0.7, 0.3), 0.3))
        hilt.rotation.z = 0.5
    if o.get("cape", Color(0, 0, 0, 0)).a > 0.0:
        var cp := _b(torso, Vector3(0.62, 0.95, 0.04), Vector3(0, 0.25, -0.22), _m(o.cape, 0.8))
        cp.rotation.x = 0.12
        cp.name = "Cape"
    if o.get("spear", false):
        _b(arm_r, Vector3(0.06, 2.4, 0.06), Vector3(0, -0.3, 0.12), _m(Color(0.45, 0.3, 0.16)))
        _b(arm_r, Vector3(0.12, 0.3, 0.04), Vector3(0, 0.95, 0.12), _m(Color(0.82, 0.84, 0.88), 0.3))
    if o.get("staff", false):
        _b(arm_r, Vector3(0.07, 1.9, 0.07), Vector3(0, -0.2, 0.12), _m(Color(0.6, 0.45, 0.2)))
        var gem := _b(arm_r, Vector3(0.18, 0.18, 0.18), Vector3(0, 0.82, 0.12), _m(Color(1.0, 0.85, 0.4), 0.2))
        var gm: StandardMaterial3D = gem.material_override
        gm.emission_enabled = true
        gm.emission = Color(1.0, 0.85, 0.4)
        gm.emission_energy_multiplier = 2.0

func animate(delta: float, speed: float) -> void:
    if speed > 0.1:
        ph += delta * speed * 2.6
        var s := sin(ph)
        leg_l.rotation.x = s * 0.7
        leg_r.rotation.x = -s * 0.7
        arm_l.rotation.x = -s * 0.6
        if arm_r.get_child_count() <= 2:
            arm_r.rotation.x = s * 0.6
        root.position.y = abs(cos(ph)) * 0.06
        torso.rotation.x = 0.06
    else:
        ph = 0.0
        leg_l.rotation.x = lerp(leg_l.rotation.x, 0.0, min(1.0, delta * 10.0))
        leg_r.rotation.x = lerp(leg_r.rotation.x, 0.0, min(1.0, delta * 10.0))
        arm_l.rotation.x = lerp(arm_l.rotation.x, 0.0, min(1.0, delta * 10.0))
        arm_r.rotation.x = lerp(arm_r.rotation.x, 0.0, min(1.0, delta * 10.0))
        root.position.y = sin(Time.get_ticks_msec() / 600.0) * 0.01
        torso.rotation.x = 0.0
        head.rotation.y = sin(Time.get_ticks_msec() / 1700.0 + position.x) * 0.25
