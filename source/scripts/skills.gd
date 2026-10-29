extends Node
## อาชีพ 4 สายหลัก + เลื่อนขั้น (0.27 · docs/PLAN_4CLASS_TH.md)
## สายหลัก Lv.10: อัศวิน sword · นักหน้าไม้ archer · นักเวท mage · โจร rogue — แต่ละสายใช้โมเดล KayKit ของตัวเอง (MODEL)
## เลื่อนขั้น Lv.40 (ADV): สายย่อย 2 สายต่อสายหลัก ใช้สกิลชุดเดิมของ 8 อาชีพ fix25
## เลือกที่ปรมาจารย์อาชีพ (จัตุรัส) · ครั้งแรก/เลื่อนขั้นครั้งแรกฟรี · เปลี่ยนสาย 500 เหรียญ
## สกิลอาชีพปลดล็อกเองตามเลเวล (5 / 15 / 30) · ต้องถืออาวุธประจำสาย · สกิลที่ 2 กดต่อกัน 3 จังหวะภายใน 1.8 วิ
## เยียวยา (สกิลพื้นฐาน) ใช้ได้ทุกอาชีพ · ฟันวงพายุ/ลูกไฟ ใช้ได้เฉพาะตอนยังไม่มีอาชีพ

const CLASS_LV := 10
const ADV_LV := 40
const CHANGE_COST := 500
const BASES := ["sword", "archer", "mage", "rogue"]
const ADV := {"sword": ["paladin", "dragoon"], "archer": ["sniper", "summoner"], "mage": ["cleric", "necro"], "rogue": ["ninja", "monk"]}
## โมเดลตัวละครตามอาชีพ (model.gd FILES) · สายย่อยใช้โมเดลสายหลัก ยกเว้นอัศวินมังกร = คนเถื่อน
const MODEL := {"none": "knight", "sword": "knight", "archer": "hooded", "mage": "mage", "rogue": "rogue", "dragoon": "barbarian"}
const CLS := {
    "none": {"n": "ผู้ฝึกหัด", "col": Color(0.8, 0.8, 0.8), "d": "ยังไม่ได้เลือกอาชีพ"},
    "sword": {"n": "อัศวิน", "col": Color(1.0, 0.54, 0.42), "w": "sword", "d": "ดาบกับโล่ ประชิดตัว ถึก เลือดเยอะ · ดาเมจจาก STR", "pas": "VIT +2+Lv/3 · STR +Lv/5"},
    "mage": {"n": "นักเวท", "col": Color(0.7, 0.55, 1.0), "w": "staff", "d": "ยิงเวทระยะไกล สกิลวงกว้างรุนแรง · ดาเมจจาก INT · มานาฟื้นเร็ว", "pas": "INT +4+Lv/2 · มานาฟื้นเร็ว ×2.5"},
    "archer": {"n": "นักหน้าไม้", "col": Color(0.49, 1.0, 0.54), "w": "bow", "d": "ยิงหน้าไม้ไกลและเร็ว คริติคอลสูง · ดาเมจจาก AGI", "pas": "AGI +3+Lv/3 · คริ +10%"},
    "rogue": {"n": "โจร", "col": Color("#c9a0ff"), "w": "sword", "d": "มีดคู่ ไม่มีโล่ คล่องแคล่ว ตีรัว · ดาเมจจาก STR+AGI", "pas": "STR +1+Lv/5 · AGI +2+Lv/4 · คริ +6%"},
    # 8 อาชีพเพิ่ม (js/056-fix25.js NC25)
    "ninja": {"n": "นินจา", "col": Color("#8a9aff"), "w": "sword", "d": "เร็ว ลอบสังหาร คริติคอลสูง วาร์ปไปหลังศัตรู · ดาเมจจาก AGI+STR", "pas": "AGI +3+Lv/3 · คริ +12% · เดินเร็ว +15%"},
    "sniper": {"n": "สไนเปอร์", "col": Color("#ffd23a"), "w": "bow", "d": "ยิงไกลที่สุดในเกม นัดเดียวแรงมาก คริแรง · ดาเมจจาก AGI", "pas": "AGI +4+Lv/3 · คริ +8% · ดาเมจคริ +60%"},
    "paladin": {"n": "พาลาดิน", "col": Color("#ffe9a0"), "w": "sword", "d": "อัศวินศักดิ์สิทธิ์ ถึกที่สุด ฮีลตัวเองได้ · ดาเมจจาก STR", "pas": "VIT +4+Lv/3 · ลดดาเมจที่ได้รับ 15% · ฟื้นเลือด 0.5%/วิ"},
    "cleric": {"n": "นักบวช", "col": Color("#bff0ff"), "w": "staff", "d": "แสงศักดิ์สิทธิ์ ฮีลแรง บัฟพลัง ยิงแสงพิพากษา · ดาเมจจาก INT", "pas": "INT +3+Lv/3 · VIT +Lv/5 · มานาฟื้นเร็ว ×2"},
    "necro": {"n": "เนโครแมนเซอร์", "col": Color("#7affb0"), "w": "staff", "d": "ปลุกโครงกระดูกเป็นกองทัพ สาปศัตรู ดูดเลือด · ดาเมจจาก INT", "pas": "INT +4+Lv/3 · ดูดเลือด 4% ของดาเมจ"},
    "monk": {"n": "มังค์", "col": Color("#ffb46a"), "w": "sword", "d": "หมัดมวยวัดตีเร็วต่อเนื่อง คอมโบรัว · ดาเมจจาก STR+AGI", "pas": "STR +2+Lv/4 · AGI +2+Lv/4 · ตีเร็วขึ้น 25%"},
    "dragoon": {"n": "อัศวินมังกร", "col": Color("#ff6a5a"), "w": "sword", "d": "ทวนยาวระยะไกล กระโดดแทงจากฟ้า ลมหายใจมังกร · ดาเมจจาก STR", "pas": "STR +3+Lv/3 · VIT +Lv/6 · ระยะฟันยาวขึ้น"},
    "summoner": {"n": "พรานอสูร", "col": Color("#9adf6a"), "w": "bow", "d": "พรานหน้าไม้ เรียกหมาป่า หมี อินทรี มาสู้แทน · ดาเมจจาก AGI", "pas": "AGI +3+Lv/3 · สัตว์อัญเชิญแรงขึ้น 30%"},
}
const CLASS_ORDER := ["sword", "archer", "mage", "rogue", "paladin", "dragoon", "sniper", "summoner", "cleric", "necro", "ninja", "monk"]
const WNAME := {"sword": "ดาบ", "staff": "คทา", "bow": "ธนู"}
const SK := {
    "rogue": [
        {"n": "มีดพิษคู่", "lv": 5, "mp": 12, "cd": 5.0, "d": "แทงมีดคู่ด้านหน้า 2 ครั้ง ครั้งละ ×1.2"},
        {"n": "ใบมีดสามจังหวะ", "lv": 15, "mp": [8, 10, 16], "cd": 9.0, "steps": 3, "d": "① พุ่งแทง ×1.5 → ② ฟันไขว้รอบตัว ×1.5 → ③ ปามีด 3 เล่มทะลุ ×2.2 + มึนงง"},
        {"n": "พายุมีดบิน", "lv": 30, "mp": 40, "cd": 22.0, "d": "ปามีด 12 เล่มรอบตัว 2 ระลอก ครั้งละ ×1.2 · หลบได้ 0.8 วิ"}],
    "sword": [
        {"n": "กระทืบปฐพี", "lv": 5, "mp": 15, "cd": 7.0, "d": "กระทืบพื้น คลื่นกระแทกรอบตัว ×1.8 + มึนงง 1.6 วิ"},
        {"n": "ดาบสามจังหวะ", "lv": 15, "mp": [8, 10, 16], "cd": 9.0, "steps": 3, "d": "① พุ่งฟัน ×1.4 → ② ฟันเสย ×1.6 → ③ คลื่นดาบพุ่งไกล ×2.4 (กดซ้ำภายใน 1.8 วิ)"},
        {"n": "พายุดาบ", "lv": 30, "mp": 40, "cd": 24.0, "d": "หมุนตัวเป็นพายุ 2.6 วิ ฟันทุกตัวรอบตัวต่อเนื่อง เดินไปด้วยได้"}],
    "mage": [
        {"n": "วงแหวนเพลิง", "lv": 5, "mp": 20, "cd": 9.0, "d": "วงไฟรอบตัว 4.5 วิ เผาศัตรูในวงต่อเนื่อง"},
        {"n": "เวทธาตุสามสาย", "lv": 15, "mp": [10, 14, 24], "cd": 10.0, "steps": 3, "d": "① น้ำแข็ง 5 เล่ม → ② สายฟ้าลูกโซ่ 5 ตัว → ③ อุกกาบาตยักษ์ ×3.2"},
        {"n": "พายุอุกกาบาต", "lv": 30, "mp": 60, "cd": 30.0, "d": "อุกกาบาตตกถล่มรอบตัว 3.5 วิ"}],
    "archer": [
        {"n": "ยิงกระจาย", "lv": 5, "mp": 12, "cd": 5.0, "d": "ยิงธนู 5 ดอกเป็นรูปพัด ดอกละ ×0.9"},
        {"n": "ธนูวิญญาณ", "lv": 15, "mp": [8, 10, 18], "cd": 9.0, "steps": 3, "d": "① ธนูทะลวง ×1.5 → ② ตีลังกาถอยยิง ×1.2 → ③ ธนูระเบิด ×2.6 + มึนงง"},
        {"n": "ฝนธนู", "lv": 30, "mp": 45, "cd": 24.0, "d": "ห่าธนูตกด้านหน้า 3 วิ ดาเมจต่อเนื่อง"}],
    "ninja": [
        {"n": "ดาวกระจายพายุ", "lv": 5, "mp": 14, "cd": 6.0, "d": "ปาดาวกระจาย 8 ทิศรอบตัว ดอกละ ×0.9"},
        {"n": "เงาพริบตา", "lv": 15, "mp": [10, 12, 18], "cd": 9.0, "steps": 3, "d": "① วาร์ปไปหลังศัตรูแล้วแทง ×1.8 → ② ฟันรอบตัว ×1.4 → ③ ระเบิดควัน ×2.0 มึน + อมตะ 1.5 วิ"},
        {"n": "พันเงาสังหาร", "lv": 30, "mp": 45, "cd": 24.0, "d": "กลายเป็นเงา 2.5 วิ วาร์ปฟันศัตรูรอบตัวต่อเนื่อง ครั้งละ ×1.3 (อมตะ)"}],
    "sniper": [
        {"n": "กระสุนเจาะเกราะ", "lv": 5, "mp": 12, "cd": 5.0, "d": "ยิงนัดเดียวไกลมาก ทะลุทุกตัว ×3.0"},
        {"n": "ยิงสามจังหวะ", "lv": 15, "mp": [8, 10, 18], "cd": 9.0, "steps": 3, "d": "① เล็งหัว ×2.4 คริแน่นอน → ② ตีลังกาถอยยิงคู่ ×1.4 → ③ กระสุนระเบิด ×2.8"},
        {"n": "ห่ากระสุนพิฆาต", "lv": 30, "mp": 45, "cd": 24.0, "d": "ยิงกระหน่ำพื้นที่ด้านหน้า 3 วิ"}],
    "paladin": [
        {"n": "ค้อนศักดิ์สิทธิ์", "lv": 5, "mp": 16, "cd": 7.0, "d": "ฟาดค้อนแสงรอบตัว ×1.7 มึนงง + ฮีลตัวเอง 10%"},
        {"n": "ดาบแห่งแสง", "lv": 15, "mp": [10, 12, 20], "cd": 9.0, "steps": 3, "d": "① พุ่งชาร์จ ×1.5 → ② โล่กระแทก ×1.6 มึน → ③ เสาแสงถล่ม ×2.8"},
        {"n": "ปราการเทพ", "lv": 30, "mp": 40, "cd": 28.0, "d": "โล่แสง 6 วิ: ลดดาเมจ 60% · แสงเผาศัตรูรอบตัว"}],
    "cleric": [
        {"n": "แสงรักษา", "lv": 5, "mp": 20, "cd": 9.0, "d": "ฮีลตัวเอง 30% + ระเบิดแสง ×1.2 รอบตัว"},
        {"n": "พิพากษาสวรรค์", "lv": 15, "mp": [10, 14, 22], "cd": 10.0, "steps": 3, "d": "① ลูกแสง 3 ลูก ×1.4 → ② วงแหวนแสง ×1.5 → ③ ลำแสงสวรรค์ ×3.2"},
        {"n": "อวยพรเทวา", "lv": 30, "mp": 50, "cd": 30.0, "d": "8 วิ: โจมตี +35% · ฮีล 4%/วิ · มานาฟื้นเร็ว"}],
    "necro": [
        {"n": "ปลุกโครงกระดูก", "lv": 5, "mp": 18, "cd": 8.0, "d": "เรียกนักรบโครงกระดูก 2 ตัวมาสู้ (สูงสุด 6)"},
        {"n": "คำสาปวิญญาณ", "lv": 15, "mp": [10, 14, 20], "cd": 10.0, "steps": 3, "d": "① ลูกวิญญาณดูดเลือด ×1.6 → ② ทุ่งคำสาป 4 วิ → ③ หอกกระดูกทะลุ ×3.0"},
        {"n": "กองทัพมรณะ", "lv": 30, "mp": 55, "cd": 30.0, "d": "ระเบิดพลังมรณะ ×2.2 + เรียกโครงกระดูก 5 ตัว"}],
    "monk": [
        {"n": "หมัดพันครั้ง", "lv": 5, "mp": 12, "cd": 5.0, "d": "ต่อยรัวด้านหน้า 8 ครั้ง ครั้งละ ×0.55"},
        {"n": "ฝ่ามือมังกร", "lv": 15, "mp": [8, 10, 18], "cd": 8.0, "steps": 3, "d": "① ฝ่ามือคลื่นพลัง ×1.6 → ② เตะเสย ×1.8 → ③ หมัดมังกร ×3.0"},
        {"n": "จิตอรหันต์", "lv": 30, "mp": 40, "cd": 26.0, "d": "4 วิ: อมตะ · ออร่าทองตีรอบตัวรัว ๆ"}],
    "dragoon": [
        {"n": "แทงทะลวง", "lv": 5, "mp": 12, "cd": 5.0, "d": "แทงทวนพุ่งไปข้างหน้าทะลุทุกตัว ×1.9"},
        {"n": "กระโดดมังกร", "lv": 15, "mp": [10, 12, 20], "cd": 9.0, "steps": 3, "d": "① กระโดดลงจากฟ้า ×1.8 → ② กวาดทวนรอบตัว ×1.5 → ③ ลมหายใจมังกร ×2.6"},
        {"n": "มังกรเทพลงมา", "lv": 30, "mp": 50, "cd": 28.0, "d": "มังกรเพลิงพุ่งลงจากฟ้า ระเบิด ×4.2 วงกว้าง"}],
    "summoner": [
        {"n": "เรียกหมาป่า", "lv": 5, "mp": 16, "cd": 8.0, "d": "เรียกหมาป่า 2 ตัวมาสู้ (สูงสุด 4)"},
        {"n": "สัญชาตญาณป่า", "lv": 15, "mp": [10, 12, 20], "cd": 10.0, "steps": 3, "d": "① เหยี่ยวจู่โจม ×1.4 → ② หมีฟาดพื้น ×1.8 → ③ คำรามป่า ศัตรูมึน 2 วิ"},
        {"n": "ราชสีห์วิญญาณ", "lv": 30, "mp": 50, "cd": 30.0, "d": "อัญเชิญราชสีห์วิญญาณทอง 25 วิ + คลื่นคำราม ×2.0"}],
}
const PASSIVE := {
    "rogue": [{"lv": 10, "n": "มือไว", "d": "AGI +4", "st": {"agi": 4}}, {"lv": 20, "n": "จุดอ่อน", "d": "คริติคอล +5%", "crit": 0.05}, {"lv": 35, "n": "เงาเร้น", "d": "AGI +8 · STR +4", "st": {"agi": 8, "str": 4}}, {"lv": 50, "n": "มีดเทวดา", "d": "STR +10 · คริ +6%", "st": {"str": 10}, "crit": 0.06}],
    "none": [{"lv": 5, "n": "ผู้ฝึกหัดอดทน", "d": "END +2", "st": {"end": 2}}],
    "sword": [{"lv": 10, "n": "จิตวิญญาณนักรบ", "d": "STR +3", "st": {"str": 3}}, {"lv": 20, "n": "ผิวเหล็ก", "d": "VIT +6", "st": {"vit": 6}}, {"lv": 35, "n": "สายเลือดนักรบ", "d": "ฟื้นเลือด 1%/วิ", "regen": 0.01}, {"lv": 50, "n": "โทสะ", "d": "STR +12", "st": {"str": 12}}],
    "mage": [{"lv": 10, "n": "สมาธิ", "d": "INT +4", "st": {"int": 4}}, {"lv": 20, "n": "กระแสมานา", "d": "มานาฟื้นเร็วขึ้น 50%", "mpr": 0.5}, {"lv": 35, "n": "จิตแกร่ง", "d": "INT +10 · VIT +4", "st": {"int": 10, "vit": 4}}, {"lv": 50, "n": "อาร์คเมจ", "d": "INT +15", "st": {"int": 15}}],
    "archer": [{"lv": 10, "n": "ตาเหยี่ยว", "d": "คริติคอล +5%", "crit": 0.05}, {"lv": 20, "n": "ฝีเท้าเบา", "d": "AGI +5 · END +4", "st": {"agi": 5, "end": 4}}, {"lv": 35, "n": "นักล่า", "d": "AGI +10", "st": {"agi": 10}}, {"lv": 50, "n": "มือปืนเทวดา", "d": "คริติคอล +8% · AGI +8", "crit": 0.08, "st": {"agi": 8}}],
    "ninja": [{"lv": 10, "n": "ฝีเท้าเงา", "d": "AGI +5", "st": {"agi": 5}}, {"lv": 20, "n": "สัญชาตญาณนักฆ่า", "d": "คริติคอล +5%", "crit": 0.05}, {"lv": 35, "n": "เงาไร้ตัวตน", "d": "AGI +10 · STR +5", "st": {"agi": 10, "str": 5}}, {"lv": 50, "n": "จุดตาย", "d": "คริติคอล +8%", "crit": 0.08}, {"lv": 80, "n": "ราชันเงา", "d": "AGI +18 · STR +10", "st": {"agi": 18, "str": 10}}, {"lv": 120, "n": "นินจาตำนาน", "d": "คริ +10% · AGI +25", "crit": 0.1, "st": {"agi": 25}}],
    "sniper": [{"lv": 10, "n": "สายตาอินทรี", "d": "คริติคอล +5%", "crit": 0.05}, {"lv": 20, "n": "มือนิ่ง", "d": "AGI +6", "st": {"agi": 6}}, {"lv": 35, "n": "นักแม่นปืน", "d": "AGI +12", "st": {"agi": 12}}, {"lv": 50, "n": "เล็งจุดอ่อน", "d": "คริติคอล +8%", "crit": 0.08}, {"lv": 80, "n": "ราชาซุ่มยิง", "d": "AGI +22", "st": {"agi": 22}}, {"lv": 120, "n": "กระสุนเทพ", "d": "คริ +10% · AGI +25", "crit": 0.1, "st": {"agi": 25}}],
    "paladin": [{"lv": 10, "n": "ศรัทธามั่น", "d": "VIT +6", "st": {"vit": 6}}, {"lv": 20, "n": "พรแห่งแสง", "d": "ฟื้นเลือด 1%/วิ", "regen": 0.01}, {"lv": 35, "n": "เกราะศรัทธา", "d": "VIT +12 · STR +6", "st": {"vit": 12, "str": 6}}, {"lv": 50, "n": "อัศวินแสง", "d": "STR +12", "st": {"str": 12}}, {"lv": 80, "n": "ผู้พิทักษ์", "d": "VIT +25", "st": {"vit": 25}}, {"lv": 120, "n": "อัครเทวทูต", "d": "VIT +30 · STR +20 · ฟื้นเลือด 1%/วิ", "st": {"vit": 30, "str": 20}, "regen": 0.01}],
    "cleric": [{"lv": 10, "n": "จิตสงบ", "d": "INT +5", "st": {"int": 5}}, {"lv": 20, "n": "พรกระแสมานา", "d": "มานาฟื้นเร็ว +60%", "mpr": 0.6}, {"lv": 35, "n": "ผู้รักษา", "d": "INT +10 · VIT +6 · ฟื้นเลือด 0.5%/วิ", "st": {"int": 10, "vit": 6}, "regen": 0.005}, {"lv": 50, "n": "แสงพิพากษา", "d": "INT +14", "st": {"int": 14}}, {"lv": 80, "n": "นักบุญ", "d": "INT +22 · VIT +10", "st": {"int": 22, "vit": 10}}, {"lv": 120, "n": "ผู้แทนสวรรค์", "d": "INT +30 · VIT +16", "st": {"int": 30, "vit": 16}}],
    "necro": [{"lv": 10, "n": "กลิ่นอายความตาย", "d": "INT +5", "st": {"int": 5}}, {"lv": 20, "n": "กระดูกแกร่ง", "d": "VIT +6", "st": {"vit": 6}}, {"lv": 35, "n": "ดูดวิญญาณ", "d": "INT +12", "st": {"int": 12}}, {"lv": 50, "n": "จ้าวกระดูก", "d": "INT +14 · VIT +6", "st": {"int": 14, "vit": 6}}, {"lv": 80, "n": "ราชันมรณะ", "d": "INT +24", "st": {"int": 24}}, {"lv": 120, "n": "อมตะ", "d": "INT +30 · VIT +16", "st": {"int": 30, "vit": 16}}],
    "monk": [{"lv": 10, "n": "หมัดเหล็ก", "d": "STR +4 · AGI +2", "st": {"str": 4, "agi": 2}}, {"lv": 20, "n": "ลมปราณ", "d": "ฟื้นเลือด 0.8%/วิ", "regen": 0.008}, {"lv": 35, "n": "มวยวัด", "d": "STR +8 · AGI +8", "st": {"str": 8, "agi": 8}}, {"lv": 50, "n": "จิตไร้ขอบเขต", "d": "คริติคอล +6%", "crit": 0.06}, {"lv": 80, "n": "ปรมาจารย์", "d": "STR +16 · AGI +14", "st": {"str": 16, "agi": 14}}, {"lv": 120, "n": "อรหันต์", "d": "STR +24 · AGI +20 · VIT +10", "st": {"str": 24, "agi": 20, "vit": 10}}],
    "dragoon": [{"lv": 10, "n": "เลือดมังกร", "d": "STR +5", "st": {"str": 5}}, {"lv": 20, "n": "เกล็ดมังกร", "d": "VIT +6", "st": {"vit": 6}}, {"lv": 35, "n": "ทวนเพลิง", "d": "STR +12", "st": {"str": 12}}, {"lv": 50, "n": "วิญญาณมังกร", "d": "STR +12 · VIT +8", "st": {"str": 12, "vit": 8}}, {"lv": 80, "n": "จ้าวนภา", "d": "STR +24", "st": {"str": 24}}, {"lv": 120, "n": "ราชันมังกร", "d": "STR +30 · VIT +18", "st": {"str": 30, "vit": 18}}],
    "summoner": [{"lv": 10, "n": "สหายป่า", "d": "AGI +5", "st": {"agi": 5}}, {"lv": 20, "n": "ภาษาสัตว์", "d": "VIT +6", "st": {"vit": 6}}, {"lv": 35, "n": "จ้าวฝูง", "d": "AGI +10 · VIT +6", "st": {"agi": 10, "vit": 6}}, {"lv": 50, "n": "วิญญาณป่า", "d": "AGI +14", "st": {"agi": 14}}, {"lv": 80, "n": "ผู้นำเผ่า", "d": "AGI +22 · VIT +10", "st": {"agi": 22, "vit": 10}}, {"lv": 120, "n": "จ้าวสรรพสัตว์", "d": "AGI +30 · VIT +16", "st": {"agi": 30, "vit": 16}}],
}

