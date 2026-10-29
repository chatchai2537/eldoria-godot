# ใบงานรับช่วงสำหรับ AI — Eldoria Godot 0.4-modern

อัปเดต: 28 ตุลาคม 2026 โดย Codex

## อ่านตรงนี้ก่อน

เจ้าของสั่งให้ปรับภาพเป็นแนวโมเดิร์นจริงจัง และให้เขียนขั้นตอนเพื่อ AI ตัวอื่นนำขึ้นระบบต่อได้ หากผู้ทำรอบนี้ขึ้นไม่ได้
โปรเจคที่ถูกต้องคือ **chatchai2537/eldoria-godot** ไม่ใช่เกมเว็บ 2D ใน wiwekwin2537-stack/eldoria-game
เว็บจริง: https://chatchai2537.github.io/eldoria-godot/
ฐาน remote ที่อ่านรอบนี้: 903dc46b15b46dc28759a1278522a4e20e166776
ชุด ZIP นี้รวมงาน 0.2 + 0.3 + 0.4 ครบ อย่าเอาเฉพาะภาพไปทับโค้ดเก่าของ remote

**ยังไม่อัปเดต GitHub หรือเว็บจริง**: การเขียน HANDOFF.md ผ่าน GitHub ถูกปฏิเสธ `403 Resource not accessible by integration` แม้เปิดอ่าน repo ได้ ห้ามอ้างว่าขึ้นระบบแล้ว
ต้องแก้สิทธิ์ GitHub App/บัญชีที่เข้าถึง repo นี้ให้เขียน Contents ได้ หรือใช้ git credential ที่เจ้าของให้สิทธิ์กับ repo นี้จริง
อย่าสร้าง repo ใหม่ อย่า force push อย่าแก้ repo เกม 2D แทน

## คำสั่งเจ้าของล่าสุด (มีผลเหนือข้อมูลเก่า)

1. เจ้าของยืนยัน **0.2 เข้าเล่นได้** และยืนยัน **0.3 เล่นดี ไม่แลค** บนมือถือของเขา
2. การตีธรรมดา: กดตีค้างเพื่อยืนฟันท่าเดียวต่อเนื่อง ไม่มีคอมโบ 3 จังหวะ ไม่มีท่าหมุนตีรอบตัว
3. มอนไม่ต้องกระเด็นถอย ทั้งตอนโดนตีและหลังมอนโจมตี
4. หลบเป็น **กลิ้ง** ไม่ใช่พุ่ง; ปุ่มกลิ้งขัดจังหวะการตีได้
5. ปรับภาพให้ทันสมัยและจริงจัง แต่คุมความลื่นจาก 0.3
6. อัปเดตใบงานให้ AI ตัวอื่นรู้ว่าแก้ตรงไหนและนำขึ้นอย่างไร
7. คุยกับเจ้าของเป็นภาษาไทย เขาทดสอบหลักบนมือถือ
8. ห้ามใช้ภาพ AI แทนตัวละครหรือมอน 3D; ทุกรุ่นนี้ยังใช้โมเดล 3D และ skeleton จริง

## 0.5 สไลม์ทรงใหม่ (29 ต.ค. 2026 โดย Claude)

- เจ้าของอนุมัติทรงสไลม์ใหม่จากภาพตัวอย่าง: ทรงหยดน้ำ ก้นแบนย้วยออกข้าง จุกบนหัวโค้งไปหลัง ตาโต ประกายแสง 2 จุด แก้มชมพู ปาก
- แก้เฉพาะ `source/scripts/slime.gd`: เพิ่ม `_drop()` สร้าง ArrayMesh ตอนรัน (cache ต่อเลเวล/มือถือ) แทน SphereMesh และวางหน้าใหม่ใน `setup()`
- ไม่แตะ AI การกระโดด ไล่ ตี เลือด ดาเมจ สีตามเลเวล shader `slime.gdshader` และไม่เพิ่มไฟล์ภาพ/โมเดล
- มือถือ 24×14 ช่อง (~670 สามเหลี่ยม) เดสก์ท็อป 40×24
- `source/tools/make_slime.py`: ต้นแบบ Python ที่ใช้ออกแบบ+เรนเดอร์ภาพตัวอย่าง (ไม่ได้ใช้ในเกม)
- รัน `run_tests.sh` ด้วย Godot 4.7.2 ผ่านครบ (ALL TESTS PASS) และถ่ายภาพในเกมแล้วสไลม์แสดงถูกต้อง · **ยังไม่ได้ export เว็บ/APK** (index.* ที่ root ยังเป็นสไลม์เก่า)

