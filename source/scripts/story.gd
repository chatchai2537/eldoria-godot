extends Node
## เนื้อเรื่องหลัก (js/031-core.js STORY · STCH · kingTalk · giveRw · updTrack · guideTarget · openJournal)
## คุยกับพระราชาในท้องพระโรง (ห้อง hall) → รับภารกิจ → ทำเป้าหมาย → กลับไปรายงาน → รับรางวัล + บทถัดไป
## ระบบที่ 3D ยังไม่มี (ดันเจี้ยน · เควสกิลด์ · รูน): บทนั้นขึ้นว่า "เร็ว ๆ นี้" และยังทำไม่ได้

const Items = preload("res://scripts/items.gd")
const ZBN := {"iron": "ราชาโกเลมสนิม", "copper": "ด้วงยักษ์หลอมทองแดง", "silver": "ราชาหมาป่าน้ำแข็ง", "gold": "ฟาโรห์โกเลมทองคำ", "diamond": "มังกรคริสตัลแห่งห้วงลึก"}
## need: ชนิดเป้าหมาย · go: จุดที่ลูกศรชี้ · rw: รางวัล (rune ของเกม 2D ยังไม่มีระบบ → ไม่แจก)
const CH := [
    {"t": "บทนำ: การเข้าเฝ้า", "d": "ไปเข้าเฝ้าพระราชาที่ปราสาทกลางเมือง", "go": "king",
        "done": ["เจ้าคือผู้ที่เทพธิดาเลือก… ข้า อัลดริคที่สาม ขอต้อนรับ", "ผลึกอรุณที่ปกป้องแผ่นดินถูกทำลาย เศษทั้งห้าตกไปอยู่ในเหมืองที่เต็มไปด้วยอสูร", "รับดาบ ขวาน และที่ขุดแร่เหล่านี้ไว้ — มันคือของขวัญจากราชวงศ์"],
        "rw": {"coin": 50, "hpp": 3, "scroll": 2, "kit": 1, "xp": 20}},
    {"t": "บทที่ 1: บททดสอบแรก", "d": "กำจัดสไลม์ในทุ่งหญ้า", "need": "slime", "n": 8, "go": "field",
        "intro": "สไลม์ล้นทุ่งหญ้านอกเมือง ชาวนาเดือดร้อนนัก ไปกำจัดพวกมันสัก 8 ตัว แล้วกลับมารายงานข้า",
        "done": ["ฝีมือไม่เลว! ชาวนาฝากขอบใจเจ้ามาด้วย"], "rw": {"coin": 120, "xp": 60, "mpp": 2}},
    {"t": "บทที่ 2: อาวุธคู่กาย", "d": "ถึง Lv.5 และหลอม/ตีอาวุธระดับเหล็กขึ้นไป", "need": "weapon", "n": 2, "go": "forge",
        "intro": "ดาบหินคงไม่พอสู้อสูรในเหมือง ไปเก็บไม้ ขุดแร่ หลอมเป็นแท่งที่ร้านลุงเหล็ก แล้วตีอาวุธเหล็กสักเล่ม — และฝึกจนถึง Lv.5",
        "done": ["อาวุธดี! ผู้กล้าที่ดีต้องรู้จักดูแลอาวุธของตน"], "rw": {"coin": 150, "estone": 2, "xp": 100}},
    {"t": "บทที่ 3: เส้นทางแห่งอาชีพ", "d": "ถึง Lv.10 แล้วเลือกอาชีพกับปรมาจารย์", "need": "cls", "n": 1, "go": "cls",
        "intro": "ปรมาจารย์อาชีพที่จัตุรัสรอคนอย่างเจ้าอยู่ เมื่อถึง Lv.10 จงไปเลือกทางของตน — ดาบ เวท หรือธนู",
        "done": ["เส้นทางของเจ้าชัดเจนแล้ว จงฝึกฝนให้ถึงที่สุด"], "rw": {"coin": 300, "bless": 1, "xp": 200}},
    {"t": "บทที่ 4: เสียงกระซิบใต้พิภพ", "d": "พิชิตดันเจี้ยนชั้น 5", "need": "dg", "n": 5, "go": "cave",
        "intro": "ประตูดันเจี้ยนใต้ทุ่งหญ้าส่งเสียงกระซิบทุกคืน ลงไปสำรวจให้ถึงชั้นห้า แล้วบอกข้าว่าเห็นอะไร",
        "done": ["เงามืดกำลังขยับตัว… เราต้องรวบรวมเศษผลึกก่อนมันจะแข็งแกร่ง"], "rw": {"coin": 400, "estone": 3, "xp": 350}},
    {"t": "บทที่ 5: ราชาโกเลมสนิม", "d": "ปราบบอส ราชาโกเลมสนิม (เหมืองเหล็กร้าง)", "need": "boss:iron", "n": 1, "go": "zone",
        "intro": "เศษผลึกชิ้นแรกอยู่ในเหมืองเหล็กร้าง โกเลมสนิมยักษ์กลืนมันเข้าไป! ไปเอาคืนมา",
        "done": ["เศษผลึกชิ้นแรก! แสงของมันยังอบอุ่นเหมือนวันวาน"], "rw": {"coin": 600, "xp": 600, "shard": 1}},
    {"t": "บทที่ 6: สหายแห่งกิลด์", "d": "ทำเควสกิลด์ให้สำเร็จ", "need": "guild", "n": 3, "go": "guild",
        "intro": "ผู้กล้าไม่อาจสู้เพียงลำพัง ไปช่วยงานกิลด์นักผจญภัยสัก 3 งาน ไอริสจะคอยดูแลเจ้า",
        "done": ["กิลด์ชื่นชมเจ้ามาก ชื่อเสียงของเจ้าเริ่มขจรขจาย"], "rw": {"coin": 500, "estone": 3, "xp": 500}},
    {"t": "บทที่ 7: เปลวไฟใต้ภูเขา", "d": "ปราบบอส ด้วงยักษ์หลอมทองแดง (ถ้ำทองแดงลาวา)", "need": "boss:copper", "n": 1, "go": "zone",
        "intro": "เศษชิ้นที่สองหลอมรวมกับลาวาในถ้ำทองแดง ด้วงยักษ์เฝ้ามันไว้ จงระวังเปลวไฟ",
        "done": ["สองชิ้นแล้ว! ปราสาทเริ่มสว่างขึ้นในยามค่ำ"], "rw": {"coin": 900, "xp": 1200, "shard": 1, "bless": 1}},
    {"t": "บทที่ 8: ห้วงลึกชั้นยี่สิบห้า", "d": "พิชิตดันเจี้ยนชั้น 25", "need": "dg", "n": 25, "go": "cave",
        "intro": "นักบวชเห็นนิมิต — เงาแห่งห้วงลึกกำลังรวบรวมพลังที่ก้นดันเจี้ยน ลงไปให้ลึกกว่าเดิม",
        "done": ["ยิ่งลึกยิ่งมืด… แต่เจ้ากลับมาได้เสมอ"], "rw": {"coin": 1500, "estone": 5, "xp": 2500}},
    {"t": "บทที่ 9: ราชาหมาป่าน้ำแข็ง", "d": "ปราบบอส ราชาหมาป่าน้ำแข็ง (ยอดเขาเงินหิมะ)", "need": "boss:silver", "n": 1, "go": "zone",
        "intro": "เศษชิ้นที่สามแช่แข็งอยู่ในถ้ำเงิน ฝูงหมาป่าน้ำแข็งเฝ้ามันไว้",
        "done": ["สามชิ้น! เจ้าคือความหวังของแผ่นดินโดยแท้"], "rw": {"coin": 2200, "xp": 4500, "shard": 1}},
    {"t": "บทที่ 10: ฟาโรห์ทองคำ", "d": "ปราบบอส ฟาโรห์โกเลมทองคำ (หุบเขาทองคำ)", "need": "boss:gold", "n": 1, "go": "zone",
        "intro": "ฟาโรห์โกเลมทองคำตื่นจากหลับใหลเพราะเศษผลึกชิ้นที่สี่ จงทำให้มันหลับอีกครั้ง",
        "done": ["สี่ชิ้น… เหลือเพียงชิ้นสุดท้าย"], "rw": {"coin": 3500, "xp": 8000, "shard": 1, "bless": 2}},
    {"t": "บทที่ 11: ห้าสิบชั้นแห่งความมืด", "d": "พิชิตดันเจี้ยนชั้น 50", "need": "dg", "n": 50, "go": "cave",
        "intro": "ก่อนเผชิญมังกร เจ้าต้องแข็งแกร่งกว่านี้ ห้าสิบชั้นแห่งความมืดคือบททดสอบ",
        "done": ["เจ้าผ่านครึ่งทางของห้วงลึกแล้ว ข้าภูมิใจในตัวเจ้า"], "rw": {"coin": 5000, "estone": 8, "xp": 14000}},
    {"t": "บทที่ 12: มังกรคริสตัล", "d": "ปราบบอส มังกรคริสตัลแห่งห้วงลึก (ห้วงลึกเพชรนิรันดร์)", "need": "boss:diamond", "n": 1, "go": "zone",
        "intro": "เศษสุดท้ายอยู่ในอกของมังกรคริสตัล… มันเคยเป็นผู้พิทักษ์ผลึกก่อนถูกเงามืดครอบงำ",
        "done": ["ห้าชิ้นครบแล้ว! แต่ผลึกยังไม่ส่องแสง… เงาแห่งห้วงลึกยังมีชีวิตอยู่ที่ชั้นร้อย"], "rw": {"coin": 8000, "xp": 25000, "shard": 1}},
    {"t": "บทที่ 13: ร้อยชั้นสุดท้าย", "d": "พิชิตดันเจี้ยนชั้น 100", "need": "dg", "n": 100, "go": "cave",
        "intro": "นี่คือศึกสุดท้าย จงลงไปถึงชั้นร้อยและผนึกเงาแห่งห้วงลึกเสีย ทั้งแผ่นดินฝากไว้กับเจ้า",
        "done": ["เจ้าทำได้… เจ้าทำได้จริง ๆ!"], "rw": {"coin": 20000, "xp": 60000, "bless": 5, "end": 1}},
    {"t": "ตำนานบทใหม่", "d": "อิสระ — สำรวจ ตีบวก และท้าดันเจี้ยน", "free": true},
]