var town
var cd := [0.0, 0.0, 0.0]
var step := 0
var win := 0.0
var pers: Array = []   # ผลต่อเนื่อง: {k, t, l, tick, acc, at}
var bless_t := 0.0     # อวยพรเทวา
var aegis_t := 0.0     # ปราการเทพ
var zen_t := 0.0       # จิตอรหันต์
var allies: Array = [] # สัตว์/โครงกระดูกที่เรียกมา

func setup(t) -> void:
    town = t

# ---------- ค่าพลังจากอาชีพ ----------
func passives_on(p) -> Array:
    var L := []
    for ps in PASSIVE.get(p.cls, []):
        if p.lv >= int(ps.lv):
            L.append(ps)
    return L

## โบนัสสเตตัสจากอาชีพ + พาสซีฟ (calcBonus)
func stat_bonus(p, k: String) -> int:
    var b := 0
    var L: int = p.lv
    match p.cls:
        "sword":
            if k == "vit":
                b += 2 + L / 3
            elif k == "str":
                b += L / 5
        "mage":
            if k == "int":
                b += 4 + L / 2
        "archer":
            if k == "agi":
                b += 3 + L / 3
        "ninja":
            if k == "agi":
                b += 3 + L / 3
        "sniper":
            if k == "agi":
                b += 4 + L / 3
        "paladin":
            if k == "vit":
                b += 4 + L / 3
        "cleric":
            if k == "int":
                b += 3 + L / 3
            elif k == "vit":
                b += L / 5
        "necro":
            if k == "int":
                b += 4 + L / 3
        "monk":
            if k == "str" or k == "agi":
                b += 2 + L / 4
        "dragoon":
            if k == "str":
                b += 3 + L / 3
            elif k == "vit":
                b += L / 6
        "summoner":
            if k == "agi":
                b += 3 + L / 3
        "rogue":
            if k == "agi":
                b += 2 + L / 4
            elif k == "str":
                b += 1 + L / 5
    for ps in passives_on(p):
        if ps.has("st"):
            b += int(ps.st.get(k, 0))
    return b

