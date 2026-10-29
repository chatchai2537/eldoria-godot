extends Node
## แท่นผนึกอสูร / บอสตำนาน 6 ตัว (js/094-fix62.js · 145-fix113.js · 096-fix64.js ข้อ 4 · 150-fix118.js · 091-fix59.js · 174-fix147.js)
## ทางเข้า: หอผนึกอสูร (ห้อง seal113 ในเมือง) → แท่นผนึก/ผู้เฝ้า → เลือกบอส จ่ายค่าท้า → ลานผนึก (mine.gd zi = LB_BASE + i)
## ในลาน: เวลา 8 นาที · ท่าไม้ตาย = วงเตือนก่อนลง (หลบ/กลิ้งพ้นได้) ดาเมจ % เลือดสูงสุด · เรียกสมุนเป็นระยะ · เลือด < 30% คลั่ง (ตีแรง ×1.3 ท่าถี่ ×1.6)
## ชนะ: ตราอสูร 1–2 (10 อัน = แลกชิ้นชุดบอสตามใจ) · 12% ได้ชิ้นชุดทันที · เหรียญ = ค่าท้า ×1.2 · XP ครึ่งหลอดของเลเวลบอส
## จำกัด: ชนะแล้วพัก 30 นาที (fix64) · ลงได้วันละ 2 ครั้งต่อบอส (fix118 · นับตอนจ่ายค่าท้า)
const Items = preload("res://scripts/items.gd")

const LB := [
    {"id": "thorn", "n": "ราชาพฤกษาหนาม", "f": "golem", "c": ["#5a8a3a", "#1e3a12", "#9aff6a"], "lv": 20, "hp": 6.0, "atk": 1.3, "cost": 3000, "adds": "wisp", "sc": 1.9,
        "fl": ["#4a6a30", "#55783a", "#3e5a28"], "wl": "#2a3a1c", "ac": "#9aff6a", "tip": "หนามแทงจากพื้นใต้เท้า · เรียกภูตป่า"},
    {"id": "serp", "n": "นาคราชอสรพิษ", "f": "drake", "c": ["#2a9a7a", "#0e3a30", "#6affc8"], "lv": 35, "hp": 6.0, "atk": 1.35, "cost": 6000, "adds": "bat", "sc": 2.0,
        "fl": ["#2e5048", "#365c52", "#28463e"], "wl": "#163028", "ac": "#6affc8", "tip": "บ่อพิษค้างบนพื้น (อย่ายืนแช่) · พ่นพิษวงกว้าง"},
    {"id": "frost", "n": "ราชันย์หมาป่าเหมันต์", "f": "wolf", "c": ["#e8f4ff", "#7a9ab8", "#bfe8ff"], "lv": 55, "hp": 5.5, "atk": 1.4, "cost": 12000, "adds": "wolf", "sc": 2.3,
        "fl": ["#c8dce8", "#b8ccdc", "#a8bccc"], "wl": "#4a6a88", "ac": "#7ad8ff", "tip": "วงน้ำแข็งรอบตัวบอส (หนีออกนอกวง) · เรียกฝูงหมาป่า"},
    {"id": "phar", "n": "ฟาโรห์อมตะสุริยัน", "f": "skeleton", "c": ["#e0b030", "#2a5ac8", "#ffe880"], "lv": 75, "hp": 5.5, "atk": 1.45, "cost": 20000, "adds": "skeleton", "sc": 2.1,
        "fl": ["#c8a868", "#b89858", "#a88848"], "wl": "#5a4020", "ac": "#ffe880", "tip": "ลำแสงสุริยะตกหลายจุด · ปลุกทหารโครงกระดูก"},
    {"id": "blood", "n": "มังกรโลหิตโบราณ", "f": "dragon", "c": ["#c81a2a", "#3a0408", "#ffc040"], "lv": 95, "hp": 3.5, "atk": 1.5, "cost": 35000, "adds": "drake", "sc": 2.0,
        "fl": ["#4a2a22", "#563028", "#3e221c"], "wl": "#24100a", "ac": "#ff5a2a", "tip": "ฝนไฟถล่มทั้งลาน · คลั่งแล้วพ่นไฟถี่ขึ้น"},
    {"id": "void", "n": "จักรพรรดิเงานิรันดร์", "f": "skeleton", "c": ["#3a2a5a", "#06020c", "#b07aff"], "lv": 115, "hp": 10.0, "atk": 1.6, "cost": 60000, "adds": "wisp", "sc": 2.6,
        "fl": ["#2e2640", "#362c4a", "#282036"], "wl": "#120a1c", "ac": "#b07aff", "tip": "วาปหายแล้วโผล่ใหม่ · หลุมเงาหลายจุด · เรียกเงาสมุน"},
]
## ดาเมจท่าไม้ตาย = สัดส่วนเลือดสูงสุดผู้เล่น (PCT62) · สี (COL62)
const PCT := {"hit": 0.3, "thorn": 0.25, "pool": 0.2, "ice": 0.3, "sun": 0.25, "fire": 0.28, "void": 0.32}
const COL := {"hit": Color(1.0, 0.31, 0.24), "thorn": Color(0.59, 1.0, 0.39), "pool": Color(0.31, 1.0, 0.75), "ice": Color(0.67, 0.9, 1.0), "sun": Color(1.0, 0.9, 0.47), "fire": Color(1.0, 0.35, 0.16), "void": Color(0.7, 0.47, 1.0)}
const K := 2.0 / 32.0   # พิกเซลเกม 2D → หน่วย 3D
const TIME := 480.0
const LIM := 2
const CD_SEC := 1800
const NEED := 10