var town
## สถานะ (เซฟใน player.story): ch บท · st "active"/"report" · slime นับสไลม์ · base ค่าตอนเริ่มบท · boss บอสที่ปราบแล้ว · shards · dg ชั้นดันเจี้ยนสูงสุด · guild เควสที่ทำ
var S := {}
var tracker: Button
var arrow: MeshInstance3D
var _tick := 0.0
var dlg_lines: Array = []
var dlg_i := 0

func setup(t) -> void:
    town = t
    reset()

func reset() -> void:
    S = {"ch": 0, "st": "active", "slime": 0, "base": 0, "boss": {}, "shards": 0, "dg": 0, "guild": 0, "gbase": 0}

func load_state(d) -> void:
    reset()
    if d is Dictionary:
        for k in S.keys():
            if d.has(k):
                S[k] = d[k]
        S.ch = clampi(int(S.ch), 0, CH.size() - 1)
        for k in ["slime", "base", "shards", "dg", "guild", "gbase"]:
            S[k] = int(S[k])
        if not (S.boss is Dictionary):
            S.boss = {}

# ---------- เป้าหมาย ----------
func cur() -> Dictionary:
    return CH[int(S.ch)]

## [ทำได้, ต้องทำ] · [] = ไม่มีเป้าหมาย
func need() -> Array:
    var c := cur()
    if not c.has("need"):
        return []
    var p = town.player
    var n := int(c.n)
    match str(c.need):
        "slime":
            return [int(S.slime) - int(S.base), n]
        "weapon":
            var w := 0
            if p.eq.has("weapon") and int(p.eq.weapon.t) >= 1:
                w = 1
            return [(1 if p.lv >= 5 else 0) + w, n]
        "cls":
            return [1 if p.cls != "none" else 0, n]
        "dg":
            return [min(int(S.dg), n), n]
        "guild":
            return [max(0, int(S.guild) - int(S.gbase)), n]
    if str(c.need).begins_with("boss:"):
        return [1 if S.boss.has(str(c.need).substr(5)) else 0, n]
    return []