func crit_bonus(p) -> float:
    var c: float = {"archer": 0.1, "ninja": 0.12, "sniper": 0.08, "rogue": 0.06}.get(p.cls, 0.0)
    for ps in passives_on(p):
        c += float(ps.get("crit", 0.0))
    return c

func mp_regen_mult(p) -> float:
    var m: float = {"mage": 2.5, "cleric": 2.0}.get(p.cls, 1.0)
    if bless_t > 0.0:
        m += 1.0
    for ps in passives_on(p):
        m += float(ps.get("mpr", 0.0))
    return m

## ตัวคูณพิเศษของอาชีพ (fix25): ดาเมจคริ · โจมตี (อวยพรเทวา) · ดาเมจที่ได้รับ (พาลาดิน/ปราการเทพ) · ความเร็ว · ความเร็วตี · ดูดเลือด
func crit_dmg_bonus(p) -> float:
    return 0.6 if p.cls == "sniper" else 0.0

func atk_mult(_p) -> float:
    return 1.35 if bless_t > 0.0 else 1.0

func dmg_taken_mult(p) -> float:
    var m := 0.85 if p.cls == "paladin" else 1.0
    if aegis_t > 0.0:
        m *= 0.4
    return m

func speed_mult(p) -> float:
    return (1.15 if p.cls == "ninja" else 1.0) * (1.3 if zen_t > 0.0 else 1.0)

