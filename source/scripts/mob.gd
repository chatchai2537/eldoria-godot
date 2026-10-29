extends Node3D
## มอนในเหมือง (js/031-core.js FAM · mkMob · updMob · bossSkill) — โมเดล 3D สร้างจากรูปทรง (ไม่ใช้ภาพวาด)
## ค่าพิกเซลเกม 2D × K (1 ช่อง = 32px = 2 หน่วย) · เจ้าของสั่ง: ไม่กระเด็นทั้งมอนและผู้เล่น

const K := 2.0 / 32.0
## sz=ขนาด hp/atk=ตัวคูณ spd=ความเร็ว r=รัศมีตัว range=ระยะตี type=ท่าตี wu=เวลาง้าง cd=คูลดาวน์ keep=ระยะยืนยิง fly=บิน
const FAM := {
    "beetle": {"sz": 1.15, "hp": 1.3, "atk": 1.0, "spd": 44, "r": 13, "range": 24, "type": "melee", "wu": 0.35, "cd": 1.3},
    "bat": {"sz": 1.0, "hp": 0.7, "atk": 0.8, "spd": 92, "r": 11, "range": 22, "type": "melee", "wu": 0.22, "cd": 1.0, "fly": true},
    "golem": {"sz": 1.0, "hp": 1.7, "atk": 1.35, "spd": 34, "r": 16, "range": 34, "type": "smash", "wu": 0.65, "cd": 1.9},
    "wolf": {"sz": 1.25, "hp": 1.0, "atk": 1.1, "spd": 82, "r": 13, "range": 80, "type": "lunge", "wu": 0.38, "cd": 1.7},
    "wisp": {"sz": 1.0, "hp": 0.8, "atk": 0.9, "spd": 56, "r": 11, "range": 180, "type": "shoot", "wu": 0.5, "cd": 2.1, "keep": 120, "fly": true},
    "dragon": {"sz": 1.0, "hp": 1.5, "atk": 1.4, "spd": 50, "r": 26, "range": 44, "type": "smash", "wu": 0.6, "cd": 1.6, "fly": true},
    # ดันเจี้ยน (js/031-core.js 2315)
    "skeleton": {"sz": 1.0, "hp": 0.9, "atk": 1.1, "spd": 62, "r": 12, "range": 26, "type": "melee", "wu": 0.3, "cd": 1.2},
    "zombie": {"sz": 1.0, "hp": 1.5, "atk": 1.2, "spd": 30, "r": 13, "range": 28, "type": "lunge", "wu": 0.55, "cd": 1.8},
    "drake": {"sz": 0.62, "hp": 1.2, "atk": 1.2, "spd": 58, "r": 16, "range": 210, "type": "shoot", "wu": 0.55, "cd": 2.2, "keep": 130, "fly": true},
}

## เลือด/พลังโจมตี: mobStats + ตัวคูณจาก fix ตัวหลัง (031 L3194 · fix8 ×1.7/×1.35 · fix31 ×1.25/×1.2)
static func stats(L: int, f: String, elite: bool, boss: bool) -> Vector2i:
    var F: Dictionary = FAM[f]
    var hp := (12.0 + 6.0 * L) * float(F.hp)
    var at := (6.0 + 2.4 * L) * float(F.atk)
    if elite:
        hp *= 2.5
        at *= 1.25
    if boss:
        hp *= 12.0
        at *= 1.5
    hp = round(round(hp) * (1.0 + L / 110.0))
    at = round(round(at) * (1.0 + L / 180.0))
    hp = round(round(hp * 1.7) * 1.25)
    at = round(round(at * 1.35) * 1.2)
    # fix119 4b: มอนเลเวลต่ำ (ต่ำกว่า 25) เลือด/พลังลดลง L1 ×0.6 → L25 ×1.0
    if L < 25:
        var k: float = 0.6 + 0.4 * float(max(0, L - 1)) / 24.0
        hp = max(1.0, round(hp * k))
        at = max(1.0, round(at * k))
    return Vector2i(int(hp), int(at))

