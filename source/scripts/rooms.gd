extends Node3D
## ห้องในร้าน/อาคาร (เดินเข้าประตูแล้วเข้าไปข้างใน เหมือน enterShop ของเกม 2D: js/022-core.js)
## ห้อง IW×IH ช่อง: แถว 0-1 ผนังหลัง · แถว 2 เจ้าของร้านยืน · แถว 3 เคาน์เตอร์ (เดินผ่านไม่ได้) · แถว 4-13 พื้นลูกค้า · แถว 14 ผนังหน้า + ทางออกตรงกลาง
## ห้องสร้างครั้งแรกที่เข้า แล้วเก็บไว้ (อยู่ไกลออกไปทางตะวันออก x ≥ 700 ไม่ทับโลกข้างนอก)

const IW := 26
const IH := 15
const TS := 2.0
const BASE_X := 700.0
const ORDER := ["gear", "potion", "inn", "skill", "store", "guild", "fashion", "bank", "ware", "seal113", "hall"]

## สี/ของตกแต่งตามชนิดร้าน · keeper = โมเดลเจ้าของร้าน
const THEME := {
    "gear": {"floor": Color(0.36, 0.27, 0.19), "wall": Color(0.45, 0.43, 0.42), "kind": "weapons", "keeper": "barbarian"},
    "potion": {"floor": Color(0.42, 0.33, 0.24), "wall": Color(0.48, 0.58, 0.5), "kind": "potions", "keeper": "mage"},
    "inn": {"floor": Color(0.46, 0.32, 0.2), "wall": Color(0.62, 0.5, 0.36), "kind": "inn", "keeper": "rogue"},
    "skill": {"floor": Color(0.3, 0.26, 0.36), "wall": Color(0.38, 0.32, 0.55), "kind": "books", "keeper": "mage"},
    "store": {"floor": Color(0.45, 0.35, 0.24), "wall": Color(0.66, 0.56, 0.42), "kind": "goods", "keeper": "rogue"},
    "guild": {"floor": Color(0.38, 0.3, 0.22), "wall": Color(0.5, 0.42, 0.32), "kind": "guild", "keeper": "hooded"},
    "fashion": {"floor": Color(0.62, 0.5, 0.52), "wall": Color(0.78, 0.6, 0.66), "kind": "fashion", "keeper": "rogue"},
    "bank": {"floor": Color(0.7, 0.68, 0.64), "wall": Color(0.8, 0.77, 0.7), "kind": "bank", "keeper": "knight"},
    "ware": {"floor": Color(0.5, 0.38, 0.26), "wall": Color(0.7, 0.62, 0.5), "kind": "house", "keeper": "rogue"},
    "seal113": {"floor": Color(0.2, 0.18, 0.24), "wall": Color(0.28, 0.24, 0.34), "kind": "seal", "keeper": "mage"},
    "hall": {"floor": Color(0.6, 0.55, 0.5), "wall": Color(0.72, 0.68, 0.62), "kind": "hall", "keeper": "knight"},
}

var town
var built := {}        # id -> Node3D
var keepers := {}      # id -> Node3D (เจ้าของร้าน)
var cur := ""
var talk_pending := false

func setup(t) -> void:
    town = t

func origin(id: String) -> Vector3:
    return Vector3(BASE_X + ORDER.find(id) * 90.0, 0.0, 0.0)

func rw(id: String, x: float, y: float) -> Vector3:
    return origin(id) + Vector3(x * TS, 0.0, y * TS)

func in_room_area(wx: float) -> bool:
    return wx >= BASE_X - 10.0

## ช่องในห้องเดินได้ไหม (ใช้กับ town.blocked ตอนอยู่ในห้อง)
func blocked(wx: float, wz: float) -> bool:
    var o := origin(cur)
    var tx := int(floor((wx - o.x) / TS))
    var ty := int(floor((wz - o.z) / TS))
    if tx < 1 or tx > IW - 2 or ty < 4 or ty > IH - 1:
        return true
    if ty == IH - 1:
        return not (tx == (IW >> 1) - 1 or tx == (IW >> 1))
    return _deco_solid.get(cur, {}).has(Vector2i(tx, ty))

