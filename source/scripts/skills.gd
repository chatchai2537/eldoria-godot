extends Node
## อาชีพ 3 สายหลัก (js/031-core.js CLS · CSKILLS · PASSIVE · CLASS_LV · NEEDW · useSkill · pickClass)
## เลือกที่ปรมาจารย์อาชีพ (จัตุรัส) ตั้งแต่ Lv.10 · ครั้งแรกฟรี เปลี่ยนสาย 500 เหรียญ
## สกิลอาชีพปลดล็อกเองตามเลเวล (5 / 15 / 30) · ต้องถืออาวุธประจำสาย · สกิลที่ 2 กดต่อกัน 3 จังหวะภายใน 1.8 วิ
## เยียวยา (สกิลพื้นฐาน) ใช้ได้ทุกอาชีพ · ฟันวงพายุ/ลูกไฟ ใช้ได้เฉพาะตอนยังไม่มีอาชีพ

const CLASS_LV := 10
const CHANGE_COST := 500
const CLS := {
    "none": {"n": "ผู้ฝึกหัด", "col": Color(0.8, 0.8, 0.8), "d": "ยังไม่ได้เลือกอาชีพ"},
    "sword": {"n": "นักดาบ", "col": Color(1.0, 0.54, 0.42), "w": "sword", "d": "ต่อสู้ระยะประชิด ถึก เลือดเยอะ · ดาเมจจาก STR", "pas": "VIT +2+Lv/3 · STR +Lv/5"},
    "mage": {"n": "นักเวท", "col": Color(0.7, 0.55, 1.0), "w": "staff", "d": "ยิงเวทระยะไกล สกิลวงกว้างรุนแรง · ดาเมจจาก INT · มานาฟื้นเร็ว", "pas": "INT +4+Lv/2 · มานาฟื้นเร็ว ×2.5"},
    "archer": {"n": "นักธนู", "col": Color(0.49, 1.0, 0.54), "w": "bow", "d": "ยิงธนูไกลและเร็ว คริติคอลสูง · ดาเมจจาก AGI", "pas": "AGI +3+Lv/3 · คริ +10%"},
}
const WNAME := {"sword": "ดาบ", "staff": "คทา", "bow": "ธนู"}
const SK := {
    "sword": [
        {"n": "กระทืบปฐพี", "lv": 5, "mp": 15, "cd": 7.0, "d": "กระทืบพื้น คลื่นกระแทกรอบตัว ×1.8 + มึนงง 1.6 วิ"},
        {"n": "ดาบสามจังหวะ", "lv": 15, "mp": [8, 10, 16], "cd": 9.0, "steps": 3, "d": "① พุ่งฟัน ×1.4 → ② ฟันเสย ×1.6 → ③ คลื่นดาบพุ่งไกล ×2.4 (กดซ้ำภายใน 1.8 วิ)"},
        {"n": "พายุดาบ", "lv": 30, "mp": 40, "cd": 24.0, "d": "หมุนตัวเป็นพายุ 2.6 วิ ฟันทุกตัวรอบตัวต่อเนื่อง เดินไปด้วยได้"}],
    "mage": [
        {"n": "วงแหวนเพลิง", "lv": 5, "mp": 20, "cd": 9.0, "d": "วงไฟรอบตัว 4.5 วิ เผาศัตรูในวงต่อเนื่อง"},
        {"n": "เวทธาตุสามสาย", "lv": 15, "mp": [10, 14, 24], "cd": 10.0, "steps": 3, "d": "① น้ำแข็ง 5 เล่ม → ② สายฟ้าลูกโซ่ 5 ตัว → ③ อุกกาบาตยักษ์ ×3.2"},
        {"n": "พายุอุกกาบาต", "lv": 30, "mp": 60, "cd": 30.0, "d": "อุกกาบาตตกถล่มรอบตัว 3.5 วิ"}],
    "archer": [
        {"n": "ยิงกระจาย", "lv": 5, "mp": 12, "cd": 5.0, "d": "ยิงธนู 5 ดอกเป็นรูปพัด ดอกละ ×0.9"},
        {"n": "ธนูวิญญาณ", "lv": 15, "mp": [8, 10, 18], "cd": 9.0, "steps": 3, "d": "① ธนูทะลวง ×1.5 → ② ตีลังกาถอยยิง ×1.2 → ③ ธนูระเบิด ×2.6 + มึนงง"},
        {"n": "ฝนธนู", "lv": 30, "mp": 45, "cd": 24.0, "d": "ห่าธนูตกด้านหน้า 3 วิ ดาเมจต่อเนื่อง"}],
}
const PASSIVE := {
    "none": [{"lv": 5, "n": "ผู้ฝึกหัดอดทน", "d": "END +2", "st": {"end": 2}}],
    "sword": [{"lv": 10, "n": "จิตวิญญาณนักรบ", "d": "STR +3", "st": {"str": 3}}, {"lv": 20, "n": "ผิวเหล็ก", "d": "VIT +6", "st": {"vit": 6}}, {"lv": 35, "n": "สายเลือดนักรบ", "d": "ฟื้นเลือด 1%/วิ", "regen": 0.01}, {"lv": 50, "n": "โทสะ", "d": "STR +12", "st": {"str": 12}}],
    "mage": [{"lv": 10, "n": "สมาธิ", "d": "INT +4", "st": {"int": 4}}, {"lv": 20, "n": "กระแสมานา", "d": "มานาฟื้นเร็วขึ้น 50%", "mpr": 0.5}, {"lv": 35, "n": "จิตแกร่ง", "d": "INT +10 · VIT +4", "st": {"int": 10, "vit": 4}}, {"lv": 50, "n": "อาร์คเมจ", "d": "INT +15", "st": {"int": 15}}],
    "archer": [{"lv": 10, "n": "ตาเหยี่ยว", "d": "คริติคอล +5%", "crit": 0.05}, {"lv": 20, "n": "ฝีเท้าเบา", "d": "AGI +5 · END +4", "st": {"agi": 5, "end": 4}}, {"lv": 35, "n": "นักล่า", "d": "AGI +10", "st": {"agi": 10}}, {"lv": 50, "n": "มือปืนเทวดา", "d": "คริติคอล +8% · AGI +8", "crit": 0.08, "st": {"agi": 8}}],
}

