extends Node
## กิลด์นักผจญภัย — บอร์ดเควส (js/031-core.js QST · QT · qGen · qRefresh · questEv · openGuild · qTake · qDrop · qClaim)
## รับได้พร้อมกัน 3 เควส · บอร์ดเปลี่ยนทุก 1 ชั่วโมง (หรือรีเฟรช 20 เหรียญ) · ตกปลายังไม่มีระบบ → ไม่มีเควสตกปลา

## [ชนิด, เป้าหมาย, ชื่อ, จำนวนฐาน, เลเวลต่ำสุด, เลเวลสูงสุด]
const QT := [
    ["kill", "slime", "กำจัดสไลม์", 8, 0, 20], ["kill", "skeleton", "กำจัดโครงกระดูก", 8, 1, 100], ["kill", "zombie", "กำจัดซอมบี้", 8, 1, 100],
    ["kill", "bat", "กำจัดค้างคาว", 8, 5, 100], ["kill", "wolf", "กำจัดหมาป่า", 6, 18, 100], ["kill", "golem", "กำจัดโกเลม", 5, 10, 100],
    ["kill", "wisp", "กำจัดภูต", 6, 25, 100], ["kill", "drake", "กำจัดมังกรเล็ก", 4, 60, 100],
    ["item", "gel", "ส่งเจลสไลม์", 6, 0, 25], ["item", "bone", "ส่งกระดูกเก่า", 6, 1, 100], ["item", "pelt", "ส่งหนังหมาป่า", 4, 18, 100],
    ["mine", "", "ขุดแร่", 6, 3, 100], ["boss", "", "ล้มบอส", 1, 12, 100], ["floor", "", "ลงดันเจี้ยนถึงชั้น", 0, 1, 100],
]

var town
var Q := {"offer": [], "act": [], "hour": -1, "done": 0}

func setup(t) -> void:
    town = t

func load_state(d) -> void:
    Q = {"offer": [], "act": [], "hour": -1, "done": 0}
    if d is Dictionary:
        for k in Q.keys():
            if d.has(k):
                Q[k] = d[k]
        Q.done = int(Q.done)
        Q.hour = int(Q.hour)

func _hour() -> int:
    return int(Time.get_unix_time_from_system() / 3600.0)

func gen() -> Dictionary:
    var p = town.player
    var L: int = p.lv
    var C := []
    for q in QT:
        if L >= int(q[4]) and L <= int(q[5]) + 10:
            C.append(q)
    var q: Array = C[randi() % C.size()]
    var t: String = q[0]
    var n := 0
    if t == "floor":
        n = min(town.mine.DG_MAX, p.dg_max + 1 + randi() % 3)
    else:
        n = max(1, int(round(int(q[3]) * randf_range(0.8, 1.4))))
    var unit := " ชิ้น" if t == "item" else (" ก้อน" if t == "mine" else ("" if t == "floor" else " ตัว"))
    return {"t": t, "k": q[1], "d": "%s %d%s" % [q[2], n, unit], "n": n, "c": 0,
        "coin": int(round((20 + L * 8) * (3 if t == "boss" else (2 if t == "floor" else 1)))),
        "xp": int(round(p.need(L) * (0.35 if t == "boss" else 0.18))),
        "es": 2 if (t == "boss" or t == "floor") else (1 if randf() < 0.5 else 0)}

func refresh(force: bool = false) -> void:
    var h := _hour()
    if force or int(Q.hour) != h or Q.offer.size() < 4:
        Q.hour = h
        Q.offer = [gen(), gen(), gen(), gen()]

## เหตุการณ์จากระบบอื่น: kill (ตระกูลมอน) · mine · boss · floor (ชั้น)
func event(t: String, k = null) -> void:
    for q in Q.act:
        if int(q.c) >= int(q.n):
            continue
        var ch := false
        if t == "kill" and q.t == "kill" and q.k == k:
            q.c = int(q.c) + 1
            ch = true
        elif t == q.t and (t == "mine" or t == "boss"):
            q.c = int(q.c) + 1
            ch = true
        elif t == "floor" and q.t == "floor" and int(k) >= int(q.n):
            q.c = q.n
            ch = true
        if ch and int(q.c) >= int(q.n):
            town.field.say_msg("เควสสำเร็จ: " + str(q.d) + " — กลับไปรับรางวัลที่กิลด์", 3.5)

