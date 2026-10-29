extends Node
## ตกปลา (js/031-core.js FISHES · fishStart · pickFish · fishPress · fishCatch · fishTick)
## มีคันเบ็ดในกระเป๋า + ยืนริมน้ำในทุ่งหญ้า หันเข้าน้ำ → กดตี = เหวี่ยงเบ็ด
## ทุ่นกระตุก → กดตีภายใน 0.9 วิ → แถบดึงปลา: กดตอนเข็มอยู่ในช่องสีเขียว (ปลาหายากต้องกดหลายครั้ง) · ขยับตัว = เลิกตก

## ราคาขายอยู่ในรายการรับซื้อของร้านชำ (town.json) · ผลตอนกิน: hpp/mpp = % · buff ชั่วคราว
const FISHES := {
    "carp": {"n": "ปลาตะเพียน", "hpp": 4, "xp": 3, "c": Color("#c8b070")},
    "tilapia": {"n": "ปลานิล", "hpp": 5, "xp": 4, "c": Color("#a8b4bc")},
    "catfish": {"n": "ปลาดุก", "hpp": 6, "xp": 6, "c": Color("#6a6458")},
    "salmon": {"n": "ปลาแซลมอน", "mpp": 15, "buff": {"int": 3}, "sec": 120, "xp": 10, "c": Color("#ff9a7a")},
    "goldfish": {"n": "ปลาทองคำ", "hpp": 20, "xp": 25, "c": Color("#ffe14a")},
    "dragon": {"n": "ปลามังกรฟ้า", "hpp": 40, "buff": {"str": 3, "vit": 3, "int": 3, "agi": 3, "end": 3}, "sec": 240, "xp": 80, "c": Color("#7fe0ff")},
}
const RARE := {"carp": 0, "tilapia": 0, "catfish": 1, "salmon": 1, "goldfish": 2, "dragon": 3}

var town
var st := ""          # "" · cast · wait · bite · reel
var t := 0.0
var wait := 0.0
var rod := 1
var fish := ""
var need := 1
var hits := 0
var zone := 0.2
var zc := 0.5
var cur := 0.0
var dir := 1.0
var spd := 1.0
var bob_at := Vector3.ZERO
var start_pos := Vector3.ZERO
var bob: MeshInstance3D
var line: MeshInstance3D
var bar: Panel
var bar_zone: ColorRect
var bar_cur: ColorRect

func setup(tn) -> void:
    town = tn

func build_ui(cl: CanvasLayer) -> void:
    bar = Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.08, 0.1, 0.14, 0.9)
    sb.border_color = Color(0.76, 0.67, 0.46)
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(8)
    bar.add_theme_stylebox_override("panel", sb)
    bar.anchor_left = 0.5
    bar.anchor_right = 0.5
    bar.anchor_top = 1.0
    bar.anchor_bottom = 1.0
    bar.offset_left = -170
    bar.offset_right = 170
    bar.offset_top = -150
    bar.offset_bottom = -120
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar_zone = ColorRect.new()
    bar_zone.color = Color(0.3, 0.85, 0.4, 0.8)
    bar.add_child(bar_zone)
    bar_cur = ColorRect.new()
    bar_cur.color = Color(1, 1, 1)
    bar.add_child(bar_cur)
    bar.visible = false
    cl.add_child(bar)

func has_rod() -> int:
    var p = town.player
    return 2 if p.inv_count("rod2") > 0 else (1 if p.inv_count("rod") > 0 else 0)

## น้ำข้างหน้า (ช่องที่ยืน+ระยะ 1-2.8 หน่วย) · คืน Vector3.INF = ไม่มี
func water_ahead(p) -> Vector3:
    if town.mine.cur >= 0 or town.room != "" or p.position.x >= town.OX:
        return Vector3.INF
    var fwd := Vector3(sin(p.heading), 0, cos(p.heading))
    for dd in [1.2, 2.0, 2.8]:
        var w: Vector3 = p.position + fwd * dd
        var tx := int(floor((w.x - town.FX0) / 2.0))
        var ty := int(floor((w.z - town.FZ0) / 2.0))
        if town.ftile(tx, ty) == town.F_WATER:
            return Vector3(w.x, 0, w.z)
    return Vector3.INF

func try_start(p) -> bool:
    if st != "":
        press()
        return true
    if has_rod() == 0:
        return false
    var w := water_ahead(p)
    if w == Vector3.INF:
        return false
    rod = has_rod()
    st = "cast"
    t = 0.0
    bob_at = w
    start_pos = p.position
    p.set_path(PackedVector3Array())
    p.body.action("1H_Melee_Attack_Slice_Diagonal", 0.4)
    _visual(true)
    if town.get("sfx") != null: town.sfx.at("splash", w, -4.0)
    town.field.say_msg("เหวี่ยงเบ็ด… รอปลากินเหยื่อ (ขยับตัว = เลิกตก)")
    return true