## ปัญหาเดิมและสิ่งที่ยืนยันแล้ว

เว็บเคยขึ้น `WebGL context lost` และเจ้าของแจ้ง APK เข้าแล้วเด้ง
ยังไม่มี Android logcat ที่ยืนยันรากปัญหาเดิม ห้ามสรุปว่า GPU/หน่วยความจำเป็นต้นเหตุที่พิสูจน์แล้ว
0.2 แก้หลายจุดเสี่ยง: MSAA ตั้งแต่ startup, โหลดเมืองเป็นช่วง, พื้นมือถือเบาลง, ไม่สร้าง sky cubemap/เงาจริง/อนุภาคน้ำพุบนมือถือ, แบ่ง MultiMesh ตามพื้นที่ และเพิ่มบันทึก startup
ผลจริงที่ยืนยันโดยเจ้าของคือเข้าเล่นได้หลังการแก้ และ 0.3 ไม่แลคตามที่เขารายงาน
0.4 ผ่านเครื่องทดสอบ แต่ **ยังไม่ยืนยันผลมือถือจริง**

## เปลี่ยนภาพใน 0.4 อย่างไร

แนวทางเป็น modern fantasy: หินเทา หลังคาสเลต ไม้และปูนสีอบอุ่น แสงอุ่นตัดแสงแวดล้อมเย็น และ UI น้ำเงินเข้มขอบทองหม่น
คงผังเมือง ร้าน NPC ประตูและเส้นทางเดิมทั้งหมด

- `source/scripts/visual_style.gd` ใหม่: โหลด texture ร่วมกัน, cache วัสดุหลังคา, เลือกหิน/ไม้/ปูนตามวัสดุเดิม, สร้าง contact shadow แบบ PlaneMesh + GradientTexture ขนาดเล็ก
- `source/assets/style/`: สีและ normal ของ stone/plaster/wood/slate ขนาด 256×256, town_ao.png ขนาด 512×512 รวม 9 ไฟล์ มี mipmaps
- `source/tools/generate_style_textures.py`: สร้าง texture เดิมซ้ำได้จาก Python + NumPy + Pillow ด้วย seed=104; AO สร้างจาก shop footprints ใน data/town.json ไม่ได้ย้ายอาคาร
- `source/scripts/town.gd`: ใช้ VisualStyle ใน M()/gable(), ลดสีสดจัด ปรับแสงและป้าย ใช้ AO ในพื้น แผง HUD ขนาดใหม่; มือถือยังไม่เปิดเงาจริงหรือ sky cubemap
- `source/shaders/town_ground.gdshader`: หินปูถนนใหญ่ขึ้น ช่องปูนแคบลง สีหญ้า/หินสุขุม และ sample town_ao เพิ่มหนึ่งครั้ง
- `source/shaders/terrain.gdshader`, `grass.gdshader`, `foliage.gdshader`: ลดเขียวจัดและ backlight ของใบไม้
- `source/scripts/model.gd`: ปรับวัสดุเกราะ/ผ้า และ scale กระดูก head เป็น 0.84 โดยไม่เปลี่ยน animation path หรือ skeleton; ฉากลูกยังอยู่ใน inst เดิม ส่วน roll_pivot จาก 0.3 ครอบนอก inst
- `source/scripts/player.gd`, `npc.gd`: contact shadow ใต้เท้า วงเลือกสีทองหม่น ป้ายเล็กลง
- `source/scripts/field.gd`: HUD เป็น PanelContainer สีเข้ม ตัวเลขและแถบเล็กลง แสดง HP/MP/EXP/เหรียญ/เจลครบ
- `source/scripts/mobile.gd`: ปุ่มตี/กลิ้งสีเรียบขึ้น ตำแหน่งและ multi-touch เดิม