var town
var cd := [0.0, 0.0, 0.0]
var step := 0
var win := 0.0
var pers: Array = []   # ผลต่อเนื่อง: {k, t, l, tick, acc, at}

func setup(t) -> void:
    town = t

# ---------- ค่าพลังจากอาชีพ ----------
func passives_on(p) -> Array:
    var L := []
    for ps in PASSIVE.get(p.cls, []):
        if p.lv >= int(ps.lv):
            L.append(ps)
    return L

## โบนัสสเตตัสจากอาชีพ + พาสซีฟ (calcBonus)
func stat_bonus(p, k: String) -> int:
    var b := 0
    var L: int = p.lv
    match p.cls:
        "sword":
            if k == "vit":
                b += 2 + L / 3
            elif k == "str":
                b += L / 5
        "mage":
            if k == "int":
                b += 4 + L / 2
        "archer":
            if k == "agi":
                b += 3 + L / 3
    for ps in passives_on(p):
        if ps.has("st"):
            b += int(ps.st.get(k, 0))
    return b

func crit_bonus(p) -> float:
    var c := 0.1 if p.cls == "archer" else 0.0
    for ps in passives_on(p):
        c += float(ps.get("crit", 0.0))
    return c

func mp_regen_mult(p) -> float:
    var m := 2.5 if p.cls == "mage" else 1.0
    for ps in passives_on(p):
        m += float(ps.get("mpr", 0.0))
    return m