var town
## เซฟ: cd = เวลาที่ชนะล่าสุด (unix) ต่อบอส · day/n = จำนวนครั้งที่ลงวันนี้
var S := {"cd": {}, "day": "", "n": {}}
var act := -1
var el := 0.0
var cyc := 6.0
var sum_t := 12.0
var won := 0   # 0 = กำลังสู้ · 1 = ชนะ · -1 = หมดเวลา
var later: Array = []   # [เวลาที่เหลือ, Callable] ท่าที่ทยอยลง
var rage := false
var aggro := false
var aoes: Array = []
var last_msg := ""
var _disc: CylinderMesh

func setup(t) -> void:
    town = t

func load_state(d) -> void:
    S = {"cd": {}, "day": "", "n": {}}
    if d is Dictionary:
        if d.get("cd") is Dictionary:
            for k in d.cd:
                S.cd[str(k)] = int(d.cd[k])
        S.day = str(d.get("day", ""))
        if d.get("n") is Dictionary:
            for k in d.n:
                S.n[str(k)] = int(d.n[k])

func _now() -> int:
    return int(Time.get_unix_time_from_system())

func _today() -> String:
    return Time.get_date_string_from_system()

func left_today(i: int) -> int:
    if S.day != _today():
        S.day = _today()
        S.n = {}
    return max(0, LIM - int(S.n.get(str(i), 0)))

func cd_left(i: int) -> int:
    var t0 := int(S.cd.get(str(i), 0))
    return max(0, t0 + CD_SEC - _now()) if t0 > 0 else 0

func in_arena() -> bool:
    return act >= 0 and town.mine.cur >= 0 and town.mine.is_lb(town.mine.cur)

# ---------- แผนที่ลาน (build62: วงรี 36×28 · เสา 4 ต้น · ทางเข้าด้านล่าง) ----------
func zdef(i: int) -> Dictionary:
    var B: Dictionary = LB[i]
    return {"id": "lb_" + str(B.id), "n": "ลานผนึก" + str(B.n), "lv": [int(B.lv), int(B.lv)], "ores": [], "dark": false, "mobs": [],
        "pal": {"fl": B.fl, "top": B.wl, "face": Color.html(str(B.wl)).darkened(0.25).to_html(false), "vd": "#050208"},
        "boss": {"f": B.f, "n": B.n, "lv": int(B.lv) + 3, "c": B.c}}