**ข้อจำกัดภาพที่ต้องพูดตรง ๆ**: โมเดลยังเป็น KayKit Adventurers เดิม ปรับสัดส่วนและวัสดุ ยังไม่ใช่มนุษย์ photorealistic หรือโมเดลสมจริงใหม่ทั้งชุด อย่าอ้างว่าทำเปลี่ยนโมเดลสมจริงครบแล้ว

## สิ่งที่ห้ามเปิดกลับบนมือถือโดยไม่วัด

- ห้ามเปิด MSAA 4x ตั้งแต่เริ่ม
- ห้ามเปิด real shadow atlas ใหญ่, sky radiance/reflection cubemap, SSAO/volumetric fog หรือ GPU fountain particles บนมือถือจากรุ่นนี้
- Normal maps ใช้บน desktop เท่านั้น; `VisualStyle.normals_enabled()` ปิดบน Android/iOS/web mobile/touchscreen/--mobile เพื่อลดการ sample texture
- มือถือใช้สีวัสดุที่มีลายและ AO อบล่วงหน้าแทน normal-map shading หนัก ๆ
- คงเป้าหญ้า 3,000 และ terrain 80×80 บนมือถือ, จำกัด 30 FPS และ MultiMesh แบบ chunk 32 หน่วย
- ห้ามรื้อระบบการตี/กลิ้งใหม่เพียงเพื่อแก้ภาพ

## โครงสร้างและไฟล์เดิมที่สำคัญ

- `source/project.godot`: startup.tscn, Godot 4.7.2, app version 0.4-modern, mobile Compatibility, MSAA=0 และ log
- `source/startup.tscn`, `scripts/startup.gd`: หน้ารอโหลด 2D บันทึก user://startup_state.json ถ้าครั้งก่อนโหลดค้าง รอบถัดไปไม่สร้างป่านอกเมือง/หญ้า แต่คง gameplay
- `source/scripts/town.gd`: สร้างเมืองเป็นช่วงผ่าน loading_stage/world_ready; ปิด process/input ระหว่างสร้าง จึงอย่าเรียก player ก่อน world_ready
- `source/scripts/player.gd`: ฟันทุก 0.45 วินาที กดค้าง; ROLL.time=0.5, distance=2.3, cd=0.65; รักษาชื่อ dash() ให้ input เดิมเรียก แต่พฤติกรรมเป็นกลิ้งแล้ว
- `source/scripts/model.gd`: begin_roll/update_roll/end_roll หมุน pivot 360 องศาและคืนท่าปกติเมื่อจบ/ตาย
- `source/scripts/slime.gd`: ไม่มี knockback; cache sphere mesh และวัสดุตา ลดรายละเอียดบนมือถือ
- `source/scripts/field.gd`: HUD อัปเดต 10 Hz; ความสูงของดรอปแคชหลังตกพื้น; กติการางวัลเดิม
- `source/scripts/mobile.gd`: จับ attack_touch_id; ปล่อยนิ้วแล้วหยุดฟัน ไม่มีการยิงซ้ำจากนิ้วจอย
- `source/data/town.json`: ผังและข้อมูลร้านจริง ไม่ควรแก้เพื่อปรับภาพ
- `user://logs/eldoria.log`: ข้อความ/error ของเอนจิน; native crash อาจหยุดก่อนเขียน log จึงยังต้องใช้ logcat หากเกิดอีก

## ผลทดสอบที่ทำรอบนี้

Godot 4.7.2 official Linux, OpenGL Compatibility ผ่าน Mesa llvmpipe บน Xvfb (เป็น software renderer ไม่ใช่เครื่องเจ้าของ)

