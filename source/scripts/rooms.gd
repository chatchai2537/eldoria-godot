extends Node3D
## ห้องในร้าน/อาคาร (เดินเข้าประตูแล้วเข้าไปข้างใน เหมือน enterShop ของเกม 2D: js/022-core.js)
## ห้อง IW×IH ช่อง: แถว 0-1 ผนังหลัง · แถว 2 เจ้าของร้านยืน · แถว 3 เคาน์เตอร์ (เดินผ่านไม่ได้) · แถว 4-13 พื้นลูกค้า · แถว 14 ผนังหน้า + ทางออกตรงกลาง
## ห้องสร้างครั้งแรกที่เข้า แล้วเก็บไว้ (อยู่ไกลออกไปทางตะวันออก x ≥ 700 ไม่ทับโลกข้างนอก)

const IW := 26
const IH := 15
## ขนาดเท่าเกม 2D: ตัวละครกว้างราว 1 ช่อง → ห้องย่อแนวนอนด้วย S (ความสูงคงเดิม)
## ตัวเลขใน _build/_decor เขียนเป็นหน่วยก่อนย่อ (ช่องละ TS0) แล้ว root ย่อ x/z ด้วย S
const S := 0.55
const TS0 := 2.0
const TS := TS0 * S
const WALL_H := 7.0
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
    if town.get("sfx") != null: town.sfx.play("door")
    built[id].visible = true
    var p = town.player
    p.set_path(PackedVector3Array())
    p.target_mob = null
    # จุดเกิด: กลางห้องค่อนล่าง · ถ้ามีของตกแต่งขวาง เลื่อนลงไปหาช่องว่าง
    var row := 7.5
    while row < IH - 1.6 and blocked(rw(id, IW >> 1, row).x, rw(id, IW >> 1, row).z):
        row += 1.0
    p.position = rw(id, IW >> 1, min(row, IH - 1.6))
    p.heading = PI
    p.body.rotation.y = PI
    # กล้องหันเข้าหาเคาน์เตอร์ · ออกจากร้านแล้วคืนมุมเดิม
    _cam_saved = Vector3(town.cam_yaw, town.cam_dist, town.cam_pitch)
    town.cam_yaw = 0.0
    town.cam_dist = 9.0
    town.cam_pitch = -0.4
    town._update_sky()
    town.talk_target = null
    town.ui_dialog.visible = false
    town.click_marker.visible = false
    var sh: Dictionary = town.shops_by_id.get(id, {})
    var ow: Dictionary = sh.get("owner", {}) if sh.get("owner") is Dictionary else {}
    var greet: Array = ow.get("greet", [])
    # แบบเกม 2D: เจ้าของร้านโบกมือ + คำทักลอยเหนือหัว 3.4 วิ · ข้อความระบบบอกวิธีคุย
    keepers[id].get_meta("body").action("Interact", 0.8)
    if greet.size() > 0:
        bubble(str(greet[randi() % greet.size()]), 3.4)
    town.field.say_msg(town.clean(str(sh.get("name", id))) + " — เดินไปหน้าเคาน์เตอร์แล้วกดปุ่มตี คุยกับ" + town.clean(str(ow.get("name", ""))) + " · เดินชนทางออกด้านล่างเพื่อออก", 4.0)

## ออกจากห้องเงียบ ๆ (ไม่ย้ายตัวละคร) — ใช้ตอนวาปจากห้องไปที่อื่น เช่น เข้าลานบอสตำนาน
func exit_silent() -> void:
    if cur == "":
        return
    built[cur].visible = false
    cur = ""
    town.room = ""
    town.ui_dialog.visible = false
    town.cam_yaw = _cam_saved.x
    town.cam_dist = _cam_saved.y
    town.cam_pitch = _cam_saved.z

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

## กล้องอยู่ในห้องเสมอ (ไม่ทะลุผนัง/เพดาน)
func clamp_cam(pos: Vector3) -> Vector3:
    var o := origin(cur)
    pos.x = clamp(pos.x, o.x + 1.0, o.x + IW * TS - 1.0)
    pos.z = clamp(pos.z, o.z + 4.0 * TS, o.z + IH * TS - 0.7)
    pos.y = min(pos.y, WALL_H - 0.9)
    return pos

func near_counter() -> bool:
    if cur == "":
        return false
    var k: Node3D = keepers[cur]
    var p = town.player
    return abs(p.position.x - k.position.x) < 3.6 and p.position.z - k.position.z < 3.6

