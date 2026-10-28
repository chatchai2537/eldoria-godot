extends Node3D
## ทุ่งหญ้า (นอกประตูตะวันตก) + ระบบต่อสู้: สไลม์ Lv1-5, ของดรอป, ตัวเลขดาเมจ, แถบเลือด/มานา/EXP
## กติกาตามเกมเดิม: สไลม์สูงสุด 16 ตัว เกิดใหม่ทุก 6 วิ · ดรอปเจล 1-2 + เหรียญ 1-3(+เลเวล/2) · EXP = 5×เลเวล

const FX0 := -150.0
const FX1 := -46.0
const FZ := 52.0
const MAX_SLIMES := 16

var town
var slimes: Array = []
var resp_t := 5.0
var shadow_tex: Texture2D
var drops: Array = []
var floaters: Array = []
var atk_id := 0
var coin_mesh: Mesh
var gel_mesh: Mesh
var coin_mat: StandardMaterial3D
var gel_mat: StandardMaterial3D

# HUD
var cl: CanvasLayer
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var xp_bar: ProgressBar
var hp_txt: Label
var mp_txt: Label
var lv_txt: Label
var bag_txt: Label
var msg: Label
var msg_t := 0.0
var atk_btn: Button
var death_panel: PanelContainer
var hud_box: VBoxContainer
var bars: Array = []

func setup(t) -> void:
    town = t
    var g := Gradient.new()
    g.set_color(0, Color(1, 1, 1, 1))
    g.set_color(1, Color(1, 1, 1, 0))
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.fill = GradientTexture2D.FILL_RADIAL
    gt.fill_from = Vector2(0.5, 0.5)
    gt.fill_to = Vector2(1.0, 0.5)
    shadow_tex = gt
    var cm := CylinderMesh.new()
    cm.top_radius = 0.16
    cm.bottom_radius = 0.16
    cm.height = 0.05
    cm.radial_segments = 16
    coin_mesh = cm
    coin_mat = StandardMaterial3D.new()
    coin_mat.albedo_color = Color(1.0, 0.8, 0.25)
    coin_mat.metallic = 1.0
    coin_mat.roughness = 0.25
    coin_mat.emission_enabled = true
    coin_mat.emission = Color(0.5, 0.35, 0.0)
    var gm := SphereMesh.new()
    gm.radius = 0.15
    gm.height = 0.24
    gel_mesh = gm
    gel_mat = StandardMaterial3D.new()
    gel_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.85)
    gel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    gel_mat.roughness = 0.05
    gel_mat.emission_enabled = true
    gel_mat.emission = Color(0.1, 0.3, 0.6)
    _build_decor()
    for i in 16:
        spawn()
    _build_hud()

func in_field(x: float, z: float) -> bool:
    return x >= FX0 + 2.0 and x <= FX1 and abs(z) <= FZ - 2.0

## เลเวลสไลม์ตามระยะห่างจากเมือง (ยิ่งไกลยิ่งเก่ง เหมือนเกมเดิม)
func lv_at(x: float) -> int:
    return clampi(int(ceil((FX1 - x) / ((FX1 - FX0) / 5.0))), 1, 5)

func spawn() -> void:
    for i in 200:
        var x := randf_range(FX0 + 4.0, FX1 - 2.0)
        var z := randf_range(-FZ + 4.0, FZ - 4.0)
        if Vector2(x - FX1, z).length() < 16.0:
            continue
        if Vector2(x - town.player.position.x, z - town.player.position.z).length() < 12.5:
            continue
        var s := Node3D.new()
        s.set_script(preload("res://scripts/slime.gd"))
        add_child(s)
        s.setup(self, lv_at(x), Vector3(x, town.ground_y(x, z), z))
        slimes.append(s)
        return

