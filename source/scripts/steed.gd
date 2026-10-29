extends Node3D
## สัตว์ขี่ · สัตว์เลี้ยง (js/031-core.js ANIMS · MOUNTS · PET · toggleMount · petTick · 038-fix7 สมดุลความเร็ว/สัตว์ขี่บิน · 107-fix75 สัตว์ใหม่ · PETST7 โบนัสสเตตัส)
## ซื้อที่ลุงขายผัก (แผงของไร่ลุงในเมือง) หลังเลือกอาชีพแล้ว · ขี่ = เดินเร็วขึ้น (รวมทั้งหมดไม่เกิน ×2.05) · ตี/เข้าร้าน/เข้าเหมือง = ลงจากหลัง
## สัตว์เลี้ยง: ตามติดทุกที่ · ดูดของดรอปจากไกลขึ้น · โบนัสสเตตัสเฉพาะตัวที่พาเดิน
## โมเดลสร้างจากรูปทรง 3D (ไม่ใช้ภาพวาด) — build_mount / build_pet ใช้ร่วมกับ tools/make_icons.gd

## สัตว์ขี่: n ชื่อ · p ราคา · spd ตัวคูณความเร็ว (fix7) · lv เลเวลขั้นต่ำ · fly บินได้ · base รูปร่าง · pal [ตัว, เงา, แผงคอ/ขน, ขา]
const MOUNTS := {
    "horse": {"n": "ม้าศึกหุ้มเกราะ", "p": 6000, "spd": 1.3, "lv": 0, "base": "horse", "pal": ["#8a5430", "#4a2a14", "#2a1a10", "#5a3418"], "d": "เร็วขึ้น 30% · เกราะหน้าม้าเหล็ก อานหนังแท้"},
    "wolf": {"n": "หมาป่าเงาจันทร์", "p": 20000, "spd": 1.45, "lv": 0, "base": "wolf", "boss": true, "pal": ["#7a80a0", "#3a3e58", "#e8ecff", "#4a4e68"], "d": "สัตว์ขี่ในตำนาน: เร็วขึ้น 45% · ดวงตาเรืองแสง · ต้องปราบเงาแห่งห้วงลึก (ดันเจี้ยนชั้น 100)"},
    "unicorn": {"n": "ยูนิคอร์นแสงจันทร์", "p": 35000, "spd": 1.4, "lv": 40, "base": "horse", "horn": "#ffe8a0", "pal": ["#eef0fa", "#b8bcd8", "#f0c8ff", "#d8dcf0"], "d": "สัตว์ขี่หายาก: เร็วขึ้น 40% · ประกายรุ้ง"},
    "flame": {"n": "ม้าอัคคีนรก", "p": 55000, "spd": 1.5, "lv": 45, "base": "horse", "glow": true, "pal": ["#241a20", "#0a0608", "#ff6a1a", "#1a1014"], "d": "สัตว์ขี่หายาก: เร็วขึ้น 50% · แผงคอเปลวไฟ"},
    "pegasus": {"n": "เพกาซัสสายฟ้า", "p": 80000, "spd": 1.35, "lv": 50, "base": "horse", "fly": true, "wing": ["#e8f4ff", "#9fd0ff"], "pal": ["#dfe9fa", "#a8b8d8", "#7ab8ff", "#c8d4ee"], "d": "สัตว์ขี่บิน: ปีกแสงฟ้า"},
    "tiger": {"n": "พยัคฆ์ขาวสายฟ้า", "p": 120000, "spd": 1.5, "lv": 60, "base": "wolf", "pal": ["#e8ecf4", "#2a2a38", "#9ab8ff", "#c8ccd8"], "d": "ประกายสายฟ้าวิ่งรอบตัว · เร็ว"},
    "drake": {"n": "มังกรเวหาอเวจี", "p": 180000, "spd": 1.5, "lv": 65, "base": "dragon", "fly": true, "wing": ["#6a2a5a", "#c04a8a"], "pal": ["#34204a", "#160c24", "#e04a9a", "#24143a"], "d": "สัตว์ขี่บินหายาก: ปีกมังกรม่วง"},
    "kirin": {"n": "กิเลนอัคคีมงคล", "p": 200000, "spd": 1.55, "lv": 70, "base": "horse", "horn": "#ffd23a", "glow": true, "pal": ["#c83a1a", "#6a1408", "#ffd23a", "#8a2a10"], "d": "เขาทองคำ ไฟมงคลโคจร"},
    "phoenix": {"n": "อาชาฟีนิกซ์เพลิง", "p": 260000, "spd": 1.55, "lv": 75, "base": "horse", "fly": true, "glow": true, "wing": ["#ffb04a", "#ff4a1a"], "pal": ["#ff8a2a", "#a02a08", "#ffd23a", "#c0501a"], "d": "สัตว์ขี่บิน: ปีกเพลิง"},
    "dfrost": {"n": "มังกรน้ำแข็งนิรันดร์", "p": 320000, "spd": 1.55, "lv": 80, "base": "dragon", "fly": true, "wing": ["#e8f8ff", "#8ad0ff"], "pal": ["#bfe8ff", "#4a8ab8", "#e8fbff", "#8ac0e0"], "d": "สัตว์ขี่บิน: เกล็ดน้ำแข็ง"},
    "dgold": {"n": "มังกรทองจักรพรรดิ", "p": 450000, "spd": 1.6, "lv": 90, "base": "dragon", "fly": true, "glow": true, "wing": ["#ffe08a", "#e0a020"], "pal": ["#e0b030", "#8a5a10", "#ff6a3a", "#b08020"], "d": "สัตว์ขี่บินระดับตำนาน: ออร่าทอง"},
}
const MOUNT_ORDER := ["horse", "wolf", "unicorn", "flame", "pegasus", "tiger", "drake", "kirin", "phoenix", "dfrost", "dgold"]
## สัตว์เลี้ยง (st = โบนัสสเตตัส PETST7 / NP75)
const PETS := {
    "dog": {"n": "หมาชิบะ", "p": 1500, "lv": 0, "st": {"str": 2, "vit": 2}, "c": ["#e0a050", "#fff4e0"], "d": "ตามติดทุกที่ ดูดของดรอปเข้าหาตัว · STR+2 VIT+2"},
    "cat": {"n": "แมวส้ม", "p": 1500, "lv": 0, "st": {"agi": 2, "int": 2}, "c": ["#f0903a", "#ffe0c0"], "d": "ตามติดทุกที่ ดูดของดรอป · AGI+2 INT+2"},
    "slimeq": {"n": "สไลม์เจ้าหญิง", "p": 12000, "lv": 10, "st": {"vit": 3}, "c": ["#ff8ad8", "#ffe060"], "d": "สไลม์ใส่มงกุฎ เด้งดึ๋ง · VIT+3"},
    "panda": {"n": "แพนด้าน้อย", "p": 18000, "lv": 15, "st": {"vit": 2, "str": 2}, "c": ["#f4f4f0", "#202024"], "d": "กลิ้งตามตัว กินไผ่ · STR+2 VIT+2"},
    "fox": {"n": "จิ้งจอกเก้าหาง", "p": 25000, "lv": 20, "st": {"agi": 3, "int": 2}, "c": ["#ff8a2a", "#fff0e0"], "d": "หางเปลวไฟ 9 หาง · AGI+3 INT+2"},
    "owl": {"n": "นกฮูกเวทมนตร์", "p": 30000, "lv": 25, "fly": true, "st": {"int": 4}, "c": ["#8a6a4a", "#ffe06a"], "d": "บินได้ ดวงตาเรืองแสง · INT+4"},
    "drago": {"n": "ลูกมังกรน้อย", "p": 60000, "lv": 40, "fly": true, "st": {"str": 3, "vit": 3}, "c": ["#5ac85a", "#ffd23a"], "d": "บินได้ พ่นไฟเล็ก ๆ · STR+3 VIT+3"},
}
const PET_ORDER := ["dog", "cat", "slimeq", "panda", "fox", "owl", "drago"]
const SPEED_CAP := 2.05
const SADDLE := 0.95

