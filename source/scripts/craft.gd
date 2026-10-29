extends Node
## เตาหลอม · ทั่งตีเหล็ก (คราฟ / ตีบวก / ซ่อม) · หม้อปรุงยา — อยู่ในร้าน (rooms.gd STATIONS)
## เกม 2D: js/031-core.js furnaceHTML smeltX burnCoal anvilHTML craftGear · v4.7 ENHCFG · 030-core.js CRAFT
## กติกาเจ้าของ (GAME_DESIGN.md): คราฟสุ่มคุณภาพ ขาว/เขียว/ม่วง/แดง · ตีบวกแตกได้ มีของกันแตก · ซ่อมก่อนใส่

const Items = preload("res://scripts/items.gd")

var town
var anvil_tab := "craft"
var anvil_tier := 0
var enh_sel := -1        # ของที่เลือกตีบวก (ลำดับใน _enh_list)
var last_q := -1         # คุณภาพของที่คราฟล่าสุด (ไว้ให้เทสดู)

## ตำราช่าง (js/031-core.js SMQ · smithQuest): คราฟระดับไหนได้ต้องรับตำราจากช่างหนวดเหล็ก (ร้านอาวุธ) ก่อน
## ปลดทีละขั้น: ถึงเลเวล → รับเควส → เอาของมาส่ง → ปลดล็อก (player.smith_u = ระดับสูงสุดที่ตีได้)
const SMQ := [{},
    {"lv": 5, "n": "ตำราช่าง: ชุดเหล็ก", "need": {"ingot": 6, "wing": 4}, "w": "แร่เหล็กขุดได้ใน \"เหมืองเหล็กร้าง\" (ประตูมิติในทุ่งหญ้า) และดันเจี้ยนชั้นต้น · หลอมที่เตาหลอมในร้านข้า (ใช้ถ่านจากไม้) · ปีกค้างคาวดรอปจากค้างคาวเหมือง/ค้างคาวในดันเจี้ยน"},
    {"lv": 20, "n": "ตำราช่าง: ชุดทองแดง", "need": {"ingCu": 8, "shell": 6}, "w": "แร่ทองแดงอยู่ใน \"ถ้ำทองแดงลาวา\" · เปลือกด้วงดรอปจากด้วงหินสนิม (เหมืองเหล็ก) และด้วงในดันเจี้ยน"},
    {"lv": 40, "n": "ตำราช่าง: ชุดเงิน", "need": {"ingAg": 10, "pelt": 8}, "w": "แร่เงินอยู่บน \"ยอดเขาเงินหิมะ\" · หนังหมาป่าดรอปจากหมาป่าสำริด/หมาป่าหิมะ"},
    {"lv": 60, "n": "ตำราช่าง: ชุดทอง", "need": {"ingAu": 12, "core": 8}, "w": "แร่ทองอยู่ใน \"สุสานทองคำ\" · แกนหินเวทดรอปจากโกเลมทุกชนิด"},
    {"lv": 80, "n": "ตำราช่าง: ชุดเพชร", "need": {"ingDm": 12, "scale": 4}, "w": "แร่เพชรอยู่ใน \"เหมืองเพชรห้วงลึก\" · เกล็ดมังกรดรอปจากมังกร/ดันเจี้ยนชั้นลึก"}]
var _sm_t := 0.0
var _sm_note := 0

func smith_next() -> int:
    var u: int = town.player.smith_u
    return u + 1 if u < 5 else 0

func smith_avail() -> bool:
    var n := smith_next()
    return n > 0 and town.player.lv >= int(SMQ[n].lv)

func smith_need_txt(n: int) -> String:
    var a := []
    for k in SMQ[n].need:
        a.append("%s %d/%d" % [Items.item_name(str(k)), min(town.player.inv_count(str(k)), int(SMQ[n].need[k])), int(SMQ[n].need[k])])
    return " · ".join(a)