# ---------- ฉากทุ่งหญ้า ----------
func _build_decor() -> void:
    # ป้ายทางเข้า
    var sign_p := Vector3(-50.0, town.ground_y(-50, 5), 5.0)
    var wood: Material = town.M(Color(0.45, 0.3, 0.18), 0.9)
    town.box(self, Vector3(0.2, 2.2, 0.2), sign_p + Vector3(0, 1.1, 0), wood)
    town.box(self, Vector3(0.15, 0.9, 2.4), sign_p + Vector3(0, 2.0, 0), wood)
    town.label3d("ทุ่งหญ้า\nสไลม์ Lv.1-5 (ยิ่งไกลยิ่งเก่ง)", sign_p + Vector3(0, 3.4, 0), 34)
    # ดอกไม้ป่า + ก้อนหินเล็ก (เดินผ่านได้)
    var fx := []
    var fc := []
    var cols := [Color(1, 0.95, 0.4), Color(1, 1, 1), Color(0.95, 0.5, 0.75), Color(0.6, 0.6, 1.0), Color(1, 0.55, 0.3)]
    for i in 1400:
        var x := randf_range(FX0, FX1)
        var z := randf_range(-FZ, FZ)
        if abs(z - 1.0) < 2.8:
            continue
        var n: float = town.noise.get_noise_2d(x * 3.0, z * 3.0)
        if n < 0.05 and randf() < 0.7:
            continue
        var s := randf_range(0.7, 1.2)
        fx.append(town._xf(Vector3(x, town.ground_y(x, z) + 0.35 * s, z), Vector3(s, s, s), randf() * TAU))
        fc.append(cols[randi() % cols.size()])
    var fm := SphereMesh.new()
    fm.radius = 0.09
    fm.height = 0.12
    fm.radial_segments = 6
    fm.rings = 3
    var fmat := StandardMaterial3D.new()
    fmat.vertex_color_use_as_albedo = true
    fmat.roughness = 0.7
    town._mm(fm, fx, fc, fmat, false)
    var rx := []
    var rc := []
    for i in 90:
        var x2 := randf_range(FX0, FX1)
        var z2 := randf_range(-FZ, FZ)
        if abs(z2 - 1.0) < 3.5:
            continue
        var s2 := randf_range(0.25, 0.7)
        rx.append(town._xf(Vector3(x2, town.ground_y(x2, z2) + s2 * 0.2, z2), Vector3(s2 * 1.3, s2 * 0.7, s2), randf() * TAU, randf_range(-0.3, 0.3)))
        rc.append(Color(0.55, 0.54, 0.5).lerp(Color(0.42, 0.44, 0.4), randf()))
    var rm := SphereMesh.new()
    rm.radius = 1.0
    rm.height = 1.6
    rm.radial_segments = 8
    rm.rings = 5
    var rmat := StandardMaterial3D.new()
    rmat.vertex_color_use_as_albedo = true
    rmat.roughness = 0.95
    town._mm(rm, rx, rc, rmat)

# ---------- การโจมตีของผู้เล่น (เรียกทุกเฟรมในช่วงดาบฟัน) ----------
func new_attack() -> int:
    atk_id += 1
    return atk_id

func melee(p, spin: bool, id: int) -> void:
    var fwd := Vector3(sin(p.heading), 0, cos(p.heading))
    var c: Vector3 = p.position if spin else p.position + fwd * 1.4
    var r := 2.3 if spin else 1.45
    for s in slimes:
        if not is_instance_valid(s) or s.dead or s.last_atk == id:
            continue
        var d := Vector2(s.position.x - c.x, s.position.z - c.z).length()
        if d < r + s.radius * 0.6:
            s.last_atk = id
            var cr: bool = randf() < 0.08 + p.stats.agi * 0.004
            var dm: int = max(1, int(round(p.atk() * randf_range(0.9, 1.1) * (1.8 if cr else 1.0))))
            s.take_hit(dm, p.position)
            float_text(("คริ! " if cr else "") + str(dm), s.position + Vector3(0, s.radius * 2.0 + 0.4, 0), Color(1.0, 0.85, 0.3) if cr else Color(1, 1, 1), 1.4 if cr else 1.0)
            if s.dead:
                _killed(s)

func _killed(s) -> void:
    say_msg("สไลม์แตก!")
    var n := 1 + (1 if randf() < 0.4 else 0)
    var c: int = 1 + randi() % 3 + (s.lv >> 1)
    for i in n:
        _drop("gel", s.position)
    for i in c:
        _drop("coin", s.position)
    town.player.gain_xp(5 * s.lv)

