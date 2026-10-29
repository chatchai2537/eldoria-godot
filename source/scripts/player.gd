extends Node3D
const VisualStyle = preload("res://scripts/visual_style.gd")
## ผู้เล่น: คลิกเดิน / WASD · ยืนฟันธรรมดาซ้ำเมื่อกดค้าง · กลิ้งหลบ

const BAL := {"hp": 100, "mp": 50, "slime_dmg": 4, "combo_dmg": 8, "iframe": 0.8, "combo_win": 4.0, "kb": 55.0, "kb_heavy": 240.0, "stun": 0.28, "regen_delay": 6.0, "regen": 1.5, "mp_regen": 2.0}
const K := 2.0 / 32.0
const ATTACK_ANIMATION := "1H_Melee_Attack_Slice_Diagonal"
const ATTACK_DURATION := 0.45

var town
var body: Node3D
var path := PackedVector3Array()
var speed := 6.0
var heading := 0.0
var moving_speed := 0.0

# สถานะต่อสู้
var max_hp := 100
var max_mp := 50
var hp := 100.0
var mp := 50.0
var lv := 1
var xp := 0
var sp := 0
var stats := {"str": 0, "vit": 0, "int": 0, "agi": 0, "end": 0}
var coins := 0
var gel := 0
var stone := 0
var wood := 0
const Items = preload("res://scripts/items.gd")
var inv := {}          # ไอเท็มอื่นในกระเป๋า id -> จำนวน (เจล/หิน/ไม้ อยู่ในตัวแปรของมันเอง)
## อุปกรณ์ที่สวม: ช่อง -> ของ {k,t,q,e,b} · gear = อุปกรณ์ในกระเป๋า (รวมขวาน/ที่ขุดแร่ ที่ใช้จากกระเป๋าเลย)
var eq := {}
var gear: Array = []
## ชื่ออาวุธที่ถือ (เช่น "sword0") — เขียนค่าลงไปได้ (= ใส่อาวุธใหม่ระดับขาว) ใช้กับร้าน/เทส/เซฟเก่า
var weapon: String:
    get:
        return (str(eq.weapon.k) + str(eq.weapon.t)) if eq.has("weapon") else ""
    set(v):
        if v == "" or not Items.is_gear(v):
            eq.erase("weapon")
        else:
            eq["weapon"] = make_inst(v)
        update_gear_visual()
var weapon_tier: int:
    get:
        return int(eq.weapon.t) if eq.has("weapon") else 0
    set(v):
        if eq.has("weapon"):
            eq.weapon.t = clampi(v, 0, 5)
var skills := {}       # สกิลที่เรียนแล้ว id -> true
var cls := "none"
var dg_max := 1        # ดันเจี้ยนชั้นสูงสุดที่ลงได้
var pending_story = null
var pending_guild = null   # เนื้อเรื่องที่โหลดก่อนระบบ story ถูกสร้าง
var loaded_hp := -1.0      # อาชีพ: none / sword / mage / archer (skills.gd)
var skill_cd := {}     # คูลดาวน์ที่เหลือ
var buffs: Array = []  # [{stat, amt, t}] จากอาหาร
var bank := {}         # ของที่ฝากธนาคาร id -> จำนวน
var iframe := 0.0
var stun := 0.0
var kx := 0.0
var kz := 0.0
var hit_combo := 0
var hit_combo_t := 0.0
var since_hit := 99.0
var dead := false
var dead_t := 0.0
# ฟันดาบ
var at := -1.0
var atk_dur := ATTACK_DURATION
var queued := false
var attack_held := false
var cur_atk := 0
var target_mob = null
# เก็บชื่อ dash() ไว้ให้ input เดิมเรียกได้ แต่เป็นกลิ้ง 0.5 วิ ไม่พุ่ง
const ROLL := {"time": 0.5, "cd": 0.65, "distance": 2.3}
var dash_t := 0.0
var dash_cd := 0.0
var dash_v := Vector3.ZERO