- ทุกเกมสคริปต์ parse ผ่าน
- startup/recovery smoke: เมืองโหลดครบ, NPC 19, สไลม์ 16, เดิน/ต่อสู้/EXP/ดรอป/ร้านยังทำงาน
- combat smoke: กดค้างใช้ slash เดิมซ้ำ, ปล่อยหยุด, ยืนตีไม่เคลื่อน, กลิ้งขัดการตี/ระยะ 2.3/ช่วงอมตะ/คืนโมเดล, มอนไม่ถอย, touch press/release
- visual smoke: วัสดุใช้ texture ร่วม, mobile ไม่เปิด normal maps, contact shadow มีจริง, head scale ถูก, HUD ใหม่ และ real shadows/sky ยังปิด
- เรนเดอร์ before/after เมืองพิกัด 22,18 เวลา 0.38 yaw 0.45 ระยะ 32; ภาพอยู่ verification/
- APK ตรวจ Android v2/v3 signature, ZIP integrity และ zip alignment ผ่าน

ผลวัดฉากเดียวบน software renderer (ดู JSON/log ที่แนบ):
| ค่า | 0.3 | 0.4 |
|---|---:|---:|
| Draw calls | 663 | 675 |
| Primitives | 231,400 | 231,302 |
| Texture MiB | 58.45 | 56.05 |
| Median frame ms | 65.05 | 64.70 |
| p95 frame ms | 76.53 | 99.59 |

ตัวเลขนี้ใช้ตรวจว่าปริมาณงานไม่ได้โตมากเท่านั้น ไม่ใช่ FPS มือถือ และไม่ใช่หลักฐานว่าทุกเฟรมลื่นเท่าเดิม (p95 รอบนี้สูงกว่า) ต้องลองมือถือเจ้าของก่อนรับรอง

## สร้างซ้ำอย่างไร

1. เปิด `source/project.godot` ด้วย Godot **4.7.2** และติดตั้ง export templates รุ่นเดียวกัน
2. รัน import ก่อน ห้ามเอา cache .godot จากเครื่องอื่นมาแทน source
3. ต้องการสร้างลายวัสดุใหม่:
   `python3 source/tools/generate_style_textures.py`
   จากนั้น import อีกครั้ง และตรวจ .png.import ให้ mipmaps/generate=true
4. ตรวจโค้ดและ regression:
```
godot --headless --path source --editor --import
godot --headless --path source --script res://tests/startup_smoke.gd -- --mobile
godot --headless --path source --script res://tests/startup_smoke.gd -- --mobile --recovery-test
godot --headless --path source --script res://tests/combat_smoke.gd -- --mobile
godot --headless --path source --script res://tests/visual_smoke.gd -- --mobile
```
ใช้ user data แยกจากข้อมูลจริง เพราะ smoke test เขียน marker/จำลองสถานะผู้เล่น
ต้องตรวจ log ด้วยว่าไม่มี `SCRIPT ERROR`, `Parse Error`, `ERROR:`; Godot บาง runtime error ไม่ทำให้ exit code เป็น 1 เสมอ

5. Export เว็บ:
```
mkdir -p build/web
godot --headless --path source --export-release Web ../build/web/index.html
```
Web preset เป็น no-threads, Compatibility และทั้ง desktop/mobile texture variants; exclude tests/tools/build จากไฟล์เกม
นำ index.* ทุกไฟล์ที่ export รอบเดียวกันไป root ของ repo ห้ามแก้ index.js/wasm/pck ด้วยมือหรือผสมคนละรุ่น