## คุยเรื่องตำรา (smithQuest): ครั้งแรก = รับเควส · ของครบ = ปลดล็อก · คืนข้อความที่ช่างพูด
func smith_act() -> String:
    var p = town.player
    var n := smith_next()
    if n == 0:
        return "เจ้าปลดล็อกตำราครบทุกระดับแล้ว! ไม่มีอะไรที่ข้าสอนเจ้าได้อีก"
    var Q: Dictionary = SMQ[n]
    if p.lv < int(Q.lv):
        return "ตำรา%sยังยากเกินไปสำหรับเจ้า กลับมาเมื่อถึง Lv.%d แล้วข้าจะสอนให้" % [Items.TNAMES[n], int(Q.lv)]
    if p.smith_q != n:
        p.smith_q = n
        return "%s — ถ้าอยากตีชุด%s เอาของพวกนี้มาให้ข้าก่อน: %s" % [Q.n, Items.TNAMES[n], smith_need_txt(n)]
    for k in Q.need:
        if p.inv_count(str(k)) < int(Q.need[k]):
            return "ยังขาดอยู่นะ: " + smith_need_txt(n)
    for k in Q.need:
        p.inv_take(str(k), int(Q.need[k]))
    p.smith_u = n
    p.smith_q = 0
    p.save_game()
    return "ฝีมือเจ้าใช้ได้! หลอมแร่เป็นแท่งที่เตาซ้ายมือ แล้วตีที่ทั่งขวามือ — ตอนนี้เจ้าตีของระดับ%sได้แล้ว" % Items.TNAMES[n]

func smith_label() -> String:
    var n := smith_next()
    return ("! " if smith_avail() else "") + "ตำราช่าง" + ((" (%s)" % Items.TNAMES[n]) if n > 0 else " (ครบแล้ว)")

func open_smith(say: String = "") -> void:
    var p = town.player
    var n := smith_next()
    _head("ตำราช่าง — ช่างหนวดเหล็ก", "ตีของได้ถึงระดับ%s · คราฟระดับสูงขึ้นต้องรับตำราทีละขั้น" % Items.TNAMES[p.smith_u])
    if say != "":
        town.ui_shop_body.add_child(town._lbl("ช่าง: \"" + say + "\"", 15, Color(1.0, 0.9, 0.6)))
    if n > 0:
        var Q: Dictionary = SMQ[n]
        town.ui_shop_body.add_child(town._lbl("%s (ต้อง Lv.%d)" % [Q.n, int(Q.lv)], 18, Color(0.95, 0.92, 0.85), true))
        for k in Q.need:
            town.ui_shop_body.add_child(town._row("%s %d/%d" % [Items.item_name(str(k)), min(p.inv_count(str(k)), int(Q.need[k])), int(Q.need[k])], "", [], str(k)))
        town.ui_shop_body.add_child(town._lbl("หาของได้ที่: " + str(Q.w), 13, Color(0.8, 0.85, 0.95)))
        var lbl := "รับตำรา" if p.smith_q != n else "ส่งของ / เรียนตำรา"
        town.ui_shop_body.add_child(_big(lbl, p.lv >= int(Q.lv), func(): open_smith(smith_act()), Color(1.0, 0.88, 0.4)))
    town.ui_shop_body.add_child(_big("กลับไปหน้าร้าน", true, func(): town.open_shop("gear")))
    town.ui_shop.visible = true

func _process(delta: float) -> void:
    if town == null or town.player == null:
        return
    _sm_t += delta
    if _sm_t < 3.0:
        return
    _sm_t = 0.0
    var n := smith_next()
    if smith_avail() and town.player.smith_q != n and _sm_note != n:
        _sm_note = n
        town.field.say_msg("ช่างหนวดเหล็กมีตำรา%sให้เจ้าแล้ว — ไปที่ร้านอาวุธ" % Items.TNAMES[n], 4.0)

func setup(t) -> void:
    town = t

# ---------- ตรรกะ (เทสเรียกตรงได้) ----------
func burn_coal(n: int) -> String:
    var p = town.player
    var mx: int = p.wood / 2
    n = mx if n < 0 else min(n, mx)
    if n <= 0:
        return "ไม้ไม่พอ: ต้องใช้ไม้ 2 ท่อนต่อถ่าน 1"
    p.wood -= 2 * n
    p.inv_add("coal", n)
    return "เผาถ่านได้ ถ่าน +%d" % n

func smelt_max(i: int) -> int:
    var p = town.player
    var s: Array = Items.SMELT[i]
    return min(p.inv_count(str(s[0])) / int(s[1]), p.inv_count("coal") / int(s[3]))