func blocked_reason() -> String:
    var c := cur()
    match str(c.get("need", "")):
        "guild":
            return "เควสกิลด์ยังไม่เปิดในเกม 3D (เร็ว ๆ นี้)"
    return ""

func done() -> bool:
    if int(S.ch) == 0:
        return false
    var n := need()
    return n.size() == 2 and int(n[0]) >= int(n[1])

## เริ่มนับใหม่ตอนรับบท
func _base(i: int) -> void:
    if CH[i].get("need", "") == "slime":
        S.base = S.slime
    if CH[i].get("need", "") == "guild":
        S.gbase = S.guild

# ---------- เหตุการณ์จากระบบอื่น ----------
func on_slime() -> void:
    S.slime = int(S.slime) + 1

func on_boss(zone_id: String) -> void:
    S.boss[zone_id] = true

func on_floor(f: int) -> void:
    S.dg = max(int(S.dg), f)

# ---------- รางวัล ----------
func give(r: Dictionary) -> Array:
    var p = town.player
    var L := []
    if r.has("coin"):
        p.coins += int(r.coin)
        L.append("%d เหรียญ" % int(r.coin))
    for k in ["hpp", "mpp", "estone", "bless", "scroll"]:
        if r.has(k):
            p.inv_add(k, int(r[k]))
            L.append("%s ×%d" % [Items.item_name(k), int(r[k])])
    if r.has("shard"):
        S.shards = int(S.shards) + 1
        L.append("เศษผลึกอรุณ (%d/5)" % int(S.shards))
    if r.has("kit"):
        for id in ["sword0", "axe0", "pick0"]:
            if p.inv_count(id) == 0:
                p.inv_add(id, 1)
        if not p.eq.has("weapon"):
            for it in p.gear:
                if it.k == "sword":
                    p.equip(it)
                    break
        L.append("ดาบ/ขวาน/ที่ขุดแร่หิน")
    if r.has("xp"):
        p.gain_xp(int(r.xp))
        L.append("EXP %d" % int(r.xp))
    return L