func atk_speed_mult(p) -> float:
    return 0.8 if p.cls == "monk" else 1.0

func lifesteal(p) -> float:
    return 0.04 if p.cls == "necro" else 0.0

func hp_regen_pct(p) -> float:
    var r := 0.005 if p.cls == "paladin" else 0.0
    if bless_t > 0.0:
        r += 0.04
    for ps in passives_on(p):
        r += float(ps.get("regen", 0.0))
    return r

## แจ้งเตือนตอนเลเวลอัป: ถึง Lv.10 ไปเลือกอาชีพ · ปลดล็อกสกิล/พาสซีฟใหม่
func on_level(p, l0: int) -> void:
    var msg := ""
    if l0 < CLASS_LV and p.lv >= CLASS_LV and p.cls == "none":
        msg = "Lv.%d แล้ว! ไปเลือกอาชีพกับปรมาจารย์อาชีพที่จัตุรัสได้เลย" % CLASS_LV
    if l0 < ADV_LV and p.lv >= ADV_LV and BASES.has(p.cls):
        msg = "Lv.%d แล้ว! ไปเลื่อนขั้นอาชีพกับปรมาจารย์อาชีพได้เลย" % ADV_LV
    if p.cls != "none":
        for s in SK[p.cls]:
            if l0 < int(s.lv) and p.lv >= int(s.lv):
                msg = "ปลดล็อกสกิลใหม่: " + str(s.n)
    for ps in PASSIVE.get(p.cls, []):
        if l0 < int(ps.lv) and p.lv >= int(ps.lv):
            msg += (" · " if msg != "" else "") + "พาสซีฟ " + str(ps.n) + " — " + str(ps.d)
    if msg != "":
        town.field.say_msg(msg, 4.5)
    if town.mobile != null:
        town.mobile.refresh_skills()

# ---------- เลือกอาชีพ ----------
## สายหลักของอาชีพ k (สายย่อย → สายหลัก)
func base_of(k: String) -> String:
    for b in ADV.keys():
        if (ADV[b] as Array).has(k):
            return b
    return k

func model_of(k: String) -> String:
    return str(MODEL.get(k, MODEL.get(base_of(k), "knight")))