func smelt(i: int, n: int) -> String:
    var p = town.player
    var s: Array = Items.SMELT[i]
    var mx := smelt_max(i)
    n = mx if n < 0 else min(n, mx)
    if n <= 0:
        if p.inv_count("coal") < int(s[3]):
            return "ไม่มีถ่าน — เอาไม้ไปเผาเป็นถ่านก่อน"
        return "วัตถุดิบไม่พอ: ต้องใช้%s %d + ถ่าน %d" % [Items.item_name(str(s[0])), int(s[1]), int(s[3])]
    p.inv_take(str(s[0]), int(s[1]) * n)
    p.inv_take("coal", int(s[3]) * n)
    p.inv_add(str(s[2]), n)
    return "หลอมได้%s +%d" % [Items.item_name(str(s[2])), n]

func can_craft(kind: String, tier: int) -> bool:
    var p = town.player
    var r: Array = Items.RECIPE[kind]
    return p.inv_count(Items.MATKEY[tier]) >= int(r[0]) and p.wood >= int(r[1])

## สุ่มคุณภาพ (เครื่องมือขวาน/ที่ขุดไม่สุ่ม — เป็นขาวเสมอ)
func roll_quality(kind: String, r: float = -1.0) -> int:
    if kind == "axe" or kind == "pick":
        return 0
    if r < 0.0:
        r = randf() * 100.0
    var acc := 0.0
    for q in range(Items.QCHANCE.size() - 1, 0, -1):
        acc += Items.QCHANCE[q]
        if r < acc:
            return q
    return 0

func craft(kind: String, tier: int) -> String:
    var p = town.player
    var r: Array = Items.RECIPE[kind]
    var mk: String = Items.MATKEY[tier]
    if tier > p.smith_u:
        return "ยังตี%sไม่เป็น — รับตำราจากช่างหนวดเหล็ก ร้านอาวุธ (Lv.%d)" % [Items.TNAMES[tier], int(SMQ[tier].lv)]
    if not can_craft(kind, tier):
        return "วัตถุดิบไม่พอ: ต้องใช้%s %d%s" % [Items.item_name(mk), int(r[0]), (" + ไม้ %d" % int(r[1])) if int(r[1]) > 0 else ""]
    p.inv_take(mk, int(r[0]))
    p.wood -= int(r[1])
    var it: Dictionary = p.make_inst(kind + str(tier), roll_quality(kind))
    last_q = int(it.q)
    p.gear.append(it)
    var qn := "" if kind == "axe" or kind == "pick" else " (คุณภาพ%s)" % Items.QNAMES[last_q]
    return "คราฟ%sสำเร็จ!%s %s %d" % [Items.inst_name(it), qn, Items.stat_label(kind), Items.inst_stat(it)]

## ตีบวก: สำเร็จตาม RATE · พลาดต่ำกว่า +5 เสียแค่ของที่ใช้ · พลาดตั้งแต่ +5 ของแตก (มีหินอวยพร = ไม่แตก ใช้หิน 1)
## ของแตก: ถ้าสวมอยู่ ถอดเข้ากระเป๋าทันที · ใส่ไม่ได้จนกว่าจะซ่อม
func enhance(it: Dictionary, roll: float = -1.0) -> String:
    var p = town.player
    if it.get("b", false):
        return "ของแตกอยู่ — ซ่อมก่อน"
    var l := int(it.e)
    if l >= Items.MAXP:
        return "ถึงระดับสูงสุดแล้ว (+%d)" % Items.MAXP
    var c := Items.enh_cost(l)
    if p.coins < c.x:
        return "เหรียญไม่พอ (ต้องใช้ %d มี %d)" % [c.x, p.coins]
    if p.inv_count("estone") < c.y:
        return "หินเสริมพลังไม่พอ (ต้องใช้ %d มี %d) — ได้จากบอสเหมือง หรือแลกที่กิลด์" % [c.y, p.inv_count("estone")]
    p.coins -= c.x
    p.inv_take("estone", c.y)
    if roll < 0.0:
        roll = randf() * 100.0
    if roll < Items.RATE[l]:
        it.e = l + 1
        p.recalc_stats()
        p.update_gear_visual()
        return "ตีบวกสำเร็จ! %s" % Items.inst_name(it)
    if l < Items.BREAK_FROM:
        return "พลาด… วัตถุดิบหายไป (ของไม่เสียหาย)"
    if p.inv_take("bless", 1):
        return "พลาด… แต่หินอวยพรคุ้มครอง ของไม่แตก (+%d)" % l
    it.b = true
    for sl in p.eq.keys():
        if p.eq[sl] == it:
            p.unequip(sl)
            break
    p.recalc_stats()
    return "ของแตก! %s ถูกถอดเข้ากระเป๋า — ต้องซ่อมก่อนใส่" % Items.inst_name(it)