## สถานีคราฟในร้าน: [ชนิด, ตำแหน่งหน่วยก่อนย่อ (x, z)] — ยืนใกล้แล้วกดตี/แตะ = เปิด
const STATIONS := {"gear": [["furnace", Vector2(8.0, 18.0)], ["anvil", Vector2(44.0, 18.0)]], "potion": [["cauldron", Vector2(8.0, 18.0)]], "seal113": [["altar", Vector2(26.0, 18.0)]]}
const STN_NAMES := {"furnace": "เตาหลอม", "anvil": "ทั่งตีเหล็ก (คราฟ / ตีบวก)", "cauldron": "หม้อปรุงยา", "altar": "แท่นผนึกอสูร (บอสตำนาน)"}
var stn_pending := ""

func station_pos(id: String, i: int) -> Vector3:
    var v: Vector2 = STATIONS[id][i][1]
    return origin(id) + Vector3(v.x * S, 0, v.y * S)

func near_station() -> String:
    if cur == "" or not STATIONS.has(cur):
        return ""
    var p = town.player
    for i in STATIONS[cur].size():
        var w := station_pos(cur, i)
        if Vector2(p.position.x - w.x, p.position.z - w.z).length() < 2.5:
            return str(STATIONS[cur][i][0])
    return ""

func station_at(screen: Vector2) -> int:
    if cur == "" or not STATIONS.has(cur):
        return -1
    for i in STATIONS[cur].size():
        var sp: Vector2 = town.cam.unproject_position(station_pos(cur, i) + Vector3(0, 1.0, 0))
        if sp.distance_to(screen) < 70.0:
            return i
    return -1

func walk_to_station(i: int) -> void:
    var w := station_pos(cur, i)
    var p = town.player
    var side := -1.0 if p.position.x < w.x else 1.0
    var dest := w + Vector3(side * 1.6, 0, 0)
    if town.blocked(dest.x, dest.z):
        dest = w + Vector3(0, 0, 1.7)
    p.set_path(PackedVector3Array([dest]))
    stn_pending = str(STATIONS[cur][i][0])

func interact_if_near() -> void:
    var st := near_station()
    if st == "altar":
        town.legend.open()
        return
    if st != "":
        town.craft.open(st)
        return
    if near_counter():
        interact()
    else:
        town.field.say_msg("เดินไปหน้าเคาน์เตอร์ก่อน")

## คุย/เปิดหน้าร้าน แบบ shopAct ของเกม 2D: เจ้าของโบกมือ + พูดประโยคถัดไป (วน) + เปิดหน้าร้าน
var line_i := {}

func interact() -> void:
    var id := cur
    var sh: Dictionary = town.shops_by_id.get(id, {})
    var k: Node3D = keepers[id]
    k.get_meta("body").action("Interact", 0.8)
    var ow: Dictionary = sh.get("owner", {}) if sh.get("owner") is Dictionary else {}
    var lines: Array = ow.get("lines", [])
    if lines.is_empty():
        lines = ow.get("greet", [])
    if lines.size() > 0:
        var i: int = line_i.get(id, 0)
        line_i[id] = i + 1
        bubble(str(lines[i % lines.size()]), 3.2)
    if id == "hall":
        town.story.king_talk()
    elif id == "guild":
        town.guild.open()
    elif id == "bank":
        town.open_bank()
    elif id == "seal113":
        town.legend.open()
    elif (sh.get("buy", []) as Array).size() > 0 or (sh.get("sell", []) as Array).size() > 0:
        town.open_shop(id)
    else:
        var extra := {"fashion": "ร้านแฟชั่นใช้เหรียญแฟชั่น — เร็ว ๆ นี้", "hall": "ภารกิจของพระราชา — เร็ว ๆ นี้"}
        if extra.has(id):
            town.field.say_msg(str(extra[id]))

## คำพูดลอยเหนือหัวเจ้าของร้าน (แทนกล่องข้อความ)
func bubble(text: String, sec: float = 2.2) -> void:
    if cur == "":
        return
    var k: Node3D = keepers[cur]
    var b: Label3D = k.get_meta("bub")
    b.text = town.clean(text)
    b.visible = true
    k.set_meta("bub_t", sec)

func bubble_text() -> String:
    if cur == "":
        return ""
    var b: Label3D = keepers[cur].get_meta("bub")
    return b.text if b.visible else ""

func keeper_at(screen: Vector2) -> bool:
    if cur == "":
        return false
    var k: Node3D = keepers[cur]
    var sp: Vector2 = town.cam.unproject_position(k.global_position + Vector3(0, 1.2, 0))
    return sp.distance_to(screen) < 70.0