func setup(t, pos: Vector3) -> void:
    town = t
    position = pos
    body = Node3D.new()
    body.set_script(load("res://scripts/model.gd"))
    add_child(body)
    body.build({"model": "knight", "keep": ["1H_Sword", "Round_Shield", "Knight_Cape", "Knight_Helmet"]})
    update_gear_visual()
    VisualStyle.add_contact(self, 1.65, 1.3)
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.61
    tm.outer_radius = 0.65
    ring.mesh = tm
    var rm := StandardMaterial3D.new()
    rm.albedo_color = Color(0.80, 0.72, 0.50, 0.5)
    rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = rm
    ring.position.y = 0.04
    ring.scale = Vector3(1, 0.2, 1)
    add_child(ring)

# ---- ค่าพลัง (สูตรเดียวกับ js/030-core.js) ----
func stat_total(k: String) -> int:
    var v: int = int(stats.get(k, 0))
    if town != null and town.classes != null:
        v += town.classes.stat_bonus(self, k)
    for b in buffs:
        if b.stat == k:
            v += int(b.amt)
    return v

func is_ranged() -> bool:
    return eq.has("weapon") and Items.RANGED.has(str(eq.weapon.k))

func ranged_spec() -> Dictionary:
    return Items.RANGED[str(eq.weapon.k)] if is_ranged() else {}

## โจมตี: ดาบใช้ STR · คทาใช้ INT · ธนูใช้ AGI · + อาวุธ (SWATK+คุณภาพ+ตีบวก) + แหวน
func atk() -> int:
    var w: int = Items.inst_stat(eq.weapon) if eq.has("weapon") else 0
    if eq.has("ring"):
        w += Items.inst_stat(eq.ring)
    var main := "str"
    if is_ranged():
        main = str(ranged_spec().stat)
    return 1 + w + stat_total(main) + ((lv - 1) >> 1)

# ---- อุปกรณ์ ----
func make_inst(id: String, q: int = 0) -> Dictionary:
    return {"k": Items.gear_kind(id), "t": Items.gear_tier(id), "q": q, "e": 0, "b": false}

## อุปกรณ์บนตัวละคร: ดาบ/คทา/หน้าไม้(ธนู) ในมือ · หมวก · ผ้าคลุม (เสื้อ) · โล่ (เกราะแขน) · สีตามระดับ เรืองแสงตามคุณภาพ
const TIER_COL := [Color("#9a9da5"), Color("#aab4c5"), Color("#d98443"), Color("#cfd7e6"), Color("#f2c230"), Color("#5ec8ff")]

func update_gear_visual() -> void:
    if body == null or body.inst == null:
        return
    var w: Dictionary = eq.get("weapon", {})
    var wk := str(w.get("k", ""))
    if wk == "staff":
        body.borrow_item("mage", "2H_Staff")
    elif wk == "bow":
        body.borrow_item("rogue", "1H_Crossbow")
    var glow := func(it: Dictionary) -> float:
        return [0.0, 0.0, 0.12, 0.25][int(it.get("q", 0))] + (0.15 if int(it.get("e", 0)) >= 7 else 0.0)
    body.show_item("1H_Sword", wk == "sword", TIER_COL[int(w.get("t", 0))], glow.call(w) if wk == "sword" else 0.0)
    body.show_item("2H_Staff", wk == "staff", TIER_COL[int(w.get("t", 0))], glow.call(w) if wk == "staff" else 0.0)
    body.show_item("1H_Crossbow", wk == "bow", TIER_COL[int(w.get("t", 0))], glow.call(w) if wk == "bow" else 0.0)
    for pair in [["helm", "Knight_Helmet"], ["chest", "Knight_Cape"], ["arm", "Round_Shield"]]:
        var it: Dictionary = eq.get(pair[0], {})
        # ผ้าคลุมไม่เรืองแสง (ผืนใหญ่ บังตัวละคร) · ย้อมสีอ่อน ๆ
        var gl: float = 0.0 if pair[0] == "chest" or it.is_empty() else glow.call(it)
        body.show_item(str(pair[1]), not it.is_empty(), TIER_COL[int(it.get("t", 0))] if not it.is_empty() else Color(0, 0, 0, 0), gl, 0.35 if pair[0] == "chest" else 0.65)