var town
var S := {"mounts": [], "mount": "", "pets": [], "pet": "", "on": false}
var tab := "mount"
var mount_node: Node3D
var mount_key := ""
var pet_node: Node3D
var pet_key := ""
var _t := 0.0

func setup(t) -> void:
    town = t

func load_state(d) -> void:
    S = {"mounts": [], "mount": "", "pets": [], "pet": "", "on": false}
    if d is Dictionary:
        for k in d.get("mounts", []):
            if MOUNTS.has(str(k)) and not S.mounts.has(str(k)):
                S.mounts.append(str(k))
        for k in d.get("pets", []):
            if PETS.has(str(k)) and not S.pets.has(str(k)):
                S.pets.append(str(k))
        S.mount = str(d.get("mount", "")) if S.mounts.has(str(d.get("mount", ""))) else ""
        S.pet = str(d.get("pet", "")) if S.pets.has(str(d.get("pet", ""))) else ""
        S.on = bool(d.get("on", false)) and S.mount != ""
    if town != null and town.player != null:
        town.player.recalc_stats()

# ---------- ค่าที่ระบบอื่นเรียก ----------
func riding() -> bool:
    return S.on and S.mount != ""

func speed_mult() -> float:
    return float(MOUNTS[S.mount].spd) if riding() else 1.0

