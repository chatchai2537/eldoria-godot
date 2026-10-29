extends RefCounted
## ไอเท็มและผลของการซื้อ/ใช้ (ค่าตามร้านในเกม 2D: data/town.json → shops[].buy)
## ชนิด: "equip" ใส่ทันที · "bag" เก็บเข้ากระเป๋า · "now" ใช้ทันทีตอนซื้อ · "skill" เรียนสกิล
## ไม่มีในตาราง BUY = ระบบนั้นยังไม่มี → ปุ่ม "เร็ว ๆ นี้" (ไม่ขายของที่ใช้ไม่ได้)
## ของที่ HIDE = ระบบที่เจ้าของเลิกแล้ว (ที่ดิน/ฟาร์ม) ไม่แสดงในร้าน

const SWATK := [0, 2, 3, 5, 8, 12, 4, 9, 15, 22, 30, 40]  # js/015-core.js โจมตีดาบตามระดับ · 6-11 = ชุดบอส fix59 (st[0])

const BUY := {
    # ร้านอาวุธลุงเหล็ก
    "g_sword0": {"type": "equip", "item": "sword0", "tier": 0},
    "g_staff0": {"type": "equip", "item": "staff0", "tier": 0},
    "g_bow0": {"type": "equip", "item": "bow0", "tier": 0},
    "g_axe0": {"type": "bag", "item": "axe0"},
    "g_pick0": {"type": "bag", "item": "pick0"},
    # ร้านยาหมอใจดี
    "buyhpp": {"type": "bag", "item": "hpp"},
    "buympp": {"type": "bag", "item": "mpp"},
    "hp": {"type": "now", "hp": 50},
    "mp": {"type": "now", "mp": 30},
    "phoenix": {"type": "bag", "item": "phoenix"},
    # ร้านชำป้าแดง
    "scroll": {"type": "bag", "item": "scroll"},
    "bottle": {"type": "bag", "item": "bottle"},
    "bread": {"type": "bag", "item": "bread"},
    "apple": {"type": "bag", "item": "apple"},
    "rod": {"type": "bag", "item": "rod"},
    "rod2": {"type": "bag", "item": "rod2"},
    # โรงเตี๊ยม
    "beer": {"type": "now", "hp": 15},
    "soup": {"type": "now", "hp": 10},
    "rest": {"type": "now", "hp": 9999, "mp": 9999},
    # ร้านสกิล (ใช้ได้ตอนยังไม่มีอาชีพ)
    "bsk0": {"type": "skill", "skill": "whirl"},
    "bsk1": {"type": "skill", "skill": "fireball"},
    "bsk2": {"type": "skill", "skill": "heal"},
    # กิลด์นักผจญภัย: แลกของ (cost = วัตถุดิบที่ต้องใช้ + ราคาเหรียญในร้าน)
    "gx_estone": {"type": "trade", "item": "estone", "cost": {"core": 2, "dust": 2}},
    "gx_estone2": {"type": "trade", "item": "estone", "cost": {"bone": 6, "rag": 4}},
    "gx_bless": {"type": "trade", "item": "bless", "cost": {"scale": 3}},
    "gx_phoenix": {"type": "trade", "item": "phoenix", "cost": {"wing": 8, "pelt": 4}},
    # แผงอาหาร
    "f_carrot": {"type": "bag", "item": "f_carrot"},
    "f_cabbage": {"type": "bag", "item": "f_cabbage"},
    "f_corn": {"type": "bag", "item": "f_corn"},
    "f_apple": {"type": "bag", "item": "f_apple"},
    "f_orange": {"type": "bag", "item": "f_orange"},
    "f_grape": {"type": "bag", "item": "f_grape"},
    "f_banana": {"type": "bag", "item": "f_banana"},
    "f_bread": {"type": "bag", "item": "bread"},
    "f_pie": {"type": "bag", "item": "f_pie"},
    "f_cake": {"type": "bag", "item": "f_cake"},
    "f_pumpkin": {"type": "bag", "item": "f_pumpkin"},
    "f_honey": {"type": "bag", "item": "f_honey"},
}