func equip(it: Dictionary) -> String:
    var k := str(it.k)
    if not Items.SLOT_OF.has(k):
        return "ของชิ้นนี้ใช้จากกระเป๋าได้เลย ไม่ต้องสวม"
    if it.get("b", false):
        return Items.inst_name(it) + " แตกอยู่ — ซ่อมที่ทั่งตีเหล็กก่อน"
    var slot: String = Items.SLOT_OF[k]
    gear.erase(it)
    if eq.has(slot):
        gear.append(eq[slot])
    eq[slot] = it
    recalc_stats()
    update_gear_visual()
    return "สวม " + Items.inst_name(it) + " แล้ว"

func unequip(slot: String) -> String:
    if not eq.has(slot):
        return ""
    var it: Dictionary = eq[slot]
    eq.erase(slot)
    gear.append(it)
    recalc_stats()
    update_gear_visual()
    return "ถอด " + Items.inst_name(it) + " เข้ากระเป๋า"

## เครื่องมือที่ดีที่สุดในกระเป๋า (ไม่แตก) · ไม่มี = {}
func best_tool(kind: String) -> Dictionary:
    var best := {}
    for it in gear:
        if it.k == kind and not it.get("b", false) and (best.is_empty() or int(it.t) > int(best.t) or (int(it.t) == int(best.t) and int(it.e) > int(best.e))):
            best = it
    return best

# ---- สเตตัส (js/031-core.js recalcStats / statAdd) ----
const STAT_NAMES := {"str": "STR พลัง (โจมตี)", "vit": "VIT อึด (เลือด +12 · ป้องกัน)", "int": "INT ปัญญา (มานา +6)", "agi": "AGI ว่องไว (คริ +0.4%)", "end": "END ทนทาน"}

func recalc_stats() -> void:
    max_hp = 100 + (lv - 1) * 15 + stat_total("vit") * 12 + (Items.inst_stat(eq.neck) if eq.has("neck") else 0)
    max_mp = 50 + (lv - 1) * 5 + stat_total("int") * 6
    hp = min(hp, float(max_hp))
    mp = min(mp, float(max_mp))

func stat_add(k: String, n: int = 1) -> int:
    if sp <= 0 or not stats.has(k):
        return 0
    n = min(max(1, n), sp)
    sp -= n
    stats[k] = int(stats[k]) + n
    recalc_stats()
    if k == "vit":
        hp = min(float(max_hp), hp + 12 * n)
    if k == "int":
        mp = min(float(max_mp), mp + 6 * n)
    return n

func crit_rate() -> float:
    return 0.08 + stat_total("agi") * 0.004 + (town.classes.crit_bonus(self) if town != null and town.classes != null else 0.0)

# ---- เซฟเกม (ในเครื่อง · เซฟเองทุก 10 วิ และตอนออก/สลับแอป) ----
var save_path := "user://eldoria_save.json"
var save_enabled := true
var _save_t := 0.0
const SAVE_KEYS := ["lv", "xp", "sp", "hp", "mp", "coins", "gel", "stone", "wood", "cls", "dg_max"]

func save_game() -> bool:
    if not save_enabled:
        return false
    var d := {"v": 2, "stats": stats.duplicate(), "inv": inv.duplicate(), "skills": skills.keys(), "bank": bank.duplicate(), "gear": gear.duplicate(true), "eq": eq.duplicate(true), "story": town.story.S.duplicate(true) if town.story != null else {}, "guild": town.guild.Q.duplicate(true) if town.guild != null else {}}
    for k in SAVE_KEYS:
        d[k] = get(k)
    var tmp := save_path + ".tmp"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify(d))
    f.close()
    DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(save_path))
    return true