## แตะเจ้าของร้าน: เดินไปหน้าเคาน์เตอร์แล้วเปิดเอง
func walk_to_counter() -> void:
    var k: Node3D = keepers[cur]
    town.player.set_path(PackedVector3Array([Vector3(k.position.x, 0, k.position.z + 2.3)]))
    talk_pending = true

func _process(_delta: float) -> void:
    if cur == "":
        return
    var p = town.player
    var o := origin(cur)
    if p.position.z > o.z + (IH - 1) * TS - 0.2:
        leave()
        return
    var k: Node3D = keepers[cur]
    if k.get_meta("bub_t", 0.0) > 0.0:
        k.set_meta("bub_t", k.get_meta("bub_t") - _delta)
        if k.get_meta("bub_t") <= 0.0:
            k.get_meta("bub").visible = false
    if talk_pending and near_counter() and not p.has_path():
        talk_pending = false
        interact()
    if stn_pending != "" and not p.has_path():
        if near_station() == stn_pending:
            if stn_pending == "altar":
                town.legend.open()
            else:
                town.craft.open(stn_pending)
        stn_pending = ""
    var st := near_station()
    if town.ui_shop.visible:
        town.prompt.text = ""
    elif st != "":
        town.prompt.text = "กดตี / แตะ = ใช้" + str(STN_NAMES[st])
    else:
        town.prompt.text = "กดตี / แตะเจ้าของร้าน = คุย" if near_counter() else ""