## ระบบที่เจ้าของเลิกแล้ว: ไม่แสดงในร้าน
const HIDE := ["f_egg", "f_milk", "f_tomato", "f_wheat", "f_strawberry", "gs146_opt111", "gs146_lock130"]  # ฟาร์ม · สุ่มออปชั่นซ้ำ/ล็อคออป (เจ้าของเลิกแล้ว)

## ใช้ไอเท็ม: hp/mp = เพิ่มตรง ๆ · hpp/mpp = เพิ่มเป็น % ของสูงสุด · buff = {สเตตัส: ค่า} นาน sec วินาที
## "อิ่ม" และ "แรง" ของเกม 2D ยังไม่มีระบบ (รอเจ้าของตอบ) → ใส่ไว้ใน note
const ITEM := {
    "gel": {"name": "เจลสไลม์"},
    "stone": {"name": "หินธรรมดา"},
    "wood": {"name": "ไม้"},
    "sword0": {"name": "ดาบหินธรรมดา"},
    "staff0": {"name": "คทาหินธรรมดา"},
    "bow0": {"name": "หน้าไม้หินธรรมดา"},
    "axe0": {"name": "ขวานหินธรรมดา", "note": "มีในกระเป๋า = หันหน้าเข้าต้นไม้แล้วกดตีเพื่อตัดไม้ (1 หน่วย/ที)"},
    "pick0": {"name": "ที่ขุดแร่หินธรรมดา", "note": "มีในกระเป๋า = หันเข้าก้อนแร่ในเหมืองแล้วกดตีเพื่อขุด (ขุดหิน/เหล็กได้)"},
    "iron": {"name": "แร่เหล็ก"},
    "copper": {"name": "แร่ทองแดง"},
    "silver": {"name": "แร่เงิน"},
    "gold": {"name": "แร่ทอง"},
    "gem": {"name": "เพชร"},
    "coal": {"name": "ถ่าน"},
    "rod": {"name": "คันเบ็ดไม้", "note": "ยืนริมน้ำในทุ่งหญ้า หันเข้าน้ำ แล้วกดตีเพื่อตกปลา"},
    "rod2": {"name": "คันเบ็ดเหล็กชั้นดี", "note": "ปลาหายากขึ้นง่าย · ช่องดึงปลากว้างขึ้น"},
    "carp": {"name": "ปลาตะเพียน", "use": {"hpp": 4}, "note": "อิ่ม +10 · เลือด +4%"},
    "tilapia": {"name": "ปลานิล", "use": {"hpp": 5}, "note": "อิ่ม +12 · เลือด +5%"},
    "catfish": {"name": "ปลาดุก", "use": {"hpp": 6}, "note": "อิ่ม +16 · เลือด +6%"},
    "salmon": {"name": "ปลาแซลมอน", "use": {"mpp": 15, "buff": {"int": 3}, "sec": 120}, "note": "อิ่ม +22 · มานา +15% · INT +3 120 วิ"},
    "goldfish": {"name": "ปลาทองคำ", "use": {"hpp": 20}, "note": "อิ่ม +15 · เลือด +20% · ขายได้แพง"},
    "dragon": {"name": "ปลามังกรฟ้า", "use": {"hpp": 40, "buff": {"str": 3, "vit": 3, "int": 3, "agi": 3, "end": 3}, "sec": 240}, "note": "ปลาในตำนาน · เลือด +40% · ทุกสเตตัส +3 240 วิ"},
    "ingSt": {"name": "แท่งหิน"},
    "estone": {"name": "หินเสริมพลัง", "note": "ใช้ตีบวกอุปกรณ์ · ได้จากบอสเหมือง หรือแลกที่กิลด์"},
    "bless": {"name": "หินอวยพร", "note": "ตีบวกพลาดแล้วของไม่แตก (ใช้อัตโนมัติ)"},
    "bone": {"name": "กระดูกเก่า"},
    "rag": {"name": "ผ้าเน่าซอมบี้"},
    "pelt": {"name": "หนังหมาป่า"},
    "wing": {"name": "ปีกค้างคาว"},
    "shell": {"name": "เปลือกด้วง"},
    "core": {"name": "แกนหินเวท"},
    "dust": {"name": "ผงวิญญาณ"},
    "scale": {"name": "เกล็ดมังกร"},
    # ตราอสูร (fix62): ได้จากบอสตำนาน · 10 อันแลกชิ้นชุดบอสที่แท่นผนึกอสูร
    "lbm0": {"name": "ตราอสูร: ราชาพฤกษาหนาม", "note": "สะสม 10 อันแลกชิ้นชุดหนามพงไพรที่แท่นผนึกอสูร"},
    "lbm1": {"name": "ตราอสูร: นาคราชอสรพิษ", "note": "สะสม 10 อันแลกชิ้นชุดเกล็ดอสรพิษที่แท่นผนึกอสูร"},
    "lbm2": {"name": "ตราอสูร: ราชันย์หมาป่าเหมันต์", "note": "สะสม 10 อันแลกชิ้นชุดเขี้ยวเหมันต์ที่แท่นผนึกอสูร"},
    "lbm3": {"name": "ตราอสูร: ฟาโรห์อมตะสุริยัน", "note": "สะสม 10 อันแลกชิ้นชุดฟาโรห์สุริยันที่แท่นผนึกอสูร"},
    "lbm4": {"name": "ตราอสูร: มังกรโลหิตโบราณ", "note": "สะสม 10 อันแลกชิ้นชุดมังกรโลหิตที่แท่นผนึกอสูร"},
    "lbm5": {"name": "ตราอสูร: จักรพรรดิเงานิรันดร์", "note": "สะสม 10 อันแลกชิ้นชุดจักรพรรดิเงาที่แท่นผนึกอสูร"},
    "ingot": {"name": "แท่งเหล็ก"},
    "ingCu": {"name": "แท่งทองแดง"},
    "ingAg": {"name": "แท่งเงิน"},
    "ingAu": {"name": "แท่งทอง"},
    "ingDm": {"name": "แท่งเพชร"},
    "hpp": {"name": "ยาเลือด (ขวด)", "use": {"hp": 60}},
    "mpp": {"name": "ยามานา (ขวด)", "use": {"mp": 40}},
    "phoenix": {"name": "ขนนกฟีนิกซ์", "note": "ตายแล้วฟื้นทันทีตรงที่ล้ม (ใช้อัตโนมัติ)"},
    "scroll": {"name": "ม้วนวาปกลับเมือง", "use": {"warp": true}},
    "bottle": {"name": "ขวดเปล่า", "note": "ไว้ปรุงยาที่ร้านหมอยา (ระบบปรุงยากำลังมา)"},
    "apple": {"name": "แอปเปิ้ล", "use": {"hp": 5}, "note": "อิ่ม +12"},
    "bread": {"name": "ขนมปังอุ่น ๆ", "use": {"food": true}, "note": "อิ่ม +25 (รอระบบความหิว)"},
    "f_carrot": {"name": "แครอท", "use": {"buff": {"agi": 3}, "sec": 120}, "note": "อิ่ม +12 · AGI +3 120 วิ"},
    "f_cabbage": {"name": "กะหล่ำปลี", "use": {"hpp": 8}, "note": "อิ่ม +18 · เลือด +8%"},
    "f_corn": {"name": "ข้าวโพดหวาน", "use": {"food": true}, "note": "อิ่ม +22 · แรง +15 (รอระบบความหิว/แรง)"},
    "f_apple": {"name": "แอปเปิ้ล (แผง)", "use": {"hpp": 5}, "note": "อิ่ม +12 · เลือด +5%"},
    "f_orange": {"name": "ส้มสายน้ำผึ้ง", "use": {"buff": {"end": 3}, "sec": 90}, "note": "อิ่ม +10 · แรง +25 · END +3 90 วิ"},
    "f_grape": {"name": "องุ่นม่วง", "use": {"mpp": 20}, "note": "อิ่ม +8 · มานา +20%"},
    "f_banana": {"name": "กล้วยหอม", "use": {"food": true}, "note": "อิ่ม +15 · แรง +40 (รอระบบความหิว/แรง)"},
    "f_pie": {"name": "พายเนื้อ", "use": {"buff": {"str": 4}, "sec": 180}, "note": "อิ่ม +50 · STR +4 180 วิ"},
    "f_cake": {"name": "เค้กผลไม้", "use": {"buff": {"str": 2, "vit": 2, "agi": 2, "end": 2}, "sec": 150}, "note": "อิ่ม +35 · STR VIT AGI END +2 150 วิ"},
    "f_pumpkin": {"name": "ฟักทอง", "use": {"hpp": 15}, "note": "อิ่ม +40 · เลือด +15%"},
    "f_honey": {"name": "น้ำผึ้งป่า", "use": {"hpp": 10, "buff": {"vit": 4}, "sec": 180}, "note": "อิ่ม +10 · เลือด +10% · VIT +4 180 วิ"},
}

