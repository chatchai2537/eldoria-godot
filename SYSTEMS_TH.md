# แผนที่ระบบ Eldoria Godot — เจอบัค/จะเพิ่มระบบ → เปิดเฉพาะฟังก์ชันที่ระบุ ไม่ต้องอ่านทั้งไฟล์

ไฟล์ทั้งหมดอยู่ใน `source/scripts/` · ค้นด้วย `grep -n "^func ชื่อ" source/scripts/ไฟล์.gd`
ทุกระบบมีเทสใน `source/tests/all_systems.gd` (ชื่อเทสเป็นภาษาไทย ค้นคำในวงเล็บ) · รันทั้งหมด `bash source/tools/run_tests.sh`

| ระบบ | ไฟล์ · ฟังก์ชัน | ค่าจากเกม 2D / หมายเหตุ | คำในเทส |
|---|---|---|---|
| โหลดเกม/กันเด้ง | startup.gd `_load_world` `_write_marker` · town.gd `_ready` `_stage` | โหลดค้างครั้งก่อน → recovery_mode ไม่สร้างป่า/หญ้า | "โหลดเกมจนจบ" |
| โหมดมือถือ | town.gd `_ready` (is_mobile) `_mobile_scale` `_setup_env` | 30 FPS · ไม่มี MSAA/เงาจริง/sky/glow/fog | startup_smoke |
| ปุ่มมือถือ | mobile.gd `_input` `_layout` `_world_dir` | จอยลอยซ้าย · ปุ่มตี (กดค้าง) · ปุ่มกลิ้ง · ลากขวาหมุนกล้อง · สองนิ้วซูม | "มือถือ:" |
| คลิก/แตะ | town.gd `click_at` `_npc_at` `_ground_at` · field.gd `slime_at` | แตะสไลม์ = เดินไปตี | — |
| เมือง (ผัง) | town.gd `_layout` `_build_*` · data/town.json | ร้าน 15 · NPC 19 · ประตู · ผังจาก `js/031-core.js` buildTown | "ร้านค้า" "NPC" |
| ภาพ/วัสดุ | visual_style.gd · town.gd `M` `box` `gable` · shaders/ | normal map เฉพาะคอม | visual_smoke |
| ร้านค้า | town.gd `open_shop` `shop_buy` `shop_sell` `_row` `_btn` · items.gd `BUY` | ซื้อได้เฉพาะของที่มีใน `Items.BUY` (equip/bag/now) · อื่น ๆ ปุ่ม "เร็ว ๆ นี้" · ขายตาม sell ของร้าน | "ร้าน:" "ร้านยา" "ร้านชำ" |
| กระเป๋า/ไอเท็ม | player.gd `inv` `inv_count` `inv_add` `inv_take` `use_item` · town.gd `toggle_bag` `refresh_bag` · items.gd `ITEM` | เจล/หิน/ไม้เก็บในตัวแปรของมัน · ยา H/N · ม้วนวาปใช้นอกเมือง · ฟีนิกซ์ใช้เองตอนล้ม (`_die`) · ยังไม่มีจำกัดช่อง/น้ำหนัก | "กระเป๋า" "ม้วนวาป" "ฟีนิกซ์" |
| สเตตัส/หน้าตัวละคร | player.gd `recalc_stats` `stat_add` `crit_rate` `STAT_NAMES` · town.gd `toggle_char` `refresh_char` | เลือด 100+(lv-1)×15+vit×12 · มานา 50+(lv-1)×5+int×6 · แต้ม +3/เลเวล (`js/031-core.js` 320) | "อัป VIT" "เลเวลอัป" |
| เซฟเกม | player.gd `save_game` `load_game` `_notification` `SAVE_KEYS` · town.gd `_build_player` (โหลดตอนเริ่ม) | เซฟทุก 10 วิ + ตอนออก/สลับแอป · เขียน .tmp แล้ว rename · ปิดเซฟเองตอนรันเทส/--shot · เพิ่มค่าที่ต้องเซฟ → ใส่ใน SAVE_KEYS | "เซฟ" "โหลด" |
| อาวุธ/ATK | player.gd `weapon` `weapon_tier` `atk` · items.gd `SWATK` | ATK = 1 + SWATK[ระดับ] (ถ้าถือ) + str + (lv-1)>>1 | "ดาบ" |
| คุย NPC | town.gd `_talk` `say` · npc.gd | บทพูดจาก NL ของเกม 2D | "คุยกับ NPC" |
| เดิน/หาทาง | town.gd `blocked` `find_path` `_grid_path` `_field_path` · player.gd `_try_move` `drive` | เมือง A* 44×34 · ทุ่ง A* 60×44 · ต่อกันที่ประตูตะวันตก | "หาทาง" "เดินจากเมือง" |
| พื้น/ความสูง | town.gd `h` `ground_y` `fh` `in_field_rect` | ในเขตทุ่ง h() = -4 (ใช้พื้นทุ่งแทน) | "บ่อน้ำ" "พื้นหญ้า" |
| ทุ่งหญ้า (ผัง) | town.gd `ftile` `ftile_solid` `fw` `ftile_at` · data/field.json | ผังจริง `js/013-core.js` 60×44 · น้ำ/ต้นไม้/ประตูดัน/หินวาร์ปเดินไม่ได้ · ตอไม้ (f_cut) เดินได้ · ช่อง (x,y) → โลก (-164+2x, -45+2y) | "แผนที่ทุ่ง" "น้ำ" "ต้นไม้" |
| ทุ่งหญ้า (ภาพ) | field.gd `_build_ground_mesh` `_build_water` `_build_trees` `_build_grass_flowers` `_build_portal` `_build_dungeon_gate` `_build_warp` | กอหญ้า มือถือ 2,600 / คอม 22,000 | — |
| เก็บหิน/กิ่งไม้ | field.gd `_add_pickup` `_update_world` · player.gd `stone` `wood` | 34 ชิ้น · เกิดใหม่ 8 วิ · เดินทับเก็บ (`js/031-core.js` ~849) | "เก็บหิน" |
| ตัดไม้ | field.gd `trees` `tree_at` `_build_trees` `_mm_one` `_tree_show` `tree_in_front` `try_chop` `_update_trees` · player.gd `attack` (เรียก try_chop เมื่อไม่มีสไลม์ใกล้) `axe_dmg` · town.gd `f_cut` | hp [2,3,5,8] ไม้ [1,2,3,5] ตามขนาด · แอปเปิ้ล 30%+ไม้×5% · งอก 100-140 วิ (fix149) · ต้องมี axe0 | "ตัดไม้" "ต้นไม้" "ตอไม้" |
| ประตูมิติ/ดันเจี้ยน/วาร์ป | field.gd `_update_world` (ข้อความ) | ยังเข้าไม่ได้ (เร็ว ๆ นี้) | "ประตูมิติ" |
| สไลม์ | slime.gd `setup` `_process` `take_hit` `_mv` · field.gd `spawn` `lv_at` | เลือด 2+lv · ตี 4+(lv-1)×2 · 16 ตัว เกิดใหม่ 6 วิ · lv=ceil((60-x)/12) · **ไม่กระเด็น** | "สไลม์" |
| ตี | player.gd `set_attack_held` `attack` `_process` · field.gd `melee` `new_attack` | ท่าเดียว ทุก 0.45 วิ · กดค้างฟันซ้ำ · ยืนกับที่ · คริ 8%+agi×0.4% ×1.8 | "กดค้างตี" combat_smoke |
| กลิ้งหลบ | player.gd `dash` · model.gd `begin_roll` `update_roll` `end_roll` | 0.5 วิ · 2.3 หน่วย · คูลดาวน์ .65 · อมตะ · ขัดการตีได้ | combat_smoke |
| โดนตี/ตาย/ฟื้น | player.gd `hurt_by` `_die` `_revive` | ไม่กระเด็น · ฟันที่วิหาร tw(7.5,23.5) หลัง 3 วิ | "โดนตี" "ล้ม" "ฟื้น" |
| ดรอป/EXP/เลเวล | field.gd `_killed` `_drop` `_process` · player.gd `gain_xp` `need` | เจล 1-2 · เหรียญ 1-3+(lv>>1) · EXP 5×lv · ต้องการ 20+lv²×12 · เลเวลอัป +3 แต้ม | "ดรอป" "EXP" "เลเวลอัป" |
| HUD | field.gd `_build_hud` `_update_hud` `say_msg` `float_text` | อัปเดต 10 ครั้ง/วิ | — |
| ตัวละคร 3D | model.gd `build` `animate` `action` · npc.gd `setup` | KayKit (CC0) | visual_smoke |
| กล้อง | town.gd `_update_cam` | จอตั้ง: KEEP_WIDTH fov 62 | — |
| ทดสอบภาพ | town.gd `_test_ui` · อาร์กิวเมนต์ `--shot=ชื่อ,เวลา,หมุน,ระยะ,ช่องX,ช่องY[,โหมด]` | ช่อง X ติดลบ = ทุ่ง | — |
| ห้องในร้าน | rooms.gd `enter` `leave` `blocked` `interact_if_near` `interact` `_build` `_decor` `THEME` · town.gd `room` (เดินชนประตู → `rooms.enter`) `_update_sky` (ในร้านแสงกลางวันคงที่) | ห้อง 26×15 ช่อง วางที่ x=700+ลำดับ×90 · แถว 0-1 ผนัง · 2 เจ้าของ · 3 เคาน์เตอร์ · 14 ทางออกช่อง 12-13 · กล้องหันเข้าเคาน์เตอร์ ออกแล้วคืนมุมเดิม | "ห้องในร้าน" |
| สกิลพื้นฐาน | items.gd `SKILL` `SKILL_ORDER` · player.gd `learn_skill` `use_skill` `skill_cd` · field.gd `aoe` `shoot` · mobile.gd `skill_btns` `refresh_skills` | เรียนที่ร้านสกิล (bsk0-2) · คีย์ 1/2/3 | "สกิล" |
| อาวุธยิงไกล | items.gd `RANGED` · player.gd `is_ranged` `atk` `attack` · field.gd `projectiles` `shoot` `_update_projectiles` `hit_slime` | คทาใช้ INT ระยะ 17.5 · ธนูใช้ AGI ระยะ 22.5 | "คทา" |
| อาหาร/บัฟ | items.gd `ITEM[].use` (hpp/mpp/buff/sec) · player.gd `use_item` `buffs` `stat_total` | อิ่ม/แรง ยังไม่มี (รอเจ้าของ) · ของฟาร์มซ่อน `Items.HIDE` | "อาหาร" |
| ธนาคาร | town.gd `open_bank` `bank_move` · player.gd `bank` (เซฟด้วย) | ฝาก/ถอนของในกระเป๋า | "ธนาคาร" |