func load_game() -> bool:
    if not save_enabled or not FileAccess.file_exists(save_path):
        return false
    var d = JSON.parse_string(FileAccess.get_file_as_string(save_path))
    if not (d is Dictionary):
        return false
    for k in SAVE_KEYS:
        if d.has(k):
            var v = d[k]
            if typeof(get(k)) == TYPE_INT:
                v = int(v)
            elif typeof(get(k)) == TYPE_FLOAT:
                v = float(v)
            else:
                v = str(v)
            set(k, v)
    if d.get("stats") is Dictionary:
        for k in stats.keys():
            stats[k] = int(d.stats.get(k, 0))
    inv = {}
    if d.get("inv") is Dictionary:
        for k in d.inv.keys():
            inv[str(k)] = int(d.inv[k])
    bank = {}
    if d.get("bank") is Dictionary:
        for k in d.bank.keys():
            bank[str(k)] = int(d.bank[k])
    skills = {}
    if d.get("skills") is Array:
        for k in d.skills:
            if Items.SKILL.has(str(k)):
                skills[str(k)] = true
    # อุปกรณ์ (เซฟรุ่น 2) · เซฟรุ่นเก่า: weapon/weapon_tier + ขวาน/ที่ขุดใน inv → แปลงเป็นของชิ้น
    gear = []
    eq = {}
    if d.get("gear") is Array:
        for it in d.gear:
            if it is Dictionary and Items.KINDS.has(str(it.get("k", ""))):
                gear.append(_clean_inst(it))
    if d.get("eq") is Dictionary:
        for sl in d.eq.keys():
            if d.eq[sl] is Dictionary and Items.SLOTS.has(str(sl)):
                eq[str(sl)] = _clean_inst(d.eq[sl])
    elif str(d.get("weapon", "")) != "":
        weapon = str(d.weapon)
        weapon_tier = int(d.get("weapon_tier", 0))
    for k in inv.keys():
        if Items.is_gear(str(k)):
            for i in int(inv[k]):
                gear.append(make_inst(str(k)))
            inv.erase(k)
    update_gear_visual()
    pending_story = d.get("story")
    pending_guild = d.get("guild")
    if town.guild != null:
        town.guild.load_state(pending_guild)
    if town.story != null:
        town.story.load_state(pending_story)
    if not ["none", "sword", "mage", "archer", "ninja", "sniper", "paladin", "cleric", "necro", "monk", "dragoon", "summoner"].has(cls):
        cls = "none"
    var keep_hp := hp
    loaded_hp = hp
    var keep_mp := mp
    recalc_stats()
    hp = clamp(keep_hp, 1.0, float(max_hp))
    mp = clamp(keep_mp, 0.0, float(max_mp))
    return true

func _clean_inst(it: Dictionary) -> Dictionary:
    return {"k": str(it.k), "t": clampi(int(it.get("t", 0)), 0, 5), "q": clampi(int(it.get("q", 0)), 0, 3), "e": clampi(int(it.get("e", 0)), 0, Items.MAXP), "b": bool(it.get("b", false))}

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_GO_BACK_REQUEST:
        save_game()

# ---- กระเป๋า ----
func inv_count(id: String) -> int:
    if Items.is_gear(id):
        var n := 0
        for it in gear:
            if str(it.k) + str(it.t) == id:
                n += 1
        for sl in eq:
            if str(eq[sl].k) + str(eq[sl].t) == id:
                n += 1
        return n
    match id:
        "gel": return gel
        "stone": return stone
        "wood": return wood
    return int(inv.get(id, 0))

func inv_add(id: String, n: int) -> void:
    if Items.is_gear(id):
        if n > 0:
            for i in n:
                gear.append(make_inst(id))
        else:
            for i in -n:
                for it in gear:
                    if str(it.k) + str(it.t) == id:
                        gear.erase(it)
                        break
        return
    match id:
        "gel": gel += n
        "stone": stone += n
        "wood": wood += n
        _:
            inv[id] = int(inv.get(id, 0)) + n
            if inv[id] <= 0:
                inv.erase(id)

func inv_take(id: String, n: int) -> bool:
    if inv_count(id) < n:
        return false
    inv_add(id, -n)
    return true