## สกิลพื้นฐาน (ร้านสกิล · ใช้ได้ตอนยังไม่มีอาชีพ)
const SKILL := {
    "whirl": {"name": "ฟันวงพายุ", "mp": 10, "cd": 4.0, "mult": 1.3, "radius": 2.6},
    "fireball": {"name": "ลูกไฟ", "mp": 8, "cd": 2.5, "mult": 1.6, "range": 17.5, "speed": 18.0},
    "heal": {"name": "เยียวยา", "mp": 15, "cd": 8.0, "heal_pct": 25},
}
const SKILL_ORDER := ["whirl", "fireball", "heal"]

## อาวุธยิงไกล ตามชนิด (fix43 ระยะ: คทา 280px · ธนู 360px)
const RANGED := {
    "staff": {"stat": "int", "range": 17.5, "speed": 20.0, "kind": "bolt"},
    "bow": {"stat": "agi", "range": 22.5, "speed": 26.0, "kind": "arrow"},
}

# ---------- อุปกรณ์ / คราฟ / ตีบวก (js/015-core.js · 031-core.js furnace/anvil · v4.7 ENHCFG · GAME_DESIGN.md) ----------
## ไอดีอุปกรณ์ = ชนิด + ระดับ เช่น sword0 · helm3 · pick5 · ของแต่ละชิ้นเก็บเป็น {k,t,q,e,b} (q = คุณภาพ · e = ตีบวก · b = แตก)
const KINDS := {"sword": "ดาบ", "staff": "คทา", "bow": "หน้าไม้", "axe": "ขวาน", "pick": "ที่ขุดแร่", "helm": "หมวก", "chest": "เสื้อเกราะ", "pants": "กางเกง", "arm": "เกราะแขน", "neck": "สร้อย", "ring": "แหวน"}
const KIND_ORDER := ["sword", "staff", "bow", "axe", "pick", "helm", "chest", "pants", "arm", "neck", "ring"]
const SLOT_OF := {"sword": "weapon", "staff": "weapon", "bow": "weapon", "helm": "helm", "chest": "chest", "pants": "pants", "arm": "arm", "neck": "neck", "ring": "ring"}
const SLOTS := ["weapon", "helm", "chest", "pants", "arm", "neck", "ring"]
const SLOT_NAMES := {"weapon": "อาวุธ", "helm": "หมวก", "chest": "เสื้อ", "pants": "กางเกง", "arm": "มือรอง", "neck": "สร้อย", "ring": "แหวน"}
## ระดับ 0-5 = คราฟได้ · 6-11 = ชุดดรอปจากบอส (fix59 B59 · คราฟไม่ได้ · ขายร้านไม่ได้ · ต้องถึงเลเวลของชุด)
const TNAMES := ["หินธรรมดา", "เหล็ก", "ทองแดง", "เงิน", "ทอง", "เพชร", "หนามพงไพร", "เกล็ดอสรพิษ", "เขี้ยวเหมันต์", "ฟาโรห์สุริยัน", "มังกรโลหิต", "จักรพรรดิเงา"]
const ADEF := {"helm": [1, 2, 3, 4, 5, 7, 3, 5, 8, 11, 14, 19], "chest": [2, 3, 5, 6, 8, 11, 5, 8, 13, 18, 23, 30], "pants": [1, 2, 3, 4, 5, 7, 3, 5, 8, 11, 14, 19], "arm": [1, 1, 2, 3, 4, 6, 2, 4, 7, 10, 13, 17]}
const NECKHP := [6, 12, 20, 30, 45, 70, 22, 50, 95, 150, 210, 310]
const RINGATK := [0, 1, 2, 3, 4, 6, 2, 5, 8, 12, 17, 24]
const MATKEY := ["ingSt", "ingot", "ingCu", "ingAg", "ingAu", "ingDm", "ingDm", "ingDm", "ingDm", "ingDm", "ingDm", "ingDm"]
const BOSS_T0 := 6
const BOSS_LV := [10, 25, 45, 65, 85, 110]
const RARITY := [["ทั่วไป", "#c8c8d8"], ["ไม่ธรรมดา", "#7ad86a"], ["หายาก", "#5ab4ff"], ["ฮีโร่", "#c88aff"], ["ตำนาน", "#ffb03a"], ["ตำนาน", "#ffb03a"]]
const BOSS_PIECES := ["sword", "staff", "bow", "helm", "chest", "pants", "arm", "neck", "ring"]

