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
func atk() -> int:
    return 1 + stats.str + ((lv - 1) >> 1)

func def() -> int:
    return (stats.vit >> 1) + ((lv - 1) >> 2)

func need(l: int) -> int:
    return int(round((20 + l * l * 12) * (1.0 if l < 20 else 1.0 + (l - 20) / 40.0)))

func gain_xp(n: int) -> void:
    xp += n
    town.field.float_text("+%d EXP" % n, position + Vector3(0, 2.6, 0), Color(0.6, 1.0, 0.5), 0.7)
    var up := false
    while xp >= need(lv) and lv < 99:
        xp -= need(lv)
        lv += 1
        up = true
    if up:
        sp += 3
        hp = max_hp
        mp = max_mp
        town.field.say_msg("เลเวลอัป! Lv.%d ได้แต้มสเตตัส +3" % lv, 3.5)
        town.field.float_text("LEVEL UP!", position + Vector3(0, 3.2, 0), Color(1.0, 0.85, 0.3), 1.5)

# ---- โดนสไลม์ตี (hurtPlayer เดิม) ----
func hurt_by(sl) -> void:
    if dead:
        return
    # เจ้าของสั่ง: โดนสไลม์ตีไม่กระเด็น ไม่ชะงัก (เตรียมทำระบบหลบ) — โดนแค่เลือดลด
    var dmg: int = max(1, BAL.slime_dmg + (sl.lv - 1) * 2 - def())
    hp = max(0.0, hp - dmg)
    iframe = BAL.iframe
    since_hit = 0.0
    town.field.float_text("-%d" % dmg, position + Vector3(0, 2.4, 0), Color(1.0, 0.35, 0.3), 1.1)
    town.field.say_msg("โดนสไลม์ตี เลือด -%d" % dmg)
    if hp <= 0.0:
        _die()
    elif at < 0.0:
        body.action("Hit_A", 0.35)

func _die() -> void:
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
    if at >= 0.0:
        queued = true
        return
    atk_dur = ATTACK_DURATION
    at = 0.0
    queued = false
    path = PackedVector3Array()
    var s = town.field.nearest_slime(position, 3.5)
    if s != null:
        heading = atan2(s.position.x - position.x, s.position.z - position.z)
        body.rotation.y = heading
    cur_atk = town.field.new_attack()
    body.action(ATTACK_ANIMATION, atk_dur)

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
    _try_move(dir.normalized() * speed * amt * delta)
    _face(dir, delta)
    moving_speed = speed * amt

func _face(dir: Vector3, delta: float) -> void:
    if dir.length() < 0.01:
        return
    var want := atan2(dir.x, dir.z)
    heading = lerp_angle(heading, want, min(1.0, delta * 12.0))
    body.rotation.y = heading

func _process(delta: float) -> void:
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
    mp = min(float(max_mp), mp + BAL.mp_regen * delta)
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
            town.field.melee(self, false, cur_atk)
        if u >= 1.0:
            at = -1.0
            if queued:
                attack()
    var holding := attack_held or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_SPACE)
    if holding and at < 0.0 and not town.ui_shop.visible and not town.ui_dialog.visible:
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
            var step: float = min(d.length(), speed * delta)
            var dir := d.normalized()
            if not _try_move(dir * step):
                path = PackedVector3Array()
            _face(dir, delta)
            moving_speed = speed
    position.y = town.ground_y(position.x, position.z)
    body.animate(delta, moving_speed)
    moving_speed = 0.0