## ใช้ไอเท็มในกระเป๋า · คืนข้อความบอกผล
func use_item(id: String) -> String:
    var u: Dictionary = Items.ITEM.get(id, {}).get("use", {})
    if u.is_empty() or inv_count(id) <= 0 or dead:
        return ""
    if u.has("warp"):
        if position.x >= town.OX and abs(position.z) <= 34.0 and town.mine.cur < 0 and town.room == "":
            return "ใช้ม้วนวาปได้เฉพาะนอกเมือง"
        inv_take(id, 1)
        path = PackedVector3Array()
        target_mob = null
        if town.mine.cur >= 0:
            town.mine.leave(false)
        position = town.tw(town.SPAWN.x, town.SPAWN.y)
        return "วาปกลับเมืองเอลโดเรียแล้ว"
    var only_hp: bool = (u.has("hp") or u.has("hpp")) and not (u.has("mp") or u.has("mpp") or u.has("buff"))
    var only_mp: bool = (u.has("mp") or u.has("mpp")) and not (u.has("hp") or u.has("hpp") or u.has("buff"))
    if only_hp and hp >= max_hp:
        return "เลือดเต็มอยู่แล้ว"
    if only_mp and mp >= max_mp:
        return "มานาเต็มอยู่แล้ว"
    inv_take(id, 1)
    hp = min(float(max_hp), hp + float(u.get("hp", 0)) + max_hp * float(u.get("hpp", 0)) / 100.0)
    mp = min(float(max_mp), mp + float(u.get("mp", 0)) + max_mp * float(u.get("mpp", 0)) / 100.0)
    if u.has("buff"):
        for k in u.buff.keys():
            buffs.append({"stat": str(k), "amt": int(u.buff[k]), "t": float(u.get("sec", 60))})
        recalc_stats()
    var verb := "กิน " if Items.ITEM.get(id, {}).get("note", "").find("อิ่ม") >= 0 else "ใช้ "
    return verb + Items.item_name(id) + " แล้ว"

# ---- สกิล (ร้านสกิล) ----
func learn_skill(id: String) -> bool:
    if skills.has(id) or not Items.SKILL.has(id):
        return false
    skills[id] = true
    return true

func use_skill(id: String) -> String:
    if dead or not skills.has(id):
        return ""
    var sk: Dictionary = Items.SKILL[id]
    if float(skill_cd.get(id, 0.0)) > 0.0:
        return "%s ยังไม่พร้อม (%.1f วิ)" % [sk.name, skill_cd[id]]
    if mp < float(sk.mp):
        return "มานาไม่พอ (ต้องใช้ %d)" % int(sk.mp)
    if id == "heal" and hp >= max_hp:
        return "เลือดเต็มอยู่แล้ว"
    mp -= float(sk.mp)
    skill_cd[id] = float(sk.cd)
    match id:
        "whirl":
            body.action("2H_Melee_Attack_Spin", 0.6)
            town.field.aoe(self, float(sk.radius), float(sk.mult))
        "fireball":
            body.action("Spellcast_Shoot", 0.5)
            town.field.shoot(self, {"range": sk.range, "speed": sk.speed, "kind": "fire"}, float(sk.mult))
        "heal":
            body.action("Spellcast_Raise", 0.6)
            hp = min(float(max_hp), hp + max_hp * float(sk.heal_pct) / 100.0)
            town.field.float_text("+%d%%" % int(sk.heal_pct), position + Vector3(0, 2.6, 0), Color(0.5, 1.0, 0.6), 1.1)
    return sk.name

## แรงขวาน AXEDMG = 1 + (ระดับขวาน >> 1)  (js/015-core.js)
func axe_dmg() -> int:
    var a := best_tool("axe")
    return Items.inst_stat(a) if not a.is_empty() else 1

func def() -> int:
    var d := (stat_total("vit") >> 1) + ((lv - 1) >> 2)
    for sl in ["helm", "chest", "pants", "arm"]:
        if eq.has(sl):
            d += Items.inst_stat(eq[sl])
    return d

func need(l: int) -> int:
    return int(round((20 + l * l * 12) * (1.0 if l < 20 else 1.0 + (l - 20) / 40.0)))