static func is_boss_tier(t: int) -> bool:
    return t >= BOSS_T0

## เลเวลที่ต้องมีจึงสวมได้ (ชุดบอสเท่านั้น)
static func req_lv(t: int) -> int:
    return BOSS_LV[t - BOSS_T0] if t >= BOSS_T0 else 0

## โบนัสชุด (js/031-core.js SETB · fix59 sb · fix111 นับ 7 ช่อง: 3 ชิ้น = ขั้น 1 · 5 ชิ้น = ขั้น 2 · 7 ชิ้น = ดาเมจ/เลือด +%)
const SETB := [
    [{"vit": 1}, {"end": 3}, "วิ่งได้นานขึ้น"], [{"vit": 2}, {"str": 2, "vit": 3}, "ถึกขึ้น"], [{"end": 3}, {"agi": 4, "end": 4}, "วิ่งไว วิ่งนาน"],
    [{"int": 4}, {"str": 4, "agi": 3}, "ฟันแรง คริแรง"], [{"str": 3}, {"str": 6, "vit": 5}, "นักรบทองคำ"], [{"vit": 6}, {"str": 10, "vit": 10, "end": 8, "agi": 5}, "ชุดในตำนาน"],
    [{"vit": 3}, {"vit": 5, "str": 3}, "ผู้พิทักษ์ป่า"], [{"agi": 5}, {"agi": 8, "str": 5}, "พิษอสรพิษ"], [{"vit": 6, "int": 4}, {"vit": 10, "str": 6, "agi": 6}, "ราชันย์หมาป่าน้ำแข็ง"],
    [{"int": 8, "vit": 6}, {"int": 14, "str": 10, "vit": 10}, "บุตรแห่งดวงอาทิตย์"], [{"str": 12, "vit": 8}, {"str": 20, "vit": 16, "agi": 10}, "เลือดมังกรเดือด"], [{"str": 14, "int": 14}, {"str": 24, "vit": 22, "agi": 16, "int": 20}, "ผู้ครองห้วงเงา"]]