func nearest_slime(pos: Vector3, maxd: float):
    var best = null
    var bd := maxd
    for s in slimes:
        if not is_instance_valid(s) or s.dead:
            continue
        var d := Vector2(s.position.x - pos.x, s.position.z - pos.z).length()
        if d < bd:
            bd = d
            best = s
    return best

func slime_at(screen: Vector2):
    var best = null
    var bd := 55.0
    for s in slimes:
        if not is_instance_valid(s) or s.dead or not town.cam.is_position_in_frustum(s.global_position):
            continue
        var sp: Vector2 = town.cam.unproject_position(s.global_position + Vector3(0, s.radius, 0))
        var d := sp.distance_to(screen)
        if d < bd:
            bd = d
            best = s
    return best

# ---------- ของดรอป ----------
func _drop(kind: String, at: Vector3) -> void:
    var m := MeshInstance3D.new()
    m.mesh = coin_mesh if kind == "coin" else gel_mesh
    m.material_override = coin_mat if kind == "coin" else gel_mat
    m.position = at + Vector3(0, 0.6, 0)
    add_child(m)
    var a := randf() * TAU
    drops.append({"n": m, "k": kind, "v": Vector3(cos(a) * randf_range(1.5, 3.0), randf_range(4.0, 6.0), sin(a) * randf_range(1.5, 3.0)), "t": 0.0})

func float_text(t: String, at: Vector3, c: Color, sc: float = 1.0) -> void:
    var l := Label3D.new()
    l.text = t
    l.font = town.font_b
    l.font_size = int(54 * sc)
    l.pixel_size = 0.01
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.no_depth_test = true
    l.outline_size = 12
    l.outline_modulate = Color(0, 0, 0, 0.9)
    l.modulate = c
    l.position = at
    l.render_priority = 5
    add_child(l)
    floaters.append({"n": l, "t": 0.0})

# ---------- HUD ต่อสู้ ----------
func _bar(col: Color, w: float) -> ProgressBar:
    var b := ProgressBar.new()
    b.show_percentage = false
    b.custom_minimum_size = Vector2(w, 18)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.08, 0.06, 0.05, 0.85)
    bg.set_corner_radius_all(5)
    bg.border_color = Color(0.85, 0.7, 0.4, 0.9)
    bg.set_border_width_all(2)
    var fg := StyleBoxFlat.new()
    fg.bg_color = col
    fg.set_corner_radius_all(4)
    b.add_theme_stylebox_override("background", bg)
    b.add_theme_stylebox_override("fill", fg)
    return b

func _text(sz: int, col: Color = Color(1, 1, 1)) -> Label:
    var l := Label.new()
    l.add_theme_font_override("font", town.font_b)
    l.add_theme_font_size_override("font_size", sz)
    l.add_theme_color_override("font_color", col)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    l.add_theme_constant_override("outline_size", 6)
    return l

func _build_hud() -> void:
    cl = CanvasLayer.new()
    add_child(cl)
    var box := VBoxContainer.new()
    hud_box = box
    box.anchor_top = 1.0
    box.anchor_bottom = 1.0
    box.offset_left = 16
    box.offset_top = -150
    box.add_theme_constant_override("separation", 4)
    cl.add_child(box)
    lv_txt = _text(22, Color(1.0, 0.88, 0.45))
    box.add_child(lv_txt)
    for row in [["HP", Color(0.85, 0.15, 0.18)], ["MP", Color(0.2, 0.45, 0.95)], ["EXP", Color(0.95, 0.8, 0.25)]]:
        var hb := HBoxContainer.new()
        var tag := _text(16)
        tag.text = row[0]
        tag.custom_minimum_size = Vector2(40, 0)
        hb.add_child(tag)
        var b := _bar(row[1], 240)
        bars.append(b)
        hb.add_child(b)
        var tx := _text(15)
        hb.add_child(tx)
        box.add_child(hb)
        if row[0] == "HP":
            hp_bar = b
            hp_txt = tx
        elif row[0] == "MP":
            mp_bar = b
            mp_txt = tx
        else:
            xp_bar = b
    bag_txt = _text(18, Color(0.95, 0.95, 0.85))
    box.add_child(bag_txt)
    msg = _text(24, Color(1.0, 0.95, 0.7))
    msg.anchor_left = 0.5
    msg.anchor_right = 0.5
    msg.offset_left = -400
    msg.offset_right = 400
    msg.offset_top = 70
    msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cl.add_child(msg)
    # ปุ่มดาบ (มือถือ/เมาส์) — เหมือนปุ่ม ⚔️ ในเกมเดิม
    atk_btn = Button.new()
    atk_btn.text = "ตี (J)"
    atk_btn.add_theme_font_override("font", town.font_b)
    atk_btn.add_theme_font_size_override("font_size", 22)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.55, 0.12, 0.1, 0.85)
    sb.border_color = Color(1.0, 0.8, 0.4)
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(60)
    var sb2: StyleBoxFlat = sb.duplicate()
    sb2.bg_color = Color(0.8, 0.2, 0.15, 0.95)
    atk_btn.add_theme_stylebox_override("normal", sb)
    atk_btn.add_theme_stylebox_override("hover", sb2)
    atk_btn.add_theme_stylebox_override("pressed", sb2)
    atk_btn.anchor_left = 1.0
    atk_btn.anchor_right = 1.0
    atk_btn.anchor_top = 1.0
    atk_btn.anchor_bottom = 1.0
    atk_btn.offset_left = -150
    atk_btn.offset_right = -30
    atk_btn.offset_top = -150
    atk_btn.offset_bottom = -30
    atk_btn.focus_mode = Control.FOCUS_NONE
    atk_btn.button_down.connect(func(): town.player.attack())
    cl.add_child(atk_btn)