# ---------- สร้างห้อง ----------
func _build(id: String) -> void:
    var th: Dictionary = THEME[id]
    var top := Node3D.new()
    add_child(top)
    built[id] = top
    _top = top
    var root := Node3D.new()
    top.add_child(root)
    _deco_solid[id] = {}
    var o := origin(id)
    root.transform = Transform3D(Basis.from_scale(Vector3(S, 1.0, S)), Vector3(o.x * (1.0 - S), 0.0, o.z * (1.0 - S)))
    _o = o
    var W := IW * TS0
    var H := IH * TS0
    var wall: Material = town.M(th.wall, 0.9)
    var trim: Material = town.M(Color(th.wall).darkened(0.35), 0.9)
    var floor_m: Material = town.M(th.floor, 0.85)
    # พื้นดำรอบห้อง + พื้นห้อง (ลายไม้เป็นแถบ)
    town.box(root, Vector3(W + 40, 0.1, H + 40), o + Vector3(W / 2, -0.12, H / 2), town.M(Color(0.04, 0.04, 0.06), 1.0))
    town.box(root, Vector3(W, 0.1, H), o + Vector3(W / 2, -0.05, H / 2), floor_m)
    for i in IH:
        if i % 2 == 0:
            town.box(root, Vector3(W - 0.2, 0.02, 0.06), o + Vector3(W / 2, 0.01, i * TS0), town.M(Color(th.floor).darkened(0.25), 0.9))
    # ห้องปิดทึบแบบ 3D: ผนัง 3 ด้าน + ผนังหน้ามีประตู + เพดานคาน + โคมแขวน
    # กล้องอยู่ในห้องเสมอ (clamp_cam) จึงไม่เห็นที่ว่างข้างนอก
    var WH := WALL_H
    var D := H - 2.5
    var zc := 2.5 + D / 2.0
    var lower: Material = town.M(Color(th.wall).darkened(0.25), 0.9)
    town.box(root, Vector3(W, WH, 1.0), o + Vector3(W / 2, WH / 2, 3.0), wall)
    town.box(root, Vector3(1.0, WH, D), o + Vector3(0.5, WH / 2, zc), wall)
    town.box(root, Vector3(1.0, WH, D), o + Vector3(W - 0.5, WH / 2, zc), wall)
    # ผนังล่างสีเข้ม + บัวพื้น/บัวบน
    town.box(root, Vector3(W - 2.0, 1.3, 0.15), o + Vector3(W / 2, 0.65, 3.55), lower)
    town.box(root, Vector3(W - 2.0, 0.15, 0.25), o + Vector3(W / 2, 1.35, 3.6), trim)
    for sx in [1.08, W - 1.08]:
        town.box(root, Vector3(0.15, 1.3, D - 1.0), o + Vector3(sx, 0.65, zc), lower)
        town.box(root, Vector3(0.25, 0.15, D - 1.0), o + Vector3(sx, 1.35, zc), trim)
    # เสาไม้ตามผนังข้าง
    for zz in [6.0, 14.0, 22.0]:
        for sx in [1.2, W - 1.2]:
            town.box(root, Vector3(0.5, WH, 0.5), o + Vector3(sx, WH / 2, zz), trim)
    # ผนังหน้า: ซ้าย/ขวาของประตู + คานบนประตู (ประตูกว้าง 2 ช่องกลางห้อง)
    var dw := 4.0
    var dh := 3.4
    var side := (W - dw) / 2.0
    town.box(root, Vector3(side, WH, 0.8), o + Vector3(side / 2.0, WH / 2, H - 0.4), wall)
    town.box(root, Vector3(side, WH, 0.8), o + Vector3(W - side / 2.0, WH / 2, H - 0.4), wall)
    town.box(root, Vector3(dw, WH - dh, 0.8), o + Vector3(W / 2, dh + (WH - dh) / 2.0, H - 0.4), wall)
    for dx in [-dw / 2.0, dw / 2.0]:
        town.box(root, Vector3(0.35, dh + 0.3, 0.95), o + Vector3(W / 2 + dx, (dh + 0.3) / 2.0, H - 0.4), trim)
    town.box(root, Vector3(dw + 0.7, 0.35, 0.95), o + Vector3(W / 2, dh + 0.15, H - 0.4), trim)
    # แสงข้างนอกที่ช่องประตู
    town.box(root, Vector3(dw, dh, 0.05), o + Vector3(W / 2, dh / 2.0, H + 0.2), town.M(Color(1.0, 0.93, 0.75), 0.5, 1.6))
    town.box(root, Vector3(4.0, 0.03, 1.6), o + Vector3(W / 2, 0.03, H - 1.4), town.M(Color(0.55, 0.15, 0.15), 0.9))
    _lab("ทางออก", o + Vector3(W / 2, dh + 0.9, H - 1.0), 30)
    # เพดาน + คาน
    town.box(root, Vector3(W, 0.3, D), o + Vector3(W / 2, WH + 0.15, zc), town.M(Color(0.3, 0.21, 0.14), 0.95))
    for i in range(3, IH, 3):
        town.box(root, Vector3(W, 0.5, 0.6), o + Vector3(W / 2, WH - 0.25, i * TS0), town.M(Color(0.36, 0.24, 0.14), 0.9))
    town.box(root, Vector3(0.6, 0.5, D), o + Vector3(W / 2, WH - 0.3, zc), town.M(Color(0.36, 0.24, 0.14), 0.9))
    # โคมแขวน
    for lx in [W * 0.28, W * 0.72]:
        for lz in [12.0, 22.0]:
            town.box(root, Vector3(0.06, 1.4, 0.06), o + Vector3(lx, WH - 0.7, lz), town.M(Color(0.2, 0.2, 0.2), 0.5))
            town.box(root, Vector3(0.7, 0.8, 0.7), o + Vector3(lx, WH - 1.75, lz), town.M(Color(1.0, 0.78, 0.4), 0.3, 2.2))
            town.box(root, Vector3(0.9, 0.15, 0.9), o + Vector3(lx, WH - 1.3, lz), town.M(Color(0.2, 0.15, 0.1), 0.6))
    # หน้าต่างผนังหลัง
    for x in [4.0, W - 4.0]:
        town.box(root, Vector3(3.0, 2.2, 0.2), o + Vector3(x, 3.6, 3.55), town.M(Color(0.55, 0.75, 0.95), 0.2, 0.6))
        town.box(root, Vector3(3.3, 0.25, 0.3), o + Vector3(x, 2.4, 3.6), trim)
    # เคาน์เตอร์ทั้งแถว 3
    var cz := 3.5 * TS0
    town.box(root, Vector3(W - 2.0, 0.9, 1.6), o + Vector3(W / 2, 0.45, cz), town.M(Color(0.42, 0.28, 0.16), 0.8))
    town.box(root, Vector3(W - 1.8, 0.12, 1.9), o + Vector3(W / 2, 0.95, cz), town.M(Color(0.6, 0.42, 0.24), 0.6))
    # ไฟในห้อง
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.85, 0.65)
    l.omni_range = 24.0
    l.light_energy = 1.4
    l.position = o + Vector3(W / 2 * S, WH - 1.5, H / 2 * S)
    top.add_child(l)
    for x in [6.0, W - 6.0]:
        town.box(root, Vector3(0.4, 0.5, 0.4), o + Vector3(x, 4.4, 3.8), town.M(Color(1.0, 0.75, 0.4), 0.3, 2.5))
    _decor(id, root, o, str(th.kind))
    # เจ้าของร้าน
    var sh: Dictionary = town.shops_by_id.get(id, {})
    var ow: Dictionary = sh.get("owner", {}) if sh.get("owner") is Dictionary else {}
    var k := Node3D.new()
    k.position = rw(id, IW >> 1, 2.5)
    top.add_child(k)
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
    var bub := Label3D.new()
    bub.font = town.font_b
    bub.font_size = 38
    bub.pixel_size = 0.009
    bub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    bub.outline_size = 10
    bub.outline_modulate = Color(0.1, 0.07, 0.04, 0.95)
    bub.modulate = Color(1, 1, 1)
    bub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bub.width = 520.0
    bub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    bub.no_depth_test = true
    bub.render_priority = 5
    bub.position = Vector3(0, 3.55, 0)
    bub.visible = false
    k.add_child(bub)
    k.set_meta("bub", bub)
    k.set_meta("bub_t", 0.0)
    keepers[id] = k
    _lab(town.clean(str(sh.get("name", id))), o + Vector3(W / 2, 5.4, 3.8), 40)