func is_ok(q: Dictionary) -> bool:
    if q.t == "item":
        return town.player.inv_count(str(q.k)) >= int(q.n)
    return int(q.c) >= int(q.n)

func take(i: int) -> String:
    if Q.act.size() >= 3:
        return "รับเควสได้สูงสุด 3 เควส"
    var q: Dictionary = Q.offer[i]
    Q.offer.remove_at(i)
    if q.t == "floor" and town.player.dg_max >= int(q.n):
        q.c = q.n
    Q.act.append(q)
    Q.offer.append(gen())
    return "รับเควส: " + str(q.d)

func drop(i: int) -> void:
    Q.act.remove_at(i)

func claim(i: int) -> String:
    var p = town.player
    var q: Dictionary = Q.act[i]
    if not is_ok(q):
        return "ยังไม่สำเร็จ"
    if q.t == "item":
        p.inv_take(str(q.k), int(q.n))
    Q.act.remove_at(i)
    Q.done = int(Q.done) + 1
    town.story.S.guild = int(town.story.S.guild) + 1
    p.coins += int(q.coin)
    if int(q.es) > 0:
        p.inv_add("estone", int(q.es))
    p.gain_xp(int(q.xp))
    return "รับรางวัลเควส: %d เหรียญ · EXP %d%s" % [int(q.coin), int(q.xp), (" · หินเสริมพลัง ×%d" % int(q.es)) if int(q.es) > 0 else ""]

func open() -> void:
    refresh()
    var p = town.player
    town.cur_shop = "quest"
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl("กิลด์นักผจญภัย — บอร์ดเควส", 22, Color(1.0, 0.85, 0.45), true)))
    hv.add_child(town._lbl("รับได้พร้อมกัน 3 เควส · เควสใหม่ทุก 1 ชั่วโมง (หรือรีเฟรช 20 เหรียญ) · ทำสำเร็จแล้ว %d เควส" % int(Q.done), 13, Color(0.85, 0.82, 0.74)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    town.ui_shop_body.add_child(town._lbl("เควสที่รับอยู่ (%d/3)" % Q.act.size(), 16, Color(0.95, 0.9, 0.75), true))
    if Q.act.is_empty():
        town.ui_shop_body.add_child(town._lbl("ยังไม่ได้รับเควส", 14, Color(0.75, 0.72, 0.65)))
    for i in Q.act.size():
        var q: Dictionary = Q.act[i]
        var ii: int = i
        var ok := is_ok(q)
        var pr: int = min(p.inv_count(str(q.k)), int(q.n)) if q.t == "item" else int(q.c)
        var btns := []
        if ok:
            btns.append(town._btn("รับรางวัล", true, func(): town.field.say_msg(claim(ii), 3.5); open()))
        btns.append(town._btn("ยกเลิก", true, func(): drop(ii); open()))
        var r: HBoxContainer = town._row(("✅ " if ok else "⏳ ") + "%s  %d/%d" % [q.d, pr, int(q.n)], "รางวัล %d เหรียญ · EXP %d%s" % [int(q.coin), int(q.xp), (" · หินเสริมพลัง ×%d" % int(q.es)) if int(q.es) > 0 else ""], btns)
        town.ui_shop_body.add_child(r)
    town.ui_shop_body.add_child(town._lbl("เควสบนบอร์ด (แตะเพื่อรับ)", 16, Color(0.95, 0.9, 0.75), true))
    for i in Q.offer.size():
        var q: Dictionary = Q.offer[i]
        var ii: int = i
        var b := Button.new()
        b.text = "%s\nรางวัล %d เหรียญ · EXP %d%s" % [q.d, int(q.coin), int(q.xp), (" · หินเสริมพลัง ×%d" % int(q.es)) if int(q.es) > 0 else ""]
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.add_theme_font_override("font", town.font_b)
        b.add_theme_font_size_override("font_size", 14)
        b.focus_mode = Control.FOCUS_NONE
        b.pressed.connect(func(): town.field.say_msg(take(ii)); open())
        town.ui_shop_body.add_child(b)
    var row := HBoxContainer.new()
    row.add_child(town._btn("รีเฟรช (20)", p.coins >= 20, func():
        if p.coins >= 20:
            p.coins -= 20
            refresh(true)
        open()))
    row.add_child(town._btn("ขายของดรอป / แลกของ", true, func(): town.open_shop("guild")))
    town.ui_shop_body.add_child(row)
    town.ui_shop.visible = true