func gain_xp(n: int) -> void:
    xp += n
    town.field.float_text("+%d EXP" % n, position + Vector3(0, 2.6, 0), Color(0.6, 1.0, 0.5), 0.7)
    var ups := 0
    var l0 := lv
    while xp >= need(lv) and lv < 99:
        xp -= need(lv)
        lv += 1
        ups += 1
    if ups > 0:
        sp += 3 * ups
        recalc_stats()
        hp = max_hp
        mp = max_mp
        town.field.say_msg("เลเวลอัป! Lv.%d ได้แต้มสเตตัส +3" % lv, 3.5)
        town.field.float_text("LEVEL UP!", position + Vector3(0, 3.2, 0), Color(1.0, 0.85, 0.3), 1.5)
        if town.classes != null:
            town.classes.on_level(self, l0)

# ---- โดนสไลม์ตี (hurtPlayer เดิม) ----
func hurt_by(sl) -> void:
    if dead:
        return
    # เจ้าของสั่ง: โดนสไลม์ตีไม่กระเด็น ไม่ชะงัก (เตรียมทำระบบหลบ) — โดนแค่เลือดลด
    var dmg: int = max(1, BAL.slime_dmg + (sl.lv - 1) * 2 - def())
    if town.classes != null:
        dmg = max(1, int(round(dmg * town.classes.dmg_taken_mult(self))))
    hp = max(0.0, hp - dmg)
    iframe = BAL.iframe
    since_hit = 0.0
    town.field.float_text("-%d" % dmg, position + Vector3(0, 2.4, 0), Color(1.0, 0.35, 0.3), 1.1)
    town.field.say_msg("โดนสไลม์ตี เลือด -%d" % dmg)
    if hp <= 0.0:
        _die()
    elif at < 0.0:
        body.action("Hit_A", 0.35)

## โดนมอนในเหมืองตี (zHurt): ลดด้วยป้องกัน×0.8 · ไม่กระเด็น ไม่ชะงัก (เจ้าของสั่ง) · กลิ้งหลบได้ (อมตะ)
func hurt_mob(dmg: int, msg: String) -> void:
    if dead or iframe > 0.0:
        return
    var d: int = max(1, int(round(dmg - def() * 0.8)))
    if town.classes != null:
        d = max(1, int(round(d * town.classes.dmg_taken_mult(self))))
    hp = max(0.0, hp - d)
    iframe = BAL.iframe
    since_hit = 0.0
    town.field.float_text("-%d" % d, position + Vector3(0, 2.4, 0), Color(1.0, 0.35, 0.3), 1.1)
    town.field.say_msg(msg + " เลือด -%d" % d)
    if hp <= 0.0:
        _die()
    elif at < 0.0:
        body.action("Hit_A", 0.35)

func _die() -> void:
    if inv_take("phoenix", 1):
        hp = max_hp
        iframe = 2.0
        town.field.say_msg("ขนนกฟีนิกซ์ส่องแสง! ฟื้นทันทีตรงที่ล้ม", 3.0)
        return
    dead = true
    dead_t = 3.0
    path = PackedVector3Array()
    target_mob = null
    at = -1.0
    queued = false
    attack_held = false
    dash_t = 0.0
    body.end_roll()
    body.action("Death_A")
    town.field.say_msg("คุณล้มลงแล้ว... วิญญาณกำลังกลับสู่วิหารแห่งแสง", 3.0)

func _revive() -> void:
    dead = false
    hp = max_hp
    mp = max_mp
    kx = 0.0
    kz = 0.0
    iframe = 2.0
    stun = 0.3
    hit_combo = 0
    if town.mine.cur >= 0:
        town.mine.leave(false)
    position = town.tw(7.5, 23.5)
    body.revive()
    town.field.say_msg("ฟื้นที่วิหารแห่งแสง — เลือดเต็มแล้ว", 3.0)

# ---- ตีธรรมดาท่าเดียว: แตะ = หนึ่งครั้ง / กดค้าง = ฟันซ้ำโดยยืนที่เดิม ----
func set_attack_held(pressed: bool) -> void:
    attack_held = pressed
    if pressed:
        attack()