var _deco_solid := {}
var _cam_saved := Vector3(0.0, 14.0, -0.78)

func enter(id: String) -> void:
    if not THEME.has(id) or cur != "":
        return
    if not built.has(id):
        _build(id)
    cur = id
    town.room = id
    built[id].visible = true
    var p = town.player
    p.set_path(PackedVector3Array())
    p.target_mob = null
    # จุดเกิด: กลางห้องค่อนล่าง · ถ้ามีของตกแต่งขวาง เลื่อนลงไปหาช่องว่าง
    var row := IH - 4.5
    while row < IH - 1.6 and blocked(rw(id, IW >> 1, row).x, rw(id, IW >> 1, row).z):
        row += 1.0
    p.position = rw(id, IW >> 1, min(row, IH - 1.6))
    p.heading = PI
    p.body.rotation.y = PI
    # กล้องหันเข้าหาเคาน์เตอร์ · ออกจากร้านแล้วคืนมุมเดิม
    _cam_saved = Vector3(town.cam_yaw, town.cam_dist, town.cam_pitch)
    town.cam_yaw = 0.0
    town.cam_dist = 17.0
    town.cam_pitch = -0.6
    town._update_sky()
    town.talk_target = null
    town.ui_dialog.visible = false
    town.click_marker.visible = false
    var sh: Dictionary = town.shops_by_id.get(id, {})
    var ow: Dictionary = sh.get("owner", {}) if sh.get("owner") is Dictionary else {}
    var greet: Array = ow.get("greet", [])
    var g := ""
    if greet.size() > 0:
        g = town.clean(str(ow.get("name", ""))) + ": " + town.clean(str(greet[randi() % greet.size()])) + "\n"
    town.field.say_msg(g + "เดินไปหน้าเคาน์เตอร์แล้วแตะเจ้าของร้าน หรือกดปุ่มตี · เดินลงทางออกด้านล่างเพื่อออก", 5.0)

func leave() -> void:
    if cur == "":
        return
    var id := cur
    built[id].visible = false
    cur = ""
    town.room = ""
    town.ui_shop.visible = false
    town.ui_dialog.visible = false
    var p = town.player
    p.set_path(PackedVector3Array())
    var door_p := Vector2(22.0, 9.3) if id == "hall" else Vector2.ZERO
    for d in town.doors:
        if d.id == id:
            door_p = d.p
    p.position = town.tw(door_p.x, door_p.y + 1.3)
    p.heading = 0.0
    p.body.rotation.y = 0.0
    town.in_door = id
    town.cam_yaw = _cam_saved.x
    town.cam_dist = _cam_saved.y
    town.cam_pitch = _cam_saved.z
    town._update_sky()
    town.field.say_msg("ออกจาก" + town.clean(str(town.shops_by_id.get(id, {}).get("name", ""))) + "แล้ว")

func near_counter() -> bool:
    if cur == "":
        return false
    var k: Node3D = keepers[cur]
    var p = town.player
    return abs(p.position.x - k.position.x) < 6.0 and p.position.z - k.position.z < 6.5

func interact_if_near() -> void:
    if near_counter():
        interact()
    else:
        town.field.say_msg("เดินไปหน้าเคาน์เตอร์ก่อน")

## คุย/เปิดหน้าร้านตามชนิดอาคาร
func interact() -> void:
    var id := cur
    var sh: Dictionary = town.shops_by_id.get(id, {})
    var k: Node3D = keepers[id]
    k.get_meta("body").action("Interact", 0.8)
    if (sh.get("buy", []) as Array).size() > 0 or (sh.get("sell", []) as Array).size() > 0:
        town.open_shop(id)
    elif id == "bank":
        town.open_bank()
    else:
        var ow: Dictionary = sh.get("owner", {}) if sh.get("owner") is Dictionary else {}
        var lines: Array = ow.get("lines", [])
        if lines.is_empty():
            lines = ow.get("greet", [])
        var extra := {"fashion": " (ร้านแฟชั่นใช้เหรียญแฟชั่น — เร็ว ๆ นี้)", "seal113": " (แท่นผนึกอสูร — เร็ว ๆ นี้)", "hall": " (ภารกิจของพระราชา — เร็ว ๆ นี้)", "ware": ""}
        town.say(str(ow.get("name", "")), (str(lines[randi() % lines.size()]) if lines.size() > 0 else "...") + str(extra.get(id, "")))