## ระดับในเกม 2D (ใช้คิดค่าเต็มเซ็ต/สร้อย+แหวน): คราฟ 0-5 · ชุดบอส 11-16
static func t2d(t: int) -> int:
    return t if t < BOSS_T0 else 11 + (t - BOSS_T0)

static func _addst(o: Dictionary, add: Dictionary) -> void:
    for k in add:
        o[k] = int(o.get(k, 0)) + int(add[k])

## ---- ชุดประจำอาชีพ (0.29 · docs/PLAN_4CLASS_TH.md ข้อ 3) ----
## 4 ชิ้นหลัก: อาวุธประจำสาย + หมวก + เสื้อ + มือรอง (ช่องแขน) ระดับหลอมเดียวกัน (0-5) · 2 ชิ้น / 4 ชิ้น
## ซ้อนกับโบนัสชุดตามแร่ 3/5/7 ชิ้นเดิม (SETB) · สายย่อยใช้ชุดของสายหลัก
const CSET := {
    "sword": {"n": "ชุดอัศวิน", "w": "sword", "off": "โล่", "b2": {"vit": [2, 2]}, "b4": {"str": [2, 2]}, "hp": 0.05, "dmg": 0.0, "txt": "เลือด +5%"},
    "archer": {"n": "ชุดพรานหน้าไม้", "w": "bow", "off": "ซองลูกศร", "b2": {"agi": [2, 2]}, "b4": {"agi": [2, 2]}, "hp": 0.0, "dmg": 0.05, "txt": "ดาเมจ +5%"},
    "mage": {"n": "ชุดจอมเวท", "w": "staff", "off": "คัมภีร์", "b2": {"int": [3, 2]}, "b4": {"int": [3, 2], "vit": [1, 1]}, "hp": 0.0, "dmg": 0.04, "txt": "ดาเมจ +4%"},
    "rogue": {"n": "ชุดเงาจันทร์", "w": "sword", "off": "มีดซ้าย", "b2": {"agi": [2, 1], "str": [1, 1]}, "b4": {"str": [2, 2]}, "hp": 0.0, "dmg": 0.06, "txt": "ดาเมจ +6%"},
}
const CSET_SLOTS := ["weapon", "helm", "chest", "arm"]