var mine
var f := "beetle"
var F: Dictionary
var nm := ""
var col: Array = []
var lv := 1
var hp := 10
var max_hp := 10
var atk_v := 5
var elite := false
var boss := false
var sc := 1.0
var radius := 0.8
var dead := false
var die_t := 0.0
var last_atk := -1
var home := Vector3.ZERO
var st := "idle"
var stt := 0.0
var cd := 1.0
var aggro := false
var wdir := Vector3.ZERO
var dv := Vector3.ZERO
var hit_done := false
var hurt := 0.0
var t := 0.0
var summoned := 0
var tg := Vector3.ZERO
var heading := 0.0
var stun_t := 0.0   # มึนงงจากสกิล (บอสโดน 35%)

var vis: Node3D
var parts := {}
var bar: MeshInstance3D
var bar_bg: MeshInstance3D
var lbl: Label3D
var ring: MeshInstance3D
var eye_mat: StandardMaterial3D

func setup(m, fam: String, name_: String, colors: Array, level: int, pos: Vector3, o: Dictionary = {}) -> void:
    mine = m
    f = fam
    F = FAM[f]
    nm = name_
    col = colors
    lv = level
    elite = o.get("elite", false)
    boss = o.get("boss", false)
    var s := stats(lv, f, elite, boss)
    hp = s.x
    max_hp = s.x
    atk_v = s.y
    sc = (2.3 if boss else (1.3 if elite else 1.0)) * (1.0 + float(o.get("span", 0.0)) * 0.18) * float(F.sz)
    sc *= float(o.get("scm", 1.0))  # บอสตำนาน: ขนาดตามตาราง (fix62 sc)
    radius = float(F.r) * K * sc
    position = pos
    home = pos
    t = randf() * 9.0
    stt = randf() * 2.0
    cd = randf_range(0.5, 1.5)
    _build()

func _c(i: int) -> Color:
    return Color.html(str(col[i]))