func keeper_at(screen: Vector2) -> bool:
    if cur == "":
        return false
    var k: Node3D = keepers[cur]
    var sp: Vector2 = town.cam.unproject_position(k.global_position + Vector3(0, 1.2, 0))
    return sp.distance_to(screen) < 70.0

## แตะเจ้าของร้าน: เดินไปหน้าเคาน์เตอร์แล้วเปิดเอง
func walk_to_counter() -> void:
    var k: Node3D = keepers[cur]
    town.player.set_path(PackedVector3Array([Vector3(k.position.x, 0, k.position.z + 4.6)]))
    talk_pending = true

func _process(_delta: float) -> void:
    if cur == "":
        return
    var p = town.player
    var o := origin(cur)
    if p.position.z > o.z + (IH - 1) * TS - 0.2:
        leave()
        return
    if talk_pending and near_counter() and not p.has_path():
        talk_pending = false
        interact()
    town.prompt.text = "แตะเจ้าของร้าน / ปุ่มตี = คุย · ทางออกด้านล่าง" if near_counter() else ""

# ---------- สร้างห้อง ----------
func _build(id: String) -> void:
    var th: Dictionary = THEME[id]
    var root := Node3D.new()
    add_child(root)
    built[id] = root
    _deco_solid[id] = {}
    var o := origin(id)
    var W := IW * TS
    var H := IH * TS
    var wall: Material = town.M(th.wall, 0.9)
    var trim: Material = town.M(Color(th.wall).darkened(0.35), 0.9)
    var floor_m: Material = town.M(th.floor, 0.85)
    # พื้นดำรอบห้อง + พื้นห้อง (ลายไม้เป็นแถบ)
    town.box(root, Vector3(W + 40, 0.1, H + 40), o + Vector3(W / 2, -0.12, H / 2), town.M(Color(0.04, 0.04, 0.06), 1.0))
    town.box(root, Vector3(W, 0.1, H), o + Vector3(W / 2, -0.05, H / 2), floor_m)
    for i in IH:
        if i % 2 == 0:
            town.box(root, Vector3(W - 0.2, 0.02, 0.06), o + Vector3(W / 2, 0.01, i * TS), town.M(Color(th.floor).darkened(0.25), 0.9))
    # ผนังหลังสูง · ข้างสูง · หน้าเตี้ย (กล้องมองเห็นข้างใน)
    town.box(root, Vector3(W, 6.0, 1.0), o + Vector3(W / 2, 3.0, 3.0), wall)
    town.box(root, Vector3(W, 0.4, 1.1), o + Vector3(W / 2, 6.0, 3.0), trim)
    town.box(root, Vector3(1.0, 5.0, H), o + Vector3(0.5, 2.5, H / 2), wall)
    town.box(root, Vector3(1.0, 5.0, H), o + Vector3(W - 0.5, 2.5, H / 2), wall)
    var gx := (IW >> 1) - 1
    town.box(root, Vector3(gx * TS - 0.0, 1.0, 0.6), o + Vector3(gx * TS / 2.0, 0.5, H - 0.3), wall)
    town.box(root, Vector3(gx * TS, 1.0, 0.6), o + Vector3(W - gx * TS / 2.0, 0.5, H - 0.3), wall)
    town.box(root, Vector3(4.0, 0.03, 1.6), o + Vector3(W / 2, 0.03, H - 1.4), town.M(Color(0.55, 0.15, 0.15), 0.9))
    town.label3d("ทางออก", o + Vector3(W / 2, 1.6, H - 0.4), 30)
    # หน้าต่างผนังหลัง
    for x in [4.0, W - 4.0]:
        town.box(root, Vector3(3.0, 2.2, 0.2), o + Vector3(x, 3.6, 3.55), town.M(Color(0.55, 0.75, 0.95), 0.2, 0.6))
        town.box(root, Vector3(3.3, 0.25, 0.3), o + Vector3(x, 2.4, 3.6), trim)
    # เคาน์เตอร์ทั้งแถว 3
    var cz := 3.5 * TS
    town.box(root, Vector3(W - 2.0, 1.15, 1.6), o + Vector3(W / 2, 0.575, cz), town.M(Color(0.42, 0.28, 0.16), 0.8))
    town.box(root, Vector3(W - 1.8, 0.14, 1.9), o + Vector3(W / 2, 1.2, cz), town.M(Color(0.6, 0.42, 0.24), 0.6))
    # ไฟในห้อง
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.85, 0.65)
    l.omni_range = 34.0
    l.light_energy = 1.4
    l.position = o + Vector3(W / 2, 7.0, H / 2)
    root.add_child(l)
    for x in [6.0, W - 6.0]:
        town.box(root, Vector3(0.4, 0.5, 0.4), o + Vector3(x, 4.4, 3.8), town.M(Color(1.0, 0.75, 0.4), 0.3, 2.5))
    _decor(id, root, o, str(th.kind))
    # เจ้าของร้าน
    var sh: Dictionary = town.shops_by_id.get(id, {})
    var ow: Dictionary = sh.get("owner", {}) if sh.get("owner") is Dictionary else {}
    var k := Node3D.new()
    k.position = rw(id, IW >> 1, 2.5)
    root.add_child(k)
    var body := Node3D.new()
    body.set_script(load("res://scripts/model.gd"))
    k.add_child(body)
    var tint := Color.html(str(ow.c)) if ow.get("c") else Color(0.6, 0.5, 0.4)
    var o2 := {"model": th.keeper, "tint": tint, "idle": "Idle"}
    if th.keeper == "knight":
        o2 = {"model": "knight", "keep": ["Knight_Cape"] if id == "hall" else [], "idle": "Idle"}
    body.build(o2)
    k.set_meta("body", body)
    var nl := Label3D.new()
    nl.text = town.clean(str(ow.get("name", "")))
    nl.font = town.font_b
    nl.font_size = 34
    nl.pixel_size = 0.011
    nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    nl.outline_size = 9
    nl.modulate = Color(1, 0.95, 0.7)
    nl.position = Vector3(0, 2.9, 0)
    k.add_child(nl)
    keepers[id] = k
    town.label3d(town.clean(str(sh.get("name", id))), o + Vector3(W / 2, 6.9, 3.2), 44)

