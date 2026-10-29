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

## สถานะและรับช่วง
เสร็จเฉพาะชุดโมเดลและฉากพร้อมใช้ ยังไม่ได้เปลี่ยนไอคอนในกระเป๋าหรือ mesh ที่ถือ/ตกพื้นในเกมจริง ไม่ได้ build APK จากงานนี้ เนื่องจาก field/player/model ถูกจองงานต่อสู้ระหว่างเริ่มงาน จึงแยกไฟล์ไว้ไม่ทับงาน
ผู้เชื่อมต่อให้ใช้โมเดลชุดเดียวกันทั้งภาพไอคอนและของดรอป โดยปรับ source/tools/make_icons.gd build(), field._drop/_add_pickup และ mine._drop_item (อย่า material_override ทับ surfaces) แล้วตรวจการเก็บ/จำนวน/เซฟ และ build ด้วยกุญแจแอปที่ใช้อยู่ ห้ามเปลี่ยนไอดีไอเท็มหรือค่าต่อสู้

เทส negative: ถ้าไม่มีฉากทั้ง 18 แบบ all_systems ล้มเหลว 18 ข้อ; หลังเพิ่มตรวจฉากจริง งบสามเหลี่ยม และไม่มีวัสดุโปร่งใส/เรืองแสง ไม่ได้วัด FPS บนอุปกรณ์เจ้าของ

ผลตรวจสุดท้ายบนฐาน Claude 0.33: startup/recovery/combat/visual/all ผ่านทั้งหมด — ALL checks=582 failures=0