func repair(it: Dictionary) -> String:
    var p = town.player
    if not it.get("b", false):
        return "ของชิ้นนี้ไม่ได้แตก"
    var cc := Items.repair_cost(it)
    var mk: String = Items.MATKEY[int(it.t)]
    if p.coins < cc or p.inv_count(mk) < 1:
        return "ซ่อมต้องใช้ %d เหรียญ + %s 1" % [cc, Items.item_name(mk)]
    p.coins -= cc
    p.inv_take(mk, 1)
    it.b = false
    return "ซ่อม %s เสร็จแล้ว ใส่ได้ตามเดิม" % Items.inst_name(it)

func brew(c: String) -> String:
    var p = town.player
    var need: Dictionary = Items.BREW[c]
    for k in need:
        if p.inv_count(str(k)) < int(need[k]):
            return "วัตถุดิบไม่พอ: ต้องใช้ %s" % _need_text(need)
    for k in need:
        p.inv_take(str(k), int(need[k]))
    p.inv_add(c, 1)
    return "ปรุง%sสำเร็จ!" % Items.item_name(c)

func _need_text(need: Dictionary) -> String:
    var a := []
    for k in need:
        a.append("%s %d (มี %d)" % [Items.item_name(str(k)), int(need[k]), town.player.inv_count(str(k))])
    return " + ".join(a)

## ของที่ตีบวก/ซ่อมได้: ที่สวมอยู่ + ในกระเป๋า
func enh_list() -> Array:
    var p = town.player
    var L := []
    for sl in Items.SLOTS:
        if p.eq.has(sl):
            L.append(p.eq[sl])
    for it in p.gear:
        L.append(it)
    return L