func say_msg(t: String, dur: float = 2.5) -> void:
    msg.text = t
    msg_t = dur

func _update_hud() -> void:
    var p = town.player
    hp_bar.max_value = p.max_hp
    hp_bar.value = p.hp
    hp_txt.text = " %d/%d" % [round(p.hp), p.max_hp]
    mp_bar.max_value = p.max_mp
    mp_bar.value = p.mp
    mp_txt.text = " %d/%d" % [round(p.mp), p.max_mp]
    xp_bar.max_value = p.need(p.lv)
    xp_bar.value = p.xp
    lv_txt.text = "Lv.%d  ·  ATK %d  DEF %d" % [p.lv, p.atk(), p.def()]
    bag_txt.text = "เหรียญ %d  ·  เจลสไลม์ %d" % [p.coins, p.gel]

func _process(delta: float) -> void:
    for i in range(slimes.size() - 1, -1, -1):
        if not is_instance_valid(slimes[i]):
            slimes.remove_at(i)
    var alive := 0
    for s in slimes:
        if is_instance_valid(s) and not s.dead:
            alive += 1
    resp_t -= delta
    if alive < MAX_SLIMES and resp_t <= 0.0:
        spawn()
        resp_t = 6.0
    var p = town.player
    for i in range(drops.size() - 1, -1, -1):
        var d: Dictionary = drops[i]
        var n: MeshInstance3D = d.n
        d.t += delta
        var gy: float = town.ground_y(n.position.x, n.position.z) + 0.15
        if d.t < 0.6:
            var v: Vector3 = d.v
            v.y -= 18.0 * delta
            n.position += v * delta
            if n.position.y < gy:
                n.position.y = gy
                v = v * Vector3(0.5, -0.35, 0.5)
            d.v = v
        else:
            var to: Vector3 = p.position + Vector3(0, 1.0, 0) - n.position
            if to.length() < 4.5 and not p.dead:
                n.position += to.normalized() * min(to.length(), (6.0 + d.t * 6.0) * delta)
                if to.length() < 0.5:
                    if d.k == "coin":
                        p.coins += 1
                    else:
                        p.gel += 1
                    n.queue_free()
                    drops.remove_at(i)
                    continue
            else:
                n.position.y = gy + 0.12 + sin(d.t * 3.0) * 0.08
        n.rotation.y += delta * 3.0
    for i in range(floaters.size() - 1, -1, -1):
        var f: Dictionary = floaters[i]
        f.t += delta
        var l: Label3D = f.n
        l.position.y += delta * 1.6
        l.modulate.a = clamp(1.6 - f.t * 1.6, 0.0, 1.0)
        if f.t > 1.0:
            l.queue_free()
            floaters.remove_at(i)
    if msg_t > 0.0:
        msg_t -= delta
        if msg_t <= 0.0:
            msg.text = ""
    _update_hud()