# ---------- คุยกับพระราชา ----------
func king_talk() -> void:
    var c := cur()
    if S.st == "report" or int(S.ch) == 0:
        var lines: Array = c.done.duplicate()
        var rw := give(c.get("rw", {}))
        if rw.size() > 0:
            lines[lines.size() - 1] = str(lines.back()) + "\n【รางวัล: " + " · ".join(rw) + "】"
        if c.get("rw", {}).has("end"):
            lines.append("ภาคแรกจบลงแล้ว — เจ้าคือผู้กล้าแห่งเอลโดเรีย")
        S.ch = int(S.ch) + 1
        S.st = "active"
        _base(int(S.ch))
        var n := cur()
        if not n.get("free", false):
            lines.append("📜 " + str(n.t) + " — " + str(n.get("intro", n.d)))
        _dialog(lines, true)
        update_tracker()
        town.player.save_game()
        return
    if c.get("free", false):
        _dialog(["เอลโดเรียสงบสุขได้เพราะเจ้า ผู้กล้า"], false)
        return
    var nd := need()
    var br := blocked_reason()
    _dialog(["ภารกิจ “%s” — %s%s · %s" % [str(c.t).get_slice(": ", 1) if str(c.t).find(": ") >= 0 else c.t, c.d, (" (%d/%d)" % [min(int(nd[0]), int(nd[1])), int(nd[1])]) if nd.size() == 2 else "", br if br != "" else "ข้าเชื่อมั่นในตัวเจ้า"]], false)