# ---------- หน้าต่าง ----------
func _head(title: String, sub: String) -> void:
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl(title, 22, Color(1.0, 0.85, 0.45), true)))
    hv.add_child(town._lbl(sub, 14, Color(0.85, 0.82, 0.74)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)

func _big(text: String, ok: bool, cb: Callable, col: Color = Color(0.95, 0.92, 0.85), icon: String = "") -> Button:
    var b := Button.new()
    b.text = town.clean(text)
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.add_theme_font_override("font", town.font_b)
    b.add_theme_font_size_override("font_size", 15)
    b.add_theme_color_override("font_color", col)
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size = Vector2(0, 40)
    var tx: Texture2D = town.icon_tex(icon)
    if tx != null:
        b.icon = tx
        b.add_theme_constant_override("icon_max_width", 36)
    if not ok:
        b.modulate = Color(1, 1, 1, 0.5)
    b.pressed.connect(cb)
    return b

func _msg(t: String) -> void:
    if t != "":
        town.field.say_msg(t, 3.0)

func open(kind: String) -> void:
    town.cur_shop = "stn_" + kind
    if town.ui_bag != null:
        town.ui_bag.visible = false
    match kind:
        "furnace":
            _furnace()
        "anvil":
            _anvil()
        "cauldron":
            _cauldron()
    town.ui_shop.visible = true

func _furnace() -> void:
    var p = town.player
    _head("เตาหลอม", "แร่ต้องหลอมเป็นแท่งก่อนจึงจะคราฟของได้ · หลอมต้องใช้ถ่าน (เผาจากไม้) · ถ่าน %d · ไม้ %d" % [p.inv_count("coal"), p.wood])
    var mx: int = p.wood / 2
    var r := HBoxContainer.new()
    var b1 := _big("เผาถ่าน  ไม้ 2 → ถ่าน 1", mx > 0, func(): _msg(burn_coal(1)); open("furnace"), Color(0.95, 0.92, 0.85), "coal")
    b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    r.add_child(b1)
    r.add_child(town._btn("ทั้งหมด ×%d" % mx, mx > 0, func(): _msg(burn_coal(-1)); open("furnace")))
    town.ui_shop_body.add_child(r)
    for i in Items.SMELT.size():
        var s: Array = Items.SMELT[i]
        var m := smelt_max(i)
        var ii := i
        var row := HBoxContainer.new()
        var b := _big("หลอม%s  ·  %s %d (มี %d) + ถ่าน %d · มีแท่ง %d" % [Items.item_name(str(s[2])), Items.item_name(str(s[0])), int(s[1]), p.inv_count(str(s[0])), int(s[3]), p.inv_count(str(s[2]))], m > 0, func(): _msg(smelt(ii, 1)); open("furnace"), Color(0.95, 0.92, 0.85), str(s[2]))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(b)
        row.add_child(town._btn("ทั้งหมด ×%d" % m, m > 0, func(): _msg(smelt(ii, -1)); open("furnace")))
        town.ui_shop_body.add_child(row)

func _anvil() -> void:
    var p = town.player
    _head("ทั่งตีเหล็ก", "เหรียญ %d · หินเสริมพลัง %d · หินอวยพร %d" % [p.coins, p.inv_count("estone"), p.inv_count("bless")])
    var tabs := HBoxContainer.new()
    for t in [["craft", "คราฟ"], ["enh", "ตีบวก / ซ่อม"]]:
        var tt: String = t[0]
        var b: Button = town._btn(str(t[1]) + (" ◀" if anvil_tab == tt else ""), true, func(): anvil_tab = tt; open("anvil"))
        tabs.add_child(b)
    town.ui_shop_body.add_child(tabs)
    if anvil_tab == "craft":
        var tr := HBoxContainer.new()
        for t in 6:
            var ti := t
            var b: Button = town._btn(Items.TNAMES[t] + (" ◀" if anvil_tier == t else ""), true, func(): anvil_tier = ti; open("anvil"))
            b.custom_minimum_size = Vector2(70, 32)
            b.add_theme_font_size_override("font_size", 13)
            tr.add_child(b)
        town.ui_shop_body.add_child(tr)
        var mk: String = Items.MATKEY[anvil_tier]
        if anvil_tier > p.smith_u:
            town.ui_shop_body.add_child(town._lbl("ยังตีระดับ%sไม่ได้ — คุยกับช่างหนวดเหล็ก → ตำราช่าง (ต้อง Lv.%d)" % [Items.TNAMES[anvil_tier], int(SMQ[anvil_tier].lv)], 15, Color(1.0, 0.55, 0.45), true))
        town.ui_shop_body.add_child(town._lbl("วัสดุ: %s มี %d · ไม้ มี %d · คุณภาพสุ่ม ขาว %d%% · เขียว %d%% · ม่วง %d%% · แดง %d%%" % [Items.item_name(mk), p.inv_count(mk), p.wood, Items.QCHANCE[0], Items.QCHANCE[1], Items.QCHANCE[2], Items.QCHANCE[3]], 14, Color(0.8, 0.85, 0.95)))
        var b0: String = town.classes.base_of(p.cls) if town.classes != null else ""
        if Items.CSET.has(b0):
            var C0: Dictionary = Items.CSET[b0]
            town.ui_shop_body.add_child(town._lbl("★ %s = %s + หมวก + เสื้อ + %s ระดับเดียวกัน · ครบ 2 ชิ้น/4 ชิ้นได้โบนัส (4 ชิ้น: %s)" % [C0.n, Items.kind_name(C0.w, b0), C0.off, C0.txt], 14, Color(1.0, 0.85, 0.45)))
        for k in Items.KIND_ORDER:
            var kk: String = k
            var r: Array = Items.RECIPE[k]
            var it := {"k": k, "t": anvil_tier, "q": 0, "e": 0}
            var own: int = p.inv_count(k + str(anvil_tier))
            var base: String = town.classes.base_of(p.cls) if town.classes != null else ""
            var star := ""
            if Items.CSET.has(base) and (k == Items.CSET[base].w or k in ["helm", "chest", "arm"]):
                star = "★ "   # ชิ้นชุดประจำอาชีพ (0.29)
            var txt := "%s%s%s  ·  %s %d  ·  ใช้%s %d%s" % [star, Items.inst_name(it, base), (" (มี ×%d)" % own) if own > 0 else "", Items.stat_label(k), Items.inst_stat(it), Items.item_name(mk), int(r[0]), (" + ไม้ %d" % int(r[1])) if int(r[1]) > 0 else ""]
            town.ui_shop_body.add_child(_big(txt, can_craft(k, anvil_tier) and anvil_tier <= p.smith_u, func(): _msg(craft(kk, anvil_tier)); open("anvil"), Color(0.95, 0.92, 0.85), town.gear_icon_id(it)))
    else:
        var L := enh_list()
        if L.is_empty():
            town.ui_shop_body.add_child(town._lbl("ยังไม่มีอุปกรณ์ — คราฟหรือซื้อก่อน", 14, Color(0.75, 0.72, 0.65)))
        enh_sel = clampi(enh_sel, 0, max(0, L.size() - 1))
        for i in L.size():
            var it: Dictionary = L[i]
            var ii := i
            var worn := false
            for sl in p.eq:
                if p.eq[sl] == it:
                    worn = true
            var txt := "%s%s%s  ·  %s %d" % [Items.inst_name(it), " [สวมอยู่]" if worn else "", " [แตก]" if it.get("b", false) else "", Items.stat_label(str(it.k)), Items.inst_stat(it)]
            var col: Color = Color(1.0, 0.4, 0.35) if it.get("b", false) else Items.QCOLORS[int(it.q)]
            town.ui_shop_body.add_child(_big(("▶ " if i == enh_sel else "") + txt, true, func(): enh_sel = ii; open("anvil"), col, town.gear_icon_id(it)))
        if not L.is_empty():
            var it: Dictionary = L[enh_sel]
            var l := int(it.e)
            if it.get("b", false):
                var rc := Items.repair_cost(it)
                town.ui_shop_body.add_child(_big("ซ่อม %s  ·  %d เหรียญ + %s 1" % [Items.inst_name(it), rc, Items.item_name(Items.MATKEY[int(it.t)])], true, func(): _msg(repair(it)); open("anvil"), Color(1.0, 0.85, 0.5)))
            elif l < Items.MAXP:
                var c := Items.enh_cost(l)
                var nx := it.duplicate()
                nx.e = l + 1
                var risk := "พลาดเสียแค่ของ" if l < Items.BREAK_FROM else ("พลาด = ของแตก (มีหินอวยพร %d กันได้)" % p.inv_count("bless"))
                town.ui_shop_body.add_child(_big("ตีบวก +%d → +%d  ·  %s %d → %d  ·  สำเร็จ %d%%\n%d เหรียญ + หินเสริมพลัง %d (มี %d) · %s" % [l, l + 1, Items.stat_label(str(it.k)), Items.inst_stat(it), Items.inst_stat(nx), Items.RATE[l], c.x, c.y, p.inv_count("estone"), risk], p.coins >= c.x and p.inv_count("estone") >= c.y, func(): _msg(enhance(it)); open("anvil"), Color(1.0, 0.88, 0.4)))
            else:
                town.ui_shop_body.add_child(town._lbl("ระดับสูงสุดแล้ว +%d" % Items.MAXP, 15, Color(1.0, 0.6, 0.9)))

func _cauldron() -> void:
    _head("หม้อปรุงยา", "ปรุงยาเองแล้วเก็บไว้ในกระเป๋า · ขวดเปล่าซื้อได้ที่ร้านชำป้าแดง")
    for c in ["hpp", "mpp"]:
        var cc: String = c
        var need: Dictionary = Items.BREW[c]
        var ok := true
        for k in need:
            if town.player.inv_count(str(k)) < int(need[k]):
                ok = false
        town.ui_shop_body.add_child(_big("ปรุง%s (มี ×%d)  ·  ใช้ %s" % [Items.item_name(c), town.player.inv_count(c), _need_text(need)], ok, func(): _msg(brew(cc)); open("cauldron"), Color(0.95, 0.92, 0.85), cc))