func attack() -> void:
    if dead or stun > 0.0 or dash_t > 0.0:
        return
    # ในร้าน: ปุ่มตี = คุยกับเจ้าของร้านเมื่อยืนหน้าเคาน์เตอร์ (เหมือน E/⚔️ ในเกม 2D) · ไม่ฟันในร้าน
    if town.room != "":
        town.rooms.interact_if_near()
        return
    # หน้าประตูมิติ: ปุ่มตี = เลือกแผนที่ขุดแร่ (กด E/⚔️ ในเกม 2D)
    if town.mine.cur < 0 and town.field.near_portal(self):
        town.mine.open_menu()
        return
    if town.mine.cur < 0 and town.field.near_dungeon(self):
        town.mine.open_dg_menu()
        return
    if town.mine.cur >= 0 and town.mine.chest_near():
        town.mine.chest_act()
        return
    if at >= 0.0:
        queued = true
        return
    atk_dur = ATTACK_DURATION * (town.classes.atk_speed_mult(self) if town.classes != null else 1.0)
    at = 0.0
    queued = false
    path = PackedVector3Array()
    var s = town.field.nearest_slime(position, 3.5 if not is_ranged() else float(ranged_spec().range))
    if s != null:
        heading = atan2(s.position.x - position.x, s.position.z - position.z)
        body.rotation.y = heading
    cur_atk = town.field.new_attack()
    if is_ranged():
        body.action("Spellcast_Shoot" if str(eq.weapon.k) == "staff" else "1H_Ranged_Shoot", atk_dur)
        town.field.shoot(self, ranged_spec(), 1.0)
        return
    body.action(ATTACK_ANIMATION, atk_dur)
    # ไม่มีสไลม์ใกล้ ๆ และหันหน้าเข้าต้นไม้ = ฟันต้นไม้ (ต้องมีขวาน)
    if s == null and town.mine.cur >= 0:
        town.mine.try_mine(self)
    elif s == null and town.field.has_method("try_chop"):
        town.field.try_chop(self)

func dash(dir: Vector3) -> void:
    if dead or dash_t > 0.0 or dash_cd > 0.0:
        return
    if dir.length() < 0.1:
        dir = Vector3(sin(heading), 0, cos(heading))
    dash_v = dir.normalized()
    heading = atan2(dash_v.x, dash_v.z)
    body.rotation.y = heading
    dash_t = ROLL.time
    dash_cd = ROLL.cd
    at = -1.0
    queued = false
    path = PackedVector3Array()
    target_mob = null
    iframe = max(iframe, ROLL.time)
    body.begin_roll(ROLL.time)

func set_path(p: PackedVector3Array) -> void:
    path = p

func has_path() -> bool:
    return path.size() > 0

func _try_move(v: Vector3) -> bool:
    var r := 0.35
    var nx := position.x + v.x
    var nz := position.z + v.z
    var moved := false
    if not town.blocked(nx + sign(v.x) * r, position.z) and not town.blocked(nx + sign(v.x) * r, position.z + r * 0.8) and not town.blocked(nx + sign(v.x) * r, position.z - r * 0.8):
        position.x = nx
        moved = true
    if not town.blocked(position.x, nz + sign(v.z) * r) and not town.blocked(position.x + r * 0.8, nz + sign(v.z) * r) and not town.blocked(position.x - r * 0.8, nz + sign(v.z) * r):
        position.z = nz
        moved = true
    return moved

func drive(dir: Vector3, delta: float) -> void:
    if dead or at >= 0.0 or attack_held or stun > 0.0 or dash_t > 0.0:
        return
    path = PackedVector3Array()
    target_mob = null
    var amt: float = clamp(dir.length(), 0.0, 1.0)
    var sm: float = town.classes.speed_mult(self) if town.classes != null else 1.0
    _try_move(dir.normalized() * speed * sm * amt * delta)
    _face(dir, delta)
    moving_speed = speed * amt

func _face(dir: Vector3, delta: float) -> void:
    if dir.length() < 0.01:
        return
    var want := atan2(dir.x, dir.z)
    heading = lerp_angle(heading, want, min(1.0, delta * 12.0))
    body.rotation.y = heading