static func _cst(b: Dictionary, t: int) -> Dictionary:
    var o := {}
    for k in b:
        o[k] = int(b[k][0]) + int(b[k][1]) * t
    return o

## นับชิ้นชุดประจำอาชีพ: คืน [ระดับ, จำนวนชิ้น] ของระดับที่ใส่มากที่สุด
static func class_set_count(eq: Dictionary, base: String) -> Vector2i:
    if not CSET.has(base):
        return Vector2i(-1, 0)
    var best := Vector2i(-1, 0)
    for tt in BOSS_T0:
        var n := 0
        for sl in CSET_SLOTS:
            if eq.has(sl) and int(eq[sl].t) == tt and (sl != "weapon" or str(eq[sl].k) == str(CSET[base].w)):
                n += 1
        if n > best.y:
            best = Vector2i(tt, n)
    return best

## โบนัสจากของที่สวม: {st:{str..}, dmg, hp, lines:[ข้อความ]} · base = สายหลักของอาชีพ (ไม่ส่ง = ไม่คิดชุดอาชีพ)
static func set_info(eq: Dictionary, base: String = "") -> Dictionary:
    var st := {}
    var dmg := 0.0
    var hp := 0.0
    var lines := []
    var c := {}
    for sl in SLOTS:
        if eq.has(sl):
            var t := int(eq[sl].t)
            c[t] = int(c.get(t, 0)) + 1
    for t in c:
        var n: int = c[t]
        if n < 3:
            continue
        var S: Array = SETB[t]
        _addst(st, S[0])
        var ln := "ชุด%s %d/7: %s" % [TNAMES[t], n, _sttxt(S[0])]
        if n >= 5:
            _addst(st, S[1])
            ln += " · %s (%s)" % [_sttxt(S[1]), S[2]]
        if n >= 7:
            var f: float = snappedf(0.03 + t2d(t) * 0.0025, 0.001)
            dmg += f
            hp += f
            ln += " · ครบชุด ดาเมจ/เลือด +%.1f%%" % (f * 100.0)
        lines.append(ln)
    var cs := class_set_count(eq, base)
    if cs.y >= 2:
        var C: Dictionary = CSET[base]
        var b2 := _cst(C.b2, cs.x)
        _addst(st, b2)
        var b4 := _cst(C.b4, cs.x)
        var cl := ""
        if cs.y >= 4:
            _addst(st, b4)
            dmg += float(C.dmg)
            hp += float(C.hp)
            var tot := b2.duplicate()
            _addst(tot, b4)
            cl = "%s%s ครบ 4/4: %s · %s" % [C.n, TNAMES[cs.x], _sttxt(tot), C.txt]
        else:
            cl = "%s%s %d/4: %s (ครบ 4 ชิ้นได้เพิ่ม %s · %s)" % [C.n, TNAMES[cs.x], cs.y, _sttxt(b2), _sttxt(b4), C.txt]
        lines.append(cl)
    if eq.has("neck") and eq.has("ring") and int(eq.neck.t) == int(eq.ring.t):
        var tt := t2d(int(eq.neck.t))
        var nr := {"int": 2 + tt * 2, "agi": 1 + tt}
        _addst(st, nr)
        lines.append("สร้อย+แหวนชุดเดียวกัน: " + _sttxt(nr))
    return {"st": st, "dmg": dmg, "hp": hp, "lines": lines}