6. Android:
- preset หลักใน source ยังใช้ `com.wiwekwin.eldoria` เพื่อไม่เปลี่ยนโปรเจคหลักเงียบ ๆ
- APK ที่เจ้าของกำลังใช้จริงเป็น **รุ่นทดสอบแยก** `com.wiwekwin.eldoria.stability`, label `Eldoria ทดสอบแก้เด้ง`
- การ build เพื่ออัปเดตผู้ใช้รายนี้ต้องเปลี่ยน package/name เป็นค่ารุ่นทดสอบในสำเนา preset ชั่วคราว แล้วคืน preset หลักหลัง export
- versionCode=4 ในรอบนี้; รอบถัดไปต้องเพิ่มมากกว่า 4
- ใช้ Android SDK/Java และ android_release.apk template 4.7.2; preset package/signed=false เพื่อเซ็นไฟล์ unsigned ทีหลังด้วย apksigner จริง
```
mkdir -p build/android
godot --headless --path source --export-release Android ../build/android/unsigned.apk
apksigner sign --ks "$ELDORIA_TEST_KEY" --ks-pass env:ELDORIA_TEST_KEY_PASSWORD --key-pass env:ELDORIA_TEST_KEY_PASSWORD --out build/android/Eldoria-modern.apk build/android/unsigned.apk
apksigner verify --verbose --print-certs build/android/Eldoria-modern.apk
zipalign -c -v 4 build/android/Eldoria-modern.apk
```
คีย์รุ่นทดสอบถูกสำรองแยกไว้ในไฟล์ **Eldoria-stability-test-signing-backup.zip** (Library ID `libfile_b90ecc3ff17481918b79e6137e685e88`) มี eldoria-stability.p12, alias eldoria-stability, รหัสผ่านทดสอบ android
Certificate SHA-256 ที่ต้องตรง:
`22710908d33888d50c5a3b71ee284ed6f3649d5fd0896651753a07e06416c03d`
อย่า commit คีย์หรือสำเนา backup ลง GitHub
คีย์แอปดั้งเดิม com.wiwekwin.eldoria ไม่มีในชุดนี้ ห้ามใช้คีย์ทดสอบเซ็นทับแอปดั้งเดิม
โค้ด source/tools/apksign_v2.py เป็นทางสำรองเดิม แต่รอบนี้ใช้ apksigner จริงและตรวจลายเซ็นแยก

## นำขึ้นระบบหลังมีสิทธิ์อย่างไร

1. clone/fetch repo **chatchai2537/eldoria-godot** ด้วยบัญชีที่มีสิทธิ์เขียนจริง
2. อ่าน HANDOFF.md และตรวจ main ล่าสุดก่อน เปรียบเทียบกับฐาน 903dc46... เผื่อ AI อื่นทำงานต่อแล้ว ห้ามทับงานใหม่แบบไม่ตรวจ diff
3. นำ source/ จากชุดนี้รวมเข้า repo พร้อม HANDOFF.md และ AI_HANDOFF_TH.md ไม่เอา .godot, กุญแจ, temp หรือ build-tools ของเครื่องคลาวด์ไปด้วย
4. นำ index.* ชุด export ล่าสุดลง root; นำ **Eldoria-modern.apk** และ **apk.html** ลง root ให้คู่กัน (หน้าใหม่ลิงก์ไป APK รุ่นทดสอบนี้ชัดเจน)
5. เก็บ Eldoria.apk เดิมไว้ได้ แต่ไม่ใช้มันเป็นลิงก์ดาวน์โหลดรุ่นใหม่
6. รันทดสอบ/ตรวจไฟล์ตามด้านบน แล้ว commit และ push ตามกฎ repo ห้าม force push
7. ตรวจ GitHub Pages deployment สำเร็จ และเปิดเว็บจริง/หน้า apk.html เพื่อตรวจว่ารุ่นที่เสิร์ฟเป็น 0.4-modern
8. ให้เจ้าของติดตั้งทับ **Eldoria ทดสอบแก้เด้ง** เดิมและลองเมือง/ทุ่ง/ยืนตี/กลิ้ง บันทึกผลมือถือจริงใน HANDOFF ต่อ
9. ถ้ายังไม่มีสิทธิ์เขียน ส่ง source ZIP และ APK ให้ผู้ใช้ และระบุว่าเว็บจริงยังไม่อัปเดต ห้ามเขียนสถานะ deployed

## งานต่อที่ยังไม่ทำ

- ทดสอบ 0.4 บนมือถือเจ้าของและดูว่าภาพ/ความลื่นรับได้หรือไม่
- ปรับสัดส่วน/โมเดลให้สมจริงกว่า KayKit ต้องเลือกโมเดล 3D ที่มีสิทธิ์ใช้และทดสอบ skeleton/animation จริง ไม่ใช้ภาพ 2D ตั้งในฉาก
- ร้านซื้อขาย/กระเป๋า/บัญชี/เซฟออนไลน์ยังเป็นงานค้างใน HANDOFF เดิม ไม่ใช่งานที่รอบภาพนี้ทำเสร็จ
- ถ้าจะใช้บัญชีร่วมเกม 2D ต้องถามเจ้าของตามใบงานเดิม