## หน้าต่างคำพูดพระราชา (ต่อทีละประโยค)
func _dialog(lines: Array, quest: bool) -> void:
    dlg_lines = lines
    dlg_i = 0
    _show_dialog(quest)

func _show_dialog(quest: bool) -> void:
    town.cur_shop = "king"
    for ch in town.ui_shop_body.get_children():
        ch.queue_free()
    var top := HBoxContainer.new()
    var nm: Label = town._nowrap(town._lbl("พระราชาอัลดริค", 22, Color(1.0, 0.85, 0.45), true))
    nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(nm)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    town.ui_shop_body.add_child(town._lbl(str(dlg_lines[dlg_i]), 19, Color(0.95, 0.93, 0.88)))
    var last := dlg_i >= dlg_lines.size() - 1
    var b: Button = town._btn(("รับภารกิจ" if quest else "ลาก่อน") if last else "▶ ต่อ", true, func():
        if dlg_i < dlg_lines.size() - 1:
            dlg_i += 1
            _show_dialog(quest)
        else:
            town.close_shop()
            if quest and not cur().get("free", false):
                town.field.say_msg("ภารกิจใหม่: " + str(cur().t) + " — " + str(cur().d), 4.0))
    b.custom_minimum_size = Vector2(160, 40)
    town.ui_shop_body.add_child(b)
    var jb: Button = town._btn("บันทึกเนื้อเรื่อง", true, open_journal)
    town.ui_shop_body.add_child(jb)
    town.ui_shop.visible = true
    if town.room == "hall":
        town.rooms.bubble(str(dlg_lines[dlg_i]).get_slice("\n", 0), 3.5)

func open_journal() -> void:
    town.cur_shop = "journal"
    for ch in town.ui_shop_body.get_children():
        ch.queue_free()
    var top := HBoxContainer.new()
    var nm: Label = town._nowrap(town._lbl("บันทึกเนื้อเรื่อง · เศษผลึกอรุณ %d/5" % int(S.shards), 22, Color(1.0, 0.85, 0.45), true))
    nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(nm)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    for i in range(int(S.ch), -1, -1):
        var c: Dictionary = CH[i]
        var now := i == int(S.ch)
        var t := ("▶ " if now else "✓ ") + str(c.t)
        town.ui_shop_body.add_child(town._lbl(t, 17, Color(1.0, 0.9, 0.5) if now else Color(0.6, 0.9, 0.6), true))
        town.ui_shop_body.add_child(town._lbl(str(c.get("intro", c.d)), 14, Color(0.85, 0.82, 0.74)))
        if now and not c.get("free", false):
            var nd := need()
            var g := "เป้าหมาย: " + str(c.d) + ((" (%d/%d)" % [min(int(nd[0]), int(nd[1])), int(nd[1])]) if nd.size() == 2 else "")
            if S.st == "report" or i == 0:
                g += " — กลับไปรายงานพระราชาที่ปราสาท" if i > 0 else ""
            var br := blocked_reason()
            if br != "":
                g += " · " + br
            town.ui_shop_body.add_child(town._lbl(g, 15, Color(1.0, 0.95, 0.7)))
    town.ui_shop.visible = true