func _process(delta: float) -> void:
    _save_t += delta
    if _save_t >= 10.0:
        _save_t = 0.0
        save_game()
    for k in skill_cd.keys():
        skill_cd[k] = max(0.0, float(skill_cd[k]) - delta)
    if buffs.size() > 0:
        var changed := false
        for i in range(buffs.size() - 1, -1, -1):
            buffs[i].t -= delta
            if buffs[i].t <= 0.0:
                buffs.remove_at(i)
                changed = true
        if changed:
            recalc_stats()
    if dead:
        dead_t -= delta
        if dead_t <= 0.0:
            _revive()
        position.y = town.ground_y(position.x, position.z)
        return
    iframe = max(0.0, iframe - delta)
    stun = max(0.0, stun - delta)
    dash_cd = max(0.0, dash_cd - delta)
    if dash_t > 0.0:
        var previous := 1.0 - dash_t / float(ROLL.time)
        dash_t = max(0.0, dash_t - delta)
        var progress := 1.0 - dash_t / float(ROLL.time)
        var distance_step: float = (cos(previous * PI) - cos(progress * PI)) * 0.5 * ROLL.distance
        iframe = max(iframe, 0.12)
        _try_move(dash_v * distance_step)
        position.y = town.ground_y(position.x, position.z)
        body.animate(delta, 0.0)
        body.update_roll(progress)
        if dash_t <= 0.0:
            body.end_roll()
        return
    hit_combo_t = max(0.0, hit_combo_t - delta)
    since_hit += delta
    if since_hit > BAL.regen_delay:
        hp = min(float(max_hp), hp + BAL.regen * delta)
    mp = min(float(max_mp), mp + BAL.mp_regen * delta * (town.classes.mp_regen_mult(self) if town.classes != null else 1.0))
    if kx != 0.0 or kz != 0.0:
        _try_move(Vector3(kx, 0, kz) * delta)
        var dd := pow(0.02, delta)
        kx *= dd
        kz *= dd
        if abs(kx) + abs(kz) < 4.0 * K:
            kx = 0.0
            kz = 0.0
    # ฟันด้านหน้าทุกครั้ง ไม่มีท่าหมุนรอบตัวหรือขั้นคอมโบ
    if at >= 0.0:
        at += delta
        var u := at / atk_dur
        if u > 0.2 and u < 0.7:
            if not is_ranged():
                town.field.melee(self, false, cur_atk)
        if u >= 1.0:
            at = -1.0
            if queued:
                attack()
    var holding := attack_held or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_SPACE)
    if holding and at < 0.0 and not town.ui_shop.visible and not town.ui_dialog.visible and not town.ui_bag.visible and not town.ui_char.visible:
        attack()
    # คลิกที่สไลม์: เดินเข้าไปแล้วฟันจนกว่าจะแตก
    if target_mob != null:
        if not is_instance_valid(target_mob) or target_mob.dead:
            target_mob = null
        else:
            var to := Vector3(target_mob.position.x - position.x, 0, target_mob.position.z - position.z)
            if to.length() < 1.9:
                path = PackedVector3Array()
                if at < 0.0:
                    attack()
            elif at < 0.0 and stun <= 0.0:
                path = PackedVector3Array([Vector3(target_mob.position.x, 0, target_mob.position.z)])
    if path.size() > 0 and at < 0.0 and stun <= 0.0:
        var tgt: Vector3 = path[0]
        var d := Vector3(tgt.x - position.x, 0, tgt.z - position.z)
        if d.length() < 0.25:
            path.remove_at(0)
        else:
            var step: float = min(d.length(), speed * (town.classes.speed_mult(self) if town.classes != null else 1.0) * delta)
            var dir := d.normalized()
            if not _try_move(dir * step):
                path = PackedVector3Array()
            _face(dir, delta)
            moving_speed = speed
    position.y = town.ground_y(position.x, position.z)
    body.animate(delta, moving_speed)
    moving_speed = 0.0