## เลือกสายหลัก (Lv.10) หรือเลื่อนขั้นเป็นสายย่อย (Lv.40 ต้องเป็นสายหลักเดียวกัน)
func pick(k: String) -> String:
    var p = town.player
    if not CLS.has(k) or k == "none":
        return ""
    if p.cls == k:
        return "เป็น%sอยู่แล้ว" % CLS[k].n
    var adv: bool = not BASES.has(k)
    var cost := 0
    if adv:
        if base_of(p.cls) != base_of(k):
            return "%s เป็นสายเลื่อนขั้นของ%s — ต้องเป็น%sก่อน" % [CLS[k].n, CLS[base_of(k)].n, CLS[base_of(k)].n]
        if p.lv < ADV_LV:
            return "เลื่อนขั้นได้ตั้งแต่ Lv.%d (ตอนนี้ Lv.%d)" % [ADV_LV, p.lv]
        cost = 0 if BASES.has(p.cls) else CHANGE_COST
    else:
        if p.lv < CLASS_LV:
            return "เลือกอาชีพได้ตั้งแต่ Lv.%d — ไปฟาร์มเก็บเลเวลก่อนนะ" % CLASS_LV
        cost = 0 if p.cls == "none" else CHANGE_COST
    if p.coins < cost:
        return "เหรียญไม่พอ (ต้องใช้ %d)" % cost
    p.coins -= cost
    p.cls = k
    step = 0
    cd = [0.0, 0.0, 0.0]
    p.recalc_stats()
    if p.has_method("refresh_model"):
        p.refresh_model()
    if town.mobile != null:
        town.mobile.refresh_skills()
    if adv:
        return "เลื่อนขั้นเป็น%sแล้ว! สกิลใหม่ 3 ท่าพร้อมใช้" % CLS[k].n
    return "คุณกลายเป็น%sแล้ว! อย่าลืมคราฟ%sที่ทั่งตีเหล็ก เพื่อใช้สกิลอาชีพ" % [CLS[k].n, WNAME[CLS[k].w]]

func _class_btn(k: String, tag: String) -> Button:
    var C: Dictionary = CLS[k]
    var sk := []
    for s in SK[k]:
        sk.append("%s (Lv.%d)" % [s.n, s.lv])
    var b := Button.new()
    b.text = "%s%s\n%s\nติดตัว: %s · อาวุธ: %s\nสกิล: %s" % [C.n, tag, C.d, C.pas, WNAME[C.w], " · ".join(sk)]
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.add_theme_font_override("font", town.font_b)
    b.add_theme_font_size_override("font_size", 14)
    b.add_theme_color_override("font_color", C.col)
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func():
        var m := pick(k)
        if m != "":
            town.field.say_msg(m, 4.0)
        open_menu())
    return b