# ---------- แถบติดตามภารกิจ + ลูกศรนำทาง ----------
func build_ui(cl: CanvasLayer) -> void:
    tracker = Button.new()
    tracker.flat = true
    tracker.focus_mode = Control.FOCUS_NONE
    tracker.add_theme_font_override("font", town.font_b)
    tracker.add_theme_font_size_override("font_size", 14)
    tracker.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
    tracker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    tracker.add_theme_constant_override("outline_size", 6)
    tracker.anchor_left = 0.5
    tracker.anchor_right = 0.5
    tracker.offset_left = -165
    tracker.offset_right = 165
    tracker.offset_top = 6
    tracker.offset_bottom = 46
    tracker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tracker.pressed.connect(open_journal)
    cl.add_child(tracker)
    arrow = MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(0.7, 1.0, 0.18)
    arrow.mesh = pm
    arrow.material_override = town.M(Color(1.0, 0.85, 0.3), 0.3, 1.5)
    arrow.visible = false
    town.add_child(arrow)
    update_tracker()

func update_tracker() -> void:
    if tracker == null:
        return
    var c := cur()
    if c.get("free", false):
        tracker.text = str(c.t)
        return
    if S.st == "report":
        tracker.text = "%s\n✅ สำเร็จแล้ว! กลับไปรายงานพระราชา" % c.t
        return
    var nd := need()
    tracker.text = "%s\n%s%s" % [c.t, c.d, (" %d/%d" % [min(int(nd[0]), int(nd[1])), int(nd[1])]) if nd.size() == 2 else ""]

## จุดที่ลูกศรชี้ (guideTarget) · Vector3.INF = ไม่ชี้
func guide_target() -> Vector3:
    var c := cur()
    if c.get("free", false):
        return Vector3.INF
    var go := "king" if (S.st == "report" or int(S.ch) == 0) else str(c.get("go", ""))
    var p = town.player
    var in_field: bool = p.position.x < town.OX
    var in_mine: bool = town.mine.cur >= 0
    var gate: Vector3 = town.tw(0.6, 17.0)
    if town.room != "" and town.room != "hall":
        return Vector3.INF
    match go:
        "king":
            if town.room == "hall":
                return Vector3.INF
            if in_mine:
                return town.mine.exit_pos(town.mine.cur)
            return town.tw(22.0, 9.3) if not in_field else gate
        "field":
            return gate if not in_field and not in_mine else Vector3.INF
        "forge", "cls", "guild":
            if in_mine:
                return town.mine.exit_pos(town.mine.cur)
            if in_field:
                return gate
            if go == "cls":
                for n in town.npcs:
                    if n.npc_name == "ปรมาจารย์อาชีพ":
                        return n.global_position
            var did := "gear" if go == "forge" else "guild"
            for d in town.doors:
                if d.id == did:
                    return town.tw(d.p.x, d.p.y)
        "zone", "cave":
            if in_mine:
                return Vector3.INF
            if not in_field:
                return gate
            return town.field.portal_pos if go == "zone" else town.field.dungeon_pos
    return Vector3.INF

func _process(delta: float) -> void:
    if town == null or town.player == null:
        return
    _tick += delta
    if _tick >= 0.5:
        _tick = 0.0
        if S.st == "active" and done():
            S.st = "report"
            town.field.say_msg("ภารกิจสำเร็จ: " + str(cur().t) + " — กลับไปรายงานพระราชาที่ปราสาท", 4.0)
        update_tracker()
    if tracker != null:
        tracker.visible = town.room == "" and not town.ui_shop.visible
    if arrow == null:
        return
    var tg := guide_target()
    var p = town.player
    if tg == Vector3.INF or p.dead or Vector2(tg.x - p.position.x, tg.z - p.position.z).length() < 2.5:
        arrow.visible = false
        return
    arrow.visible = true
    var dir := Vector3(tg.x - p.position.x, 0, tg.z - p.position.z).normalized()
    var t := Time.get_ticks_msec() / 1000.0
    arrow.global_position = p.position + Vector3(0, 0.25, 0) + dir * (1.6 + sin(t * 5.0) * 0.12)
    arrow.rotation = Vector3(PI / 2.0, atan2(dir.x, dir.z), 0)