func hp_regen_pct(p) -> float:
    var r := 0.0
    for ps in passives_on(p):
        r += float(ps.get("regen", 0.0))
    return r

## แจ้งเตือนตอนเลเวลอัป: ถึง Lv.10 ไปเลือกอาชีพ · ปลดล็อกสกิล/พาสซีฟใหม่
func on_level(p, l0: int) -> void:
    var msg := ""
    if l0 < CLASS_LV and p.lv >= CLASS_LV and p.cls == "none":
        msg = "Lv.%d แล้ว! ไปเลือกอาชีพกับปรมาจารย์อาชีพที่จัตุรัสได้เลย" % CLASS_LV
    if p.cls != "none":
        for s in SK[p.cls]:
            if l0 < int(s.lv) and p.lv >= int(s.lv):
                msg = "ปลดล็อกสกิลใหม่: " + str(s.n)
    for ps in PASSIVE.get(p.cls, []):
        if l0 < int(ps.lv) and p.lv >= int(ps.lv):
            msg += (" · " if msg != "" else "") + "พาสซีฟ " + str(ps.n) + " — " + str(ps.d)
    if msg != "":
        town.field.say_msg(msg, 4.5)
    if town.mobile != null:
        town.mobile.refresh_skills()

# ---------- เลือกอาชีพ ----------
func pick(k: String) -> String:
    var p = town.player
    if not CLS.has(k) or k == "none":
        return ""
    if p.lv < CLASS_LV:
        return "เลือกอาชีพได้ตั้งแต่ Lv.%d — ไปฟาร์มเก็บเลเวลก่อนนะ" % CLASS_LV
    if p.cls == k:
        return "เป็น%sอยู่แล้ว" % CLS[k].n
    var cost := 0 if p.cls == "none" else CHANGE_COST
    if p.coins < cost:
        return "เหรียญไม่พอ (ต้องใช้ %d)" % cost
    p.coins -= cost
    p.cls = k
    step = 0
    cd = [0.0, 0.0, 0.0]
    p.recalc_stats()
    if town.mobile != null:
        town.mobile.refresh_skills()
    return "คุณกลายเป็น%sแล้ว! อย่าลืมคราฟ%sที่ทั่งตีเหล็ก เพื่อใช้สกิลอาชีพ" % [CLS[k].n, WNAME[CLS[k].w]]

