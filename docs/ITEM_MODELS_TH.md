# ชุดโมเดลไอเท็ม 3D — Codex/Astra 29 ตุลาคม 2026

18 แบบ: ดาบ มีด คทา หน้าไม้ ขวาน พลั่วขุด ยาแดง ยาฟ้า ม้วนกระดาษ ไม้ หิน เหล็ก ทองแดง เงิน ทอง เพชร เหรียญ เจล ไม่มีชุดเกราะ

ไฟล์ฉากอยู่ source/assets/item_models/*.tscn ลากลง Godot ได้ทันที เป็น mesh จริง ไม่ใช่ billboard ภาพเรนเดอร์ใน docs/item-models-preview.png มาจาก Godot Compatibility/llvmpipe บนเครื่องคลาวด์ ไม่ใช่มือถือจริง

รูปร่างกึ่งสมจริงสำหรับมุมกล้องเกม: ใบมีดมีสันและคม ด้ามพันหนัง หน้าไม้มีสาย/ลูกดอก ขวานและพลั่วมีหัวโลหะ ขวดยามีจุก/คอ/ฉลาก กระดาษมีแกนม้วนและตราประทับ ท่อนไม้มีเปลือก/หน้าตัด แร่ใช้ผิวสายแร่จาก NatureKit มี grain บนวัสดุไม้/หนัง/โลหะ ไม่มี transparency/glow/particles ใช้ 92–1152 สามเหลี่ยมต่อชิ้น รวมชิ้นส่วนเป็น mesh เดียวแยก surfaces ตามวัสดุ

## เรียกใช้
```gdscript
const ItemModels = preload("res://scripts/item_model_kit.gd")
var visual = ItemModels.instance("sword")
add_child(visual)
# หรือโหลด PackedScene:
var loot = preload("res://assets/item_models/iron.tscn").instantiate()
add_child(loot)
```
mesh(id) แชร์ mesh/material ใน runtime; instance(id) สร้าง node ใหม่ อาวุธ pivot ตรงด้ามและแนว +Y; หน้าไม้ยิงแนว -Z ของดรอป pivot ตรงกลาง ต้องตั้ง scale/rotation ตามกระดูกมือหรือก้อนของเดิมก่อนผูก

สร้างฉากซ้ำ: godot --headless --path source --script res://tools/export_item_models.gd
ภาพรวม: godot --path source --script res://tools/preview_item_models.gd (เขียน user://item-models-preview.png)

## สถานะและรับช่วง (อัปเดตหลังเชื่อมเกม)
เชื่อมโมเดลจริงเข้ากับ field._drop, field._add_pickup และ mine._drop_item แล้ว: เหรียญ เจล ไม้ หิน เหล็ก ทองแดง เงิน ทอง และเพชร รักษารหัสเพชร `gem` จำนวนของ ความเร็ว/ระยะเก็บ และ RNG เกมเดิม ไม่ material_override ทับวัสดุหลาย surface

สร้างไอคอนใหม่ 18 ไฟล์จากโมเดลเดียวกันด้วย make_icons.gd -- --item-models-only ได้แก่ sword0/staff0/bow0/axe0/pick0/hpp/mpp/hp/mp/scroll/wood/stone/iron/copper/silver/gold/gem/gel ชุดเกราะและไอคอนระดับสูงคงเดิม

ยังไม่เปลี่ยน mesh ของอาวุธที่ติดกระดูกมือ (model.gd/player.gd) ไม่ได้อัปเดต APK หรือเว็บจากงานไอเท็มนี้ เว็บ PCK export ผ่านในเครื่องแต่ยังไม่เผยแพร่ หากผู้ถือกุญแจเดิมจะ build ให้ใช้ source ล่าสุด ไม่ต้องทำโมเดลใหม่

ตรวจจริง: ชุดทดสอบก่อนเชื่อมพบ failure ของดรอป/วัสดุ/ของพื้น; หลังเชื่อม startup/recovery/combat/visual/all ผ่าน — ALL checks=632 failures=0 ตรวจรูปไอคอนที่เรนเดอร์ออกมาแล้ว ไม่มีการวัด FPS บนมือถือเจ้าของ