static func _sttxt(o: Dictionary) -> String:
    var a := []
    for k in o:
        a.append("%s +%d" % [str(k).to_upper(), int(o[k])])
    return " · ".join(a)
const RECIPE := {"sword": [3, 1], "staff": [3, 2], "bow": [2, 3], "axe": [3, 2], "pick": [3, 2], "helm": [3, 0], "chest": [5, 0], "pants": [4, 0], "arm": [3, 0], "neck": [2, 0], "ring": [1, 0]}  # [แท่ง, ไม้]
## เตาหลอม: แร่ n ก้อน + ถ่าน c → แท่ง 1 · เผาถ่าน: ไม้ 2 → ถ่าน 1
const SMELT := [["stone", 3, "ingSt", 1], ["iron", 2, "ingot", 1], ["copper", 2, "ingCu", 1], ["silver", 2, "ingAg", 1], ["gold", 2, "ingAu", 2], ["gem", 2, "ingDm", 2]]
## หม้อปรุงยา (js/030-core.js CRAFT)
const BREW := {"hpp": {"bottle": 1, "gel": 1, "wood": 1}, "mpp": {"bottle": 1, "gel": 2}}
## คุณภาพตอนคราฟ (เจ้าของสั่ง: ขาว → เขียว → ม่วง → แดง · สเตตัสต่ำ→สูง) · โอกาส % = ค่าเสนอ รอเจ้าของอนุมัติ
const QNAMES := ["ขาว", "เขียว", "ม่วง", "แดง"]
const QCOLORS := [Color(0.92, 0.92, 0.9), Color(0.45, 0.9, 0.45), Color(0.78, 0.5, 1.0), Color(1.0, 0.35, 0.3)]
const QCHANCE := [70, 22, 7, 1]
## ตีบวก: อัตราสำเร็จเดิม (js/030-core.js RATE) · สูงสุด +15 · พลาดตั้งแต่ +5 = ของแตก (หินอวยพรกันแตก) · ค่าใช้จ่ายตาม v4.7
const RATE := [100, 95, 90, 80, 70, 60, 50, 45, 40, 35, 30, 25, 20, 15, 10]
const MAXP := 15
const BREAK_FROM := 5

## ไอดีอุปกรณ์ = ชนิด + ระดับ (ระดับ 0-11 · ชุดบอสเป็นเลขสองหลัก เช่น sword10)
static func _split(id: String) -> int:
    var i := id.length()
    while i > 0 and id[i - 1] >= "0" and id[i - 1] <= "9":
        i -= 1
    return i

static func is_gear(id: String) -> bool:
    var i := _split(id)
    if i == 0 or i == id.length() or not KINDS.has(id.substr(0, i)):
        return false
    var t := int(id.substr(i))
    return t >= 0 and t < TNAMES.size() and not (t >= BOSS_T0 and id.substr(0, i) in ["axe", "pick"])

static func gear_kind(id: String) -> String:
    return id.substr(0, _split(id))

static func gear_tier(id: String) -> int:
    return int(id.substr(_split(id)))

static func q_bonus(base: int, q: int) -> int:
    return q * max(1, int(round(base * 0.2))) if q > 0 else 0