func _part(key: String, mesh: Mesh, c: Color, pos: Vector3, emit: float = 0.0, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mine.town.M(c, 0.6, emit)
    mi.position = pos
    mi.scale = scl
    vis.add_child(mi)
    parts[key] = mi
    return mi

func _sph(r: float) -> SphereMesh:
    var m := SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = 10
    m.rings = 6
    return m

func _bx(s: Vector3) -> BoxMesh:
    var b := BoxMesh.new()
    b.size = s
    return b

func _build() -> void:
    vis = Node3D.new()
    add_child(vis)
    var a := _c(0)
    var b := _c(1)
    var e := _c(2)
    match f:
        "beetle":
            _part("body", _sph(0.55), a, Vector3(0, 0.45, 0), 0.0, Vector3(1.0, 0.6, 1.25))
            _part("head", _sph(0.28), b, Vector3(0, 0.38, 0.62))
            _part("horn", _bx(Vector3(0.08, 0.08, 0.4)), b, Vector3(0, 0.5, 0.88))
            _part("eye", _bx(Vector3(0.36, 0.08, 0.06)), e, Vector3(0, 0.45, 0.85), 2.0)
            _part("legs", _bx(Vector3(1.3, 0.08, 0.7)), b, Vector3(0, 0.18, 0.05))
        "bat":
            _part("body", _sph(0.3), a, Vector3(0, 0, 0), 0.0, Vector3(1, 1.1, 1))
            _part("wl", _bx(Vector3(0.8, 0.05, 0.45)), b, Vector3(-0.5, 0.05, 0))
            _part("wr", _bx(Vector3(0.8, 0.05, 0.45)), b, Vector3(0.5, 0.05, 0))
            _part("eye", _bx(Vector3(0.26, 0.07, 0.05)), e, Vector3(0, 0.08, 0.28), 2.5)
        "golem":
            _part("body", _bx(Vector3(0.95, 0.85, 0.65)), a, Vector3(0, 1.0, 0))
            _part("head", _bx(Vector3(0.5, 0.42, 0.45)), a, Vector3(0, 1.62, 0.05))
            _part("eye", _bx(Vector3(0.34, 0.08, 0.05)), e, Vector3(0, 1.66, 0.29), 2.5)
            _part("al", _bx(Vector3(0.32, 0.85, 0.32)), b, Vector3(-0.68, 0.85, 0))
            _part("ar", _bx(Vector3(0.32, 0.85, 0.32)), b, Vector3(0.68, 0.85, 0))
            _part("legs", _bx(Vector3(0.8, 0.55, 0.45)), b, Vector3(0, 0.3, 0))
        "wolf":
            _part("body", _bx(Vector3(0.5, 0.45, 1.05)), a, Vector3(0, 0.62, 0))
            _part("head", _bx(Vector3(0.4, 0.38, 0.42)), a, Vector3(0, 0.82, 0.62))
            _part("snout", _bx(Vector3(0.22, 0.18, 0.25)), b, Vector3(0, 0.74, 0.92))
            _part("eye", _bx(Vector3(0.3, 0.06, 0.05)), e, Vector3(0, 0.9, 0.84), 2.5)
            _part("legs", _bx(Vector3(0.46, 0.42, 0.9)), b, Vector3(0, 0.21, 0))
            _part("tail", _bx(Vector3(0.12, 0.12, 0.45)), b, Vector3(0, 0.78, -0.68))
        "wisp":
            _part("body", _sph(0.38), a, Vector3(0, 0, 0), 1.6)
            _part("core", _sph(0.18), e, Vector3(0, 0, 0.12), 3.0)
            _part("tail", _sph(0.22), b, Vector3(0, -0.3, -0.25), 1.2, Vector3(1, 1, 1.6))
        "skeleton", "zombie":
            var bone := Color(0.88, 0.86, 0.78) if f == "skeleton" else a
            _part("body", _bx(Vector3(0.5, 0.65, 0.3)), bone, Vector3(0, 1.05, 0))
            _part("head", _bx(Vector3(0.38, 0.38, 0.36)), bone, Vector3(0, 1.62, 0.04 if f == "skeleton" else 0.18))
            _part("eye", _bx(Vector3(0.26, 0.06, 0.05)), e, Vector3(0, 1.66, 0.23 if f == "skeleton" else 0.37), 2.5)
            _part("al", _bx(Vector3(0.14, 0.7, 0.14)), bone.darkened(0.15), Vector3(-0.36, 1.0, 0.0 if f == "skeleton" else 0.25))
            _part("ar", _bx(Vector3(0.14, 0.7, 0.14)), bone.darkened(0.15), Vector3(0.36, 1.0, 0.0 if f == "skeleton" else 0.25))
            _part("legs", _bx(Vector3(0.4, 0.72, 0.22)), b, Vector3(0, 0.36, 0))
            if f == "skeleton":
                _part("blade", _bx(Vector3(0.06, 0.08, 0.8)), Color(0.75, 0.78, 0.82), Vector3(0.36, 0.7, 0.4))
            else:
                parts["body"].rotation.x = 0.35
        "dragon", "drake":
            _part("body", _sph(0.6), a, Vector3(0, 0.2, 0), 0.0, Vector3(0.9, 0.8, 1.4))
            _part("head", _bx(Vector3(0.45, 0.4, 0.6)), a, Vector3(0, 0.55, 0.95))
            _part("eye", _bx(Vector3(0.38, 0.07, 0.05)), e, Vector3(0, 0.62, 1.26), 3.0)
            _part("wl", _bx(Vector3(1.4, 0.06, 0.8)), b, Vector3(-0.95, 0.45, 0))
            _part("wr", _bx(Vector3(1.4, 0.06, 0.8)), b, Vector3(0.95, 0.45, 0))
            _part("tail", _bx(Vector3(0.2, 0.2, 1.0)), b, Vector3(0, 0.15, -1.1))
    if parts.has("eye"):
        eye_mat = parts["eye"].material_override.duplicate()
        parts["eye"].material_override = eye_mat
    vis.scale = Vector3.ONE * sc
    # เงาใต้ตัว
    var sh := MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(radius * 2.4, radius * 2.4)
    q.orientation = PlaneMesh.FACE_Y
    sh.mesh = q
    var shm := StandardMaterial3D.new()
    shm.albedo_texture = mine.town.field.shadow_tex
    shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    shm.albedo_color = Color(0, 0, 0, 0.45)
    sh.material_override = shm
    sh.position.y = 0.04
    add_child(sh)
    var top := _top_y()
    lbl = Label3D.new()
    lbl.text = ("บอส " if boss else ("ยอด " if elite else "")) + nm + " Lv.%d" % lv
    lbl.font = mine.town.font_b if boss else mine.town.font
    lbl.font_size = 40 if boss else 30
    lbl.pixel_size = 0.01
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.outline_size = 8
    lbl.modulate = Color(1.0, 0.75, 0.3) if boss else (Color(1.0, 0.9, 0.5) if elite else Color(1.0, 0.92, 0.85))
    lbl.position.y = top + 0.55
    add_child(lbl)
    bar_bg = _bar(Color(0.1, 0.05, 0.05), 1.2 * (2.0 if boss else 1.0), 0, top + 0.25)
    bar = _bar(Color(0.9, 0.2, 0.2), 1.16 * (2.0 if boss else 1.0), 1, top + 0.25)
    bar_bg.visible = boss
    bar.visible = boss
    # วงเตือนท่าทุบ (เห็นแล้วกลิ้งหลบ)
    ring = MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.92
    tm.outer_radius = 1.0
    tm.rings = 24
    ring.mesh = tm
    ring.material_override = mine.town.M(Color(1.0, 0.2, 0.15), 0.4, 2.0)
    ring.visible = false
    ring.top_level = true
    add_child(ring)

func _top_y() -> float:
    var base := {"beetle": 0.8, "bat": 0.5, "golem": 1.9, "wolf": 1.05, "wisp": 0.45, "dragon": 1.0, "drake": 1.0, "skeleton": 1.9, "zombie": 1.9}
    var fy := 1.6 if F.get("fly", false) else 0.0
    return float(base[f]) * sc + fy

func _bar(c: Color, w: float, pri: int, y: float) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(w, 0.13)
    m.mesh = q
    var bm := StandardMaterial3D.new()
    bm.albedo_color = c
    bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    bm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    bm.no_depth_test = true
    bm.render_priority = 1 + pri
    m.material_override = bm
    m.position.y = y
    add_child(m)
    return m

# ---------- โดนตี ----------
func take_hit(dmg: int, _from: Vector3) -> void:
    hp -= dmg
    hurt = 0.18
    aggro = true
    if st == "idle":
        st = "chase"
    bar_bg.visible = true
    bar.visible = true
    bar.scale.x = max(clamp(float(hp) / max_hp, 0.0, 1.0), 0.001)
    if hp <= 0 and not dead:
        dead = true
        die_t = 0.5
        ring.visible = false

## เรียกจาก field.hit_slime ตอนตาย
func killed_by() -> void:
    mine.mob_killed(self)

# ---------- AI (updMob) ----------
func _process(delta: float) -> void:
    if dead:
        die_t -= delta
        var s: float = max(die_t / 0.5, 0.0)
        vis.scale = Vector3.ONE * sc * s
        lbl.visible = false
        bar.visible = false
        bar_bg.visible = false
        if die_t <= 0.0:
            queue_free()
        return
    if mine.cur < 0:
        return
    if stun_t > 0.0:
        stun_t -= delta
        ring.visible = false
        if st.ends_with("WU"):
            st = "chase"
        vis.rotation.z = sin(t * 20.0) * 0.08
        t += delta
        return
    vis.rotation.z = 0.0
    var p = mine.town.player
    var to := Vector3(p.position.x - position.x, 0, p.position.z - position.z)
    var dist: float = max(to.length(), 0.01)
    var n := to / dist
    var enr := boss and float(hp) / max_hp < 0.3
    var spd := float(F.spd) * K * (1.3 if enr else 1.0)
    t += delta
    hurt = max(0.0, hurt - delta)
    var see := (260.0 if boss else 220.0) * K
    if p.dead:
        aggro = false
        if st != "idle":
            st = "idle"
    elif not aggro and dist < see:
        aggro = true
    if aggro and dist > (520.0 if boss else 430.0) * K and st != "lunge" and st != "charge":
        aggro = false
        st = "idle"
    cd -= delta * (1.4 if enr else 1.0)
    var moving := false
    match st:
        "idle":
            if aggro:
                st = "chase"
            else:
                stt -= delta
                if stt <= 0.0:
                    stt = randf_range(1.2, 3.0)
                    var a := randf() * TAU
                    wdir = Vector3(cos(a), 0, sin(a))
                    if randf() < 0.35:
                        wdir = Vector3.ZERO
                    if position.distance_to(home) > 150.0 * K:
                        wdir = (home - position).normalized()
                if wdir != Vector3.ZERO:
                    _mv(wdir * spd * 0.35 * delta)
                    moving = true
                    heading = atan2(wdir.x, wdir.z)
                if boss and hp < max_hp:
                    hp = min(max_hp, hp + int(ceil(max_hp * 0.05 * delta)))
                    bar.scale.x = max(float(hp) / max_hp, 0.001)
        "chase":
            heading = atan2(n.x, n.z)
            if boss:
                if cd <= 0.0:
                    cd = randf_range(2.2, 3.6) * (0.7 if enr else 1.0)
                    _boss_skill(dist, n, enr)
                elif dist > float(F.range) * K * 0.8 * sc:
                    _mv(n * spd * delta)
                    moving = true
                elif cd < 1.6:
                    st = "wu"
                    stt = float(F.wu)
            elif F.type == "shoot":
                var want := float(F.keep) * K
                if dist > want + 30.0 * K:
                    _mv(n * spd * delta)
                elif dist < want - 30.0 * K:
                    _mv(-n * spd * 0.8 * delta)
                else:
                    _mv(Vector3(-n.z, 0, n.x) * spd * 0.4 * delta)
                moving = true
                if cd <= 0.0 and dist < (float(F.range) + 40.0) * K:
                    st = "wu"
                    stt = float(F.wu)
            elif dist > float(F.range) * K * (0.95 if F.type == "lunge" else 0.85):
                _mv(n * spd * delta)
                moving = true
            elif cd <= 0.0:
                st = "wu"
                stt = float(F.wu)
        "wu":
            heading = atan2(n.x, n.z)
            stt -= delta
            if stt <= 0.0:
                cd = float(F.cd) * randf_range(0.85, 1.2)
                if F.type == "shoot":
                    var offs := [-0.18, 0.0, 0.18] if elite else [0.0]
                    for o in offs:
                        mine.shoot(self, n.rotated(Vector3.UP, o), 170.0 * K, _gap(atk_v), 2.2)
                    st = "chase"
                elif F.type == "lunge":
                    st = "lunge"
                    stt = 0.28
                    dv = n
                    hit_done = false
                else:
                    st = "strike"
                    stt = 0.18
                    var rr := (float(F.range) + (14.0 if F.type == "smash" else 8.0) * sc) * K
                    if dist < rr:
                        p.hurt_mob(int(atk_v * (1.25 if F.type == "smash" else 1.0)), nm + "โจมตี")
        "strike":
            stt -= delta
            if stt <= 0.0:
                st = "chase"
        "lunge":
            stt -= delta
            _mv(dv * 330.0 * K * delta)
            moving = true
            if not hit_done and dist < 22.0 * K * sc + 0.5:
                hit_done = true
                p.hurt_mob(_gap(atk_v * 1.2), nm + "พุ่งกัด")
            if stt <= 0.0:
                st = "chase"
        "slamWU":
            stt -= delta
            ring.visible = true
            ring.global_position = tg + Vector3(0, 0.08, 0)
            var rs := 95.0 * K
            ring.scale = Vector3(rs, 1, rs)
            if stt <= 0.0:
                ring.visible = false
                if Vector2(p.position.x - tg.x, p.position.z - tg.z).length() < rs:
                    p.hurt_mob(_gap(atk_v * 2.1), nm + "ทุบพื้น")
                mine.town.field.float_text("ตูม!", tg + Vector3(0, 1.5, 0), Color(1.0, 0.6, 0.3), 1.3)
                st = "strike"
                stt = 0.45
        "chargeWU":
            stt -= delta
            heading = atan2(dv.x, dv.z)
            if stt <= 0.0:
                st = "charge"
                stt = 0.55
                hit_done = false
        "charge":
            stt -= delta
            _mv(dv * 420.0 * K * delta)
            moving = true
            if not hit_done and dist < 30.0 * K * sc * 0.6 + 0.6:
                hit_done = true
                p.hurt_mob(_gap(atk_v * 1.7), nm + "พุ่งชน")
            if stt <= 0.0:
                st = "strike"
                stt = 0.4
        "volleyWU":
            stt -= delta
            if stt <= 0.0:
                var cnt := 14 if enr else 10
                var o := randf()
                for i in cnt:
                    var a := (i + o) / cnt * TAU
                    mine.shoot(self, Vector3(cos(a), 0, sin(a)), 150.0 * K, _gap(atk_v * 0.9), 2.6)
                st = "strike"
                stt = 0.4
    # ชนตัว (ค้างคาว/ด้วง)
    if not boss and F.type == "melee" and st == "chase" and dist < 14.0 * K + radius and cd <= 0.0:
        p.hurt_mob(_gap(atk_v * 0.6), nm + "ชน")
        cd = float(F.cd)
    _animate(delta, moving)

## fix77: มอนเลเวลสูงกว่าผู้เล่นเกิน 3 ตีแรงขึ้น 3%/เลเวล (สูงสุด ×2)
func _gap(d: float) -> int:
    var g: int = lv - int(mine.town.player.lv) - 3
    if g > 0:
        d *= min(2.0, 1.0 + 0.03 * g)
    return int(d)

func _boss_skill(dist: float, n: Vector3, enr: bool) -> void:
    var frac := float(hp) / max_hp
    if (frac < 0.5 and summoned == 0) or (summoned == 1 and frac < 0.25):
        summoned += 1
        mine.summon(self)
        return
    var r := randf()
    if r < 0.4 or dist < 90.0 * K:
        st = "slamWU"
        stt = 0.65 if enr else 0.9
        tg = position
    elif r < 0.72:
        st = "chargeWU"
        stt = 0.45 if enr else 0.65
        dv = n
    else:
        st = "volleyWU"
        stt = 0.6

func _mv(d: Vector3) -> void:
    if not mine.blocked_at(position.x + d.x, position.z, radius * 0.6):
        position.x += d.x
    if not mine.blocked_at(position.x, position.z + d.z, radius * 0.6):
        position.z += d.z

func _animate(delta: float, moving: bool) -> void:
    vis.rotation.y = lerp_angle(vis.rotation.y, heading, min(1.0, delta * 8.0))
    var fly: bool = F.get("fly", false)
    var y := 1.6 + sin(t * 3.0) * 0.15 if fly else 0.0
    var windup := st == "wu" or st.ends_with("WU")
    var sx := 1.0
    var sy := 1.0
    if windup:
        sy = 1.0 + 0.12 * sin(t * 30.0)
        sx = 1.08
    elif st == "strike":
        sy = 0.9
        sx = 1.1
    elif moving and not fly:
        y = abs(sin(t * 10.0)) * 0.08
    vis.position.y = y
    vis.scale = Vector3(sx, sy, sx) * sc
    if parts.has("wl"):
        var fl := sin(t * (16.0 if f == "bat" else 6.0)) * 0.7
        parts["wl"].rotation.z = fl
        parts["wr"].rotation.z = -fl
    if parts.has("tail") and f == "wolf":
        parts["tail"].rotation.y = sin(t * 8.0) * 0.4
    if parts.has("al"):
        var sw := sin(t * 6.0) * 0.4 if moving else 0.0
        if windup:
            sw = -1.6
        parts["al"].rotation.x = sw
        parts["ar"].rotation.x = -sw if not windup else sw
    if eye_mat != null:
        eye_mat.emission_energy_multiplier = 6.0 if windup else 2.5
    if hurt > 0.0:
        vis.scale *= 1.0 + hurt