func gen_arena(_i: int) -> Dictionary:
    var W := 36
    var H := 28
    var m := PackedByteArray()
    m.resize(W * H)
    for y in H:
        for x in W:
            var dx := (x - W / 2.0 + 0.5) / (W / 2.0 - 1.0)
            var dy := (y - H / 2.0 + 0.5) / (H / 2.0 - 1.0)
            m[y * W + x] = 1 if dx * dx + dy * dy > 1.0 else 0
    for pp in [Vector2i(9, 8), Vector2i(26, 8), Vector2i(9, 19), Vector2i(26, 19)]:
        m[pp.y * W + pp.x] = 1
    for y in range(H - 3, H):
        for x in range(W / 2 - 1, W / 2 + 1):
            m[y * W + x] = 0
    for x in W:
        m[(H - 1) * W + x] = 1
    var fl := []
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if m[y * W + x] == 0:
                fl.append(Vector2i(x, y))
    return {"m": m, "ores": [], "ore_at": {}, "floor": fl, "ent": Vector2i(W / 2, H - 4), "arena": Vector2i(W / 2, H / 2 - 1), "root": null, "mm": {}, "W": W, "H": H}

## ของตกแต่งลาน: ลูกไฟบนเสา · วงเวทกลางลาน (สีประจำบอส)
func decorate(i: int, root: Node3D) -> void:
    var B: Dictionary = LB[i]
    var ac := Color.html(str(B.ac))
    var mn = town.mine
    var zi: int = mn.LB_BASE + i
    for pp in [Vector2i(9, 8), Vector2i(26, 8), Vector2i(9, 19), Vector2i(26, 19)]:
        var w: Vector3 = mn.tile_w(zi, pp.x, pp.y)
        town.cyl(root, 0.45, 0.45, 0.45, w + Vector3(0, 4.1, 0), town.M(ac, 0.3, 2.5), 10)
    var c: Vector3 = mn.tile_w(zi, 18, 13)
    for r in [6.5, 4.6, 2.3]:
        var tm := TorusMesh.new()
        tm.inner_radius = r - 0.12
        tm.outer_radius = r
        tm.rings = 40
        tm.ring_segments = 4
        var mi := MeshInstance3D.new()
        mi.mesh = tm
        mi.material_override = town.M(ac, 0.4, 1.4)
        mi.position = c + Vector3(0, 0.04, 0)
        mi.scale = Vector3(1, 0.05, 1)
        root.add_child(mi)

# ---------- เข้า / ออก ----------
## ท้าสู้ (enter62 + ตรวจ fix64/fix118) · คืนข้อความเหตุผลถ้าเข้าไม่ได้ ("" = เข้าแล้ว)
func challenge(i: int) -> String:
    var B: Dictionary = LB[i]
    var p = town.player
    if in_arena():
        return "อยู่ในลานบอสอยู่แล้ว"
    if town.mine.cur >= 0:
        return "เข้าลานบอสได้จากหอผนึกอสูรในเมืองเท่านั้น"
    if p.lv < int(B.lv):
        return "%s ต้อง Lv.%d ขึ้นไป" % [B.n, int(B.lv)]
    if cd_left(i) > 0:
        return "%s เพิ่งถูกผนึก — กลับมาได้ในอีก %d นาที" % [B.n, int(ceil(cd_left(i) / 60.0))]
    if left_today(i) <= 0:
        return "วันนี้ลง%sครบ %d ครั้งแล้ว — พรุ่งนี้มาใหม่ (รีเซ็ตเที่ยงคืน)" % [B.n, LIM]
    if p.coins < int(B.cost):
        return "เหรียญไม่พอ (ค่าท้า %d)" % int(B.cost)
    p.coins -= int(B.cost)
    S.n[str(i)] = int(S.n.get(str(i), 0)) + 1
    town.close_shop()
    town.rooms.exit_silent()
    town.mine.enter(town.mine.LB_BASE + i)
    p.save_game()
    return ""

func on_enter(i: int) -> void:
    act = i
    el = 0.0
    cyc = 6.0
    sum_t = 12.0
    won = 0
    rage = false
    aggro = false
    _clear_aoe()
    town.mine._spawn_boss()
    var B: Dictionary = LB[i]
    town.field.say_msg("ลานผนึก%s — ปราบให้ได้ภายใน 8 นาที หลบวงเตือนให้ดี! · %s" % [B.n, B.tip], 5.0)

func on_leave() -> void:
    act = -1
    _clear_aoe()