func pick_fish(r: float = -1.0) -> String:
    var night: bool = town.time_of_day > 0.77 or town.time_of_day < 0.23
    var W := {"carp": 25.0, "tilapia": 25.0, "catfish": 22.0, "salmon": 18.0, "goldfish": 8.0, "dragon": 2.0} if rod == 2 else {"carp": 40.0, "tilapia": 30.0, "catfish": 18.0, "salmon": 9.0, "goldfish": 2.5, "dragon": 0.5}
    if night:
        W.catfish *= 1.6
        W.dragon *= 2.0
    var s := 0.0
    for k in W:
        s += W[k]
    if r < 0.0:
        r = randf() * s
    for k in W:
        if r < W[k]:
            return k
        r -= W[k]
    return "carp"

func press() -> void:
    match st:
        "bite":
            st = "reel"
            t = 0.0
            fish = pick_fish()
            var rare: int = RARE[fish]
            need = 1 + (1 if rare >= 2 else 0) + (1 if rare >= 3 else 0)
            hits = 0
            zone = (0.26 if rod == 2 else 0.2) - rare * 0.03
            zc = 0.3 + randf() * 0.4
            cur = 0.0
            dir = 1.0
            spd = 0.9 + rare * 0.35
        "reel":
            if abs(cur - zc) < zone / 2.0:
                hits += 1
                if hits >= need:
                    catch()
                    return
                zc = 0.2 + randf() * 0.6
                spd *= 1.15
                town.field.say_msg("ดึงอีก %d ครั้ง!" % (need - hits))
            else:
                town.field.say_msg("พลาด! ปลาหลุดไปแล้ว")
                stop()
        _:
            town.field.say_msg("ยังไม่มีปลากินเบ็ด ใจเย็น ๆ")

func catch() -> void:
    var p = town.player
    var F: Dictionary = FISHES[fish]
    p.inv_add(fish, 1)
    p.gain_xp(int(F.xp))
    town.field.say_msg("ได้%s!%s" % [F.n, " ปลาในตำนาน!" if fish == "dragon" else (" หายากมาก!" if fish == "goldfish" else "")], 3.0)
    town.guild.event("fish")
    stop()

func stop() -> void:
    st = ""
    _visual(false)
    if bar != null:
        bar.visible = false

func _visual(on: bool) -> void:
    if bob == null:
        bob = MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.15
        sm.height = 0.3
        sm.radial_segments = 8
        sm.rings = 4
        bob.mesh = sm
        bob.material_override = town.M(Color(1.0, 0.3, 0.25), 0.4, 0.4)
        town.add_child(bob)
        line = MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(0.02, 0.02, 1.0)
        line.mesh = bm
        line.material_override = town.M(Color(0.95, 0.95, 0.95), 0.5)
        town.add_child(line)
    bob.visible = on
    line.visible = on

func _process(delta: float) -> void:
    if st == "" or town == null:
        return
    var p = town.player
    t += delta
    if p.dead or p.position.distance_to(start_pos) > 0.4 or town.mine.cur >= 0:
        town.field.say_msg("เลิกตกปลา")
        stop()
        return
    var b := bob_at + Vector3(0, town.ground_y(bob_at.x, bob_at.z) + 0.05, 0)
    match st:
        "cast":
            var u: float = min(1.0, t / 0.55)
            b = p.position.lerp(bob_at, u) + Vector3(0, 1.5 + sin(u * PI) * 2.0, 0)
            if t >= 0.55:
                st = "wait"
                t = 0.0
                wait = 2.0 + randf() * 4.5
        "wait":
            b.y += sin(t * 3.0) * 0.04
            if t >= wait:
                st = "bite"
                t = 0.0
                town.field.say_msg("ปลากินเบ็ด! กดตีเลย!", 1.0)
        "bite":
            b.y += -0.15 + sin(t * 30.0) * 0.06
            if t > 0.9:
                town.field.say_msg("ปลากินเบ็ดแล้วหนีไป — กดให้ไวกว่านี้!")
                stop()
                return
        "reel":
            cur += dir * spd * delta
            if cur > 1.0:
                cur = 1.0
                dir = -1.0
            if cur < 0.0:
                cur = 0.0
                dir = 1.0
            if t > 8.0:
                town.field.say_msg("ปลาดิ้นหลุดไปแล้ว")
                stop()
                return
            if bar != null:
                bar.visible = true
                var w := bar.size.x - 8.0
                bar_zone.position = Vector2(4.0 + (zc - zone / 2.0) * w, 4.0)
                bar_zone.size = Vector2(zone * w, bar.size.y - 8.0)
                bar_cur.position = Vector2(4.0 + cur * w - 2.0, 2.0)
                bar_cur.size = Vector2(4.0, bar.size.y - 4.0)
    bob.global_position = b
    var hand: Vector3 = p.position + Vector3(0, 1.6, 0)
    var mid := (hand + b) * 0.5
    line.global_position = mid
    line.scale = Vector3(1, 1, max(0.1, hand.distance_to(b)))
    if hand.distance_to(b) > 0.05:
        line.look_at(b, Vector3.UP if abs((b - hand).normalized().y) < 0.95 else Vector3.FORWARD)
