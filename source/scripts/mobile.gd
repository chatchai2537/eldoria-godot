extends CanvasLayer
## ปุ่มมือถือ แบบเดียวกับเกม 2D (fix30): จอยสติ๊กลอยด้านซ้าย "ลากเพื่อเดิน" ขนาด 140
## กดตีค้างเพื่อยืนฟันต่อเนื่อง · ปุ่มกลิ้งหลบ · ลากหมุนกล้อง · สองนิ้วซูม
## แตะสั้น ๆ (ไม่ลาก) = คลิก: เดินไปจุดนั้น / คุย NPC / ตีสไลม์

const JOY_SIZE := 140.0

var town
var joy := Vector2.ZERO          # ทิศจอย (-1..1) แกน y = ลงจอ
var joy_id := -1
var joy_origin := Vector2.ZERO
var cam_ids := {}                # นิ้วที่ใช้หมุนกล้อง/ซูม: id -> ตำแหน่งล่าสุด
var touch_start := {}            # id -> [ตำแหน่งเริ่ม, เวลาเริ่ม, ลากแล้วไหม]
var pinch_d := 0.0
var attack_touch_id := -1

var root: Control
var joy_base: Panel
var joy_knob: Panel
var joy_hint: Label
var atk: Panel
var dash: Panel
var ride: Panel   # ปุ่มขี่/ลงสัตว์ขี่ (เห็นเมื่อมีสัตว์ขี่)
var rot_hint: Label
var compass: Panel      # เข็มทิศ: ชี้ทิศเหนือตามมุมกล้อง · แตะ = หันกล้องกลับทิศเหนือ
var needle: Node2D
var snd: Panel   # ปุ่มเปิด/ปิดเสียง (0.32) ใต้เข็มทิศ
var skill_btns := {}   # ปุ่มสกิล 4 ช่อง วงรอบปุ่มตี (ผังเดียวกับเกม 2D fix30/fix41) · ช่อง 3 = เยียวยา
const SLOT_COLOR := [Color(0.15, 0.3, 0.45, 0.92), Color(0.5, 0.18, 0.08, 0.92), Color(0.35, 0.2, 0.45, 0.92), Color(0.1, 0.4, 0.2, 0.92)]
var _sk_tick := 0.0

