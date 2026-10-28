extends RefCounted
## ไอเท็มและผลของการซื้อ/ใช้ (ค่าตามร้านในเกม 2D: data/town.json → shops[].buy)
## ชนิด: "equip" ใส่ทันที · "bag" เก็บเข้ากระเป๋า · "now" ใช้ทันทีตอนซื้อ · "skill" เรียนสกิล
## ไม่มีในตาราง BUY = ระบบนั้นยังไม่มี → ปุ่ม "เร็ว ๆ นี้" (ไม่ขายของที่ใช้ไม่ได้)
## ของที่ HIDE = ระบบที่เจ้าของเลิกแล้ว (ที่ดิน/ฟาร์ม) ไม่แสดงในร้าน

const SWATK := [0, 2, 3, 5, 8, 12]  # js/015-core.js โจมตีดาบตามระดับ

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
    # โรงเตี๊ยม
    "beer": {"type": "now", "hp": 15},
    "soup": {"type": "now", "hp": 10},
    "rest": {"type": "now", "hp": 9999, "mp": 9999},
    # ร้านสกิล (ใช้ได้ตอนยังไม่มีอาชีพ)
    "bsk0": {"type": "skill", "skill": "whirl"},
    "bsk1": {"type": "skill", "skill": "fireball"},
    "bsk2": {"type": "skill", "skill": "heal"},
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
const HIDE := ["f_egg", "f_milk", "f_tomato", "f_wheat", "f_strawberry"]

## ใช้ไอเท็ม: hp/mp = เพิ่มตรง ๆ · hpp/mpp = เพิ่มเป็น % ของสูงสุด · buff = {สเตตัส: ค่า} นาน sec วินาที
## "อิ่ม" และ "แรง" ของเกม 2D ยังไม่มีระบบ (รอเจ้าของตอบ) → ใส่ไว้ใน note
const ITEM := {
    "gel": {"name": "เจลสไลม์"},
    "stone": {"name": "หินธรรมดา"},
    "wood": {"name": "ไม้"},
    "sword0": {"name": "ดาบหินธรรมดา"},
    "staff0": {"name": "คทาหินธรรมดา"},
    "bow0": {"name": "ธนูหินธรรมดา"},
    "axe0": {"name": "ขวานหินธรรมดา", "note": "มีในกระเป๋า = หันหน้าเข้าต้นไม้แล้วกดตีเพื่อตัดไม้ (1 หน่วย/ที)"},
    "pick0": {"name": "ที่ขุดแร่หินธรรมดา", "note": "ไว้ขุดแร่ (ระบบเหมืองกำลังมา)"},
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

## อาวุธยิงไกล (fix43 ระยะ: คทา 280px · ธนู 360px)
const RANGED := {
    "staff0": {"stat": "int", "range": 17.5, "speed": 20.0, "kind": "bolt"},
    "bow0": {"stat": "agi", "range": 22.5, "speed": 26.0, "kind": "arrow"},
}

static func can_buy(id: String) -> bool:
    return BUY.has(id)

static func hidden(id: String) -> bool:
    return HIDE.has(id)

static func item_name(id: String) -> String:
    return str(ITEM.get(id, {}).get("name", id))
