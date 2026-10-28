extends RefCounted
## ไอเท็มและผลของการซื้อ/ใช้ (ค่าตามร้านในเกม 2D: data/town.json → shops[].buy)
## ชนิด: "equip" ใส่ทันที · "bag" เก็บเข้ากระเป๋า (ใช้ทีหลัง) · "now" ใช้ทันทีตอนซื้อ · ไม่มีในตาราง = ยังไม่พร้อมขาย
## ของที่ระบบยังไม่มี (ความหิว ตกปลา ขยายกระเป๋า สกิล) ปิดปุ่มซื้อไว้ ไม่ขายของที่ใช้ไม่ได้

const SWATK := [0, 2, 3, 5, 8, 12]  # js/015-core.js โจมตีดาบตามระดับ

## ซื้อแล้วได้อะไร: id สินค้าในร้าน -> ผล
const BUY := {
    "g_sword0": {"type": "equip", "slot": "sword", "item": "sword0", "tier": 0},
    "g_axe0": {"type": "bag", "item": "axe0"},
    "g_pick0": {"type": "bag", "item": "pick0"},
    "buyhpp": {"type": "bag", "item": "hpp"},
    "buympp": {"type": "bag", "item": "mpp"},
    "hp": {"type": "now", "hp": 50},
    "mp": {"type": "now", "mp": 30},
    "phoenix": {"type": "bag", "item": "phoenix"},
    "scroll": {"type": "bag", "item": "scroll"},
    "beer": {"type": "now", "hp": 15},
    "soup": {"type": "now", "hp": 10},
    "rest": {"type": "now", "hp": 9999, "mp": 9999},
}

## ไอเท็มในกระเป๋า: ชื่อไทย · ใช้แล้วได้อะไร (ว่าง = ใช้ไม่ได้/เป็นวัตถุดิบ/เครื่องมือ)
const ITEM := {
    "gel": {"name": "เจลสไลม์"},
    "stone": {"name": "หินธรรมดา"},
    "wood": {"name": "ไม้"},
    "axe0": {"name": "ขวานหินธรรมดา", "note": "มีในกระเป๋า = หันหน้าเข้าต้นไม้แล้วกดตีเพื่อตัดไม้ (1 หน่วย/ที)"},
    "pick0": {"name": "ที่ขุดแร่หินธรรมดา", "note": "ไว้ขุดแร่ (ระบบเหมืองกำลังมา)"},
    "hpp": {"name": "ยาเลือด (ขวด)", "use": {"hp": 60}},
    "mpp": {"name": "ยามานา (ขวด)", "use": {"mp": 40}},
    "phoenix": {"name": "ขนนกฟีนิกซ์", "note": "ตายแล้วฟื้นทันทีตรงที่ล้ม (ใช้อัตโนมัติ)"},
    "scroll": {"name": "ม้วนวาปกลับเมือง", "use": {"warp": true}},
    "sword0": {"name": "ดาบหินธรรมดา"},
    "apple": {"name": "แอปเปิ้ล", "use": {"hp": 5}},
}

static func can_buy(id: String) -> bool:
    return BUY.has(id)

static func item_name(id: String) -> String:
    return str(ITEM.get(id, {}).get("name", id))