func spawn_boss():
    var B: Dictionary = LB[act]
    var mn = town.mine
    var d: Dictionary = mn.data[mn.cur]
    var b = mn._mk(str(B.f), str(B.n), B.c, int(B.lv) + 3, mn.tile_w(mn.cur, d.arena.x, d.arena.y), {"boss": true, "scm": float(B.sc) / 1.4})
    b.hp = int(round(b.max_hp * float(B.hp)))
    b.max_hp = b.hp
    b.atk_v = int(round(b.atk_v * float(B.atk)))
    b.set_meta("lb", true)
    return b

## สมุน (adds) แทนลูกน้องทั่วไปของบอส
func summon(b) -> void:
    if act < 0:
        return
    var B: Dictionary = LB[act]
    var n := 2 + (2 if rage else 0)
    var mn = town.mine
    for j in n:
        var a := randf() * TAU
        var pos: Vector3 = b.position + Vector3(cos(a) * 70.0 * K, 0, sin(a) * 50.0 * K)
        if mn.blocked(pos.x, pos.z):
            continue
        var q = mn._mk(str(B.adds), "สมุน" + str(B.n), B.c, max(1, int(B.lv) - 2), pos, {"elite": true})
        q.aggro = true
        q.st = "chase"
    town.field.float_text("เรียกสมุน!", b.position + Vector3(0, 3.5 * b.sc, 0), Color(1.0, 0.6, 0.35), 1.3)

# ---------- ทุกเฟรม (setInterval 0.5 วิ ของ fix62 → ต่อเนื่อง) ----------
func tick(delta: float) -> void:
    if act < 0:
        return
    _tick_aoe(delta)
    var b = town.mine.boss
    if won != 0 or b == null or not is_instance_valid(b) or b.dead:
        return
    el += delta
    if el >= TIME:
        won = -1
        town.field.say_msg("หมดเวลา! พลังผนึกผลักเจ้าออกมา", 4.0)
        town.mine.leave(true)
        return
    var p = town.player
    if not aggro and p.position.distance_to(b.position) < 400.0 * K:
        aggro = true
        b.aggro = true
    if not aggro:
        return
    if not rage and float(b.hp) / float(b.max_hp) < 0.3:
        rage = true
        b.atk_v = int(round(b.atk_v * 1.3))
        town.field.say_msg(str(LB[act].n) + " คลั่ง!", 3.0)
    cyc -= delta * (1.6 if rage else 1.0)
    if cyc <= 0.0:
        cyc = 6.0
        _ult(b)
    sum_t -= delta
    if sum_t <= 0.0:
        sum_t = 9.0 if rage else 14.0
        summon(b)

## ท่าไม้ตายประจำตัว (ระยะเป็นพิกเซลเกม 2D × K)
func _ult(b) -> void:
    var id: String = LB[act].id
    var pp: Vector3 = town.player.position
    var bp: Vector3 = b.position
    match id:
        "thorn":
            for j in 3:
                later.append([j * 0.6, func(): aoe(town.player.position, 46.0, 1.1, "thorn")])
        "serp":
            for j in 4:
                var a := randf() * TAU
                var r := 60.0 + randf() * 120.0
                aoe(pp + Vector3(cos(a), 0, sin(a)) * r * K, 58.0, 1.3, "pool")
            aoe(bp, 150.0, 1.6, "hit")
        "frost":
            aoe(bp, 170.0, 1.5, "ice")
            aoe(pp, 50.0, 1.2, "ice")
        "phar":
            for j in 6:
                var a := randf() * TAU
                var r := randf() * 180.0
                aoe(pp + Vector3(cos(a), 0, sin(a)) * r * K, 44.0, 1.2 + j * 0.15, "sun")
        "blood":
            for j in (12 if rage else 8):
                var a := randf() * TAU
                var r := randf() * 260.0
                aoe(bp + Vector3(cos(a), 0, sin(a)) * r * K, 50.0, 1.0 + randf() * 0.8, "fire")
            aoe(pp, 60.0, 1.1, "fire")
        "void":
            if randf() < 0.6:
                var mn = town.mine
                var d: Dictionary = mn.data[mn.cur]
                var t: Vector2i = d.floor[randi() % d.floor.size()]
                b.position = mn.tile_w(mn.cur, t.x, t.y)
                town.field.float_text("วาป!", b.position + Vector3(0, 3.0, 0), COL.void, 1.2)
            for j in 5:
                var a := j * 1.2566 + randf()
                var r := (80.0 + randf() * 80.0) * 0.6
                aoe(pp + Vector3(cos(a), 0, sin(a)) * r * K, 52.0, 1.3, "void")