func setup(t) -> void:
    town = t
    layer = 5
    root = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    joy_hint = _circle_label("ลากเพื่อเดิน", 120, Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.35), 13)
    joy_hint.anchor_top = 1.0
    joy_hint.anchor_bottom = 1.0
    joy_hint.position = Vector2(26, -146)
    root.add_child(joy_hint)
    joy_base = _circle(JOY_SIZE, Color(0, 0, 0, 0.28), Color(1, 1, 1, 0.5), 4)
    joy_knob = _circle(JOY_SIZE * 0.44, Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.8), 2)
    joy_base.visible = false
    joy_knob.visible = false
    root.add_child(joy_base)
    root.add_child(joy_knob)
    atk = _button("ตี", 76, Color(0.07, 0.13, 0.18, 0.94), 28)
    dash = _button("กลิ้ง", 52, Color(0.08, 0.18, 0.20, 0.93), 18)
    root.add_child(atk)
    root.add_child(dash)
    ride = _button("ขี่", 44, Color(0.30, 0.18, 0.08, 0.93), 16)
    ride.visible = false
    root.add_child(ride)
    for i in 4:
        var b := _button("", 54, SLOT_COLOR[i], 12)
        b.visible = false
        (b.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        # รูปสกิล (0.30) วาดใต้ข้อความ · ข้อความเหลือแค่ตัวเลขคูลดาวน์เมื่อมีรูป
        var ic := TextureRect.new()
        ic.name = "Icon"
        ic.position = Vector2(-2, -2)
        ic.size = Vector2(58, 58)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(ic)
        b.move_child(ic, 0)
        b.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW   # รูปสี่เหลี่ยมถูกตัดเป็นวงกลมตามปุ่ม
        root.add_child(b)
        skill_btns[i] = b
    compass = _circle(46, Color(0.05, 0.09, 0.14, 0.82), Color(0.85, 0.72, 0.42, 0.9), 2)
    compass.size = Vector2(46, 46)
    root.add_child(compass)
    needle = Node2D.new()
    needle.position = Vector2(23, 23)
    compass.add_child(needle)
    var n_up := Polygon2D.new()
    n_up.polygon = PackedVector2Array([Vector2(0, -17), Vector2(5, 0), Vector2(-5, 0)])
    n_up.color = Color(0.95, 0.3, 0.25)
    needle.add_child(n_up)
    var n_dn := Polygon2D.new()
    n_dn.polygon = PackedVector2Array([Vector2(0, 17), Vector2(5, 0), Vector2(-5, 0)])
    n_dn.color = Color(0.9, 0.88, 0.82)
    needle.add_child(n_dn)
    var nl := Label.new()
    nl.text = "N"
    nl.add_theme_font_size_override("font_size", 10)
    nl.add_theme_color_override("font_color", Color(1, 1, 1))
    nl.position = Vector2(-4, -31)
    needle.add_child(nl)
    snd = _button("เสียง", 46, Color(0.05, 0.09, 0.14, 0.82), 13)
    root.add_child(snd)
    _snd_look()
    refresh_skills()
    _layout()
    get_viewport().size_changed.connect(_layout)

func _snd_look() -> void:
    if snd == null or town.sfx == null:
        return
    var l := snd.get_child(0) as Label
    l.text = "ปิดเสียง" if town.sfx.muted else "เสียง"
    l.add_theme_font_size_override("font_size", 11 if town.sfx.muted else 13)
    snd.modulate = Color(1, 1, 1, 0.55 if town.sfx.muted else 1.0)

func _circle(sz: float, bg: Color, border: Color, bw: int) -> Panel:
    var p := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(bw)
    sb.set_corner_radius_all(int(sz))
    p.add_theme_stylebox_override("panel", sb)
    p.size = Vector2(sz, sz)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return p

func _circle_label(t: String, sz: float, bg: Color, border: Color, fs: int) -> Label:
    var l := Label.new()
    l.text = t
    l.size = Vector2(sz, sz)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_override("font", town.font_b)
    l.add_theme_font_size_override("font_size", fs)
    l.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(int(sz))
    sb.draw_center = false
    l.add_theme_stylebox_override("normal", sb)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _button(t: String, sz: float, col: Color, fs: int) -> Panel:
    var p := _circle(sz, col, Color(0.76, 0.67, 0.46), 2)
    var l := Label.new()
    l.text = t
    l.size = Vector2(sz, sz)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_override("font", town.font_b)
    l.add_theme_font_size_override("font_size", fs)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.add_child(l)
    return p

func _layout() -> void:
    var vs := root.get_viewport_rect().size
    atk.position = Vector2(vs.x - 76 - 14, vs.y - 76 - 14)
    dash.position = Vector2(vs.x - 76 - 14 - 52 - 14, vs.y - 52 - 10)
    joy_hint.position = Vector2(26, vs.y - 146)
    ride.position = Vector2(vs.x * 0.45 - 44 - 10, vs.y - 44 - 12)
    if compass != null:
        var ml: float = town.minimap.offset_left if town.minimap != null else -150.0
        compass.position = Vector2(vs.x + ml - 46 - 10, 60)  # กลางล่าง (ไม่ทับปุ่มสกิล/จอย)
    # วงรอบปุ่มตี: ซ้ายบน · บน · ซ้าย (คล้าย sk1-sk3 ของเกม 2D)
    var c := atk.position + atk.size * 0.5
    var offs := {0: Vector2(-98, -58), 1: Vector2(-40, -106), 2: Vector2(-152, -14), 3: Vector2(22, -132)}
    for id in skill_btns.keys():
        var b: Panel = skill_btns[id]
        b.position = c + offs[id] - b.size * 0.5

func refresh_skills() -> void:
    if town.player == null or town.classes == null:
        return
    for i in skill_btns.keys():
        var nm: String = town.classes.slot_name(town.player, i)
        var b: Panel = skill_btns[i]
        b.visible = nm != ""
        var c: float = town.classes.slot_cd(town.player, i)
        var l := b.get_child(1) as Label
        var ic := b.get_node("Icon") as TextureRect
        ic.texture = town.icon_tex(town.classes.slot_icon(town.player, i))
        if ic.texture != null:
            l.text = "" if c <= 0.0 else str(int(ceil(c)))
            l.add_theme_font_size_override("font_size", 12 if c <= 0.0 else 22)
            l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
            l.add_theme_constant_override("outline_size", 6)
            ic.modulate = Color(1, 1, 1, 1.0 if c <= 0.0 else 0.45)
        else:
            l.text = nm if c <= 0.0 else "%s\n%d" % [nm, int(ceil(c))]
        b.modulate = Color(1, 1, 1, 1.0 if c <= 0.0 else 0.75)

func _process(delta: float) -> void:
    if needle != null:
        needle.rotation = town.cam_yaw_vis
        compass.visible = town.room == ""
        var ml: float = town.minimap.offset_left if town.minimap != null else -150.0
        compass.position = Vector2(root.get_viewport_rect().size.x + ml - 56, 60)
        snd.position = compass.position + Vector2(0, 54)
    _sk_tick += delta
    if _sk_tick >= 0.2:
        _sk_tick = 0.0
        refresh_skills()
        if town.steed != null:
            ride.visible = town.steed.S.mount != "" and town.room == "" and town.mine.cur < 0
            (ride.get_child(0) as Label).text = "ลง" if town.steed.riding() else "ขี่"

func _in(p: Panel, pos: Vector2, pad: float = 10.0) -> bool:
    var c := p.position + p.size * 0.5
    return pos.distance_to(c) <= p.size.x * 0.5 + pad

func _over_ui(pos: Vector2) -> bool:
    for c in [town.ui_shop, town.ui_dialog, town.ui_bag, town.bag_btn, town.ui_char, town.char_btn]:
        if c.visible and c.get_global_rect().has_point(pos):
            return true
    return false

func _press(b: Panel) -> void:
    var tw := create_tween()
    b.scale = Vector2(0.9, 0.9)
    b.pivot_offset = b.size * 0.5
    tw.tween_property(b, "scale", Vector2.ONE, 0.12)

func _input(e: InputEvent) -> void:
    if e is InputEventScreenTouch:
        var pos: Vector2 = e.position
        if e.pressed:
            if _over_ui(pos):
                return
            if _in(atk, pos):
                _press(atk)
                if attack_touch_id < 0:
                    attack_touch_id = e.index
                    town.player.set_attack_held(true)
                get_viewport().set_input_as_handled()
                return
            for sid in skill_btns.keys():
                var sb: Panel = skill_btns[sid]
                if sb.visible and _in(sb, pos, 4.0):
                    _press(sb)
                    var m: String = town.classes.use_slot(sid)
                    if m != "" and m != town.classes.slot_name(town.player, sid):
                        town.field.say_msg(m)
                    refresh_skills()
                    get_viewport().set_input_as_handled()
                    return
            if ride.visible and _in(ride, pos, 4.0):
                _press(ride)
                town.field.say_msg(town.steed.toggle())
                get_viewport().set_input_as_handled()
                return
            if snd != null and _in(snd, pos, 4.0) and town.sfx != null:
                _press(snd)
                town.sfx.toggle_mute()
                _snd_look()
                get_viewport().set_input_as_handled()
                return
            if compass.visible and _in(compass, pos, 6.0):
                _press(compass)
                town.cam_spin = 0.0
                town.cam_yaw = round(town.cam_yaw / TAU) * TAU
                get_viewport().set_input_as_handled()
                return
            if _in(dash, pos):
                _press(dash)
                town.player.dash(_world_dir())
                get_viewport().set_input_as_handled()
                return
            var vs := root.get_viewport_rect().size
            if pos.x < vs.x * 0.45 and joy_id < 0:
                joy_id = e.index
                joy_origin = pos
                joy_base.position = pos - joy_base.size * 0.5
                joy_knob.position = pos - joy_knob.size * 0.5
                joy_base.visible = true
                joy_knob.visible = true
                joy_hint.visible = false
            else:
                cam_ids[e.index] = pos
                if cam_ids.size() == 2:
                    var ps: Array = cam_ids.values()
                    pinch_d = (ps[0] as Vector2).distance_to(ps[1])
            touch_start[e.index] = [pos, Time.get_ticks_msec(), false]
        else:
            if e.index == attack_touch_id:
                attack_touch_id = -1
                town.player.set_attack_held(false)
                get_viewport().set_input_as_handled()
                return
            var ts = touch_start.get(e.index)
            if ts != null and not ts[2] and Time.get_ticks_msec() - int(ts[1]) < 350 and e.index != joy_id:
                town.click_at(pos)
            elif ts != null and not ts[2] and e.index == joy_id and Time.get_ticks_msec() - int(ts[1]) < 300:
                town.click_at(pos)
            touch_start.erase(e.index)
            if e.index == joy_id:
                joy_id = -1
                joy = Vector2.ZERO
                joy_base.visible = false
                joy_knob.visible = false
                joy_hint.visible = true
            cam_ids.erase(e.index)
            if cam_ids.is_empty():
                town.cam_dragging = false
            else:
                town.cam_spin = 0.0
    elif e is InputEventScreenDrag:
        if e.index == attack_touch_id:
            town.player.attack_held = _in(atk, e.position)
            get_viewport().set_input_as_handled()
            return
        var ts2 = touch_start.get(e.index)
        if ts2 != null and (e.position as Vector2).distance_to(ts2[0]) > 14.0:
            ts2[2] = true
        if e.index == joy_id:
            var d: Vector2 = e.position - joy_origin
            var r := JOY_SIZE * 0.5
            if d.length() > r:
                d = d.normalized() * r
            joy_knob.position = joy_origin + d - joy_knob.size * 0.5
            joy = d / r
            if joy.length() < 0.15:
                joy = Vector2.ZERO
        elif cam_ids.has(e.index):
            if cam_ids.size() >= 2:
                cam_ids[e.index] = e.position
                var ps2: Array = cam_ids.values()
                var nd := (ps2[0] as Vector2).distance_to(ps2[1])
                if pinch_d > 0.0:
                    var outside: bool = town.room == ""
                    town.cam_dist = clamp(town.cam_dist * pinch_d / max(nd, 1.0), town.CAM_NEAR if outside else 8.0, town.CAM_FAR if outside else 60.0)
                pinch_d = nd
            else:
                cam_ids[e.index] = e.position
                town.cam_dragging = true
                town.cam_yaw -= e.relative.x * 0.008
                town.cam_spin = -e.velocity.x * 0.008
                if town.room != "":
                    town.cam_pitch = clamp(town.cam_pitch - e.relative.y * 0.005, -1.4, -0.3)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        attack_touch_id = -1
        if town != null and town.player != null:
            town.player.set_attack_held(false)

## ทิศกลิ้ง: ตามจอย ถ้าไม่ดันจอย = ทิศที่หันอยู่
func _world_dir() -> Vector3:
    if joy.length() > 0.1:
        return Vector3(joy.x, 0, joy.y).normalized().rotated(Vector3.UP, town.cam_yaw)
    return Vector3.ZERO