## ราคาขายอุปกรณ์ (js/031-core.js gearPrice: GP[ระดับ] × GK[ชนิด] · fix31 ×0.6)
const GP := [8, 24, 50, 100, 200, 420]
const GK := {"sword": 1.0, "staff": 1.0, "bow": 1.0, "axe": 0.8, "pick": 0.8, "helm": 0.8, "chest": 1.4, "pants": 1.0, "arm": 0.7, "neck": 1.1, "ring": 0.9}
static func gear_price(it: Dictionary) -> int:
    if int(it.t) >= GP.size():
        return 0  # ชุดบอส: ร้านไม่รับซื้อ (เกม 2D ไม่มีราคา)
    return max(1, int(round(round(GP[int(it.t)] * float(GK[it.k])) * 0.6)))

static func enh_atk(l: int) -> int:
    return min(l, 5) + max(0, min(l, 10) - 5) * 2 + max(0, l - 10) * 3

static func enh_def(l: int) -> int:
    return int(ceil(enh_atk(l) / 2.0))

## ค่าหลักของอุปกรณ์ 1 ชิ้น (โจมตี / ป้องกัน / เลือด / แรงขุด-ตัด)
static func inst_stat(it: Dictionary) -> int:
    var k := str(it.k)
    var t := int(it.t)
    var q := int(it.get("q", 0))
    var l := int(it.get("e", 0))
    match k:
        "sword", "staff", "bow":
            return SWATK[t] + q_bonus(SWATK[t], q) + enh_atk(l)
        "helm", "chest", "pants", "arm":
            return ADEF[k][t] + q_bonus(ADEF[k][t], q) + enh_def(l)
        "neck":
            return NECKHP[t] + q_bonus(NECKHP[t], q) + l * 6
        "ring":
            return RINGATK[t] + q_bonus(RINGATK[t], q) + int(ceil(enh_atk(l) / 2.0))
        "axe", "pick":
            return 1 + (t >> 1) + l / 3
    return 0

static func stat_label(k: String) -> String:
    match k:
        "sword", "staff", "bow", "ring":
            return "โจมตี"
        "neck":
            return "เลือดสูงสุด"
        "axe":
            return "แรงตัดไม้"
        "pick":
            return "แรงขุด"
    return "ป้องกัน"

## สายหลักของผู้เล่น (player.recalc_stats ตั้งให้) — ใช้ตั้งชื่อตามอาชีพเมื่อไม่ได้ส่ง base มา
static var name_base := ""

## ชื่อชนิดตามอาชีพ: โจรถือ "มีด" (ไอเท็มชนิด sword) · ช่องมือรองตามสาย (โล่/ซองลูกศร/คัมภีร์/มีดซ้าย)
static func kind_name(k: String, base: String = "") -> String:
    var b := base if base != "" else name_base
    if k == "sword" and b == "rogue":
        return "มีด"
    if k == "arm" and CSET.has(b):
        return str(CSET[b].off)
    return str(KINDS[k])

static func inst_name(it: Dictionary, base: String = "") -> String:
    var kn := kind_name(str(it.k), base)
    var n := kn + str(TNAMES[int(it.t)])
    if int(it.get("e", 0)) > 0:
        n += " +%d" % int(it.e)
    return n

## ค่าตีบวก (v4.7 ENHCFG.cost): เหรียญ 50×(l+1)×(l+2) · หินเสริมพลัง 1+(l>>1)
static func enh_cost(l: int) -> Vector2i:
    return Vector2i(50 * (l + 1) * (l + 2), 1 + (l >> 1))

## ซ่อมของแตก (ค่าเสนอ): เหรียญ 30×(ระดับบวก+1)×(ระดับของ+1) + แท่งวัสดุของมัน 1
static func repair_cost(it: Dictionary) -> int:
    return 30 * (int(it.get("e", 0)) + 1) * (int(it.t) + 1)

static func can_buy(id: String) -> bool:
    return BUY.has(id)

static func hidden(id: String) -> bool:
    return HIDE.has(id)

static func item_name(id: String) -> String:
    if is_gear(id):   # อุปกรณ์: ชื่อตามชนิด+ระดับ (โจร = มีด)
        return kind_name(gear_kind(id)) + str(TNAMES[gear_tier(id)])
    return str(ITEM.get(id, {}).get("name", id))