## โบนัสสเตตัสจากสัตว์เลี้ยงที่พาเดิน
func pet_stat(k: String) -> int:
    if S.pet == "":
        return 0
    return int(PETS[S.pet].st.get(k, 0))

## ระยะดูดของดรอป (สัตว์เลี้ยง: 160px ของเกม 2D = 10 หน่วย)
func magnet() -> float:
    return 10.0 if S.pet != "" else 4.5

func can_ride_here() -> String:
    if town.room != "":
        return "ขี่ในอาคารไม่ได้"
    if town.mine.cur >= 0:
        return "ขี่ในเหมือง/ดันเจี้ยนไม่ได้"
    return ""

func toggle() -> String:
    if S.mount == "":
        return "ยังไม่มีสัตว์ขี่ — ซื้อได้ที่ลุงขายผัก (แผงของไร่ลุงในเมือง)"
    if riding():
        dismount()
        return "ลงจากหลัง" + str(MOUNTS[S.mount].n)
    var why := can_ride_here()
    if why != "":
        return why
    S.on = true
    _sync()
    return "ขี่" + str(MOUNTS[S.mount].n) + " — เร็วขึ้น %d%%" % int(round((float(MOUNTS[S.mount].spd) - 1.0) * 100.0))

func dismount() -> void:
    if not S.on:
        return
    S.on = false
    _sync()

# ---------- ซื้อ / เลือกใช้ ----------
func buy(kind: String, k: String) -> String:
    var p = town.player
    if p.cls == "none":
        return "ลุงจะขายให้เมื่อเจ้าเลือกอาชีพแล้ว (Lv.10)"
    var D: Dictionary = MOUNTS[k] if kind == "mount" else PETS[k]
    var own: Array = S.mounts if kind == "mount" else S.pets
    if own.has(k):
        return "มี" + str(D.n) + "แล้ว"
    if p.lv < int(D.lv):
        return "ต้อง Lv.%d ขึ้นไป" % int(D.lv)
    if D.get("boss", false) and int(town.story.S.get("dg", 0)) < 100:
        return "ต้องปราบเงาแห่งห้วงลึก (ดันเจี้ยนชั้น 100) ก่อน"
    if p.coins < int(D.p):
        return "เหรียญไม่พอ (ต้องใช้ %d)" % int(D.p)
    p.coins -= int(D.p)
    own.append(k)
    if kind == "mount":
        S.mount = k
    else:
        S.pet = k
        p.recalc_stats()
    _sync()
    p.save_game()
    return "ได้%sแล้ว! %s" % [D.n, "กดปุ่ม \"ขี่\" (คอม: R) เพื่อขี่" if kind == "mount" else "จะตามคุณไปทุกที่"]

func use(kind: String, k: String) -> String:
    if kind == "mount":
        if not S.mounts.has(k):
            return ""
        S.mount = k
        _sync()
        return "เลือก" + str(MOUNTS[k].n) + "เป็นสัตว์ขี่"
    if S.pet == k:
        S.pet = ""
        town.player.recalc_stats()
        _sync()
        return "ให้" + str(PETS[k].n) + "พักที่บ้าน"
    if not S.pets.has(k):
        return ""
    S.pet = k
    town.player.recalc_stats()
    _sync()
    return "พา" + str(PETS[k].n) + "ออกเดินทาง"