var _top: Node3D
var _o := Vector3.ZERO

## ป้ายลอย: ตำแหน่งเป็นหน่วยก่อนย่อ → แปลงเป็นตำแหน่งจริงแล้วใส่ในห้อง (ซ่อนพร้อมห้อง)
func _lab(text: String, local: Vector3, size: int) -> void:
    var l: Label3D = town.label3d(text, _o + Vector3((local.x - _o.x) * S, local.y, (local.z - _o.z) * S), size)
    l.reparent(_top)

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
            # เตาหลอม (ซ้าย) · ทั่งตีเหล็ก (ขวา) — สถานีคราฟ (STATIONS)
            var stone_m: Material = town.M(Color(0.42, 0.4, 0.38), 0.95)
            town.box(root, Vector3(3.6, 2.6, 2.6), o + Vector3(8.0, 1.3, 18.0), stone_m)
            town.box(root, Vector3(2.0, 1.1, 0.2), o + Vector3(8.0, 0.9, 19.32), town.M(Color(1.0, 0.45, 0.1), 0.3, 3.0))
            town.box(root, Vector3(1.0, 2.2, 1.0), o + Vector3(8.0, 3.7, 17.6), stone_m)
            town.box(root, Vector3(4.0, 0.25, 3.0), o + Vector3(8.0, 2.65, 18.0), town.M(Color(0.3, 0.28, 0.27), 0.9))
            town.cyl(root, 0.9, 1.0, 1.0, o + Vector3(44.0, 0.5, 18.0), wood, 10)
            town.box(root, Vector3(2.4, 0.55, 1.1), o + Vector3(44.0, 1.27, 18.0), town.M(Color(0.22, 0.23, 0.26), 0.35))
            town.box(root, Vector3(1.2, 0.35, 0.7), o + Vector3(44.0, 0.85, 18.0), town.M(Color(0.22, 0.23, 0.26), 0.35))
            town.box(root, Vector3(0.12, 0.12, 0.9), o + Vector3(44.6, 1.65, 18.0), metal, Vector3(0, 0, 0.5))
            _solid(id, 4, 9)
            _solid(id, 22, 9)
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
                _solid(id, int(t[0] / TS0), int(t[1] / TS0))
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
                _solid(id, int(x / TS0), 8)
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
                _solid(id, int(x / TS0), 8)
            for x in [6.0, 46.0]:
                town.box(root, Vector3(3.0, 4.0, 0.15), o + Vector3(x, 2.6, bz), town.M(Color(0.85, 0.9, 0.95), 0.05, 0.3))
        "bank":
            town.cyl(root, 2.0, 2.0, 0.6, o + Vector3(46.0, 3.0, bz), town.M(Color(0.55, 0.55, 0.6), 0.3), 20).rotation.x = PI / 2.0
            for i in 5:
                town.cyl(root, 0.8, 0.9, 0.5 + i * 0.1, o + Vector3(6.0 + i * 1.6, 0.25, 9.0), town.M(Color(1.0, 0.82, 0.3), 0.3, 0.4), 10)
            for x in [4.0, 48.0]:
                town.cyl(root, 0.6, 0.6, 5.5, o + Vector3(x, 2.75, 20.0), town.M(Color(0.85, 0.83, 0.78), 0.6), 12)
                _solid(id, int(x / TS0), 10)
        "house":
            for x in [8.0, 16.0, 36.0, 44.0]:
                town.box(root, Vector3(3.0, 0.8, 5.0), o + Vector3(x, 0.4, 11.0), wood)
                town.box(root, Vector3(2.8, 0.3, 3.6), o + Vector3(x, 0.95, 11.6), town.M(Color(0.75, 0.82, 0.95), 0.9))
                town.box(root, Vector3(2.4, 0.3, 0.9), o + Vector3(x, 1.05, 9.4), town.M(Color(1, 1, 1), 0.9))
                for y in [5, 6]:
                    _solid(id, int(x / TS0), y)
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
                _solid(id, int(x / TS0), 8)