func open_menu() -> void:
    var p = town.player
    town.cur_shop = "class"
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl("ปรมาจารย์อาชีพ — เลือกสายอาชีพ", 22, Color(0.85, 0.75, 1.0), true)))
    var sub := "อาชีพปัจจุบัน: %s · " % CLS[p.cls].n + ("เลือกครั้งแรกฟรี" if p.cls == "none" else "เปลี่ยนสาย %d เหรียญ" % CHANGE_COST)
    if p.lv < CLASS_LV:
        sub += " · ต้อง Lv.%d ขึ้นไป (ตอนนี้ Lv.%d)" % [CLASS_LV, p.lv]
    hv.add_child(town._lbl(sub, 14, Color(1.0, 0.85, 0.45)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    for k in ["sword", "mage", "archer"]:
        var kk: String = k
        var C: Dictionary = CLS[k]
        var sk := []
        for s in SK[k]:
            sk.append("%s (Lv.%d)" % [s.n, s.lv])
        var pas := []
        for ps in PASSIVE[k]:
            pas.append("%s Lv.%d" % [ps.n, ps.lv])
        var b := Button.new()
        b.text = "%s%s\n%s\nติดตัว: %s · อาวุธ: %s\nสกิล: %s\nพาสซีฟ: %s" % [C.n, "  ✓ ปัจจุบัน" if p.cls == k else "", C.d, C.pas, WNAME[C.w], " · ".join(sk), " · ".join(pas)]
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.add_theme_font_override("font", town.font_b)
        b.add_theme_font_size_override("font_size", 14)
        b.add_theme_color_override("font_color", C.col)
        b.focus_mode = Control.FOCUS_NONE
        b.pressed.connect(func():
            var m := pick(kk)
            if m != "":
                town.field.say_msg(m, 4.0)
            open_menu())
        town.ui_shop_body.add_child(b)
    town.ui_shop.visible = true

# ---------- ปุ่มสกิล 4 ช่อง ----------
## ช่อง 0-2: ไม่มีอาชีพ = ฟันวงพายุ / ลูกไฟ / - · มีอาชีพ = สกิลอาชีพ 3 ท่า · ช่อง 3: เยียวยา (ถ้าเรียนแล้ว)
func slot_name(p, i: int) -> String:
    if i == 3:
        return "เยียวยา" if p.skills.has("heal") else ""
    if p.cls == "none":
        var ids := ["whirl", "fireball", ""]
        var id: String = ids[i]
        return town.Items.SKILL[id].name if id != "" and p.skills.has(id) else ""
    var S: Dictionary = SK[p.cls][i]
    return str(S.n) if p.lv >= int(S.lv) else ""

func slot_cd(p, i: int) -> float:
    if i == 3:
        return float(p.skill_cd.get("heal", 0.0))
    if p.cls == "none":
        return float(p.skill_cd.get(["whirl", "fireball", ""][i], 0.0))
    return 0.0 if (i == 1 and step > 0) else float(cd[i])

func use_slot(i: int) -> String:
    var p = town.player
    if i == 3:
        return p.use_skill("heal")
    if p.cls == "none":
        var id: String = ["whirl", "fireball", ""][i]
        return p.use_skill(id) if id != "" else ""
    return use_class(i)

func _mp(S: Dictionary, st: int) -> int:
    return int(S.mp[st]) if S.mp is Array else int(S.mp)

func use_class(i: int) -> String:
    var p = town.player
    if p.dead or p.stun > 0.0 or p.dash_t > 0.0:
        return ""
    var S: Dictionary = SK[p.cls][i]
    if p.lv < int(S.lv):
        return "%s ปลดล็อกที่ Lv.%d" % [S.n, S.lv]
    var need: String = CLS[p.cls].w
    if not p.eq.has("weapon") or str(p.eq.weapon.k) != need:
        return "ต้องถือ%sเพื่อใช้สกิล%s" % [WNAME[need], CLS[p.cls].n]
    if town.room != "" or (abs(p.position.x) <= 44.0 and abs(p.position.z) <= 34.0 and p.position.x < 600.0):
        return "ใช้สกิลต่อสู้ในเมืองไม่ได้"
    var chain: bool = S.has("steps") and step > 0 and i == 1
    if not chain and cd[i] > 0.0:
        return "%s ยังไม่พร้อม (%.1f วิ)" % [S.n, cd[i]]
    var st := step if chain else 0
    var mp := _mp(S, st)
    if p.mp < mp:
        return "มานาไม่พอ (ต้องใช้ %d)" % mp
    p.mp -= mp
    p.at = -1.0
    if S.has("steps"):
        step = st + 1
        win = 1.8
        if step >= 3:
            step = 0
            win = 0.0
            cd[i] = float(S.cd)
    else:
        cd[i] = float(S.cd)
    _face_target(p)
    call("_" + p.cls + str(i), p, st)
    town.field.float_text(str(S.n) + ((" " + ["Ⅰ", "Ⅱ", "Ⅲ"][st]) if S.has("steps") else ""), p.position + Vector3(0, 3.0, 0), CLS[p.cls].col, 1.1)
    return str(S.n)

func _face_target(p) -> void:
    var s = town.field.nearest_slime(p.position, 14.0)
    if s != null:
        p.heading = atan2(s.position.x - p.position.x, s.position.z - p.position.z)
        p.body.rotation.y = p.heading

func _fwd(p) -> Vector3:
    return Vector3(sin(p.heading), 0, cos(p.heading))

# ---------- นักดาบ ----------
func _sword0(p, _st: int) -> void:
    p.body.action("2H_Melee_Attack_Spin", 0.6)
    town.field.aoe(p, 3.6, 1.8, Vector3.INF, 1.6, Color(1.0, 0.75, 0.4))

func _sword1(p, st: int) -> void:
    var f := _fwd(p)
    match st:
        0:
            p.body.action("1H_Melee_Attack_Stab", 0.4)
            for k in 6:
                var nx: Vector3 = p.position + f * 0.5
                if not town.blocked(nx.x, nx.z):
                    p.position = nx
            p.iframe = max(p.iframe, 0.3)
            town.field.aoe(p, 1.9, 1.4, p.position + f * 1.0, 0.0, Color(1.0, 0.6, 0.4))
        1:
            p.body.action("1H_Melee_Attack_Slice_Horizontal", 0.45)
            town.field.aoe(p, 2.4, 1.6, p.position + f * 0.8, 0.6, Color(1.0, 0.85, 0.5))
        2:
            p.body.action("1H_Melee_Attack_Slice_Diagonal", 0.45)
            town.field.shoot(p, {"range": 16.0, "speed": 22.0, "kind": "bolt", "pierce": true, "col": Color(1.0, 0.85, 0.5), "size": 0.45}, 2.4)

func _sword2(p, _st: int) -> void:
    p.body.action("2H_Melee_Attack_Spin", 2.6)
    pers.append({"k": "storm", "t": 0.0, "l": 2.6, "tick": 0.3, "acc": 0.0})

# ---------- นักเวท ----------
func _mage0(p, _st: int) -> void:
    p.body.action("Spellcast_Raise", 0.6)
    town.field.aoe(p, 3.2, 0.8, Vector3.INF, 0.0, Color(1.0, 0.45, 0.15))
    pers.append({"k": "firering", "t": 0.0, "l": 4.5, "tick": 0.5, "acc": 0.0})

func _mage1(p, st: int) -> void:
    match st:
        0:
            p.body.action("Spellcast_Shoot", 0.4)
            for a in [-0.3, -0.15, 0.0, 0.15, 0.3]:
                town.field.shoot(p, {"range": 15.0, "speed": 20.0, "kind": "bolt", "yaw": a, "stun": 0.6, "col": Color(0.6, 0.9, 1.0)}, 0.9)
        1:
            p.body.action("Spellcast_Shoot", 0.4)
            var hit := []
            var from: Vector3 = p.position
            for n in 5:
                var best = null
                var bd := 10.0
                for s in town.field._targets():
                    if not is_instance_valid(s) or s.dead or hit.has(s):
                        continue
                    var d := Vector2(s.position.x - from.x, s.position.z - from.z).length()
                    if d < bd:
                        bd = d
                        best = s
                if best == null:
                    break
                hit.append(best)
                _bolt(from, best.position)
                from = best.position
                town.field.hit_slime(best, p, 1.2)
        2:
            p.body.action("Spellcast_Summon", 0.6)
            var at: Vector3 = p.position + _fwd(p) * 6.0
            var s = town.field.nearest_slime(p.position, 12.0)
            if s != null:
                at = s.position
            _meteor(at, 3.5, 3.2)

func _mage2(p, _st: int) -> void:
    p.body.action("Spellcast_Raise", 0.8)
    pers.append({"k": "meteors", "t": 0.0, "l": 3.5, "tick": 0.35, "acc": 0.0})

# ---------- นักธนู ----------
func _archer0(p, _st: int) -> void:
    p.body.action("1H_Ranged_Shoot", 0.4)
    for a in [-0.36, -0.18, 0.0, 0.18, 0.36]:
        town.field.shoot(p, {"range": 22.5, "speed": 26.0, "kind": "arrow", "yaw": a}, 0.9)

func _archer1(p, st: int) -> void:
    p.body.action("1H_Ranged_Shoot", 0.4)
    match st:
        0:
            town.field.shoot(p, {"range": 26.0, "speed": 30.0, "kind": "arrow", "pierce": true}, 1.5)
        1:
            var back: Vector3 = -_fwd(p)
            for k in 5:
                var nx: Vector3 = p.position + back * 0.5
                if not town.blocked(nx.x, nx.z):
                    p.position = nx
            p.iframe = max(p.iframe, 0.4)
            town.field.shoot(p, {"range": 22.5, "speed": 26.0, "kind": "arrow"}, 1.2)
        2:
            town.field.shoot(p, {"range": 22.5, "speed": 24.0, "kind": "bolt", "boom": 3.0, "stun": 1.0, "col": Color(1.0, 0.75, 0.3), "size": 0.3}, 2.6)

func _archer2(p, _st: int) -> void:
    pers.append({"k": "rain", "t": 0.0, "l": 3.0, "tick": 0.25, "acc": 0.0, "at": p.position + _fwd(p) * 5.0})

# ---------- เอฟเฟกต์ ----------
func _meteor(at: Vector3, r: float, mult: float) -> void:
    var p = town.player
    town.field.aoe(p, r, mult, at, 0.0, Color(1.0, 0.4, 0.1))
    var m := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.6
    sm.height = 1.2
    sm.radial_segments = 10
    sm.rings = 5
    m.mesh = sm
    m.material_override = town.M(Color(1.0, 0.45, 0.1), 0.3, 3.0)
    m.position = at + Vector3(0, 0.6, 0)
    town.field.add_child(m)
    town.field.projectiles.append({"n": m, "fx": true, "t": 0.0})

func _bolt(a: Vector3, b: Vector3) -> void:
    var m := MeshInstance3D.new()
    var bm := BoxMesh.new()
    var d := b - a
    bm.size = Vector3(0.12, 0.12, max(0.1, d.length()))
    m.mesh = bm
    m.material_override = town.M(Color(0.75, 0.85, 1.0), 0.2, 4.0)
    town.field.add_child(m)
    m.position = (a + b) * 0.5 + Vector3(0, 1.1, 0)
    m.look_at(b + Vector3(0, 1.1, 0), Vector3.UP)
    town.field.projectiles.append({"n": m, "fx": true, "t": 0.0})

func _process(delta: float) -> void:
    for i in 3:
        cd[i] = max(0.0, cd[i] - delta)
    if win > 0.0:
        win -= delta
        if win <= 0.0 and step > 0:
            step = 0
            var p0 = town.player
            if p0.cls != "none":
                cd[1] = float(SK[p0.cls][1].cd)
    var p = town.player
    if p == null:
        return
    if p.cls != "none" and not p.dead:
        var r := hp_regen_pct(p)
        if r > 0.0 and p.since_hit > 2.0:
            p.hp = min(float(p.max_hp), p.hp + p.max_hp * r * delta)
    for i in range(pers.size() - 1, -1, -1):
        var e: Dictionary = pers[i]
        e.t += delta
        e.acc += delta
        if p.dead:
            pers.remove_at(i)
            continue
        while e.acc >= e.tick:
            e.acc -= e.tick
            match str(e.k):
                "storm":
                    town.field.aoe(p, 2.8, 0.7, Vector3.INF, 0.0, Color(0.9, 0.95, 1.0))
                "firering":
                    town.field.aoe(p, 3.2, 0.6, Vector3.INF, 0.0, Color(1.0, 0.45, 0.15))
                "meteors":
                    var a := randf() * TAU
                    _meteor(p.position + Vector3(cos(a), 0, sin(a)) * randf_range(1.5, 6.0), 2.2, 1.4)
                "rain":
                    var at: Vector3 = e.at + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
                    town.field.aoe(p, 3.5, 0.5, e.at, 0.0, Color(0.6, 1.0, 0.6))
                    _bolt(at + Vector3(0, 4.0, 0), at)
        if e.t >= e.l:
            pers.remove_at(i)