# ---------- หน้าต่างร้านสัตว์ (renderLife 'pet') ----------
func open() -> void:
    var p = town.player
    town.cur_shop = "steed"
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl("สัตว์ขี่ & สัตว์เลี้ยง — ลุงขายผัก", 22, Color(1.0, 0.85, 0.45), true)))
    hv.add_child(town._lbl("\"สนใจสัตว์เลี้ยงหรือม้าไหมหลาน? ลุงเลี้ยงไว้หลายตัวเลย\" · เหรียญของคุณ %d" % p.coins, 14, Color(0.85, 0.82, 0.74)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    var tabs := HBoxContainer.new()
    for t in [["mount", "สัตว์ขี่"], ["pet", "สัตว์เลี้ยง"]]:
        var tt: String = t[0]
        tabs.add_child(town._btn(str(t[1]) + (" ◀" if tab == tt else ""), true, func(): tab = tt; open()))
    tabs.add_child(town._btn("กลับแผงผัก", true, func(): town.open_shop("st_farm")))
    town.ui_shop_body.add_child(tabs)
    if p.cls == "none":
        town.ui_shop_body.add_child(town._lbl("ลุงจะขายให้เมื่อเจ้าเลือกอาชีพแล้ว (Lv.10 คุยกับปรมาจารย์อาชีพ)", 15, Color(1.0, 0.6, 0.5)))
    var order: Array = MOUNT_ORDER if tab == "mount" else PET_ORDER
    for k in order:
        var kk: String = k
        var D: Dictionary = MOUNTS[k] if tab == "mount" else PETS[k]
        var own: bool = (S.mounts if tab == "mount" else S.pets).has(k)
        var cur: bool = (S.mount == k) if tab == "mount" else (S.pet == k)
        var sub := str(D.d)
        if tab == "mount":
            sub = "เร็ว ×%.2f%s · %s" % [float(D.spd), " · บินได้" if D.get("fly", false) else "", sub]
        var head := "%s%s" % [D.n, (" (ต้อง Lv.%d)" % int(D.lv)) if int(D.lv) > 0 and not own else ""]
        var btns := []
        if own:
            if tab == "mount":
                btns.append(town._btn("ใช้อยู่" if cur else "เลือก", not cur, func(): town.field.say_msg(use("mount", kk)); open()))
            else:
                btns.append(town._btn("พักที่บ้าน" if cur else "พาเดิน", true, func(): town.field.say_msg(use("pet", kk)); open()))
        else:
            btns.append(town._btn("ซื้อ %d" % int(D.p), p.coins >= int(D.p) and p.lv >= int(D.lv) and p.cls != "none", func(): town.field.say_msg(buy(tab, kk), 3.5); open()))
        var r: HBoxContainer = town._row(head, sub, btns, ("m_" if tab == "mount" else "p_") + k)
        if cur:
            town._row_label(r).add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
        town.ui_shop_body.add_child(r)
    town.ui_shop.visible = true

# ---------- โมเดล 3D ----------
static func _m(c: Color, emit: float = 0.0, rough: float = 0.75) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emit
    return m

static func _p(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, nm: String = "") -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    if nm != "":
        mi.name = nm
    parent.add_child(mi)
    return mi

static func _bx(s: Vector3) -> BoxMesh:
    var b := BoxMesh.new()
    b.size = s
    return b

static func _cap(r: float, h: float) -> CapsuleMesh:
    var c := CapsuleMesh.new()
    c.radius = r
    c.height = h
    c.radial_segments = 10
    c.rings = 3
    return c

static func _sp(r: float) -> SphereMesh:
    var s := SphereMesh.new()
    s.radius = r
    s.height = r * 2.0
    s.radial_segments = 10
    s.rings = 6
    return s

static func _cone(r: float, h: float) -> CylinderMesh:
    var c := CylinderMesh.new()
    c.top_radius = 0.0
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 6
    return c

## สัตว์ขี่ (หันหน้า +Z) · ขามีชื่อ leg0-3 ไว้แกว่งตอนเดิน · ปีกชื่อ wingL/wingR
static func build_mount(k: String) -> Node3D:
    var D: Dictionary = MOUNTS[k]
    var pal: Array = D.pal
    var body_c := Color(pal[0])
    var mb := _m(body_c)
    var ms := _m(Color(pal[1]))
    var glow := 1.6 if D.get("glow", false) else 0.0
    var mm := _m(Color(pal[2]), glow + (0.4 if k == "wolf" else 0.0))
    var ml := _m(Color(pal[3]))
    var n := Node3D.new()
    var base: String = D.base
    if base == "dragon":
        _p(n, _cap(0.42, 2.0), mb, Vector3(0, 0.95, 0), Vector3(PI / 2.0, 0, 0))
        _p(n, _cap(0.2, 0.9), mb, Vector3(0, 1.45, 0.95), Vector3(0.7, 0, 0))
        _p(n, _bx(Vector3(0.36, 0.3, 0.55)), mb, Vector3(0, 1.75, 1.3))
        _p(n, _cone(0.08, 0.35), mm, Vector3(-0.12, 1.98, 1.15), Vector3(-0.6, 0, 0))
        _p(n, _cone(0.08, 0.35), mm, Vector3(0.12, 1.98, 1.15), Vector3(-0.6, 0, 0))
        _p(n, _sp(0.05), _m(Color(1, 0.9, 0.4), 3.0), Vector3(-0.12, 1.8, 1.55))
        _p(n, _sp(0.05), _m(Color(1, 0.9, 0.4), 3.0), Vector3(0.12, 1.8, 1.55))
        _p(n, _cone(0.22, 1.2), mb, Vector3(0, 0.85, -1.4), Vector3(-PI / 2.0 - 0.2, 0, 0))
        for i in 4:
            _p(n, _cone(0.1, 0.22), mm, Vector3(0, 1.4, 0.4 - i * 0.35))
        for i in 4:
            var lx := -0.28 if i % 2 == 0 else 0.28
            var lz := 0.5 if i < 2 else -0.5
            _p(n, _cap(0.12, 0.75), ml, Vector3(lx, 0.38, lz), Vector3.ZERO, "leg%d" % i)
    else:
        var wolf := base == "wolf"
        var L := 1.5 if not wolf else 1.35
        var H := 0.95 if not wolf else 0.8
        _p(n, _cap(0.36 if not wolf else 0.3, L), mb, Vector3(0, H, 0), Vector3(PI / 2.0, 0, 0))
        if wolf:
            _p(n, _cap(0.2, 0.55), mb, Vector3(0, H + 0.2, 0.72), Vector3(1.1, 0, 0))
            _p(n, _bx(Vector3(0.36, 0.32, 0.42)), mb, Vector3(0, H + 0.38, 0.92))
            _p(n, _bx(Vector3(0.18, 0.14, 0.26)), ms, Vector3(0, H + 0.3, 1.18))
            _p(n, _cone(0.08, 0.2), mb, Vector3(-0.12, H + 0.62, 0.86))
            _p(n, _cone(0.08, 0.2), mb, Vector3(0.12, H + 0.62, 0.86))
            _p(n, _cap(0.1, 0.7), mm, Vector3(0, H + 0.15, -0.85), Vector3(-1.0, 0, 0))
            for ex in [-0.1, 0.1]:
                _p(n, _sp(0.04), _m(Color(0.6, 0.85, 1.0) if k == "wolf" else Color(1, 0.85, 0.3), 3.0), Vector3(ex, H + 0.45, 1.13))
            if k == "tiger":
                for i in 4:
                    _p(n, _bx(Vector3(0.64, 0.05, 0.08)), ms, Vector3(0, H + 0.2, 0.4 - i * 0.28))
        else:
            _p(n, _cap(0.18, 0.75), mb, Vector3(0, H + 0.35, 0.75), Vector3(0.55, 0, 0))
            _p(n, _bx(Vector3(0.28, 0.3, 0.62)), mb, Vector3(0, H + 0.68, 1.08), Vector3(0.35, 0, 0))
            _p(n, _bx(Vector3(0.08, 0.6, 0.4)), mm, Vector3(0, H + 0.55, 0.68), Vector3(0.55, 0, 0))
            _p(n, _cap(0.1, 0.75), mm, Vector3(0, H + 0.1, -0.85), Vector3(-0.6, 0, 0))
            for ex in [-0.15, 0.15]:
                _p(n, _sp(0.035), _m(Color(0.05, 0.05, 0.05)), Vector3(ex, H + 0.76, 1.2))
            if D.has("horn"):
                _p(n, _cone(0.06, 0.45), _m(Color(D.horn), 1.2), Vector3(0, H + 1.0, 1.28), Vector3(0.5, 0, 0))
            if k == "horse":
                _p(n, _bx(Vector3(0.3, 0.32, 0.3)), _m(Color(0.7, 0.72, 0.76), 0.0, 0.35), Vector3(0, H + 0.72, 1.24), Vector3(0.35, 0, 0))
        # อาน
        _p(n, _bx(Vector3(0.62, 0.12, 0.6)), _m(Color(0.45, 0.22, 0.1)), Vector3(0, H + 0.33, 0.0))
        for i in 4:
            var lx := -0.2 if i % 2 == 0 else 0.2
            var lz := 0.5 if i < 2 else -0.5
            _p(n, _cap(0.09 if not wolf else 0.08, H + 0.1), ml, Vector3(lx, H * 0.45, lz * (1.0 if not wolf else 0.9)), Vector3.ZERO, "leg%d" % i)
    if D.has("wing"):
        var w0 := Color(D.wing[0])
        var w1 := Color(D.wing[1])
        for s in [-1.0, 1.0]:
            var wp := Node3D.new()
            wp.name = "wingL" if s < 0 else "wingR"
            wp.position = Vector3(s * 0.3, 1.35, 0.15)
            n.add_child(wp)
            _p(wp, _bx(Vector3(1.3, 0.05, 0.75)), _m(w0, 0.5), Vector3(s * 0.65, 0, 0))
            _p(wp, _bx(Vector3(0.9, 0.06, 0.4)), _m(w1, 0.8), Vector3(s * 1.15, 0.02, -0.25))
    return n

static func build_pet(k: String) -> Node3D:
    var D: Dictionary = PETS[k]
    var c0 := Color(D.c[0])
    var c1 := Color(D.c[1])
    var n := Node3D.new()
    var m0 := _m(c0)
    var m1 := _m(c1)
    var eye := _m(Color(0.05, 0.05, 0.05))
    match k:
        "slimeq":
            _p(n, _sp(0.32), _m(c0, 0.3, 0.2), Vector3(0, 0.28, 0)).scale = Vector3(1.1, 0.85, 1.1)
            for i in 5:
                var a := i * TAU / 5.0
                _p(n, _cone(0.05, 0.14), _m(c1, 1.0), Vector3(cos(a) * 0.1, 0.6, sin(a) * 0.1))
            for ex in [-0.1, 0.1]:
                _p(n, _sp(0.04), eye, Vector3(ex, 0.34, 0.28))
        "owl", "drago":
            _p(n, _sp(0.22), m0, Vector3(0, 0.3, 0)).scale = Vector3(1, 1.15, 1)
            _p(n, _sp(0.16), m0, Vector3(0, 0.6, 0.05))
            for ex in [-0.07, 0.07]:
                _p(n, _sp(0.045), _m(c1, 2.0) if k == "owl" else eye, Vector3(ex, 0.64, 0.19))
            for s in [-1.0, 1.0]:
                var wp := Node3D.new()
                wp.name = "wingL" if s < 0 else "wingR"
                wp.position = Vector3(s * 0.18, 0.4, 0)
                n.add_child(wp)
                _p(wp, _bx(Vector3(0.4, 0.04, 0.24)), m1 if k == "drago" else m0, Vector3(s * 0.2, 0, 0))
            if k == "drago":
                _p(n, _cone(0.04, 0.12), m1, Vector3(-0.06, 0.78, 0.0))
                _p(n, _cone(0.04, 0.12), m1, Vector3(0.06, 0.78, 0.0))
                _p(n, _cone(0.08, 0.35), m0, Vector3(0, 0.2, -0.3), Vector3(-PI / 2.0, 0, 0))
        _:
            var panda := k == "panda"
            _p(n, _cap(0.17 if not panda else 0.22, 0.6), m0, Vector3(0, 0.3, 0), Vector3(PI / 2.0, 0, 0))
            _p(n, _sp(0.17 if not panda else 0.2), m0, Vector3(0, 0.48, 0.3))
            _p(n, _sp(0.08), m1, Vector3(0, 0.43, 0.45))
            for ex in [-0.07, 0.07]:
                _p(n, _sp(0.03), eye, Vector3(ex, 0.52, 0.45))
                _p(n, _cone(0.06, 0.13) if not panda else _sp(0.065), m0 if not panda else m1, Vector3(ex * 1.5, 0.66 if not panda else 0.62, 0.27))
            if panda:
                for ex in [-0.07, 0.07]:
                    _p(n, _sp(0.05), m1, Vector3(ex, 0.51, 0.43))
            for i in 4:
                var lx := -0.09 if i % 2 == 0 else 0.09
                var lz := 0.17 if i < 2 else -0.17
                _p(n, _cap(0.05, 0.22), m0 if not panda else m1, Vector3(lx, 0.11, lz), Vector3.ZERO, "leg%d" % i)
            if k == "fox":
                for i in 9:
                    _p(n, _cap(0.05, 0.4), _m(c0.lerp(Color(1, 0.6, 0.2), 0.5), 0.6), Vector3((i - 4) * 0.035, 0.42, -0.36), Vector3(-0.9, (i - 4) * 0.18, 0))
            elif not panda:
                _p(n, _cap(0.05, 0.36), m0, Vector3(0, 0.45, -0.36), Vector3(-0.6, 0, 0))
            if k == "dog":
                _p(n, _bx(Vector3(0.24, 0.05, 0.05)), _m(Color(0.75, 0.15, 0.15)), Vector3(0, 0.42, 0.28))
    return n

# ---------- ภาพบนจอ ----------
func _sync() -> void:
    var p = town.player
    if p == null or p.body == null:
        return
    var want: String = str(S.mount) if riding() else ""
    if want != mount_key:
        if mount_node != null:
            mount_node.queue_free()
            mount_node = null
        mount_key = want
        if want != "":
            mount_node = build_mount(want)
            p.add_child(mount_node)
    if p.body.inst != null:
        p.body.position.y = SADDLE if riding() else 0.0
        p.body.riding = riding()
    if S.pet != pet_key:
        if pet_node != null:
            pet_node.queue_free()
            pet_node = null
        pet_key = S.pet
        if pet_key != "":
            pet_node = build_pet(pet_key)
            add_child(pet_node)
            pet_node.position = p.position

func _process(delta: float) -> void:
    if town == null or town.player == null:
        return
    var p = town.player
    _t += delta
    # ลงจากหลังอัตโนมัติ: เข้าร้าน / เหมือง / ตาย
    if riding() and (town.room != "" or town.mine.cur >= 0 or p.dead):
        dismount()
    if mount_node != null:
        mount_node.rotation.y = p.heading
        var mv: float = p.moving_speed
        var sw: float = sin(_t * 12.0) * 0.5 * min(1.0, mv / 3.0)
        for i in 4:
            var lg = mount_node.get_node_or_null("leg%d" % i)
            if lg != null:
                lg.rotation.x = sw * (1.0 if i == 0 or i == 3 else -1.0)
        var fl: float = sin(_t * (6.0 if mv > 0.1 else 2.5)) * 0.5
        for wn in ["wingL", "wingR"]:
            var w = mount_node.get_node_or_null(wn)
            if w != null:
                w.rotation.z = fl * (1.0 if wn == "wingL" else -1.0)
        mount_node.position.y = abs(sin(_t * 12.0)) * 0.06 * min(1.0, mv / 3.0)
    if pet_node != null:
        pet_node.visible = town.room == ""
        var back := Vector3(sin(p.heading), 0, cos(p.heading)) * -1.3 + Vector3(cos(p.heading), 0, -sin(p.heading)) * 0.8
        var tgt: Vector3 = p.position + back
        var to := Vector3(tgt.x - pet_node.position.x, 0, tgt.z - pet_node.position.z)
        var d := to.length()
        if d > 25.0:
            pet_node.position = tgt
        elif d > 0.3:
            var sp: float = (15.0 if d > 5.0 else 7.5) * delta
            pet_node.position += to.normalized() * min(d, sp)
            pet_node.rotation.y = lerp_angle(pet_node.rotation.y, atan2(to.x, to.z), min(1.0, delta * 10.0))
        var fly: bool = PETS[pet_key].get("fly", false)
        var gy: float = town.ground_y(pet_node.position.x, pet_node.position.z) if town.mine.cur < 0 else 0.0
        pet_node.position.y = gy + (1.4 + sin(_t * 3.0) * 0.15 if fly else (abs(sin(_t * 10.0)) * 0.08 if d > 0.3 else 0.0))
        var sw2: float = sin(_t * 14.0) * 0.6 if d > 0.3 else 0.0
        for i in 4:
            var lg2 = pet_node.get_node_or_null("leg%d" % i)
            if lg2 != null:
                lg2.rotation.x = sw2 * (1.0 if i == 0 or i == 3 else -1.0)
        for wn in ["wingL", "wingR"]:
            var w2 = pet_node.get_node_or_null(wn)
            if w2 != null:
                w2.rotation.z = sin(_t * 14.0) * 0.6 * (1.0 if wn == "wingL" else -1.0)