## วงเตือน: r = รัศมีพิกเซล 2D · l = เวลาก่อนลง (วิ)
func aoe(at: Vector3, r_px: float, l: float, kind: String) -> void:
    var r := r_px * K
    var n := Node3D.new()
    town.mine.add_child(n)
    n.position = Vector3(at.x, 0.06, at.z)
    if _disc == null:
        _disc = CylinderMesh.new()
        _disc.top_radius = 1.0
        _disc.bottom_radius = 1.0
        _disc.height = 0.04
        _disc.radial_segments = 28
    var c: Color = COL[kind]
    var outer := MeshInstance3D.new()
    outer.mesh = _disc
    outer.material_override = _amat(c, 0.28)
    outer.scale = Vector3(r, 1, r)
    n.add_child(outer)
    var inner := MeshInstance3D.new()
    inner.mesh = _disc
    inner.material_override = _amat(c, 0.45)
    inner.scale = Vector3(0.01, 1.5, 0.01)
    inner.position.y = 0.02
    n.add_child(inner)
    aoes.append({"n": n, "in": inner, "out": outer, "r": r, "l": l, "t": 0.0, "kind": kind, "done": false, "linger": 0.0, "tick": 0.0, "fade": 0.35})

func _amat(c: Color, a: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(c.r, c.g, c.b, a)
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func _inside(a: Dictionary) -> bool:
    var p = town.player
    var n: Node3D = a.n
    return Vector2(p.position.x - n.position.x, p.position.z - n.position.z).length() < float(a.r)

func _hurt(pct: float, nm: String) -> void:
    var p = town.player
    if p.dead:
        return
    var dmg: float = p.max_hp * pct * (1.15 if rage else 1.0) + p.def() * 0.8
    p.hurt_mob(int(round(dmg)), nm)

func _tick_aoe(delta: float) -> void:
    var nm: String = str(LB[act].n) if act >= 0 else ""
    for j in range(later.size() - 1, -1, -1):
        later[j][0] -= delta
        if later[j][0] <= 0.0:
            var cb: Callable = later[j][1]
            later.remove_at(j)
            if won == 0:
                cb.call()
    for j in range(aoes.size() - 1, -1, -1):
        var a: Dictionary = aoes[j]
        a.t += delta
        if not a.done:
            var u: float = min(1.0, a.t / float(a.l))
            a["in"].scale = Vector3(max(0.01, a.r * u), 1.5, max(0.01, a.r * u))
            if a.t >= a.l:
                a.done = true
                if _inside(a) and won == 0:
                    _hurt(float(PCT[a.kind]), "ท่าไม้ตายของ" + nm + " —")
                a["in"].visible = false
                if a.kind == "pool":
                    a.linger = 4.0
        elif a.linger > 0.0:
            a.linger -= delta
            a.tick -= delta
            if a.tick <= 0.0 and _inside(a) and won == 0:
                a.tick = 0.8
                _hurt(0.06, "พิษของ" + nm + " —")
        else:
            a.fade -= delta
            if a.fade <= 0.0:
                a.n.queue_free()
                aoes.remove_at(j)

func _clear_aoe() -> void:
    later.clear()
    for a in aoes:
        if is_instance_valid(a.n):
            a.n.queue_free()
    aoes.clear()

func hud_text() -> String:
    if act < 0:
        return ""
    var rem: int = max(0, int(TIME - el))
    return "ลานผนึก%s · เหลือเวลา %d:%02d%s" % [LB[act].n, rem / 60, rem % 60, " · คลั่ง!" if rage else ""]

# ---------- ชนะ / รางวัล ----------
func on_won(m) -> void:
    if act < 0 or won != 0:
        return
    won = 1
    var i := act
    var B: Dictionary = LB[i]
    var p = town.player
    _clear_aoe()
    for q in town.mine.mobs:
        if q != m and is_instance_valid(q) and not q.dead:
            q.dead = true
            q.queue_free()
    var k := "lbm%d" % i
    var n := 1 + (1 if randf() < 0.25 else 0)
    p.inv_add(k, n)
    var R := ["ตราอสูร ×%d (มี %d/%d)" % [n, p.inv_count(k), NEED]]
    if randf() < 0.12:
        var g := drop_piece(i, "จากบอสตำนาน")
        R.append(g)
    var coin := int(round(int(B.cost) * 1.2))
    p.coins += coin
    R.append("%d เหรียญ" % coin)
    # fix125: XP ครึ่งหลอดของเลเวล min(ผู้เล่น, บอส)
    var xp := int(round(p.need(min(int(p.lv), int(m.lv))) * 0.5))
    p.gain_xp(xp)
    R.append("EXP +%d" % xp)
    S.cd[str(i)] = _now()
    p.save_game()
    last_msg = "ปราบ %s สำเร็จ!\n%s" % [B.n, " · ".join(R)]
    town.field.say_msg(last_msg.replace("\n", " "), 5.0)
    _result_panel()

func _result_panel() -> void:
    _head("ชัยชนะ!", last_msg)
    var row := HBoxContainer.new()
    row.add_child(town._btn("แลกตราอสูร", true, func(): open_trade()))
    var ob: Button = town._btn("ออกจากลาน", true, func(): town.close_shop(); town.mine.leave(true))
    row.add_child(ob)
    town.ui_shop_body.add_child(row)
    town.ui_shop.visible = true

## ชุดตามเลเวลบอส (pick59)
static func pick_set(L: int) -> int:
    return 0 if L < 20 else (1 if L < 40 else (2 if L < 60 else (3 if L < 80 else (4 if L < 100 else 5))))

## ได้ชิ้นชุดบอสสุ่ม 1 ชิ้น (drop59) เข้ากระเป๋าทันที
func drop_piece(si: int, src: String) -> String:
    var kind: String = Items.BOSS_PIECES[randi() % Items.BOSS_PIECES.size()]
    return give_piece(si, kind, src)

func give_piece(si: int, kind: String, src: String) -> String:
    var p = town.player
    var id := "%s%d" % [kind, Items.BOSS_T0 + si]
    var it: Dictionary = p.make_inst(id)
    p.gear.append(it)
    var rr: Array = Items.RARITY[si]
    var msg := "ได้ %s [%s] %s! (ต้อง Lv.%d)" % [Items.inst_name(it), rr[0], src, Items.req_lv(int(it.t))]
    town.field.say_msg(msg, 4.5)
    p.save_game()
    return Items.inst_name(it)

## แลกตรา 10 อัน → ชิ้นที่เลือก (pickPiece62)
func trade(i: int, kind: String) -> String:
    var p = town.player
    var k := "lbm%d" % i
    if p.inv_count(k) < NEED:
        return "ตราไม่พอ (มี %d/%d)" % [p.inv_count(k), NEED]
    p.inv_take(k, NEED)
    give_piece(i, kind, "จากการแลกตรา")
    return "แลกได้ %s%s แล้ว" % [Items.KINDS[kind], Items.TNAMES[Items.BOSS_T0 + i]]

# ---------- หน้าต่าง (open113) ----------
func _head(title: String, sub: String) -> void:
    town.cur_shop = "altar"
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl(title, 22, Color(0.85, 0.7, 1.0), true)))
    hv.add_child(town._lbl(sub, 14, Color(0.88, 0.85, 0.95)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)

func open() -> void:
    if in_arena():
        if won == 1:
            _result_panel()
            return
        _head("แท่นผนึกอสูร", "จะยอมแพ้หรือ? ออกตอนนี้ไม่ได้รางวัล")
        town.ui_shop_body.add_child(town._btn("ออกจากลาน", true, func(): town.close_shop(); town.mine.leave(true)))
        town.ui_shop.visible = true
        return
    var p = town.player
    _head("แท่นผนึกอสูร — บอสตำนาน", "ผู้เฝ้าแท่นผนึก: \"อสูรทั้งหกถูกผนึกไว้ในคริสตัลนี้ จ่ายค่าท้าแล้วเข้าไปได้เลย ชนะได้ตราอสูร 1–2 อัน · สะสม 10 อันแลกชิ้นชุดบอสที่ต้องการ · มีเวลา 8 นาที หลบวงเตือนให้ดี\" · เหรียญของคุณ %d" % p.coins)
    for i in LB.size():
        var B: Dictionary = LB[i]
        var ii: int = i
        var seal: int = p.inv_count("lbm%d" % i)
        var lv_ok: bool = p.lv >= int(B.lv)
        var cdl := cd_left(i)
        var left := left_today(i)
        var lines := ["%s  Lv.%d%s" % [B.n, int(B.lv), "" if lv_ok else " (ล็อก)"],
            "ค่าท้า %d เหรียญ · ตราอสูร %d/%d · ดรอปชุด%s [%s]" % [int(B.cost), seal, NEED, Items.TNAMES[Items.BOSS_T0 + i], Items.RARITY[i][0]],
            "วิธีสู้: " + str(B.tip),
            ("พักฟื้นอีก %d นาที · " % int(ceil(cdl / 60.0)) if cdl > 0 else "") + "วันนี้ลงได้อีก %d/%d ครั้ง" % [left, LIM]]
        var can: bool = lv_ok and cdl <= 0 and left > 0 and p.coins >= int(B.cost)
        var r: HBoxContainer = town._row(lines[0], "\n".join(lines.slice(1)), [
            town._btn("ท้าสู้", can, func():
                var m := challenge(ii)
                if m != "":
                    town.field.say_msg(m, 3.0)
                    open()),
            town._btn("แลกตรา", seal >= NEED, func(): pick_piece(ii))], "lbm%d" % i)
        var lb: Label = town._row_label(r)
        lb.add_theme_color_override("font_color", Color.html(str(B.ac)) if lv_ok else Color(0.6, 0.58, 0.62))
        town.ui_shop_body.add_child(r)
    town.ui_shop_body.add_child(town._lbl("ชุดบอส: ใส่ชุดเดียวกัน 3 ชิ้น = โบนัสขั้น 1 · 5 ชิ้น = ขั้น 2 · 7 ชิ้น (อาวุธ หมวก เสื้อ กางเกง แขน สร้อย แหวน) = ดาเมจ/เลือดเพิ่ม · คราฟไม่ได้ ขายร้านไม่ได้", 13, Color(0.75, 0.72, 0.8)))
    town.ui_shop.visible = true

func open_trade() -> void:
    _head("แลกตราอสูร", "เลือกเซ็ตที่จะแลก (ใช้ตราอสูรของบอสตัวนั้น %d อัน)" % NEED)
    for i in LB.size():
        var ii: int = i
        var n: int = town.player.inv_count("lbm%d" % i)
        town.ui_shop_body.add_child(town._row("ชุด%s — ตรา %d/%d" % [Items.TNAMES[Items.BOSS_T0 + i], n, NEED], "", [town._btn("เลือก", n >= NEED, func(): pick_piece(ii))], "lbm%d" % i))
    town.ui_shop.visible = true

func pick_piece(i: int) -> void:
    var t := Items.BOSS_T0 + i
    var p = town.player
    _head("แลกชุด%s" % Items.TNAMES[t], "ตราอสูรที่มี %d/%d · ต้อง Lv.%d จึงจะสวมได้" % [p.inv_count("lbm%d" % i), NEED, Items.req_lv(t)])
    for k in Items.BOSS_PIECES:
        var kk: String = k
        var it := {"k": k, "t": t, "q": 0, "e": 0}
        town.ui_shop_body.add_child(town._row("%s%s" % [Items.KINDS[k], Items.TNAMES[t]], "%s %d" % [Items.stat_label(k), Items.inst_stat(it)], [
            town._btn("แลก", p.inv_count("lbm%d" % i) >= NEED, func():
                town.field.say_msg(trade(i, kk), 3.5)
                pick_piece(i))], "%s%d" % [k, t]))
    town.ui_shop_body.add_child(town._btn("กลับ", true, func(): open()))
    town.ui_shop.visible = true