func open_menu() -> void:
    var p = town.player
    town.cur_shop = "class"
    for c in town.ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(town._nowrap(town._lbl("ปรมาจารย์อาชีพ — 4 สำนัก", 22, Color(0.85, 0.75, 1.0), true)))
    var sub := "อาชีพปัจจุบัน: %s · " % CLS[p.cls].n + ("เลือกครั้งแรกฟรี" if p.cls == "none" else "เปลี่ยนสาย %d เหรียญ" % CHANGE_COST)
    if p.lv < CLASS_LV:
        sub += " · ต้อง Lv.%d ขึ้นไป (ตอนนี้ Lv.%d)" % [CLASS_LV, p.lv]
    hv.add_child(town._lbl(sub, 14, Color(1.0, 0.85, 0.45)))
    top.add_child(hv)
    var xb: Button = town._btn("X", true, town.close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    town.ui_shop_body.add_child(top)
    var base: String = base_of(p.cls)
    if ADV.has(base):
        var head := "เลื่อนขั้น (Lv.%d)" % ADV_LV + (" — ครั้งแรกฟรี" if BASES.has(p.cls) else " — สลับสายย่อย %d เหรียญ" % CHANGE_COST)
        town.ui_shop_body.add_child(town._lbl(head, 17, Color(1.0, 0.9, 0.5), true))
        for k in ADV[base]:
            town.ui_shop_body.add_child(_class_btn(k, "  ✓ ปัจจุบัน" if p.cls == k else ("" if p.lv >= ADV_LV else "  (Lv.%d)" % ADV_LV)))
        town.ui_shop_body.add_child(town._lbl("สายหลัก (เปลี่ยนแล้วกลับเป็นสายหลัก ต้องเลื่อนขั้นใหม่)", 15, Color(0.8, 0.85, 0.95)))
    for k in BASES:
        town.ui_shop_body.add_child(_class_btn(k, "  ✓ สายของคุณ" if base == k else ""))
    town.ui_shop.visible = true

# ---------- ปุ่มสกิล 4 ช่อง ----------
## ช่อง 0-2: ไม่มีอาชีพ = ฟันวงพายุ / ลูกไฟ / - · มีอาชีพ = สกิลอาชีพ 3 ท่า · ช่อง 3: เยียวยา (ถ้าเรียนแล้ว)
func slot_name(p, i: int) -> String:
    if i == 3:
        return "เยียวยา" if p.skills.has("heal") else ""
    if p.cls == "none":
        var ids := ["whirl", "fireball", ""]
        var id: String = ids[i]
        return town.Items.SKILL[id].name if id != "" and p.skills.has(id) else ""
    var S: Dictionary = SK[p.cls][i]
    return str(S.n) if p.lv >= int(S.lv) else ""

func slot_cd(p, i: int) -> float:
    if i == 3:
        return float(p.skill_cd.get("heal", 0.0))
    if p.cls == "none":
        return float(p.skill_cd.get(["whirl", "fireball", ""][i], 0.0))
    return 0.0 if (i == 1 and step > 0) else float(cd[i])

func use_slot(i: int) -> String:
    var p = town.player
    if i == 3:
        return p.use_skill("heal")
    if p.cls == "none":
        var id: String = ["whirl", "fireball", ""][i]
        return p.use_skill(id) if id != "" else ""
    return use_class(i)

func _mp(S: Dictionary, st: int) -> int:
    return int(S.mp[st]) if S.mp is Array else int(S.mp)

func use_class(i: int) -> String:
    var p = town.player
    if p.dead or p.stun > 0.0 or p.dash_t > 0.0:
        return ""
    var S: Dictionary = SK[p.cls][i]
    if p.lv < int(S.lv):
        return "%s ปลดล็อกที่ Lv.%d" % [S.n, S.lv]
    var need: String = CLS[p.cls].w
    if not p.eq.has("weapon") or str(p.eq.weapon.k) != need:
        return "ต้องถือ%sเพื่อใช้สกิล%s" % [WNAME[need], CLS[p.cls].n]
    if town.room != "" or (abs(p.position.x) <= 44.0 and abs(p.position.z) <= 34.0 and p.position.x < 600.0):
        return "ใช้สกิลต่อสู้ในเมืองไม่ได้"
    var chain: bool = S.has("steps") and step > 0 and i == 1
    if not chain and cd[i] > 0.0:
        return "%s ยังไม่พร้อม (%.1f วิ)" % [S.n, cd[i]]
    var st := step if chain else 0
    var mp := _mp(S, st)
    if p.mp < mp:
        return "มานาไม่พอ (ต้องใช้ %d)" % mp
    p.mp -= mp
    p.at = -1.0
    if S.has("steps"):
        step = st + 1
        win = 1.8
        if step >= 3:
            step = 0
            win = 0.0
            cd[i] = float(S.cd)
    else:
        cd[i] = float(S.cd)
    _face_target(p)
    call("_" + p.cls + str(i), p, st)
    town.field.float_text(str(S.n) + ((" " + ["Ⅰ", "Ⅱ", "Ⅲ"][st]) if S.has("steps") else ""), p.position + Vector3(0, 3.0, 0), CLS[p.cls].col, 1.1)
    return str(S.n)

func _face_target(p) -> void:
    var s = town.field.nearest_slime(p.position, 14.0)
    if s != null:
        p.heading = atan2(s.position.x - p.position.x, s.position.z - p.position.z)
        p.body.rotation.y = p.heading

func _fwd(p) -> Vector3:
    return Vector3(sin(p.heading), 0, cos(p.heading))

# ---------- นักดาบ ----------
func _sword0(p, _st: int) -> void:
    p.body.action("2H_Melee_Attack_Spin", 0.6)
    town.field.aoe(p, 3.6, 1.8, Vector3.INF, 1.6, Color(1.0, 0.75, 0.4))

func _sword1(p, st: int) -> void:
    var f := _fwd(p)
    match st:
        0:
            p.body.action("1H_Melee_Attack_Stab", 0.4)
            for k in 6:
                var nx: Vector3 = p.position + f * 0.5
                if not town.blocked(nx.x, nx.z):
                    p.position = nx
            p.iframe = max(p.iframe, 0.3)
            town.field.aoe(p, 1.9, 1.4, p.position + f * 1.0, 0.0, Color(1.0, 0.6, 0.4))
        1:
            p.body.action("1H_Melee_Attack_Slice_Horizontal", 0.45)
            town.field.aoe(p, 2.4, 1.6, p.position + f * 0.8, 0.6, Color(1.0, 0.85, 0.5))
        2:
            p.body.action("1H_Melee_Attack_Slice_Diagonal", 0.45)
            town.field.shoot(p, {"range": 16.0, "speed": 22.0, "kind": "bolt", "pierce": true, "col": Color(1.0, 0.85, 0.5), "size": 0.45}, 2.4)

func _sword2(p, _st: int) -> void:
    p.body.action("2H_Melee_Attack_Spin", 2.6)
    pers.append({"k": "storm", "t": 0.0, "l": 2.6, "tick": 0.3, "acc": 0.0})

# ---------- นักเวท ----------
func _mage0(p, _st: int) -> void:
    p.body.action("Spellcast_Raise", 0.6)
    town.field.aoe(p, 3.2, 0.8, Vector3.INF, 0.0, Color(1.0, 0.45, 0.15))
    pers.append({"k": "firering", "t": 0.0, "l": 4.5, "tick": 0.5, "acc": 0.0})

func _mage1(p, st: int) -> void:
    match st:
        0:
            p.body.action("Spellcast_Shoot", 0.4)
            for a in [-0.3, -0.15, 0.0, 0.15, 0.3]:
                town.field.shoot(p, {"range": 15.0, "speed": 20.0, "kind": "bolt", "yaw": a, "stun": 0.6, "col": Color(0.6, 0.9, 1.0)}, 0.9)
        1:
            p.body.action("Spellcast_Shoot", 0.4)
            var hit := []
            var from: Vector3 = p.position
            for n in 5:
                var best = null
                var bd := 10.0
                for s in town.field._targets():
                    if not is_instance_valid(s) or s.dead or hit.has(s):
                        continue
                    var d := Vector2(s.position.x - from.x, s.position.z - from.z).length()
                    if d < bd:
                        bd = d
                        best = s
                if best == null:
                    break
                hit.append(best)
                _bolt(from, best.position)
                from = best.position
                town.field.hit_slime(best, p, 1.2)
        2:
            p.body.action("Spellcast_Summon", 0.6)
            var at: Vector3 = p.position + _fwd(p) * 6.0
            var s = town.field.nearest_slime(p.position, 12.0)
            if s != null:
                at = s.position
            _meteor(at, 3.5, 3.2)

func _mage2(p, _st: int) -> void:
    p.body.action("Spellcast_Raise", 0.8)
    pers.append({"k": "meteors", "t": 0.0, "l": 3.5, "tick": 0.35, "acc": 0.0})

# ---------- นักธนู ----------
func _archer0(p, _st: int) -> void:
    p.body.action("1H_Ranged_Shoot", 0.4)
    for a in [-0.36, -0.18, 0.0, 0.18, 0.36]:
        town.field.shoot(p, {"range": 22.5, "speed": 26.0, "kind": "arrow", "yaw": a}, 0.9)

func _archer1(p, st: int) -> void:
    p.body.action("1H_Ranged_Shoot", 0.4)
    match st:
        0:
            town.field.shoot(p, {"range": 26.0, "speed": 30.0, "kind": "arrow", "pierce": true}, 1.5)
        1:
            var back: Vector3 = -_fwd(p)
            for k in 5:
                var nx: Vector3 = p.position + back * 0.5
                if not town.blocked(nx.x, nx.z):
                    p.position = nx
            p.iframe = max(p.iframe, 0.4)
            town.field.shoot(p, {"range": 22.5, "speed": 26.0, "kind": "arrow"}, 1.2)
        2:
            town.field.shoot(p, {"range": 22.5, "speed": 24.0, "kind": "bolt", "boom": 3.0, "stun": 1.0, "col": Color(1.0, 0.75, 0.3), "size": 0.3}, 2.6)

func _archer2(p, _st: int) -> void:
    pers.append({"k": "rain", "t": 0.0, "l": 3.0, "tick": 0.25, "acc": 0.0, "at": p.position + _fwd(p) * 5.0})

# ---------- โจร (0.27) ----------
func _rogue0(p, _st: int) -> void:
    p.body.action("Dualwield_Melee_Attack_Stab", 0.35)
    for k in 2:
        town.field.aoe(p, 1.8, 1.2, p.position + _fwd(p) * 1.6, 0.0, Color(0.75, 0.6, 1.0))

func _rogue1(p, st: int) -> void:
    match st:
        0:
            p.body.action("Dualwield_Melee_Attack_Stab", 0.35)
            for k in 6:
                _blink(p, p.position + _fwd(p) * 0.5)
            town.field.aoe(p, 2.0, 1.5, p.position + _fwd(p) * 1.0, 0.0, Color(0.75, 0.6, 1.0))
        1:
            p.body.action("Dualwield_Melee_Attack_Slice", 0.4)
            town.field.aoe(p, 2.6, 1.5, Vector3.INF, 0.0, Color(0.7, 0.55, 1.0))
        2:
            p.body.action("Throw", 0.4)
            for a in [-0.15, 0.0, 0.15]:
                town.field.shoot(p, {"range": 16.0, "speed": 26.0, "kind": "bolt", "yaw": a, "pierce": true, "stun": 0.8, "col": Color(0.85, 0.85, 0.95), "size": 0.16}, 2.2)

func _rogue2(p, _st: int) -> void:
    p.body.action("Throw", 0.4)
    p.iframe = max(p.iframe, 0.8)
    for wave in 2:
        for i in 12:
            town.field.shoot(p, {"range": 13.0 + wave * 3.0, "speed": 20.0 + wave * 6.0, "kind": "bolt", "yaw": (i + wave * 0.5) * TAU / 12.0, "col": Color(0.8, 0.75, 1.0), "size": 0.16}, 1.2)

# ---------- 8 อาชีพเพิ่ม (fix25) ----------
func _nearest(p, r: float):
    return town.field.nearest_slime(p.position, r)

func _blink(p, to: Vector3) -> void:
    if not town.blocked(to.x, to.z):
        p.position = to

func _ninja0(p, _st: int) -> void:
    p.body.action("1H_Melee_Attack_Stab", 0.35)
    for i in 8:
        town.field.shoot(p, {"range": 12.0, "speed": 22.0, "kind": "bolt", "yaw": i * TAU / 8.0, "col": Color(0.75, 0.8, 1.0), "size": 0.18}, 0.9)

func _ninja1(p, st: int) -> void:
    match st:
        0:
            var s = _nearest(p, 10.0)
            if s != null:
                var back: Vector3 = (s.position - p.position).normalized()
                _blink(p, s.position + back * 1.2)
                p.heading = atan2(-back.x, -back.z)
                p.body.rotation.y = p.heading
                town.field.hit_slime(s, p, 1.8)
            p.body.action("1H_Melee_Attack_Stab", 0.35)
        1:
            p.body.action("2H_Melee_Attack_Spin", 0.45)
            town.field.aoe(p, 2.6, 1.4, Vector3.INF, 0.0, Color(0.6, 0.65, 1.0))
        2:
            town.field.aoe(p, 3.0, 2.0, Vector3.INF, 1.0, Color(0.5, 0.5, 0.6))
            p.iframe = max(p.iframe, 1.5)

func _ninja2(p, _st: int) -> void:
    pers.append({"k": "shadow", "t": 0.0, "l": 2.5, "tick": 0.25, "acc": 0.0})

func _sniper0(p, _st: int) -> void:
    p.body.action("1H_Ranged_Shoot", 0.4)
    town.field.shoot(p, {"range": 35.0, "speed": 40.0, "kind": "arrow", "pierce": true}, 3.0)

func _sniper1(p, st: int) -> void:
    p.body.action("1H_Ranged_Shoot", 0.4)
    match st:
        0:
            town.field.shoot(p, {"range": 30.0, "speed": 36.0, "kind": "arrow"}, 2.4 * 1.8)  # คริแน่นอน
        1:
            var back: Vector3 = -_fwd(p)
            for k in 5:
                _blink(p, p.position + back * 0.5)
            p.iframe = max(p.iframe, 0.4)
            for a in [-0.08, 0.08]:
                town.field.shoot(p, {"range": 28.0, "speed": 34.0, "kind": "arrow", "yaw": a}, 1.4)
        2:
            town.field.shoot(p, {"range": 28.0, "speed": 30.0, "kind": "bolt", "boom": 3.2, "col": Color(1.0, 0.8, 0.3), "size": 0.3}, 2.8)

func _sniper2(p, _st: int) -> void:
    pers.append({"k": "barrage", "t": 0.0, "l": 3.0, "tick": 0.2, "acc": 0.0, "at": p.position + _fwd(p) * 7.0})

func _paladin0(p, _st: int) -> void:
    p.body.action("2H_Melee_Attack_Spin", 0.5)
    town.field.aoe(p, 3.0, 1.7, Vector3.INF, 1.0, Color(1.0, 0.92, 0.55))
    p.hp = min(float(p.max_hp), p.hp + p.max_hp * 0.1)

func _paladin1(p, st: int) -> void:
    var f := _fwd(p)
    match st:
        0:
            for k in 6:
                _blink(p, p.position + f * 0.5)
            town.field.aoe(p, 2.0, 1.5, p.position + f, 0.0, Color(1.0, 0.92, 0.55))
        1:
            town.field.aoe(p, 2.2, 1.6, p.position + f * 1.2, 1.2, Color(1.0, 0.92, 0.55))
        2:
            var s = _nearest(p, 12.0)
            var at: Vector3 = s.position if s != null else p.position + f * 5.0
            town.field.aoe(p, 2.6, 2.8, at, 0.0, Color(1.0, 0.95, 0.7))
            _bolt(at + Vector3(0, 6.0, 0), at)
    p.body.action("1H_Melee_Attack_Slice_Horizontal", 0.4)

func _paladin2(p, _st: int) -> void:
    aegis_t = 6.0
    pers.append({"k": "aegis", "t": 0.0, "l": 6.0, "tick": 0.5, "acc": 0.0})

func _cleric0(p, _st: int) -> void:
    p.body.action("Spellcast_Raise", 0.6)
    p.hp = min(float(p.max_hp), p.hp + p.max_hp * 0.3)
    town.field.aoe(p, 2.8, 1.2, Vector3.INF, 0.0, Color(0.7, 1.0, 0.8))
    town.field.float_text("+30%", p.position + Vector3(0, 2.6, 0), Color(0.5, 1.0, 0.6), 1.1)

func _cleric1(p, st: int) -> void:
    p.body.action("Spellcast_Shoot", 0.4)
    match st:
        0:
            for a in [-0.2, 0.0, 0.2]:
                town.field.shoot(p, {"range": 16.0, "speed": 18.0, "kind": "bolt", "yaw": a, "col": Color(1.0, 1.0, 0.75)}, 1.4)
        1:
            town.field.aoe(p, 3.2, 1.5, Vector3.INF, 0.0, Color(1.0, 1.0, 0.75))
        2:
            town.field.shoot(p, {"range": 22.0, "speed": 30.0, "kind": "bolt", "pierce": true, "col": Color(1.0, 0.95, 0.6), "size": 0.45}, 3.2)

func _cleric2(p, _st: int) -> void:
    p.body.action("Spellcast_Raise", 0.8)
    bless_t = 8.0

func _necro0(p, _st: int) -> void:
    p.body.action("Spellcast_Summon", 0.6)
    _summon(p, "skeleton", 2, 6, 0.6, 30.0)

func _necro1(p, st: int) -> void:
    p.body.action("Spellcast_Shoot", 0.4)
    match st:
        0:
            town.field.shoot(p, {"range": 16.0, "speed": 18.0, "kind": "bolt", "col": Color(0.5, 1.0, 0.7)}, 1.6)
            p.hp = min(float(p.max_hp), p.hp + p.max_hp * 0.03)
        1:
            pers.append({"k": "curse", "t": 0.0, "l": 4.0, "tick": 0.5, "acc": 0.0, "at": p.position + _fwd(p) * 4.0})
        2:
            town.field.shoot(p, {"range": 20.0, "speed": 26.0, "kind": "arrow", "pierce": true}, 3.0)

func _necro2(p, _st: int) -> void:
    p.body.action("Spellcast_Summon", 0.8)
    town.field.aoe(p, 4.0, 2.2, Vector3.INF, 0.0, Color(0.4, 1.0, 0.6))
    _summon(p, "skeleton", 5, 11, 0.6, 30.0)

func _monk0(p, _st: int) -> void:
    pers.append({"k": "flurry", "t": 0.0, "l": 0.8, "tick": 0.1, "acc": 0.0})

func _monk1(p, st: int) -> void:
    match st:
        0:
            p.body.action("1H_Melee_Attack_Stab", 0.35)
            town.field.shoot(p, {"range": 10.0, "speed": 20.0, "kind": "bolt", "col": Color(1.0, 0.75, 0.4), "size": 0.35}, 1.6)
        1:
            p.body.action("1H_Melee_Attack_Slice_Horizontal", 0.4)
            town.field.aoe(p, 2.2, 1.8, p.position + _fwd(p), 0.8, Color(1.0, 0.75, 0.4))
        2:
            p.body.action("1H_Melee_Attack_Stab", 0.4)
            town.field.shoot(p, {"range": 14.0, "speed": 22.0, "kind": "bolt", "pierce": true, "col": Color(1.0, 0.6, 0.2), "size": 0.6}, 3.0)

func _monk2(p, _st: int) -> void:
    zen_t = 4.0
    p.iframe = max(p.iframe, 4.0)
    pers.append({"k": "zen", "t": 0.0, "l": 4.0, "tick": 0.25, "acc": 0.0})

func _dragoon0(p, _st: int) -> void:
    p.body.action("1H_Melee_Attack_Stab", 0.35)
    town.field.shoot(p, {"range": 9.0, "speed": 30.0, "kind": "arrow", "pierce": true}, 1.9)

func _dragoon1(p, st: int) -> void:
    match st:
        0:
            var s = _nearest(p, 8.0)
            var at: Vector3 = s.position if s != null else p.position + _fwd(p) * 4.0
            _blink(p, at + (p.position - at).normalized() * 1.0)
            town.field.aoe(p, 2.5, 1.8, at, 0.0, Color(1.0, 0.5, 0.4))
            p.iframe = max(p.iframe, 0.4)
        1:
            p.body.action("2H_Melee_Attack_Spin", 0.45)
            town.field.aoe(p, 2.8, 1.5, Vector3.INF, 0.0, Color(1.0, 0.5, 0.4))
        2:
            for a in [-0.25, 0.0, 0.25]:
                town.field.shoot(p, {"range": 8.0, "speed": 14.0, "kind": "fire", "yaw": a, "col": Color(1.0, 0.4, 0.1), "size": 0.35}, 0.9)

func _dragoon2(p, _st: int) -> void:
    var s = _nearest(p, 14.0)
    var at: Vector3 = s.position if s != null else p.position + _fwd(p) * 6.0
    _meteor(at, 4.0, 4.2)

func _summoner0(p, _st: int) -> void:
    p.body.action("Spellcast_Summon", 0.6)
    _summon(p, "wolf", 2, 4, 0.7 * 1.3, 30.0)

func _summoner1(p, st: int) -> void:
    p.body.action("Spellcast_Shoot", 0.4)
    match st:
        0:
            town.field.shoot(p, {"range": 18.0, "speed": 28.0, "kind": "arrow", "col": Color(0.8, 0.7, 0.5)}, 1.4 * 1.3)
        1:
            var s = _nearest(p, 10.0)
            var at: Vector3 = s.position if s != null else p.position + _fwd(p) * 3.0
            town.field.aoe(p, 2.4, 1.8 * 1.3, at, 0.0, Color(0.6, 0.4, 0.25))
        2:
            town.field.aoe(p, 4.0, 0.5, Vector3.INF, 2.0, Color(0.7, 0.9, 0.4))
            for a in allies:
                if is_instance_valid(a):
                    a.life = max(a.life, 20.0)

func _summoner2(p, _st: int) -> void:
    p.body.action("Spellcast_Summon", 0.8)
    town.field.aoe(p, 3.5, 2.0, Vector3.INF, 0.0, Color(1.0, 0.85, 0.3))
    _summon(p, "lion", 1, 1, 1.5 * 1.3, 25.0)

## เรียกสัตว์/โครงกระดูก n ตัว (รวมไม่เกิน mx ตัวต่อชนิด)
func _summon(p, kind: String, n: int, mx: int, mult: float, sec: float) -> void:
    allies = allies.filter(func(a): return is_instance_valid(a))
    var have := 0
    for a in allies:
        if a.kind == kind:
            have += 1
    for i in min(n, mx - have):
        var a := Node3D.new()
        a.set_script(load("res://scripts/ally.gd"))
        town.field.add_child(a)
        var ang := randf() * TAU
        a.setup(town, kind, mult, sec, p.position + Vector3(cos(ang), 0, sin(ang)) * 1.5)
        allies.append(a)

# ---------- เอฟเฟกต์ ----------
func _meteor(at: Vector3, r: float, mult: float) -> void:
    var p = town.player
    town.field.aoe(p, r, mult, at, 0.0, Color(1.0, 0.4, 0.1))
    var m := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.6
    sm.height = 1.2
    sm.radial_segments = 10
    sm.rings = 5
    m.mesh = sm
    m.material_override = town.M(Color(1.0, 0.45, 0.1), 0.3, 3.0)
    m.position = at + Vector3(0, 0.6, 0)
    town.field.add_child(m)
    town.field.projectiles.append({"n": m, "fx": true, "t": 0.0})

func _bolt(a: Vector3, b: Vector3) -> void:
    var m := MeshInstance3D.new()
    var bm := BoxMesh.new()
    var d := b - a
    bm.size = Vector3(0.12, 0.12, max(0.1, d.length()))
    m.mesh = bm
    m.material_override = town.M(Color(0.75, 0.85, 1.0), 0.2, 4.0)
    town.field.add_child(m)
    m.position = (a + b) * 0.5 + Vector3(0, 1.1, 0)
    var dn := d.normalized()
    m.look_at(b + Vector3(0, 1.1, 0), Vector3.FORWARD if abs(dn.y) > 0.95 else Vector3.UP)
    town.field.projectiles.append({"n": m, "fx": true, "t": 0.0})

func _process(delta: float) -> void:
    for i in 3:
        cd[i] = max(0.0, cd[i] - delta)
    bless_t = max(0.0, bless_t - delta)
    aegis_t = max(0.0, aegis_t - delta)
    zen_t = max(0.0, zen_t - delta)
    if win > 0.0:
        win -= delta
        if win <= 0.0 and step > 0:
            step = 0
            var p0 = town.player
            if p0.cls != "none":
                cd[1] = float(SK[p0.cls][1].cd)
    var p = town.player
    if p == null:
        return
    if p.cls != "none" and not p.dead and aegis_t <= 0.0:
        var r := hp_regen_pct(p)
        if r > 0.0:
            p.hp = min(float(p.max_hp), p.hp + p.max_hp * r * delta)
    for i in range(pers.size() - 1, -1, -1):
        var e: Dictionary = pers[i]
        e.t += delta
        e.acc += delta
        if p.dead:
            pers.remove_at(i)
            continue
        while e.acc >= e.tick:
            e.acc -= e.tick
            match str(e.k):
                "storm":
                    town.field.aoe(p, 2.8, 0.7, Vector3.INF, 0.0, Color(0.9, 0.95, 1.0))
                "firering":
                    town.field.aoe(p, 3.2, 0.6, Vector3.INF, 0.0, Color(1.0, 0.45, 0.15))
                "meteors":
                    var a := randf() * TAU
                    _meteor(p.position + Vector3(cos(a), 0, sin(a)) * randf_range(1.5, 6.0), 2.2, 1.4)
                "rain":
                    var at: Vector3 = e.at + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
                    town.field.aoe(p, 3.5, 0.5, e.at, 0.0, Color(0.6, 1.0, 0.6))
                    _bolt(at + Vector3(0, 4.0, 0), at)
                "shadow":
                    p.iframe = max(p.iframe, 0.3)
                    var s = _nearest(p, 8.0)
                    if s != null:
                        _blink(p, s.position + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)))
                        town.field.hit_slime(s, p, 1.3)
                "barrage":
                    town.field.aoe(p, 2.8, 0.6, e.at + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0)), 0.0, Color(1.0, 0.85, 0.4))
                "aegis":
                    town.field.aoe(p, 2.5, 0.5, Vector3.INF, 0.0, Color(1.0, 0.95, 0.6))
                "curse":
                    town.field.aoe(p, 3.0, 0.5, e.at, 0.0, Color(0.4, 1.0, 0.5))
                "flurry":
                    town.field.aoe(p, 1.9, 0.55, p.position + _fwd(p) * 1.2, 0.0, Color(1.0, 0.75, 0.4))
                "zen":
                    town.field.aoe(p, 2.5, 0.6, Vector3.INF, 0.0, Color(1.0, 0.85, 0.3))
        if e.t >= e.l:
            pers.remove_at(i)