func _solid(id: String, tx: int, ty: int) -> void:
    _deco_solid[id][Vector2i(tx, ty)] = true

func _decor(id: String, root: Node3D, o: Vector3, kind: String) -> void:
    var wood: Material = town.M(Color(0.45, 0.3, 0.17), 0.85)
    var dark: Material = town.M(Color(0.3, 0.2, 0.12), 0.9)
    var metal: Material = town.M(Color(0.75, 0.78, 0.82), 0.3)
    var bz := 3.7  # หน้าผนังหลัง
    match kind:
        "weapons":
            for i in 7:
                var x := 3.0 + i * 3.0
                town.box(root, Vector3(0.18, 2.4, 0.08), o + Vector3(x, 3.4, bz), metal, Vector3(0, 0, 0.15 * (i % 2 * 2 - 1)))
                town.box(root, Vector3(0.9, 0.12, 0.12), o + Vector3(x, 2.3, bz), town.M(Color(0.85, 0.7, 0.3), 0.4))
            for x in [8.0, 44.0]:
                town.box(root, Vector3(1.6, 0.9, 1.0), o + Vector3(x, 0.45, 18.0), town.M(Color(0.25, 0.26, 0.3), 0.5))
                _solid(id, int(x / TS), 9)
            town.cyl(root, 0.6, 0.6, 1.8, o + Vector3(46.0, 0.9, 12.0), dark, 10)
        "potions":
            for row in 3:
                town.box(root, Vector3(18.0, 0.15, 0.8), o + Vector3(26.0, 2.0 + row * 1.2, bz), wood)
                for i in 14:
                    var c := Color.from_hsv(randf(), 0.7, 0.9)
                    town.cyl(root, 0.18, 0.22, 0.6, o + Vector3(18.0 + i * 1.2, 2.4 + row * 1.2, bz), town.M(c, 0.15, 0.6), 8)
            town.cyl(root, 1.1, 0.9, 1.0, o + Vector3(8.0, 0.5, 18.0), town.M(Color(0.2, 0.2, 0.22), 0.4), 14)
            town.cyl(root, 0.95, 0.95, 0.05, o + Vector3(8.0, 1.02, 18.0), town.M(Color(0.3, 0.9, 0.4), 0.2, 1.5), 14)
            _solid(id, 4, 9)
        "inn":
            for t in [[10.0, 14.0], [26.0, 18.0], [42.0, 14.0]]:
                town.cyl(root, 1.4, 1.4, 0.15, o + Vector3(t[0], 1.0, t[1]), wood, 14)
                town.cyl(root, 0.2, 0.25, 1.0, o + Vector3(t[0], 0.5, t[1]), dark, 8)
                for a in 4:
                    var off := Vector3(cos(a * PI / 2.0), 0, sin(a * PI / 2.0)) * 2.0
                    town.cyl(root, 0.45, 0.45, 0.6, o + Vector3(t[0], 0.3, t[1]) + off, wood, 8)
                _solid(id, int(t[0] / TS), int(t[1] / TS))
            for x in [4.0, 6.0, 46.0, 48.0]:
                town.cyl(root, 0.7, 0.8, 1.6, o + Vector3(x, 0.8, 9.0), town.M(Color(0.5, 0.32, 0.16), 0.8), 10)
            town.box(root, Vector3(4.0, 3.0, 0.8), o + Vector3(26.0, 1.5, bz), town.M(Color(0.35, 0.33, 0.32), 0.95))
            town.box(root, Vector3(2.4, 1.4, 0.3), o + Vector3(26.0, 1.0, bz + 0.45), town.M(Color(1.0, 0.5, 0.15), 0.3, 3.0))
        "books":
            for x in [6.0, 14.0, 38.0, 46.0]:
                town.box(root, Vector3(5.0, 4.0, 0.8), o + Vector3(x, 2.0, bz), wood)
                for r in 3:
                    for i in 8:
                        town.box(root, Vector3(0.45, 0.8, 0.5), o + Vector3(x - 2.0 + i * 0.55, 0.9 + r * 1.25, bz + 0.2), town.M(Color.from_hsv(randf(), 0.5, 0.6), 0.8))
            for x in [12.0, 40.0]:
                town.cyl(root, 0.3, 0.4, 1.0, o + Vector3(x, 0.5, 16.0), dark, 8)
                var orb := MeshInstance3D.new()
                var sm := SphereMesh.new()
                sm.radius = 0.5
                sm.height = 1.0
                orb.mesh = sm
                orb.material_override = town.M(Color(0.6, 0.75, 1.0), 0.1, 2.0)
                orb.position = o + Vector3(x, 1.5, 16.0)
                root.add_child(orb)
                _solid(id, int(x / TS), 8)
        "goods":
            for i in 6:
                var x := 4.0 + i * 2.2
                town.box(root, Vector3(1.6, 1.4, 1.6), o + Vector3(x, 0.7, 10.0 + (i % 2) * 1.8), town.M(Color(0.62, 0.45, 0.25), 0.85))
            for x in [40.0, 42.5, 45.0]:
                town.cyl(root, 0.7, 0.8, 1.6, o + Vector3(x, 0.8, 10.0), town.M(Color(0.5, 0.32, 0.16), 0.8), 10)
            for x in range(2, 7):
                _solid(id, x, 5)
            for x in range(20, 23):
                _solid(id, x, 5)
            town.box(root, Vector3(22.0, 0.15, 0.8), o + Vector3(26.0, 2.6, bz), wood)
            for i in 12:
                town.box(root, Vector3(0.9, 0.7, 0.7), o + Vector3(16.0 + i * 1.8, 3.05, bz), town.M(Color.from_hsv(randf_range(0.05, 0.15), 0.6, 0.7), 0.8))
        "guild":
            town.box(root, Vector3(8.0, 4.0, 0.3), o + Vector3(26.0, 3.2, bz), wood)
            for i in 10:
                town.box(root, Vector3(1.2, 1.4, 0.05), o + Vector3(23.0 + (i % 5) * 1.5, 2.4 + int(i / 5) * 1.7, bz + 0.2), town.M(Color(0.92, 0.88, 0.75), 0.9))
            for x in [8.0, 44.0]:
                town.box(root, Vector3(1.6, 4.5, 0.1), o + Vector3(x, 3.6, bz), town.M(Color(0.65, 0.15, 0.15), 0.9))
            town.box(root, Vector3(6.0, 1.0, 2.5), o + Vector3(26.0, 0.9, 18.0), wood)
            for x in range(11, 15):
                _solid(id, x, 9)
        "fashion":
            for x in [8.0, 16.0, 36.0, 44.0]:
                town.cyl(root, 0.15, 0.4, 1.4, o + Vector3(x, 0.7, 16.0), dark, 8)
                town.cyl(root, 0.55, 0.4, 1.6, o + Vector3(x, 2.2, 16.0), town.M(Color.from_hsv(randf(), 0.45, 0.85), 0.7), 12)
                _solid(id, int(x / TS), 8)
            for x in [6.0, 46.0]:
                town.box(root, Vector3(3.0, 4.0, 0.15), o + Vector3(x, 2.6, bz), town.M(Color(0.85, 0.9, 0.95), 0.05, 0.3))
        "bank":
            town.cyl(root, 2.0, 2.0, 0.6, o + Vector3(46.0, 3.0, bz), town.M(Color(0.55, 0.55, 0.6), 0.3), 20).rotation.x = PI / 2.0
            for i in 5:
                town.cyl(root, 0.8, 0.9, 0.5 + i * 0.1, o + Vector3(6.0 + i * 1.6, 0.25, 9.0), town.M(Color(1.0, 0.82, 0.3), 0.3, 0.4), 10)
            for x in [4.0, 48.0]:
                town.cyl(root, 0.6, 0.6, 5.5, o + Vector3(x, 2.75, 20.0), town.M(Color(0.85, 0.83, 0.78), 0.6), 12)
                _solid(id, int(x / TS), 10)
        "house":
            for x in [8.0, 16.0, 36.0, 44.0]:
                town.box(root, Vector3(3.0, 0.8, 5.0), o + Vector3(x, 0.4, 11.0), wood)
                town.box(root, Vector3(2.8, 0.3, 3.6), o + Vector3(x, 0.95, 11.6), town.M(Color(0.75, 0.82, 0.95), 0.9))
                town.box(root, Vector3(2.4, 0.3, 0.9), o + Vector3(x, 1.05, 9.4), town.M(Color(1, 1, 1), 0.9))
                for y in [5, 6]:
                    _solid(id, int(x / TS), y)
            town.box(root, Vector3(10.0, 0.03, 6.0), o + Vector3(26.0, 0.03, 18.0), town.M(Color(0.6, 0.2, 0.25), 0.9))
        "seal":
            town.cyl(root, 3.0, 3.4, 0.6, o + Vector3(26.0, 0.3, 18.0), town.M(Color(0.25, 0.22, 0.3), 0.8), 20)
            town.cyl(root, 2.4, 2.4, 0.08, o + Vector3(26.0, 0.65, 18.0), town.M(Color(0.65, 0.3, 1.0), 0.2, 2.5), 20)
            for i in 6:
                var a := i * TAU / 6.0
                town.box(root, Vector3(0.6, 2.4, 0.6), o + Vector3(26.0 + cos(a) * 4.0, 1.2, 18.0 + sin(a) * 4.0), town.M(Color(0.3, 0.27, 0.36), 0.8))
            for x in range(11, 15):
                for y in range(8, 11):
                    _solid(id, x, y)
        "hall":
            town.box(root, Vector3(4.0, 0.04, 22.0), o + Vector3(26.0, 0.04, 18.0), town.M(Color(0.7, 0.12, 0.12), 0.9))
            town.box(root, Vector3(3.0, 3.5, 1.2), o + Vector3(26.0, 1.75, bz + 0.3), town.M(Color(0.85, 0.68, 0.25), 0.4, 0.3))
            for x in [8.0, 18.0, 34.0, 44.0]:
                town.cyl(root, 0.8, 0.8, 6.0, o + Vector3(x, 3.0, 16.0), town.M(Color(0.9, 0.88, 0.82), 0.6), 14)
                _solid(id, int(x / TS), 8)
