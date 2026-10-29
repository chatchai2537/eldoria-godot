extends Node3D
const VisualStyle = preload("res://scripts/visual_style.gd")
const BuildingKit = preload("res://scripts/building_kit.gd")
signal loading_stage(message: String, progress: float)
signal world_ready
## ตำนานเอลโดเรีย (Godot) · ขั้นที่ 1: เมืองเอลโดเรีย เดินได้
## ผังเมืองยกมาจากเกมเว็บ (js/031-core.js buildTown): 44 x 34 ช่อง · 1 ช่อง = 2 เมตร

const TW := 44
const TH := 34
const TS := 2.0
const OX := -44.0
const OZ := -34.0
const HALF := 220.0
# ทุ่งหญ้า = แผนที่เดียวกับเกม 2D (js/013-core.js) 60×44 ช่อง · ประตูเมืองช่อง (59,22) ต่อกับประตูตะวันตกของเมือง
const FX0 := -164.0
const FZ0 := -45.0
const FW := 60
const FH := 44
const F_GRASS := 0
const F_WATER := 1
const F_SAND := 2
const F_TREE := 3
const F_DOOR := 5
const F_WARP := 8
const F_GATE := 9

var noise := FastNoiseLite.new()
var noise_tex: NoiseTexture2D
var font: FontFile
var font_b: FontFile
var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var time_of_day := 0.33
var day_len := 600.0
var time_scale := 1.0
var grid := []
var roadset := {}
var astar := AStarGrid2D.new()
var lights: Array = []
var glow_mats: Array = []
var doors: Array = []
var player: Node3D
var field: Node3D
var cam: Camera3D
var cam_yaw := 0.0
var cam_pitch := -0.78
var cam_dist := 22.0
## กล้องมุมบนหมุนได้แบบ ROM: ลากนิ้วซ้าย-ขวาหมุน · ถ่างนิ้วซูม · มุมก้มเปลี่ยนตามระยะซูม · หมุนแล้วไหลต่อเล็กน้อย
const CAM_NEAR := 10.0
const CAM_FAR := 34.0
var cam_yaw_vis := 0.0      # มุมที่กล้องแสดงจริง (ไล่ตาม cam_yaw ให้นุ่ม)
var cam_spin := 0.0         # ความเร็วหมุนค้าง (เรเดียน/วิ) หลังปล่อยนิ้ว
var cam_dragging := false
var fade_blds: Array = []   # อาคารที่จางลงเมื่อบังกล้อง: {meshes, aabb, f}
var rot_drag := false
var hud: Label
var prompt: Label
var click_marker: MeshInstance3D
var shot_frames := -1
var shot_name := ""
var quality := 2
var low_fps_t := 0.0

# ---------- ข้อมูลผังเมือง (จากเกมเดิม) ----------
# ข้อมูลเมืองจริง (ดึงจากเกมเว็บที่รันอยู่: SHOP_DATA, NPC_DATA, dm, D.road, D.doors, LAMP_DATA, STALL_DATA)
var TD: Dictionary = {}
var shops_by_id := {}
var npcs: Array = []
var ui_dialog: PanelContainer
var ui_dname: Label
var ui_dtext: Label
var ui_shop: PanelContainer
var ui_shop_body: VBoxContainer
var talk_target = null
var talk_idx := 0
var in_door := ""
var _last_place := ""
var _test_auto := false
var is_mobile := false
var test_lv := 0  # ทดสอบหาต้นเหตุจอดำ: ?t=1 ไม่มีหญ้า/ป่า · ?t=2 +ไม่มีคน · ?t=3 +ไม่มีฟ้าจำลอง
var mobile: CanvasLayer
var mine: Node3D
var craft: Node
var classes: Node
var story: Node
var guild: Node
var legend: Node
var steed: Node3D
var minimap: Control
var fishing: Node
var world_loaded := false
var recovery_mode := false
var _sky_tick := 0.0
var FD: Dictionary = {}
var frows: Array = []
var fpath := {}
var fastar := AStarGrid2D.new()
var room := ""      # อยู่ในร้านไหน ("" = ข้างนอก)
var rooms: Node3D
var f_cut := {}   # ช่องต้นไม้ที่ถูกตัดเหลือตอ (เดินได้)
var sky_dome_mat: ShaderMaterial
const STYLE := {
    "gear": {"roof": Color(0.312, 0.323, 0.344), "wall": Color(0.617, 0.556, 0.480), "kind": "forge"},
    "seal113": {"roof": Color(0.342, 0.255, 0.393), "wall": Color(0.651, 0.611, 0.602), "kind": "gothic"},
    "skill": {"roof": Color(0.260, 0.306, 0.422), "wall": Color(0.752, 0.703, 0.606), "kind": "gothic"},
    "store": {"roof": Color(0.271, 0.380, 0.296), "wall": Color(0.760, 0.703, 0.598), "kind": "shop"},
    "inn": {"roof": Color(0.422, 0.253, 0.242), "wall": Color(0.768, 0.712, 0.606), "kind": "inn"},
    "potion": {"roof": Color(0.280, 0.380, 0.288), "wall": Color(0.760, 0.712, 0.615), "kind": "potion"},
    "guild": {"roof": Color(0.237, 0.337, 0.364), "wall": Color(0.701, 0.653, 0.564), "kind": "guild"},
    "bank": {"roof": Color(0.250, 0.294, 0.406), "wall": Color(0.777, 0.737, 0.648), "kind": "bank"},
    "fashion": {"roof": Color(0.442, 0.285, 0.317), "wall": Color(0.785, 0.728, 0.648), "kind": "shop"},
    "ware": {"roof": Color(0.450, 0.332, 0.258), "wall": Color(0.760, 0.703, 0.598), "kind": "house"},
}
const TREES := [[2, 9], [14, 3], [29, 9], [42, 9], [2, 14], [2, 27], [3, 31], [8, 31], [12, 31], [31, 31], [38, 31], [29, 3], [13, 8]]
const LAMPS := [[14, 15], [34, 15], [13, 18], [29, 18], [15, 10], [28, 10], [12, 23], [31, 23], [14, 30], [20, 30], [23, 30], [34, 30]]
const STALLS := [[16, 20], [18, 20], [25, 20], [27, 20]]
const FLOWERS := [[16, 11, 2, 1], [26, 11, 2, 1], [4, 30, 3, 2], [35, 30, 2, 2], [30, 9, 4, 1], [10, 9, 4, 1]]
const SPAWN := Vector2(7.0, 21.5)

func tw(x: float, y: float) -> Vector3:
    return Vector3(OX + x * TS, 0.0, OZ + y * TS)

func _ready() -> void:
    set_process(false)
    set_process_unhandled_input(false)
    seed(5)
    if OS.has_feature("web"):
        var q = JavaScriptBridge.eval("(new URLSearchParams(location.search)).get('t')||'0'", true)
        test_lv = int(str(q))
    is_mobile = OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.get_cmdline_user_args().has("--mobile")
    recovery_mode = bool(get_meta("recovery_mode", false))
    if is_mobile:
        Engine.max_fps = 30
        quality = 0
        get_viewport().scaling_3d_scale = 0.8
        get_viewport().msaa_3d = Viewport.MSAA_DISABLED
        RenderingServer.directional_shadow_atlas_set_size(512, true)
        get_viewport().size_changed.connect(_mobile_scale)
        _mobile_scale()
    font = load("res://fonts/Kanit-Regular.ttf")
    font_b = load("res://fonts/Kanit-SemiBold.ttf")
    noise.seed = 11
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.01
    noise.fractal_octaves = 4
    noise_tex = NoiseTexture2D.new()
    noise_tex.width = 512
    noise_tex.height = 512
    noise_tex.seamless = true
    var tn := FastNoiseLite.new()
    tn.frequency = 0.02
    tn.fractal_octaves = 3
    noise_tex.noise = tn
    await _stage("กำลังเตรียมแผนที่", 0.05)
    _layout()
    _setup_env()
    await _stage("กำลังสร้างพื้นเมือง", 0.15)
    _build_terrain()
    _build_ground()
    await _stage("กำลังสร้างกำแพง", 0.25)
    _build_walls()
    await _stage("กำลังสร้างปราสาท", 0.35)
    _build_castle()
    await _stage("กำลังสร้างร้านค้า", 0.45)
    _build_shops()
    await _stage("กำลังสร้างวิหาร", 0.55)
    _build_temple()
    _build_plaza()
    await _stage("กำลังตกแต่งเมือง", 0.65)
    _build_training()
    _build_props()
    await _stage("กำลังสร้างธรรมชาติ", 0.75)
    if test_lv < 1 and not recovery_mode:
        _build_outside()
        _build_grass()
    await _stage("กำลังเตรียมชาวเมือง", 0.85)
    if test_lv < 2:
        _build_npcs()
    await _stage("กำลังเตรียมผู้เล่น", 0.92)
    _build_player()
    _setup_hud()
    field = Node3D.new()
    field.set_script(load("res://scripts/field.gd"))
    add_child(field)
    field.setup(self)
    rooms = Node3D.new()
    rooms.set_script(load("res://scripts/rooms.gd"))
    add_child(rooms)
    rooms.setup(self)
    story = Node.new()
    story.set_script(load("res://scripts/story.gd"))
    add_child(story)
    story.setup(self)
    story.build_ui(ui_shop.get_parent())
    minimap = Control.new()
    minimap.set_script(load("res://scripts/minimap.gd"))
    ui_shop.get_parent().add_child(minimap)
    ui_shop.get_parent().move_child(minimap, 0)
    minimap.setup(self)
    fishing = Node.new()
    fishing.set_script(load("res://scripts/fishing.gd"))
    add_child(fishing)
    fishing.setup(self)
    fishing.build_ui(ui_shop.get_parent())
    guild = Node.new()
    guild.set_script(load("res://scripts/guild.gd"))
    add_child(guild)
    guild.setup(self)
    classes = Node.new()
    classes.set_script(load("res://scripts/skills.gd"))
    add_child(classes)
    classes.setup(self)
    legend = Node.new()
    legend.set_script(load("res://scripts/legend.gd"))
    add_child(legend)
    legend.setup(self)
    steed = Node3D.new()
    steed.set_script(load("res://scripts/steed.gd"))
    add_child(steed)
    steed.setup(self)
    # ผู้เล่นโหลดเซฟก่อนสร้างระบบเนื้อเรื่อง/อาชีพ → ใส่ค่าที่โหลดไว้ตอนนี้
    legend.load_state(player.pending_legend)
    steed.load_state(player.pending_steed)
    steed._sync()
    story.load_state(player.pending_story)
    guild.load_state(player.pending_guild)
    story.update_tracker()
    player.recalc_stats()
    if player.loaded_hp > 0.0:
        player.hp = min(player.loaded_hp, float(player.max_hp))
    craft = Node.new()
    craft.set_script(load("res://scripts/craft.gd"))
    add_child(craft)
    craft.setup(self)
    mine = Node3D.new()
    mine.set_script(load("res://scripts/mine.gd"))
    add_child(mine)
    mine.setup(self)
    if is_mobile:
        for c in [ui_dialog, ui_shop, prompt, field.msg]:
            c.anchor_left = 0.0
            c.anchor_right = 1.0
            c.offset_left = 8
            c.offset_right = -8
        ui_dialog.offset_top = -200
        ui_dialog.offset_bottom = -110
        ui_shop.anchor_top = 0.34
        ui_shop.anchor_bottom = 1.0
        ui_shop.offset_top = 0
        ui_shop.offset_bottom = -6
        ui_bag.anchor_left = 0.0
        ui_bag.anchor_right = 1.0
        ui_bag.offset_left = 8
        ui_bag.offset_right = -8
        ui_bag.anchor_top = 0.0
        ui_bag.anchor_bottom = 1.0
        ui_bag.offset_top = 40
        ui_bag.offset_bottom = -100
        for pn in [ui_char]:
            pn.anchor_left = 0.0
            pn.anchor_right = 1.0
            pn.offset_left = 8
            pn.offset_right = -8
            pn.anchor_top = 0.0
            pn.anchor_bottom = 1.0
            pn.offset_top = 40
            pn.offset_bottom = -100
        field.hud_card.position = Vector2(10, 36)
        field.hud_box.add_theme_constant_override("separation", 3)
        for b in field.bars:
            b.custom_minimum_size = Vector2(118, 9)
        field.msg.offset_top = 150
        field.msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        prompt.offset_top = -230
        cam_dist = 24.0
        mobile = CanvasLayer.new()
        mobile.set_script(load("res://scripts/mobile.gd"))
        add_child(mobile)
        mobile.setup(self)
        field.atk_btn.visible = false
    world_loaded = true
    set_process(true)
    set_process_unhandled_input(true)
    loading_stage.emit("พร้อมเข้าเกม", 1.0)
    world_ready.emit()
    var args := OS.get_cmdline_user_args()
    for a in args:
        if a.begins_with("--shot="):
            var p := a.substr(7).split(",")
            shot_name = p[0]
            time_of_day = float(p[1])
            cam_yaw = float(p[2])
            cam_dist = float(p[3])
            if p.size() > 5:
                player.position = tw(float(p[4]), float(p[5]))
            time_scale = 0.0
            shot_frames = 45
            if p.size() > 6:
                call_deferred("_test_ui", p[6])

func _stage(message: String, progress: float) -> void:
    loading_stage.emit(message, progress)
    # ให้หน้ารอโหลดและงาน GPU ได้ทำงานระหว่างสร้างแต่ละส่วน
    await get_tree().process_frame
    await get_tree().process_frame

## มือถือ: ขยาย UI ตามขนาดจอจริง (เดิมย่อจาก 1600×900 จนตัวหนังสือเล็กมาก)
func _mobile_scale() -> void:
    var ws := DisplayServer.window_get_size()
    var f: float = clamp(min(ws.x, ws.y) / 400.0, 1.0, 4.0)
    get_tree().root.content_scale_size = Vector2i(int(ws.x / f), int(ws.y / f))

# ---------- ช่องเดินได้/เดินไม่ได้ ----------
func _box(x: int, y: int, w: int, hh: int, v: int = 1) -> void:
    for j in range(y, y + hh):
        for i in range(x, x + w):
            if j >= 0 and j < TH and i >= 0 and i < TW:
                grid[j][i] = v

func _road(x: int, y: int, w: int, hh: int) -> void:
    for j in range(y, y + hh):
        for i in range(x, x + w):
            roadset[j * TW + i] = true

func _layout() -> void:
    var f := FileAccess.open("res://data/town.json", FileAccess.READ)
    TD = JSON.parse_string(f.get_as_text())
    for sh in TD.shops:
        shops_by_id[sh.id] = sh
    grid = []
    var dmr: Array = TD.dm
    for y in TH:
        var row := []
        var line: String = dmr[y]
        for x in TW:
            var v := int(line.substr(x, 1))
            row.append(0 if v == 5 else v)
        grid.append(row)
    for k in TD.road:
        roadset[int(k)] = true
    for d in TD.doors:
        var sh: Dictionary = shops_by_id.get(d.id, {})
        doors.append({"n": sh.get("name", d.id), "p": Vector2(float(d.cx) / 32.0, float(d.cy) / 32.0), "id": d.id})
    doors.append({"n": "ท้องพระโรงเอลโดเรีย", "p": Vector2(22.0, 9.3), "id": "hall"})
    var ff := FileAccess.open("res://data/field.json", FileAccess.READ)
    FD = JSON.parse_string(ff.get_as_text())
    frows = FD.rows
    for k in FD.path:
        fpath[int(k)] = true
    # ทางเชื่อมจากทางเดินถึงประตูเมือง (แถว 21-22)
    for x in range(52, FW):
        for y in [21, 22]:
            fpath[y * FW + x] = true
    fastar.region = Rect2i(0, 0, FW, FH)
    fastar.cell_size = Vector2(1, 1)
    fastar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    fastar.update()
    for y in FH:
        for x in FW:
            if ftile_solid(ftile(x, y)):
                fastar.set_point_solid(Vector2i(x, y), true)
    astar.region = Rect2i(0, 0, TW, TH)
    astar.cell_size = Vector2(1, 1)
    astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    astar.update()
    for y in TH:
        for x in TW:
            if grid[y][x] != 0:
                astar.set_point_solid(Vector2i(x, y), true)

func ftile(x: int, y: int) -> int:
    if x < 0 or y < 0 or x >= FW or y >= FH:
        return -1
    return int((frows[y] as String).substr(x, 1))

func ftile_solid(t: int) -> bool:
    return t == -1 or t == F_WATER or t == F_TREE or t == F_DOOR or t == F_WARP

func fw(x: float, y: float) -> Vector3:
    return Vector3(FX0 + x * TS, 0.0, FZ0 + y * TS)

func ftile_at(wx: float, wz: float) -> Vector2i:
    return Vector2i(int(floor((wx - FX0) / TS)), int(floor((wz - FZ0) / TS)))

func blocked(wx: float, wz: float) -> bool:
    if room != "":
        return rooms.blocked(wx, wz)
    if mine != null and mine.cur >= 0:
        return mine.blocked(wx, wz)
    var tx := int(floor((wx - OX) / TS))
    var ty := int(floor((wz - OZ) / TS))
    if tx < 0 or ty < 0 or tx >= TW or ty >= TH:
        if wx < OX:
            var ft := ftile_at(wx, wz)
            if f_cut.has(ft.y * FW + ft.x):
                return false
            return ftile_solid(ftile(ft.x, ft.y))
        return true
    return grid[ty][tx] != 0

func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
    if room != "" or (mine != null and mine.cur >= 0):
        return PackedVector3Array() if blocked(to.x, to.z) else PackedVector3Array([Vector3(to.x, 0, to.z)])
    var fa := from.x < OX
    var fb := to.x < OX
    if fb and blocked(to.x, to.z):
        return PackedVector3Array()
    var gate_in := tw(0.5, 17.0)
    var gate_out := fw(59.5, 22.5)
    if fa and fb:
        return _field_path(from, to)
    if fa and not fb:
        var out := _field_path(from, gate_out)
        out.append(gate_in)
        out.append_array(_grid_path(gate_in, to))
        return out
    if fb and not fa:
        var out2 := _grid_path(from, gate_in)
        out2.append(gate_out)
        out2.append_array(_field_path(gate_out, to))
        return out2
    return _grid_path(from, to)

func _field_path(from: Vector3, to: Vector3) -> PackedVector3Array:
    var a := ftile_at(from.x, from.z)
    var b := ftile_at(to.x, to.z)
    var out := PackedVector3Array()
    if not fastar.region.has_point(a) or not fastar.region.has_point(b):
        return out
    if fastar.is_point_solid(b):
        var best := b
        var bd := 1e9
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                var c := b + Vector2i(dx, dy)
                if fastar.region.has_point(c) and not fastar.is_point_solid(c):
                    var dd := Vector2(dx, dy).length()
                    if dd < bd:
                        bd = dd
                        best = c
        b = best
        to = fw(b.x + 0.5, b.y + 0.5)
    if fastar.is_point_solid(a):
        return PackedVector3Array([Vector3(to.x, 0, to.z)])
    var pts := fastar.get_id_path(a, b)
    for i in range(1, pts.size()):
        var p: Vector2i = pts[i]
        out.append(fw(p.x + 0.5, p.y + 0.5))
    if out.size() > 0:
        out[out.size() - 1] = Vector3(to.x, 0, to.z)
    else:
        out.append(Vector3(to.x, 0, to.z))
    return out

func _grid_path(from: Vector3, to: Vector3) -> PackedVector3Array:
    var a := Vector2i(int((from.x - OX) / TS), int((from.z - OZ) / TS))
    var b := Vector2i(int((to.x - OX) / TS), int((to.z - OZ) / TS))
    var out := PackedVector3Array()
    if not astar.region.has_point(a) or not astar.region.has_point(b):
        return out
    if astar.is_point_solid(b):
        var best := b
        var bd := 1e9
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                var c := b + Vector2i(dx, dy)
                if astar.region.has_point(c) and not astar.is_point_solid(c):
                    var dd := Vector2(c - a).length() * 0.05 + Vector2(dx, dy).length()
                    if dd < bd:
                        bd = dd
                        best = c
        b = best
        to = tw(b.x + 0.5, b.y + 0.5)
    var pts := astar.get_id_path(a, b)
    for i in range(1, pts.size()):
        var p: Vector2i = pts[i]
        out.append(tw(p.x + 0.5, p.y + 0.5))
    if out.size() > 0:
        out[out.size() - 1] = Vector3(to.x, 0, to.z)
    return out

# ---------- ฟ้า แสง ----------
func _setup_env() -> void:
    env = Environment.new()
    var advanced_effects := not is_mobile and RenderingServer.get_current_rendering_method() == "forward_plus"
    var use_sky := not is_mobile and test_lv < 3
    env.background_mode = Environment.BG_SKY if use_sky else Environment.BG_COLOR
    env.background_color = Color(0.55, 0.7, 0.85)
    if use_sky:
        var sky := Sky.new()
        sky_mat = ProceduralSkyMaterial.new()
        sky.sky_material = sky_mat
        env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if use_sky else Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.61, 0.69, 0.79)
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY if use_sky else Environment.REFLECTION_SOURCE_DISABLED
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_white = 6.0
    env.tonemap_exposure = 0.88
    env.ssao_enabled = advanced_effects
    env.ssao_radius = 1.0
    env.ssao_intensity = 2.0
    env.glow_enabled = not is_mobile
    env.glow_intensity = 0.45
    env.glow_bloom = 0.05
    env.glow_hdr_threshold = 1.3
    env.fog_enabled = not is_mobile
    env.fog_density = 0.0008
    env.fog_aerial_perspective = 0.15
    env.fog_sky_affect = 0.2
    env.volumetric_fog_enabled = advanced_effects
    env.volumetric_fog_density = 0.005
    env.volumetric_fog_anisotropy = 0.6
    env.volumetric_fog_length = 100.0
    env.adjustment_enabled = true
    env.adjustment_saturation = 0.92
    env.adjustment_contrast = 1.06
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    sun = DirectionalLight3D.new()
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 120.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if not is_mobile else DirectionalLight3D.SHADOW_ORTHOGONAL
    if is_mobile:
        sun.directional_shadow_max_distance = 40.0
        sun.shadow_enabled = false  # มือถือ: ปิดเงา กันจอดำ (WebGL context lost)
    sun.light_angular_distance = 0.7
    sun.light_volumetric_fog_energy = 1.4
    add_child(sun)
    moon = DirectionalLight3D.new()
    moon.light_color = Color(0.55, 0.65, 1.0)
    moon.shadow_enabled = false
    add_child(moon)
    _update_sky()

func _update_sky() -> void:
    # ในร้าน: แสงกลางวันคงที่ (ห้องไม่มืดตอนกลางคืน)
    var in_mine: bool = mine != null and mine.cur >= 0
    var tod: float = 0.42 if (room != "" or in_mine) else time_of_day
    var ang := (tod - 0.25) * TAU
    var elev := sin(ang)
    sun.rotation = Vector3(-ang, deg_to_rad(-30.0), 0.0)
    var day: float = clamp(elev * 3.0 + 0.15, 0.0, 1.0)
    var low: float = clamp(1.0 - elev * 2.6, 0.0, 1.0) * day
    sun.light_color = Color(1.0, 0.92, 0.79).lerp(Color(1.0, 0.64, 0.42), low)
    sun.light_energy = 1.15 * day
    sun.visible = day > 0.01
    moon.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(150.0), 0.0)
    moon.light_energy = 0.35 * (1.0 - day)
    var top := Color(0.02, 0.03, 0.09).lerp(Color(0.3, 0.52, 0.85).lerp(Color(0.3, 0.32, 0.55), low), day)
    var hor := Color(0.06, 0.08, 0.16).lerp(Color(0.72, 0.82, 0.92).lerp(Color(1.0, 0.62, 0.38), low), day)
    if sky_mat != null:
        sky_mat.sky_top_color = top
        sky_mat.sky_horizon_color = hor
        sky_mat.ground_horizon_color = hor.darkened(0.15)
        sky_mat.ground_bottom_color = hor.darkened(0.6)
        sky_mat.sun_angle_max = 18.0 + low * 25.0
    else:
        env.background_color = hor
    env.fog_light_color = hor.lerp(Color(0.5, 0.6, 0.75), 0.3)
    env.ambient_light_energy = lerp(0.22, 0.52, day) if not is_mobile else lerp(0.3, 0.85, day)
    env.volumetric_fog_albedo = Color(1, 1, 1).lerp(Color(1.0, 0.8, 0.65), low)
    if in_mine and mine.zdef(mine.cur).dark:
        # เหมืองมืด: แดดอ่อน ฟ้าดำ
        sun.light_energy *= 0.55
        env.ambient_light_energy *= 0.75
        if sky_mat == null:
            env.background_color = Color.html(str(mine.zdef(mine.cur).pal.vd))
    var night := 1.0 - day
    for l in lights:
        l.light_energy = night * 2.6
    for m in glow_mats:
        m.emission_energy_multiplier = 0.08 + night * 2.1

# ---------- พื้นที่ ----------
func h(x: float, z: float) -> float:
    var dx: float = max(abs(x) - 46.0, 0.0)
    var dz: float = max(abs(z) - 36.0, 0.0)
    var dt := sqrt(dx * dx + dz * dz)
    if in_field_rect(x, z, 0.0):
        return -4.0
    var ex: float = max(max(FX0 - x, x + 46.0), 0.0)
    var ez: float = max(max(FZ0 - z, z - (FZ0 + FH * TS)), 0.0)
    var df := sqrt(ex * ex + ez * ez)
    var d: float = min(dt, df)
    var n := noise.get_noise_2d(x, z) * 7.0 + noise.get_noise_2d(x * 3.1, z * 3.1) * 1.0
    var f := smoothstep(4.0, 40.0, d)
    var rim := pow(smoothstep(70.0, 125.0, d), 1.4) * 30.0
    return n * f + rim - 0.06

func ground_y(x: float, z: float) -> float:
    if x > 600.0:
        return 0.0
    if abs(x) <= 44.0 and abs(z) <= 34.0:
        return 0.0
    if in_field_rect(x, z, 0.0):
        return fh(x, z)
    return h(x, z)

func in_field_rect(x: float, z: float, pad: float) -> bool:
    return x > FX0 - pad and x < -44.0 and z > FZ0 - pad and z < FZ0 + FH * TS + pad

## ความสูงพื้นทุ่งหญ้า: บ่อน้ำเป็นแอ่งลง ขอบทรายลาดลง
func fh(x: float, z: float) -> float:
    var w := 0.0
    for o in [Vector2(-0.6, -0.6), Vector2(0.6, -0.6), Vector2(-0.6, 0.6), Vector2(0.6, 0.6)]:
        var t := ftile_at(x + o.x, z + o.y)
        var k := ftile(t.x, t.y)
        if k == F_WATER:
            w += 0.25
        elif k == -1:
            w += 0.0
    return -1.1 * w + 0.02

func _build_terrain() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n := 80 if is_mobile else 230
    var step := HALF * 2.0 / n
    var verts := []
    for zi in n + 1:
        for xi in n + 1:
            var x := -HALF + xi * step
            var z := -HALF + zi * step
            var pm := 0.0
            if abs(z - 1.0) < 3.0 and x > 44.0 and x < 120.0:
                pm = 1.0 - smoothstep(1.5, 3.0, abs(z - 1.0))
            verts.append([Vector3(x, h(x, z), z), Color(pm, 0.0, 0.0)])
    for zi in n:
        for xi in n:
            var i0 := zi * (n + 1) + xi
            for qi in [i0, i0 + 1, i0 + n + 1, i0 + 1, i0 + n + 2, i0 + n + 1]:
                st.set_color(verts[qi][1])
                st.add_vertex(verts[qi][0])
    st.index()
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    var mat := ShaderMaterial.new()
    mat.shader = load("res://shaders/terrain.gdshader")
    mat.set_shader_parameter("noise_tex", noise_tex)
    mi.material_override = mat
    add_child(mi)

func _build_ground() -> void:
    var img := Image.create(TW, TH, false, Image.FORMAT_RGBA8)
    for y in TH:
        for x in TW:
            var c := Color(0, 0, 0, 1)
            if roadset.has(y * TW + x):
                c.r = 1.0
            if x >= 3 and x < 12 and y >= 18 and y < 27:
                c = Color(0, 1, 0, 1)
            if x >= 30 and x < 41 and y >= 19 and y < 24:
                c = Color(0, 0, 1, 1)
            img.set_pixel(x, y, c)
    var tex := ImageTexture.create_from_image(img)
    var pm := PlaneMesh.new()
    pm.size = Vector2(TW * TS, TH * TS)
    var mi := MeshInstance3D.new()
    mi.mesh = pm
    mi.position = Vector3(0, 0.0, 0)
    var mat := ShaderMaterial.new()
    mat.shader = load("res://shaders/town_ground.gdshader")
    mat.set_shader_parameter("tilemap", tex)
    mat.set_shader_parameter("contact_ao", VisualStyle.texture_for("town_ao"))
    mat.set_shader_parameter("noise_tex", noise_tex)
    mi.material_override = mat
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)

# ---------- ตัวช่วยสร้างชิ้นส่วน ----------
var _mats := {}
func M(c: Color, rough: float = 0.85, emit: float = 0.0) -> StandardMaterial3D:
    var key := str(c) + str(rough) + str(emit)
    if _mats.has(key):
        return _mats[key]
    var m := VisualStyle.surface(c, rough, emit)
    _mats[key] = m
    return m

func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var bm := BoxMesh.new()
    bm.size = size
    var mi := MeshInstance3D.new()
    mi.mesh = bm
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi

func cyl(parent: Node3D, rt: float, rb: float, hh: float, pos: Vector3, m: Material, seg: int = 16) -> MeshInstance3D:
    var cm := CylinderMesh.new()
    cm.top_radius = rt
    cm.bottom_radius = rb
    cm.height = hh
    cm.radial_segments = seg
    var mi := MeshInstance3D.new()
    mi.mesh = cm
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    return mi

func gable(parent: Node3D, w: float, d: float, hh: float, pos: Vector3, m: Material) -> MeshInstance3D:
    # หลังคาจั่ว (สันหลังคาตามแกน X)
    var pm := PrismMesh.new()
    pm.size = Vector3(d, hh, w)
    var mi := MeshInstance3D.new()
    mi.mesh = pm
    mi.material_override = VisualStyle.roof(m) if m is StandardMaterial3D else m
    mi.position = pos + Vector3(0, hh * 0.5, 0)
    mi.rotation.y = PI / 2.0
    parent.add_child(mi)
    return mi

func label3d(text: String, pos: Vector3, size: int = 48, col: Color = Color(1, 0.95, 0.8)) -> Label3D:
    var l := Label3D.new()
    l.text = clean(text)
    l.font = font_b
    l.font_size = size
    l.pixel_size = 0.009
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.modulate = col
    l.outline_size = 7
    l.outline_modulate = Color(0.1, 0.07, 0.04, 0.9)
    l.position = pos
    l.no_depth_test = false
    add_child(l)
    return l

func lantern(p: Vector3, hh: float = 3.2) -> void:
    var iron := M(Color(0.16, 0.16, 0.18), 0.5)
    cyl(self, 0.07, 0.1, hh, p + Vector3(0, hh * 0.5, 0), iron, 8)
    box(self, Vector3(0.5, 0.12, 0.5), p + Vector3(0, hh + 0.05, 0), iron)
    var gm := StandardMaterial3D.new()
    gm.albedo_color = Color(1.0, 0.8, 0.45)
    gm.emission_enabled = true
    gm.emission = Color(1.0, 0.7, 0.35)
    gm.emission_energy_multiplier = 0.3
    glow_mats.append(gm)
    var g := box(self, Vector3(0.36, 0.45, 0.36), p + Vector3(0, hh - 0.25, 0), gm)
    g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    box(self, Vector3(0.5, 0.1, 0.5), p + Vector3(0, hh - 0.52, 0), iron)
    var ol := OmniLight3D.new()
    ol.light_color = Color(1.0, 0.7, 0.4)
    ol.omni_range = 10.0
    ol.omni_attenuation = 1.4
    ol.light_energy = 0.0
    ol.position = p + Vector3(0, hh - 0.3, 0)
    add_child(ol)
    lights.append(ol)

func window(parent: Node3D, pos: Vector3, size: Vector2, rot: float = 0.0) -> void:
    var gm := StandardMaterial3D.new()
    gm.albedo_color = Color(0.16, 0.26, 0.30)
    gm.roughness = 0.2
    gm.emission_enabled = true
    gm.emission = Color(1.0, 0.72, 0.38)
    gm.emission_energy_multiplier = 0.3
    glow_mats.append(gm)
    var w := box(parent, Vector3(size.x, size.y, 0.08), pos, gm, Vector3(0, rot, 0))
    w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    box(parent, Vector3(size.x + 0.18, 0.1, 0.18), pos - Vector3(0, size.y * 0.5 + 0.05, 0).rotated(Vector3.UP, rot), M(Color(0.35, 0.22, 0.12)), Vector3(0, rot, 0))

# ---------- กำแพงเมือง ----------
func tower(p: Vector3, r: float, hh: float, roof: Color, flag: bool) -> void:
    var stone := M(Color(0.6, 0.57, 0.52), 0.95)
    cyl(self, r, r * 1.08, hh, p + Vector3(0, hh * 0.5, 0), stone, 18)
    cyl(self, r * 1.15, r * 1.15, 0.6, p + Vector3(0, hh, 0), M(Color(0.52, 0.5, 0.46), 0.95), 18)
    for i in 10:
        var a := i * TAU / 10.0
        box(self, Vector3(0.6, 0.8, 0.5), p + Vector3(cos(a) * r * 1.05, hh + 0.7, sin(a) * r * 1.05), stone, Vector3(0, -a, 0))
    cyl(self, 0.0, r * 1.2, r * 1.9, p + Vector3(0, hh + 0.35 + r * 0.95, 0), M(roof, 0.65), 18)
    for i in 3:
        var a2 := i * TAU / 3.0 + 0.4
        window(self, p + Vector3(cos(a2) * (r + 0.02), hh * 0.65, sin(a2) * (r + 0.02)), Vector2(0.45, 0.9), -a2 + PI / 2.0)
    if flag:
        cyl(self, 0.05, 0.05, 2.6, p + Vector3(0, hh + r * 1.9 + 1.4, 0), M(Color(0.3, 0.2, 0.12)), 6)
        var fl := box(self, Vector3(1.4, 0.8, 0.04), p + Vector3(0.72, hh + r * 1.9 + 2.3, 0), M(Color(0.2, 0.3, 0.7), 0.8))
        fl.set_meta("flag", true)

func _build_walls() -> void:
    var stone := M(Color(0.55, 0.52, 0.48), 0.95)
    var dark := M(Color(0.44, 0.42, 0.39), 0.95)
    var hh := 5.5
    # แนวกำแพง: เหนือ ใต้ ตะวันตก (เว้นประตู) ตะวันออก (เว้นประตู)
    var segs := [
        [tw(0, 0.5), tw(44, 0.5)], [tw(0, 33.5), tw(44, 33.5)],
        [tw(0.5, 0), tw(0.5, 16)], [tw(0.5, 18), tw(0.5, 34)],
        [tw(43.5, 0), tw(43.5, 16)], [tw(43.5, 18), tw(43.5, 34)],
    ]
    for s in segs:
        var a: Vector3 = s[0]
        var b: Vector3 = s[1]
        var mid := (a + b) * 0.5
        var horiz: bool = abs(a.z - b.z) < 0.01
        var len := a.distance_to(b)
        var size := Vector3(len, hh, 1.8) if horiz else Vector3(1.8, hh, len)
        box(self, size, mid + Vector3(0, hh * 0.5, 0), stone)
        var cnt := int(len / 1.4)
        for i in cnt:
            var t := (i + 0.5) / cnt
            var q := a.lerp(b, t)
            if i % 2 == 0:
                box(self, Vector3(0.8, 0.9, 1.9) if horiz else Vector3(1.9, 0.9, 0.8), q + Vector3(0, hh + 0.45, 0), dark)
    # ประตูเมืองตะวันตก/ตะวันออก (ซุ้มโค้งด้านบน)
    for gx in [0.5, 43.5]:
        var c := tw(gx, 17)
        box(self, Vector3(2.2, 1.6, 4.4), c + Vector3(0, hh - 0.2, 0), stone)
        var arch := cyl(self, 2.0, 2.0, 2.0, c + Vector3(0, hh - 1.0, 0), dark, 20)
        arch.rotation.z = PI / 2.0
        arch.scale = Vector3(1, 1, 0.6)
        label3d("« ทุ่งหญ้า" if gx < 1 else "ถนนสู่นครวารี »", c + Vector3(0, hh + 1.8, 0), 40)
    for p in [[1, 1], [TW - 2, 1], [1, TH - 2], [TW - 2, TH - 2]]:
        tower(tw(p[0] + 0.5, p[1] + 0.5), 2.6, 9.0, Color(0.68, 0.24, 0.16), true)
    for gx in [1, TW - 2]:
        for gy in [14, 19]:
            tower(tw(gx + 0.5, gy + 0.5), 1.9, 7.5, Color(0.68, 0.24, 0.16), false)

# ---------- ปราสาท ----------
func _build_castle() -> void:
    var c := tw(22, 4.8)
    var stone := M(Color(0.7, 0.68, 0.63), 0.9)
    var stone2 := M(Color(0.58, 0.56, 0.52), 0.9)
    var blue := M(Color(0.2, 0.32, 0.66), 0.55)
    var gold := M(Color(0.9, 0.72, 0.3), 0.35)
    # ฐานและกำแพงปราสาท
    box(self, Vector3(27, 1.2, 15), c + Vector3(0, 0.6, 0), stone2)
    box(self, Vector3(24, 9, 10), c + Vector3(0, 5.2, -1.5), stone)
    for i in 16:
        var x := -11.6 + i * 1.55
        box(self, Vector3(0.8, 1.0, 10.2), c + Vector3(x, 10.2, -1.5), stone2)
    # ตึกกลางสูง
    box(self, Vector3(9, 15, 7), c + Vector3(0, 8.7, -2.5), stone)
    gable(self, 9.8, 7.8, 4.2, c + Vector3(0, 16.2, -2.5), M(Color(0.72, 0.2, 0.18), 0.6))
    for k in 5:
        var cpt := cyl(self, 0.0, 0.35, 1.2, c + Vector3(-1.2 + k * 0.6, 21.4, -0.6), gold, 6)
    box(self, Vector3(3.2, 0.5, 0.5), c + Vector3(0, 20.6, -0.6), gold)
    cyl(self, 1.7, 1.9, 21, c + Vector3(0, 10.5, -2.5), stone2, 18)
    cyl(self, 0.0, 2.4, 5.2, c + Vector3(0, 23.6, -2.5), blue, 18)
    cyl(self, 0.05, 0.05, 2.5, c + Vector3(0, 27.4, -2.5), gold, 6)
    var fl := box(self, Vector3(1.8, 1.0, 0.05), c + Vector3(0.95, 28.1, -2.5), M(Color(0.85, 0.15, 0.15), 0.8))
    fl.set_meta("flag", true)
    # หอคอยสี่มุม
    for p in [Vector3(-12, 0, -6), Vector3(12, 0, -6), Vector3(-12, 0, 3.5), Vector3(12, 0, 3.5)]:
        tower(c + p, 2.4, 13.0, Color(0.2, 0.32, 0.66), true)
    # ซุ้มประตูหน้า (ช่อง 21-22 แถว 8)
    var g := tw(22, 8.6)
    box(self, Vector3(7, 7, 3), g + Vector3(0, 3.5, -0.8), stone)
    box(self, Vector3(3.2, 4.2, 0.4), g + Vector3(0, 2.1, 0.75), M(Color(0.25, 0.15, 0.08), 0.8))
    var arch := cyl(self, 1.6, 1.6, 0.42, g + Vector3(0, 4.2, 0.76), M(Color(0.25, 0.15, 0.08), 0.8), 20)
    arch.rotation.x = PI / 2.0
    for i in 5:
        box(self, Vector3(0.8, 0.8, 3.1), g + Vector3(-3.0 + i * 1.5, 7.4, -0.8), stone2)
    gable(self, 7.6, 3.6, 2.0, g + Vector3(0, 7.0, -0.8), blue)
    for s in [-1, 1]:
        var bn := box(self, Vector3(1.2, 3.0, 0.08), g + Vector3(s * 2.6, 4.5, 0.75), M(Color(0.2, 0.3, 0.7), 0.8))
        box(self, Vector3(0.5, 0.5, 0.1), g + Vector3(s * 2.6, 5.0, 0.8), gold)
    for i in 6:
        window(self, c + Vector3(-9.5 + i * 3.8, 6.5, 3.52), Vector2(0.9, 1.6))
    for i in 3:
        window(self, c + Vector3(-2.6 + i * 2.6, 11.5, 1.02), Vector2(0.8, 1.8))
    label3d("ปราสาทเอลโดเรีย", g + Vector3(0, 9.6, 0.5), 56, Color(1.0, 0.9, 0.55))

# ---------- ร้านค้าและบ้าน (ตำแหน่ง/ชื่อจากเกมจริง สีหลังคาตามภาพเมืองเดิม) ----------
func _spire(parent: Node3D, pos: Vector3, r: float, hh: float, m: Material) -> void:
    cyl(parent, 0.0, r, hh, pos + Vector3(0, hh * 0.5, 0), m, 8)

## หน้าต่างกรอบลึก: กระจกเรืองแสง + กรอบ 4 ด้าน + ไม้กางเขน + ขอบล่าง (+บานเกล็ด)
func _kit_window(k, glass: Material, frame: Material, shutter: Material, c: Vector3, s: Vector2, shutters: bool) -> void:
    k.box(glass, Vector3(s.x, s.y, 0.06), c)
    var t := 0.14
    k.box(frame, Vector3(s.x + t * 2.0, t, 0.2), c + Vector3(0, s.y * 0.5 + t * 0.5, 0.05))
    k.box(frame, Vector3(s.x + t * 2.0 + 0.16, t, 0.3), c + Vector3(0, -s.y * 0.5 - t * 0.5, 0.08))
    for sx in [-1.0, 1.0]:
        k.box(frame, Vector3(t, s.y, 0.2), c + Vector3(sx * (s.x + t) * 0.5, 0, 0.05))
    k.box(frame, Vector3(0.06, s.y, 0.08), c + Vector3(0, 0, 0.05))
    k.box(frame, Vector3(s.x, 0.06, 0.08), c + Vector3(0, s.y * 0.1, 0.05))
    if shutters:
        for sx in [-1.0, 1.0]:
            k.box(shutter, Vector3(s.x * 0.5, s.y + 0.1, 0.07), c + Vector3(sx * (s.x * 0.75 + t + 0.06), 0, 0.04))
            for i in 4:
                k.box(frame, Vector3(s.x * 0.44, 0.04, 0.03), c + Vector3(sx * (s.x * 0.75 + t + 0.06), -s.y * 0.38 + i * s.y * 0.25, 0.09))

func _building(b: Array, st: Dictionary, title: String, sid: String) -> void:
    # 0.25 แฟนตาซีทันสมัย: ชั้นล่างหิน · ชั้นบนยื่น (jetty) โครงไม้ · หลังคาชายคาหนา + จั่วหน้า
    # หน้าต่างมีกรอบลึก บานเกล็ด · ประตูซุ้มหิน · โคมคริสตัล · ประกอบเป็น mesh ไม่กี่ชิ้นต่อหลัง
    var beam := M(Color(0.3, 0.19, 0.11), 0.85)
    var stone := M(Color(0.5, 0.48, 0.45), 0.95)
    var stone_lt := M(Color(0.66, 0.63, 0.58), 0.95)
    var wall := M(st.wall, 0.9)
    var roof: StandardMaterial3D = VisualStyle.roof(M(st.roof, 0.65))
    var gold := M(Color(0.9, 0.72, 0.3), 0.3)
    var iron := M(Color(0.16, 0.16, 0.18), 0.5)
    var shutter := M(st.roof.darkened(0.15), 0.8)
    var door_m := M(Color(0.34, 0.2, 0.1), 0.8)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.16, 0.26, 0.30)
    glass.roughness = 0.2
    glass.emission_enabled = true
    glass.emission = Color(1.0, 0.72, 0.38)
    glass.emission_energy_multiplier = 0.3
    glow_mats.append(glass)
    var crystal := M(Color(0.45, 0.85, 1.0), 0.2, 1.6)
    var w: float = b[2] * TS
    var d: float = b[3] * TS
    var root := Node3D.new()
    root.position = tw(b[0] + b[2] * 0.5, b[1] + b[3] * 0.5)
    add_child(root)
    var kit := BuildingKit.new()
    var big: bool = b[3] >= 6
    var P := 0.7                      # ฐานหิน
    var wh := 2.9                     # ชั้นล่าง (ของประจำร้านด้านล่างอิงค่านี้)
    var band := 0.32
    var uh := 2.9 if big else 2.5     # ชั้นบน
    var jet := 0.4                    # ชั้นบนยื่นออก
    var gw := w - 0.8
    var gd := d - 1.2
    var zc := -0.1
    var fz := zc + gd * 0.5           # หน้าชั้นล่าง
    var uw := gw + jet * 2.0
    var ud := gd + jet
    var uzc := zc + jet * 0.5
    var fu := fz + jet                # หน้าชั้นบน
    var y1 := P + wh                  # พื้นชั้นบน
    var y2 := y1 + band               # เริ่มผนังชั้นบน
    var top := y2 + uh                # ขอบหลังคา
    # ฐาน + ชั้นล่างหิน + มุมหินสลับ
    kit.box(stone, Vector3(gw + 0.5, P, gd + 0.5), Vector3(0, P * 0.5, zc))
    kit.box(stone_lt, Vector3(gw + 0.62, 0.12, gd + 0.62), Vector3(0, P, zc))
    kit.box(stone, Vector3(gw, wh, gd), Vector3(0, P + wh * 0.5, zc))
    for cx in [-1.0, 1.0]:
        for i in 4:
            var qy := P + 0.35 + i * 0.68
            var long := i % 2 == 0
            kit.box(stone_lt, Vector3(0.62 if long else 0.36, 0.5, 0.36 if long else 0.62), Vector3(cx * (gw * 0.5 - (0.24 if long else 0.12)), qy, fz - (0.12 if long else 0.24)))
    # คานคั่นชั้น + ค้ำยันใต้ส่วนยื่น
    kit.box(beam, Vector3(uw + 0.12, band, ud + 0.12), Vector3(0, y1 + band * 0.5, uzc))
    var nb := int(gw / 1.4)
    for i in nb + 1:
        var bx := -gw * 0.5 + 0.2 + i * (gw - 0.4) / nb
        kit.box(beam, Vector3(0.2, 0.42, jet + 0.08), Vector3(bx, y1 - 0.2, fz + jet * 0.5 - 0.02))
        kit.box(beam, Vector3(0.18, 0.18, 0.6), Vector3(bx, y1 - 0.42, fz + 0.18), Vector3(-0.75, 0, 0))
    # ชั้นบนปูน + โครงไม้
    kit.box(wall, Vector3(uw, uh, ud), Vector3(0, y2 + uh * 0.5, uzc))
    var posts := [-uw * 0.5 + 0.12, uw * 0.5 - 0.12]
    var nbay := 4 if uw > 11.0 else 3
    for i in range(1, nbay):
        posts.append(-uw * 0.5 + i * uw / nbay)
    for px in posts:
        kit.box(beam, Vector3(0.2, uh, 0.12), Vector3(px, y2 + uh * 0.5, fu + 0.05))
    kit.box(beam, Vector3(uw, 0.18, 0.12), Vector3(0, top - 0.09, fu + 0.05))
    kit.box(beam, Vector3(uw, 0.14, 0.12), Vector3(0, y2 + 0.07, fu + 0.05))
    for sx in [-1.0, 1.0]:   # ค้ำเฉียงช่องริม
        var bx0: float = sx * (uw * 0.5 - uw / nbay * 0.5)
        var ang: float = atan2(uh - 0.3, uw / nbay - 0.3)
        kit.box(beam, Vector3(sqrt(pow(uw / nbay - 0.3, 2) + pow(uh - 0.3, 2)), 0.14, 0.1), Vector3(bx0, y2 + uh * 0.5, fu + 0.04), Vector3(0, 0, sx * ang))
        for zz in [uzc - ud * 0.5 + 0.12, uzc + ud * 0.5 - 0.12, uzc]:
            kit.box(beam, Vector3(0.12, uh, 0.2), Vector3(sx * (uw * 0.5 + 0.05), y2 + uh * 0.5, zz))
    # หลังคาหลัก: สันตามแกน X ชายคายื่น หนา
    var rh := ud * 0.5 * 0.95
    var ov := 0.6
    var ang_r := atan2(rh, ud * 0.5)
    var slen := (ud * 0.5 + ov) / cos(ang_r)
    var ridge := Vector3(0, top + rh, uzc)
    for s in [-1.0, 1.0]:
        var dir := Vector3(0, -sin(ang_r), s * cos(ang_r))
        var nrm := Vector3(0, cos(ang_r), s * sin(ang_r))
        kit.box(roof, Vector3(uw + ov * 1.6, 0.2, slen), ridge + dir * slen * 0.5 + nrm * 0.1, Vector3(s * ang_r, 0, 0))
        kit.box(beam, Vector3(uw + ov * 1.6, 0.26, 0.12), ridge + dir * slen + nrm * 0.06, Vector3(s * ang_r, 0, 0))
    kit.prism(wall, ud, rh, uw, Vector3(0, top, uzc), PI / 2.0)
    kit.box(beam, Vector3(uw + ov * 1.6 + 0.1, 0.24, 0.3), ridge + Vector3(0, 0.2, 0))
    # จั่วหน้า (cross gable) มีหน้าต่างกลม
    var cw: float = min(uw * 0.42, 4.6)
    var crh := cw * 0.5 * 0.95
    var ang_c := atan2(crh, cw * 0.5)
    var cz0 := uzc
    var cz1 := fu + 0.35
    var clen := cz1 - cz0
    var cmid := (cz0 + cz1) * 0.5
    kit.prism(wall, cw, crh, clen, Vector3(0, top, cmid))
    var cs := (cw * 0.5 + 0.45) / cos(ang_c)
    var cridge := Vector3(0, top + crh, cmid + 0.2)
    for s in [-1.0, 1.0]:
        var cdir := Vector3(s * cos(ang_c), -sin(ang_c), 0)
        var cn := Vector3(s * sin(ang_c), cos(ang_c), 0)
        kit.box(roof, Vector3(cs, 0.2, clen + 0.4), cridge + cdir * cs * 0.5 + cn * 0.1, Vector3(0, 0, -s * ang_c))
        kit.box(beam, Vector3(cs, 0.22, 0.14), cridge + cdir * cs * 0.5 + cn * 0.02 + Vector3(0, 0, clen * 0.5 + 0.18), Vector3(0, 0, -s * ang_c))
    kit.box(beam, Vector3(0.26, 0.26, clen + 0.4), cridge + Vector3(0, 0.2, 0))
    kit.cyl(gold, 0.0, 0.14, 0.8, Vector3(0, top + crh + 0.7, cz1 + 0.05), 6)
    var rw_y := top + crh * 0.42
    kit.cyl(beam, 0.62, 0.62, 0.16, Vector3(0, rw_y, cz1 - 0.3), 16, Vector3(PI / 2.0, 0, 0))
    kit.cyl(glass, 0.48, 0.48, 0.16, Vector3(0, rw_y, cz1 - 0.26), 16, Vector3(PI / 2.0, 0, 0))
    kit.box(beam, Vector3(0.08, 0.96, 0.06), Vector3(0, rw_y, cz1 - 0.16))
    kit.box(beam, Vector3(0.96, 0.08, 0.06), Vector3(0, rw_y, cz1 - 0.16))
    # ปล่องไฟ
    var chx := uw * 0.32
    var chz := uzc - ud * 0.18
    var chy0 := top + rh * 0.4
    kit.box(stone, Vector3(0.9, 2.6, 0.9), Vector3(chx, chy0 + 0.9, chz))
    kit.box(stone_lt, Vector3(1.1, 0.18, 1.1), Vector3(chx, chy0 + 2.25, chz))
    kit.box(iron, Vector3(0.5, 0.2, 0.5), Vector3(chx, chy0 + 2.42, chz))
    # หน้าต่างชั้นบน (บานเกล็ด + กระบะดอกไม้) และชั้นล่าง
    var wins: Array = []
    for i in nbay:
        var cx2 := -uw * 0.5 + (i + 0.5) * uw / nbay
        if abs(cx2) < cw * 0.5 and nbay % 2 == 1:
            continue
        wins.append(cx2)
    for wx in wins:
        _kit_window(kit, glass, beam, shutter, Vector3(wx, y2 + uh * 0.52, fu + 0.06), Vector2(0.95, 1.2), true)
        kit.box(beam, Vector3(1.3, 0.22, 0.32), Vector3(wx, y2 + uh * 0.52 - 0.82, fu + 0.22))
        for f in 4:
            kit.box(M([Color(0.85, 0.3, 0.35), Color(0.95, 0.8, 0.3), Color(0.7, 0.45, 0.85), Color(0.95, 0.55, 0.3)][(f + int(wx)) % 4], 0.8), Vector3(0.2, 0.2, 0.2), Vector3(wx - 0.45 + f * 0.3, y2 + uh * 0.52 - 0.62, fu + 0.24), Vector3(0, f * 0.7, 0.4))
    for sx in [-1.0, 1.0]:
        _kit_window(kit, glass, stone_lt, shutter, Vector3(sx * gw * 0.3, P + wh * 0.55, fz + 0.04), Vector2(1.0, 1.25), false)
        kit.box(stone_lt, Vector3(1.5, 0.26, 0.2), Vector3(sx * gw * 0.3, P + wh * 0.55 + 0.82, fz + 0.1))
    # ประตูซุ้มหินโค้ง + บันได + โคมคริสตัลสองข้าง
    var dr := 0.8
    var dh := 1.5
    kit.box(stone_lt, Vector3(dr * 2.0 + 0.6, dh, 0.3), Vector3(0, P + dh * 0.5, fz + 0.1))
    kit.cyl(stone_lt, dr + 0.3, dr + 0.3, 0.3, Vector3(0, P + dh, fz + 0.1), 14, Vector3(-PI / 2.0, 0, 0), PI)
    kit.box(door_m, Vector3(dr * 2.0, dh, 0.12), Vector3(0, P + dh * 0.5, fz + 0.28))
    kit.cyl(door_m, dr, dr, 0.12, Vector3(0, P + dh, fz + 0.28), 14, Vector3(-PI / 2.0, 0, 0), PI)
    for i in 3:
        kit.box(beam, Vector3(0.06, dh + dr * 0.6, 0.04), Vector3(-0.5 + i * 0.5, P + (dh + dr * 0.6) * 0.5, fz + 0.36))
    kit.box(iron, Vector3(1.5, 0.08, 0.05), Vector3(0, P + 0.5, fz + 0.37))
    kit.box(iron, Vector3(1.5, 0.08, 0.05), Vector3(0, P + 1.5, fz + 0.37))
    kit.box(gold, Vector3(0.12, 0.12, 0.08), Vector3(0.55, P + 1.0, fz + 0.38))
    kit.box(stone, Vector3(2.6, 0.24, 0.6), Vector3(0, 0.12, fz + 0.75))
    kit.box(stone, Vector3(2.2, 0.24, 0.4), Vector3(0, 0.36, fz + 0.5))
    for sx in [-1.0, 1.0]:
        var lx: float = sx * (dr + 0.75)
        kit.box(iron, Vector3(0.08, 0.08, 0.4), Vector3(lx, P + 2.1, fz + 0.32))
        kit.box(iron, Vector3(0.3, 0.06, 0.3), Vector3(lx, P + 2.0, fz + 0.5))
        kit.box(crystal, Vector3(0.2, 0.42, 0.2), Vector3(lx, P + 2.28, fz + 0.5), Vector3(0, PI / 4.0, 0))
        kit.cyl(iron, 0.0, 0.18, 0.2, Vector3(lx, P + 2.6, fz + 0.5), 4)
    if st.kind == "gothic":
        for sx in [-1.0, 1.0]:
            var tx: float = sx * (uw * 0.5 - 0.3)
            var tz := fu - 0.6
            var th := top + 1.8
            kit.box(wall, Vector3(1.7, th, 1.7), Vector3(tx, th * 0.5, tz))
            kit.box(stone_lt, Vector3(1.9, 0.3, 1.9), Vector3(tx, th, tz))
            kit.box(stone, Vector3(1.8, P, 1.8), Vector3(tx, P * 0.5, tz))
            kit.box(glass, Vector3(0.36, 1.1, 0.06), Vector3(tx, th - 1.4, tz + 0.86))
            kit.cyl(roof, 0.0, 1.2, 3.8, Vector3(tx, th + 0.15 + 1.9, tz), 8)
            kit.cyl(gold, 0.0, 0.09, 0.7, Vector3(tx, th + 4.3, tz), 6)
        kit.cyl(roof, 0.0, 0.7, 3.0, Vector3(0, top + rh + 1.4, uzc), 8)
    kit.commit(root)
    var reach: float = top + rh + (4.5 if st.kind == "gothic" else 1.5)
    fade_blds.append({"root": root, "meshes": [], "f": 0.0, "aabb": AABB(root.position + Vector3(-uw * 0.5 - ov, 0, uzc - ud * 0.5 - ov), Vector3(uw + ov * 2.0, reach, ud + ov * 2.0 + 0.6))})
    # ของประจำร้าน
    match st.kind:
        "forge":
            var fire := box(root, Vector3(1.2, 0.8, 0.8), Vector3(-w * 0.33, 0.6 + 0.4, fz + 1.0), M(Color(1.0, 0.45, 0.1), 0.5, 3.0))
            fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            var fl := OmniLight3D.new()
            fl.light_color = Color(1.0, 0.5, 0.2)
            fl.omni_range = 6.0
            fl.light_energy = 1.4
            fl.position = Vector3(-w * 0.33, 1.6, fz + 1.2)
            root.add_child(fl)
            box(root, Vector3(0.7, 0.5, 0.4), Vector3(w * 0.3, 0.85, fz + 1.1), M(Color(0.2, 0.2, 0.22), 0.4))
            box(root, Vector3(0.4, 0.5, 0.3), Vector3(w * 0.3, 0.45, fz + 1.1), M(Color(0.3, 0.2, 0.12)))
        "gothic":
            if sid == "seal113":
                var orb := MeshInstance3D.new()
                var sm := SphereMesh.new()
                sm.radius = 0.6
                sm.height = 1.2
                orb.mesh = sm
                orb.material_override = M(Color(0.75, 0.4, 1.0), 0.2, 2.5)
                orb.position = Vector3(0, 0.6 + wh + rh + 3.4, -0.1)
                root.add_child(orb)
                var ol := OmniLight3D.new()
                ol.light_color = Color(0.7, 0.4, 1.0)
                ol.omni_range = 8.0
                ol.light_energy = 1.3
                ol.position = orb.position
                root.add_child(ol)
            else:
                var em := cyl(root, 0.6, 0.6, 0.1, Vector3(0, 0.6 + wh * 0.85, fz + 0.12), gold, 20)
                em.rotation.x = PI / 2.0
        "inn":
            for k in 3:
                cyl(root, 0.32, 0.3, 0.8, Vector3(w * 0.38 - k * 0.7, 0.4, fz + 1.2), M(Color(0.5, 0.32, 0.16)), 10)
            cyl(root, 0.55, 0.55, 0.08, Vector3(-w * 0.32, 0.8, fz + 1.4), M(Color(0.5, 0.32, 0.16)), 12)
        "potion":
            for k in 4:
                var bt := cyl(root, 0.12, 0.18, 0.45, Vector3(-w * 0.35 + k * 0.4, 0.85, fz + 0.8), M([Color(0.3, 0.8, 0.4), Color(0.7, 0.3, 0.9), Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.95)][k], 0.15, 0.8), 8)
                bt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            box(root, Vector3(w - 1.0, 0.4, 0.6), Vector3(0, 0.4, fz + 1.4), M(Color(0.35, 0.25, 0.15)))
            for k in 10:
                var fl2 := MeshInstance3D.new()
                var fsm := SphereMesh.new()
                fsm.radius = 0.14
                fsm.height = 0.22
                fl2.mesh = fsm
                fl2.material_override = M(Color(0.65, 0.4, 0.9), 0.7)
                fl2.position = Vector3(-w * 0.4 + k * (w * 0.8 / 9.0), 0.7, fz + 1.45)
                root.add_child(fl2)
        "guild":
            var sh := box(root, Vector3(1.1, 1.3, 0.12), Vector3(0, 0.6 + wh * 0.85, fz + 0.12), M(Color(0.65, 0.18, 0.15), 0.6))
            var sw := box(root, Vector3(0.12, 1.6, 0.06), Vector3(0, 0.6 + wh * 0.85, fz + 0.2), M(Color(0.85, 0.86, 0.9), 0.3))
            sw.rotation.z = 0.6
        "bank":
            for sx in [-1, 1]:
                cyl(root, 0.25, 0.28, wh, Vector3(sx * 1.2, 0.6 + wh * 0.5, fz + 0.6), M(Color(0.86, 0.84, 0.78), 0.5), 12)
            var coin := cyl(root, 0.55, 0.55, 0.12, Vector3(0, 0.6 + wh + 0.4, fz + 0.3), gold, 20)
            coin.rotation.x = PI / 2.0
        "shop":
            for k in 6:
                var cc: Color = st.roof if k % 2 == 0 else Color(0.95, 0.92, 0.86)
                box(root, Vector3(w * 0.8 / 6.0, 0.06, 1.3), Vector3(-w * 0.4 + (k + 0.5) * w * 0.8 / 6.0, 0.6 + wh * 0.5, fz + 0.6), M(cc, 0.8), Vector3(0.35, 0, 0))
    # ป้ายแขวน
    if sid != "ware":
        box(root, Vector3(0.12, 0.12, 1.0), Vector3(-w * 0.5 + 0.5, 0.6 + wh * 0.82, fz + 0.5), beam)
        box(root, Vector3(1.2, 0.75, 0.08), Vector3(-w * 0.5 + 0.5, 0.6 + wh * 0.82 - 0.45, fz + 0.95), M(st.roof.lightened(0.2), 0.7))
    label3d(title, root.position + Vector3(0, top + rh + (4.4 if st.kind == "gothic" else 1.4), 0), 42)

func _build_shops() -> void:
    for sid in STYLE.keys():
        var sh: Dictionary = shops_by_id.get(sid, {})
        if sh.is_empty() or sh.b == null:
            continue
        _building(sh.b, STYLE[sid], sh.name, sid)
    # บ้านมุมซ้ายบน (3,3) และที่ดินแปลงหญ้าขวาบน (ตามภาพเมืองเดิม)
    _building([3, 3, 5, 4], {"roof": Color(0.72, 0.28, 0.16), "wall": Color(0.78, 0.7, 0.56), "kind": "house"}, "บ้านชาวเมือง", "ware")
    var plot := tw(38.5, 4.5)
    box(self, Vector3(10.6, 0.5, 8.2), plot + Vector3(0, 0.25, 0), M(Color(0.33, 0.55, 0.22), 0.95))
    box(self, Vector3(10.8, 1.2, 0.8), plot + Vector3(0, 0.6, 3.9), M(Color(0.5, 0.5, 0.5), 0.95))
    for i in 12:
        cyl(self, 0.07, 0.08, 1.0, plot + Vector3(-5.2 + i * 0.95, 0.9, -3.9), M(Color(0.45, 0.3, 0.16)), 5)

# ---------- วิหารแห่งแสง (จุดเกิด) ----------
func _build_temple() -> void:
    # ตามภาพเมืองเดิม: ลานหินอ่อน วงเวทสีฟ้ากลางลาน ศาลเล็กหลังคาฟ้าด้านบน คริสตัลสี่มุม
    var marble := M(Color(0.7, 0.68, 0.64), 0.45)
    var blue := M(Color(0.22, 0.4, 0.75), 0.5)
    var glow := M(Color(0.35, 0.7, 1.0), 0.2, 2.2)
    box(self, Vector3(18, 0.12, 18), tw(7.5, 22.5) + Vector3(0, 0.06, 0), marble)
    for p in [[3, 19], [11, 19], [3, 24], [11, 24]]:
        var q := tw(p[0] + 0.5, p[1] + 0.5)
        box(self, Vector3(1.2, 1.4, 1.2), q + Vector3(0, 0.7, 0), marble)
        var cr := cyl(self, 0.0, 0.38, 1.2, q + Vector3(0, 2.0, 0), glow, 6)
        cr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var cr2 := cyl(self, 0.38, 0.0, 0.5, q + Vector3(0, 1.15, 0), glow, 6)
        cr2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    # วงเวทกลางลาน (จุดเกิด)
    var mc := tw(7.5, 22.0)
    for rr in [2.6, 3.0]:
        var ring := MeshInstance3D.new()
        var tm := TorusMesh.new()
        tm.inner_radius = rr
        tm.outer_radius = rr + 0.18
        ring.mesh = tm
        ring.material_override = glow
        ring.position = mc + Vector3(0, 0.14, 0)
        ring.scale = Vector3(1, 0.04, 1)
        add_child(ring)
    var disc := cyl(self, 2.6, 2.6, 0.03, mc + Vector3(0, 0.13, 0), M(Color(0.12, 0.2, 0.42), 0.4), 40)
    disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for k in 5:
        var a1 := -PI / 2.0 + k * TAU / 5.0
        var a2 := -PI / 2.0 + (k + 2) * TAU / 5.0
        var p1 := Vector3(cos(a1), 0, sin(a1)) * 2.5
        var p2 := Vector3(cos(a2), 0, sin(a2)) * 2.5
        var ln := box(self, Vector3(p1.distance_to(p2), 0.03, 0.12), mc + (p1 + p2) * 0.5 + Vector3(0, 0.16, 0), glow, Vector3(0, -atan2(p2.z - p1.z, p2.x - p1.x), 0))
        ln.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var ol := OmniLight3D.new()
    ol.light_color = Color(0.5, 0.75, 1.0)
    ol.omni_range = 9.0
    ol.light_energy = 1.0
    ol.position = mc + Vector3(0, 1.5, 0)
    add_child(ol)
    # ศาลเล็กด้านบน
    var sh := tw(7.5, 18.9)
    box(self, Vector3(5.4, 0.4, 2.6), sh + Vector3(0, 0.2, 0), marble)
    for sx in [-1, 1]:
        cyl(self, 0.22, 0.25, 2.6, sh + Vector3(sx * 2.2, 1.7, 0.7), marble, 10)
    box(self, Vector3(4.8, 2.6, 0.5), sh + Vector3(0, 1.7, -0.7), marble)
    gable(self, 6.0, 3.0, 1.4, sh + Vector3(0, 3.0, 0), blue)
    var stg := cyl(self, 0.35, 0.35, 0.9, sh + Vector3(0, 0.85, -0.2), glow, 8)
    # รูปปั้น/ป้ายด้านล่าง
    var st := tw(7, 26)
    box(self, Vector3(3.0, 0.8, 2.6), st + Vector3(0, 0.4, 0), marble)
    cyl(self, 0.3, 0.7, 2.2, st + Vector3(0, 1.9, 0), marble, 14)
    var hd := MeshInstance3D.new()
    var hs := SphereMesh.new()
    hs.radius = 0.32
    hs.height = 0.64
    hd.mesh = hs
    hd.material_override = marble
    hd.position = st + Vector3(0, 3.3, 0)
    add_child(hd)
    for s2 in [-1, 1]:
        box(self, Vector3(1.6, 1.8, 0.14), st + Vector3(s2 * 0.9, 2.7, -0.25), marble, Vector3(0, s2 * 0.35, s2 * -0.45))
    label3d("วิหารแห่งแสง", sh + Vector3(0, 6.0, 0), 50, Color(1.0, 0.95, 0.7))

# ---------- จัตุรัสกลาง: น้ำพุ แผงตลาด ----------
func _water_mat() -> ShaderMaterial:
    var m := ShaderMaterial.new()
    m.shader = load("res://shaders/water.gdshader")
    m.set_shader_parameter("noise_tex", noise_tex)
    m.set_shader_parameter("deep", Color(0.08, 0.32, 0.45))
    m.set_shader_parameter("shallow", Color(0.35, 0.7, 0.75))
    m.set_shader_parameter("alpha", 0.85)
    m.set_shader_parameter("wave", 0.02)
    return m

func _build_plaza() -> void:
    var c := tw(22, 13)
    var stone := M(Color(0.72, 0.7, 0.66), 0.6)
    cyl(self, 3.3, 3.5, 0.9, c + Vector3(0, 0.45, 0), stone, 32)
    var w := MeshInstance3D.new()
    var wm := CylinderMesh.new()
    wm.top_radius = 2.95
    wm.bottom_radius = 2.95
    wm.height = 0.05
    wm.radial_segments = 32
    w.mesh = wm
    w.material_override = _water_mat()
    w.position = c + Vector3(0, 0.8, 0)
    add_child(w)
    cyl(self, 0.35, 0.45, 2.4, c + Vector3(0, 1.6, 0), stone, 12)
    cyl(self, 1.3, 1.1, 0.35, c + Vector3(0, 2.7, 0), stone, 24)
    cyl(self, 0.18, 0.25, 1.4, c + Vector3(0, 3.5, 0), stone, 12)
    cyl(self, 0.65, 0.5, 0.25, c + Vector3(0, 4.2, 0), stone, 20)
    if not is_mobile:
        _build_fountain_particles(c)
    _build_plaza_details()

func _build_fountain_particles(c: Vector3) -> void:
    var ps := GPUParticles3D.new()
    ps.amount = 140
    ps.lifetime = 1.4
    ps.position = c + Vector3(0, 4.4, 0)
    var pm := ParticleProcessMaterial.new()
    pm.direction = Vector3(0, 1, 0)
    pm.spread = 28.0
    pm.initial_velocity_min = 2.6
    pm.initial_velocity_max = 3.4
    pm.gravity = Vector3(0, -9.0, 0)
    pm.scale_min = 0.5
    pm.scale_max = 1.0
    ps.process_material = pm
    var q := QuadMesh.new()
    q.size = Vector2(0.12, 0.12)
    var qm := StandardMaterial3D.new()
    qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    qm.albedo_color = Color(0.8, 0.92, 1.0, 0.75)
    q.material = qm
    ps.draw_pass_1 = q
    ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ps)

func _build_plaza_details() -> void:
    # ลายเข็มทิศกลางจัตุรัส
    var cr := tw(22, 17)
    for rr in [3.2, 3.6]:
        var ring := MeshInstance3D.new()
        var tmr := TorusMesh.new()
        tmr.inner_radius = rr
        tmr.outer_radius = rr + 0.16
        ring.mesh = tmr
        ring.material_override = M(Color(0.86, 0.82, 0.72), 0.6)
        ring.position = cr + Vector3(0, 0.01, 0)
        ring.scale = Vector3(1, 0.05, 1)
        add_child(ring)
    for k in 8:
        var arm := box(self, Vector3(0.22, 0.02, 2.6 if k % 2 == 0 else 1.6), cr + Vector3(0, 0.02, 0), M(Color(0.86, 0.82, 0.72), 0.6), Vector3(0, k * PI / 4.0, 0))
        arm.position += Vector3(sin(k * PI / 4.0), 0, cos(k * PI / 4.0)) * (1.3 if k % 2 == 0 else 0.8)
    # แผงตลาด ผ้าใบลายทาง
    var cols := [Color(0.75, 0.2, 0.18), Color(0.2, 0.42, 0.7), Color(0.85, 0.65, 0.2), Color(0.3, 0.55, 0.3)]
    var stl: Array = TD.stalls
    for i in stl.size():
        var s := [int(stl[i].x), int(stl[i].y)]
        var p := tw(s[0] + 1.0, s[1] + 0.5)
        var wood := M(Color(0.45, 0.3, 0.16))
        for sx in [-1, 1]:
            for sz in [-1, 1]:
                cyl(self, 0.07, 0.07, 2.6, p + Vector3(sx * 1.8, 1.3, sz * 0.8), wood, 6)
        box(self, Vector3(3.8, 0.9, 1.7), p + Vector3(0, 0.45, 0), wood)
        for k in 6:
            var cc: Color = cols[i % cols.size()] if k % 2 == 0 else Color(0.95, 0.93, 0.86)
            box(self, Vector3(0.68, 0.06, 2.1), p + Vector3(-1.7 + k * 0.68, 2.7 - 0.0, 0.1), M(cc, 0.8), Vector3(0.25, 0, 0))
        for k in 5:
            var goods: Color = [Color(0.9, 0.3, 0.2), Color(0.95, 0.75, 0.2), Color(0.4, 0.7, 0.3), Color(0.7, 0.45, 0.25), Color(0.85, 0.85, 0.9)][k]
            var g := MeshInstance3D.new()
            var gs := SphereMesh.new()
            gs.radius = 0.22
            gs.height = 0.44
            g.mesh = gs
            g.material_override = M(goods, 0.6)
            g.position = p + Vector3(-1.4 + k * 0.7, 1.05, 0.2)
            add_child(g)

# ---------- ลานฝึก ----------
func _build_training() -> void:
    var wood := M(Color(0.45, 0.3, 0.16))
    var straw := M(Color(0.8, 0.66, 0.38), 1.0)
    for x in range(30, 41):
        for yy in [19.05, 23.95]:
            cyl(self, 0.09, 0.1, 1.2, tw(x + 0.5, yy) + Vector3(0, 0.6, 0), wood, 6)
    for yy in [19.05, 23.95]:
        box(self, Vector3(22, 0.12, 0.1), tw(35.5, yy) + Vector3(0, 0.95, 0), wood)
        box(self, Vector3(22, 0.12, 0.1), tw(35.5, yy) + Vector3(0, 0.55, 0), wood)
    for x in [32, 35, 38]:
        var p := tw(x + 0.5, 21.5)
        cyl(self, 0.09, 0.09, 2.4, p + Vector3(0, 1.2, 0), wood, 6)
        box(self, Vector3(1.6, 0.14, 0.14), p + Vector3(0, 1.75, 0), wood)
        cyl(self, 0.32, 0.3, 1.0, p + Vector3(0, 1.45, 0), straw, 10)
        var hd := MeshInstance3D.new()
        var hs := SphereMesh.new()
        hs.radius = 0.25
        hs.height = 0.5
        hd.mesh = hs
        hd.material_override = straw
        hd.position = p + Vector3(0, 2.2, 0)
        add_child(hd)
        var tgt := cyl(self, 0.18, 0.18, 0.05, p + Vector3(0, 1.5, 0.32), M(Color(0.8, 0.15, 0.12)), 16)
        tgt.rotation.x = PI / 2.0
    for p in [[31, 23], [40, 20]]:
        cyl(self, 0.45, 0.4, 1.0, tw(p[0] + 0.5, p[1] + 0.5) + Vector3(0, 0.5, 0), M(Color(0.5, 0.32, 0.16)), 12)
    label3d("ลานฝึก", tw(35.5, 19) + Vector3(0, 3.2, 0), 40)

# ---------- ของตกแต่ง: บ่อน้ำ ม้านั่ง ต้นไม้ ดอกไม้ โคมไฟ ----------
func _build_props() -> void:
    var wood := M(Color(0.45, 0.3, 0.16))
    var stone := M(Color(0.6, 0.58, 0.54), 0.95)
    var wp := tw(22, 31.5)
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.9
    tm.outer_radius = 1.35
    ring.mesh = tm
    ring.material_override = stone
    ring.position = wp + Vector3(0, 0.45, 0)
    ring.scale = Vector3(1, 1.8, 1)
    add_child(ring)
    for s in [-1, 1]:
        cyl(self, 0.09, 0.09, 2.6, wp + Vector3(s * 1.25, 1.3, 0), wood, 6)
    gable(self, 3.2, 2.2, 1.0, wp + Vector3(0, 2.55, 0), M(Color(0.55, 0.25, 0.16), 0.7))
    for x in [17, 26]:
        var bp := tw(x + 0.5, 30.5)
        box(self, Vector3(1.8, 0.12, 0.55), bp + Vector3(0, 0.5, 0), wood)
        box(self, Vector3(1.8, 0.5, 0.1), bp + Vector3(0, 0.8, -0.25), wood)
        for s in [-1, 1]:
            box(self, Vector3(0.12, 0.5, 0.5), bp + Vector3(s * 0.75, 0.25, 0), M(Color(0.2, 0.2, 0.22), 0.5))
    var trunk := M(Color(0.36, 0.24, 0.14), 0.95)
    for t in TREES:
        if grid[t[1]][t[0]] == 0:
            continue
        var p := tw(t[0] + 0.5, t[1] + 0.5)
        cyl(self, 0.22, 0.32, 3.0, p + Vector3(0, 1.5, 0), trunk, 8)
        var g := Color(0.24, 0.46, 0.16).lerp(Color(0.38, 0.56, 0.2), randf())
        for k in 4:
            var b := MeshInstance3D.new()
            var sm := SphereMesh.new()
            sm.radius = 1.0
            sm.height = 1.8
            sm.radial_segments = 12
            sm.rings = 7
            b.mesh = sm
            var r := randf_range(1.2, 1.7)
            b.scale = Vector3(r, r * 0.9, r)
            b.position = p + Vector3(randf_range(-0.8, 0.8), 3.6 + randf_range(0, 1.2), randf_range(-0.8, 0.8))
            add_child(b)
            var std := M(g.lightened(randf_range(-0.04, 0.08)), 0.8)
            b.material_override = std
    for f in FLOWERS:
        var p0 := tw(f[0], f[1])
        var size := Vector2(f[2] * TS, f[3] * TS)
        box(self, Vector3(size.x, 0.35, size.y), p0 + Vector3(size.x * 0.5, 0.17, size.y * 0.5), M(Color(0.42, 0.3, 0.2)))
        var cols := [Color(1, 0.42, 0.55), Color(1, 0.82, 0.25), Color(0.75, 0.55, 1.0), Color(1, 1, 1), Color(1, 0.6, 0.25)]
        for i in int(size.x * size.y * 4):
            var fl := MeshInstance3D.new()
            var sm2 := SphereMesh.new()
            sm2.radius = 0.12
            sm2.height = 0.2
            sm2.radial_segments = 6
            sm2.rings = 3
            fl.mesh = sm2
            fl.material_override = M(cols[i % 5], 0.7)
            fl.position = p0 + Vector3(randf_range(0.2, size.x - 0.2), 0.5, randf_range(0.2, size.y - 0.2))
            add_child(fl)
    for l in TD.lamps:
        lantern(tw(float(l[0]) + 0.5, float(l[1]) + 0.5))
    label3d("ตลาดกลาง", tw(22, 32.4) + Vector3(0, 2.6, 0), 40)

# ---------- นอกกำแพง: ทุ่งหญ้า ป่า ภูเขา ----------
func _xf(pos: Vector3, scl: Vector3, ry: float, tilt: float = 0.0) -> Transform3D:
    var b := Basis().rotated(Vector3.UP, ry)
    if tilt != 0.0:
        b = b.rotated(Vector3(1, 0, 0), tilt)
    b = b.scaled(scl)
    return Transform3D(b, pos)

func _mm(mesh: Mesh, xforms: Array, cols: Array, mat: Material, shadows: bool = true) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true
    mm.mesh = mesh
    mm.instance_count = xforms.size()
    for i in xforms.size():
        mm.set_instance_transform(i, xforms[i])
        mm.set_instance_color(i, cols[i])
    var mi := MultiMeshInstance3D.new()
    mi.multimesh = mm
    mi.material_override = mat
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)

func _foliage(sway: float) -> ShaderMaterial:
    var fm := ShaderMaterial.new()
    fm.shader = load("res://shaders/foliage.gdshader")
    fm.set_shader_parameter("noise_tex", noise_tex)
    fm.set_shader_parameter("sway", sway)
    return fm

func _outside(x: float, z: float, pad: float) -> bool:
    return abs(x) > 46.0 + pad or abs(z) > 36.0 + pad

func _build_outside() -> void:
    var tx := []
    var tc := []
    var px := []
    var pc := []
    var bx := []
    var bc := []
    var tries := 0
    var placed := 0
    while placed < (1100 if not is_mobile else 450) and tries < 40000:
        tries += 1
        var x := randf_range(-HALF + 4, HALF - 4)
        var z := randf_range(-HALF + 4, HALF - 4)
        if not _outside(x, z, 8.0) or in_field_rect(x, z, 6.0):
            continue
        if abs(z - 1.0) < 6.0 and abs(x) < 125.0:
            continue
        var dens := noise.get_noise_2d(x * 2.0 + 200, z * 2.0) * 0.5 + 0.5
        if randf() > dens * 1.25 + 0.1:
            continue
        var y := h(x, z)
        var s := randf_range(0.9, 1.5)
        tx.append(_xf(Vector3(x, y + 1.6 * s, z), Vector3(0.35 * s, 3.2 * s, 0.35 * s), randf() * TAU))
        tc.append(Color(0.36, 0.24, 0.14))
        if randf() < 0.5:
            var g := Color(0.13, 0.32, 0.17).lerp(Color(0.2, 0.42, 0.2), randf())
            for k in 4:
                var r := (2.6 - k * 0.55) * s
                px.append(_xf(Vector3(x, y + (2.4 + k * 1.55) * s, z), Vector3(r, 2.6 * s, r), randf() * TAU))
                pc.append(g.lightened(k * 0.03))
        else:
            var g2 := Color(0.25, 0.45, 0.14).lerp(Color(0.42, 0.56, 0.18), randf())
            for k in 5:
                var off := Vector3(randf_range(-1.2, 1.2), randf_range(0.0, 1.4), randf_range(-1.2, 1.2)) * s
                var r2 := randf_range(1.5, 2.2) * s
                bx.append(_xf(Vector3(x, y + 4.0 * s, z) + off, Vector3(r2, r2 * 0.85, r2), randf() * TAU))
                bc.append(g2.lightened(randf_range(-0.05, 0.08)))
        placed += 1
    var cm := CylinderMesh.new()
    cm.top_radius = 0.6
    cm.bottom_radius = 1.0
    cm.height = 1.0
    cm.radial_segments = 7
    var cone := CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 1.0
    cone.height = 1.0
    cone.radial_segments = 9
    var blob := SphereMesh.new()
    blob.radius = 1.0
    blob.height = 2.0
    blob.radial_segments = 10
    blob.rings = 6
    var bark := StandardMaterial3D.new()
    bark.vertex_color_use_as_albedo = true
    bark.roughness = 0.95
    _mm_chunks(cm, tx, tc, bark)
    _mm_chunks(cone, px, pc, _foliage(0.15))
    _mm_chunks(blob, bx, bc, _foliage(0.3))
    var rx := []
    var rc := []
    for i in 180:
        var x2 := randf_range(-HALF + 3, HALF - 3)
        var z2 := randf_range(-HALF + 3, HALF - 3)
        if not _outside(x2, z2, 5.0) or in_field_rect(x2, z2, 3.0) or (abs(z2 - 1.0) < 5.0 and abs(x2) < 125.0):
            continue
        var s2 := randf_range(0.5, 2.0)
        rx.append(_xf(Vector3(x2, h(x2, z2) + s2 * 0.15, z2), Vector3(s2 * 1.3, s2 * 0.8, s2), randf() * TAU, randf_range(-0.3, 0.3)))
        rc.append(Color(0.5, 0.49, 0.46).lerp(Color(0.38, 0.4, 0.36), randf()))
    var rm := SphereMesh.new()
    rm.radius = 1.0
    rm.height = 1.6
    rm.radial_segments = 7
    rm.rings = 4
    var rmat := StandardMaterial3D.new()
    rmat.vertex_color_use_as_albedo = true
    rmat.roughness = 0.95
    _mm_chunks(rm, rx, rc, rmat)

func _build_grass() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var pts := [Vector3(-0.05, 0, 0), Vector3(0.05, 0, 0), Vector3(-0.03, 0.45, 0.03), Vector3(0.03, 0.45, 0.03), Vector3(0.0, 0.9, 0.08)]
    for tri in [[0, 1, 2], [1, 3, 2], [2, 3, 4]]:
        for idx in tri:
            st.set_normal(Vector3.UP)
            st.add_vertex(pts[idx])
    var blade := st.commit()
    var gx := []
    var gc := []
    var target := 70000 if not is_mobile else 3000
    var tries := 0
    while gx.size() < target and tries < target * 4:
        tries += 1
        var x := randf_range(-165, 110)
        var z := randf_range(-95, 95)
        var inside := not _outside(x, z, 0.0)
        if inside:
            var tx := int(floor((x - OX) / TS))
            var tz := int(floor((z - OZ) / TS))
            if tx < 1 or tz < 1 or tx >= TW - 1 or tz >= TH - 1:
                continue
            if roadset.has(tz * TW + tx) or grid[tz][tx] != 0:
                continue
            if tx >= 3 and tx < 12 and tz >= 18 and tz < 27:
                continue
            if tx >= 30 and tx < 41 and tz >= 19 and tz < 24:
                continue
            if randf() < 0.55:
                continue
        else:
            if abs(x) < 47.5 and abs(z) < 37.5:
                continue
            if in_field_rect(x, z, 1.0):
                continue
            if is_mobile and (abs(x) > 80.0 or abs(z) > 60.0):
                continue
            if abs(z - 1.0) < 2.6 and x > 0.0 and x < 150.0:
                continue
        var n := noise.get_noise_2d(x * 4.0, z * 4.0)
        var s := randf_range(0.5, 1.0) * (1.0 + n * 0.4)
        gx.append(_xf(Vector3(x, h(x, z) if not inside else 0.0, z), Vector3(s * randf_range(0.8, 1.4), s, s), randf() * TAU))
        gc.append(Color(1, 1, 1).lerp(Color(1.15, 1.05, 0.7), randf() * 0.6))
    var gm := ShaderMaterial.new()
    gm.shader = load("res://shaders/grass.gdshader")
    gm.set_shader_parameter("noise_tex", noise_tex)
    _mm_chunks(blade, gx, gc, gm, false)

func _mm_chunks(mesh: Mesh, xforms: Array, cols: Array, mat: Material, shadows: bool = true) -> void:
    # แบ่งตามพื้นที่ เพื่อคัดส่วนพ้นจอออกได้ ไม่วาดหญ้าหรือป่าทั้งแผนที่
    var chunks := {}
    for i in xforms.size():
        var xf: Transform3D = xforms[i]
        var key := Vector2i(floori(xf.origin.x / 32.0), floori(xf.origin.z / 32.0))
        if not chunks.has(key):
            chunks[key] = {"x": [], "c": []}
        chunks[key].x.append(xf)
        chunks[key].c.append(cols[i])
    for chunk in chunks.values():
        _mm(mesh, chunk.x, chunk.c, mat, shadows)

# ---------- ชาวเมือง ----------
func _build_npcs() -> void:
    var ns := load("res://scripts/npc.gd")
    var nl: Dictionary = TD.npcLines if TD.npcLines is Dictionary else {}
    for d in TD.npcs:
        var v := Node3D.new()
        v.set_script(ns)
        add_child(v)
        var lines: Array = nl.get(d.name, d.lines if d.lines else [])
        v.setup(self, d, lines)
        npcs.append(v)

# ---------- ผู้เล่น ----------
func _build_player() -> void:
    player = Node3D.new()
    player.set_script(load("res://scripts/player.gd"))
    add_child(player)
    player.setup(self, tw(SPAWN.x, SPAWN.y))
    var all_args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
    var testing := all_args.has("--script")
    for a in all_args:
        if str(a).begins_with("--shot="):
            testing = true
    if testing:
        player.save_enabled = false
    elif player.load_game():
        loading_stage.emit("โหลดเซฟแล้ว", 0.95)
    apply_xray(player)
    cam = Camera3D.new()
    cam.fov = 45.0
    cam.far = 800.0
    add_child(cam)
    click_marker = MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.35
    tm.outer_radius = 0.5
    click_marker.mesh = tm
    click_marker.material_override = M(Color(0.76, 0.67, 0.46), 0.5, 0.25)
    click_marker.visible = false
    add_child(click_marker)
    _update_cam(1.0)

## เงาตัวละครทะลุตึก: เห็นเป็นเงาสีฟ้าจาง ๆ เมื่อมีอาคารบัง
## ใช้ stencil XRAY ของวัสดุ (Godot 4.5+) — วาดเฉพาะส่วนที่ถูกของอื่นบัง ไม่ทับแขนขาของตัวเอง
## (แบบ material_overlay + depth inverted เดิมทำให้แขนที่บังลำตัวตัวเองกลายเป็นสีฟ้า)
const XRAY_COL := Color(0.45, 0.82, 1.0, 0.45)
func apply_xray(n: Node) -> void:
    for m in n.find_children("*", "MeshInstance3D", true, false):
        var mi := m as MeshInstance3D
        if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or mi.mesh == null:
            continue
        for si in mi.mesh.get_surface_count():
            var mat: Material = mi.get_surface_override_material(si)
            if mat == null:
                mat = mi.mesh.surface_get_material(si)
                if mat is StandardMaterial3D:
                    mat = mat.duplicate()
                    mi.set_surface_override_material(si, mat)
            if mat is StandardMaterial3D and (mat as StandardMaterial3D).stencil_mode != BaseMaterial3D.STENCIL_MODE_XRAY:
                (mat as StandardMaterial3D).stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
                (mat as StandardMaterial3D).stencil_color = XRAY_COL

## ตึกที่อยู่ระหว่างกล้องกับตัวละครจะจางลง (แบบ ROM)
## มือถือใช้ Compatibility ซึ่งไม่รองรับ GeometryInstance3D.transparency → สลับเป็นวัสดุโปร่ง (cache ต่อวัสดุ)
var _fade_mats := {}
func _faded(m: Material) -> Material:
    if not (m is StandardMaterial3D):
        return m
    if not _fade_mats.has(m):
        var c: StandardMaterial3D = m.duplicate()
        c.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        c.albedo_color.a = 0.28
        c.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
        c.cull_mode = BaseMaterial3D.CULL_BACK
        _fade_mats[m] = c
    return _fade_mats[m]

func _update_fade(_delta: float) -> void:
    if room != "" or cam == null:
        return
    var a := cam.global_position
    var b := player.global_position + Vector3(0, 1.0, 0)
    for fb in fade_blds:
        var hit: bool = (fb.aabb as AABB).intersects_segment(a, b) != null
        var want := 1.0 if hit else 0.0
        if fb.f == want:
            continue
        fb.f = want
        if (fb.meshes as Array).is_empty():
            fb.meshes = (fb.root as Node).find_children("*", "MeshInstance3D", true, false)
        for m in fb.meshes:
            var mi := m as MeshInstance3D
            if hit:
                if not mi.has_meta("solid_mat"):
                    mi.set_meta("solid_mat", mi.material_override)
                mi.material_override = _faded(mi.material_override)
                mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            elif mi.has_meta("solid_mat"):
                mi.material_override = mi.get_meta("solid_mat")
                mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _update_cam(delta: float) -> void:
    var vsz := get_viewport().get_visible_rect().size
    if vsz.x < vsz.y:
        cam.keep_aspect = Camera3D.KEEP_WIDTH
        cam.fov = 62.0
    else:
        cam.keep_aspect = Camera3D.KEEP_HEIGHT
        cam.fov = 45.0
    var target := player.global_position + Vector3(0, 1.4, 0)
    if delta < 1.0:
        if not cam_dragging and abs(cam_spin) > 0.01:
            cam_yaw += cam_spin * delta
            cam_spin *= exp(-5.0 * delta)
        cam_yaw_vis = lerp_angle(cam_yaw_vis, cam_yaw, min(1.0, delta * 14.0))
    else:
        cam_yaw_vis = cam_yaw
    var pitch := cam_pitch
    if room == "":
        # ใกล้ = มองเฉียงเห็นตึกสูง · ไกล = มองจากบนเห็นแผนที่กว้าง
        pitch = lerp(-0.62, -1.02, clamp((cam_dist - CAM_NEAR) / (CAM_FAR - CAM_NEAR), 0.0, 1.0))
    var off := Vector3(0, 0, cam_dist).rotated(Vector3(1, 0, 0), pitch).rotated(Vector3.UP, cam_yaw_vis)
    var want := target + off
    if room != "":
        want = rooms.clamp_cam(want)
    cam.global_position = cam.global_position.lerp(want, min(1.0, delta * 8.0)) if delta < 1.0 else want
    cam.look_at(target)
    _update_fade(min(delta, 0.1))

func _setup_hud() -> void:
    var cl := CanvasLayer.new()
    add_child(cl)
    hud = Label.new()
    hud.position = Vector2(16, 12)
    hud.add_theme_font_override("font", font_b)
    hud.add_theme_font_size_override("font_size", 13)
    hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    hud.add_theme_constant_override("outline_size", 2)
    cl.add_child(hud)
    prompt = Label.new()
    prompt.add_theme_font_override("font", font_b)
    prompt.add_theme_font_size_override("font_size", 24)
    prompt.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
    prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    prompt.add_theme_constant_override("outline_size", 8)
    prompt.anchor_left = 0.5
    prompt.anchor_right = 0.5
    prompt.anchor_top = 1.0
    prompt.anchor_bottom = 1.0
    prompt.offset_left = -400
    prompt.offset_right = 400
    prompt.offset_top = -90
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cl.add_child(prompt)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.1, 0.08, 0.06, 0.88)
    sb.border_color = Color(0.85, 0.7, 0.4)
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(10)
    sb.set_content_margin_all(16)
    ui_dialog = PanelContainer.new()
    ui_dialog.add_theme_stylebox_override("panel", sb)
    ui_dialog.anchor_left = 0.5
    ui_dialog.anchor_right = 0.5
    ui_dialog.anchor_top = 1.0
    ui_dialog.anchor_bottom = 1.0
    ui_dialog.offset_left = -430
    ui_dialog.offset_right = 430
    ui_dialog.offset_top = -190
    ui_dialog.offset_bottom = -24
    var vb := VBoxContainer.new()
    ui_dialog.add_child(vb)
    ui_dname = Label.new()
    ui_dname.add_theme_font_override("font", font_b)
    ui_dname.add_theme_font_size_override("font_size", 24)
    ui_dname.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
    vb.add_child(ui_dname)
    ui_dtext = Label.new()
    ui_dtext.add_theme_font_override("font", font)
    ui_dtext.add_theme_font_size_override("font_size", 22)
    ui_dtext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vb.add_child(ui_dtext)
    var hint := Label.new()
    hint.text = "คลิกที่คนนี้อีกครั้งเพื่อคุยต่อ · คลิกพื้นเพื่อปิด"
    hint.add_theme_font_override("font", font)
    hint.add_theme_font_size_override("font_size", 15)
    hint.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7))
    vb.add_child(hint)
    ui_dialog.visible = false
    cl.add_child(ui_dialog)
    ui_shop = PanelContainer.new()
    ui_shop.add_theme_stylebox_override("panel", sb)
    ui_shop.anchor_left = 0.5
    ui_shop.anchor_right = 0.5
    # หน้าร้านอยู่ล่างจอแบบเกม 2D (เห็นเจ้าของร้านกับคำพูดด้านบน)
    ui_shop.anchor_top = 0.36
    ui_shop.anchor_bottom = 1.0
    ui_shop.offset_left = -340
    ui_shop.offset_right = 340
    ui_shop.offset_top = 0
    ui_shop.offset_bottom = -10
    var sc := ScrollContainer.new()
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    ui_shop.add_child(sc)
    ui_shop_body = VBoxContainer.new()
    ui_shop_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ui_shop_body.add_theme_constant_override("separation", 6)
    sc.add_child(ui_shop_body)
    ui_shop.visible = false
    cl.add_child(ui_shop)
    _build_bag_ui(cl, ui_shop.get_theme_stylebox("panel"))
    bag_btn = _btn("กระเป๋า", true, toggle_bag)
    bag_btn.anchor_left = 1.0
    bag_btn.anchor_right = 1.0
    bag_btn.offset_left = -130
    bag_btn.offset_right = -12
    bag_btn.offset_top = 12
    bag_btn.offset_bottom = 52
    cl.add_child(bag_btn)
    char_btn = _btn("ตัวละคร", true, toggle_char)
    char_btn.anchor_left = 1.0
    char_btn.anchor_right = 1.0
    char_btn.offset_left = -262
    char_btn.offset_right = -138
    char_btn.offset_top = 12
    char_btn.offset_bottom = 52
    cl.add_child(char_btn)
    var built := _panel(cl, ui_shop.get_theme_stylebox("panel"))
    ui_char = built[0]
    ui_char_body = built[1]

# ---------- คุยกับ NPC / หน้าร้าน ----------
## ตัดอีโมจิออก (บนเว็บไม่มีฟอนต์อีโมจิ จะขึ้นเป็นกล่องสี่เหลี่ยม)
func clean(t: String) -> String:
    var out := ""
    for i in t.length():
        var c := t.unicode_at(i)
        if c >= 0x1F000 or (c >= 0x2600 and c <= 0x27BF) or c == 0xFE0F or (c >= 0x2B00 and c <= 0x2BFF) or c == 0x200D:
            continue
        if c == 0x2192:
            out += "->"
            continue
        out += String.chr(c)
    return out.strip_edges()

func _lbl(t: String, size: int, col: Color = Color(0.95, 0.92, 0.85), bold: bool = false) -> Label:
    var l := Label.new()
    l.text = clean(t)
    l.add_theme_font_override("font", font_b if bold else font)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", col)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func say(name: String, text: String) -> void:
    ui_dname.text = clean(name)
    ui_dtext.text = clean(text)
    ui_dialog.visible = true

const Items = preload("res://scripts/items.gd")
var cur_shop := ""
var ui_bag: PanelContainer
var ui_char: PanelContainer
var ui_char_body: VBoxContainer
var char_btn: Button
var bag_btn: Button
var ui_bag_body: VBoxContainer

func _nowrap(l: Label) -> Label:
    l.autowrap_mode = TextServer.AUTOWRAP_OFF
    return l

func _btn(t: String, enabled: bool, cb: Callable) -> Button:
    var b := Button.new()
    b.text = t
    b.disabled = not enabled
    b.add_theme_font_override("font", font_b)
    b.add_theme_font_size_override("font_size", 17)
    b.custom_minimum_size = Vector2(96, 34)
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(cb)
    return b

## ไอคอนไอเท็ม (ถ่ายจากโมเดล 3D ด้วย tools/make_icons.gd → assets/icons/<id>.png) · ไม่มีไฟล์ = null
var _icons := {}
func icon_tex(id: String) -> Texture2D:
    if id == "":
        return null
    if not _icons.has(id):
        var path := "res://assets/icons/%s.png" % id
        _icons[id] = load(path) if ResourceLoader.exists(path) else null
    return _icons[id]

## id ไอคอนของอุปกรณ์ (instance) = ชนิด+ระดับ เช่น sword3
func gear_icon_id(g: Dictionary) -> String:
    return "%s%d" % [str(g.get("k", "")), int(g.get("t", 0))]

## id ไอคอนของสินค้าในร้าน (BUY id → ไอเท็มที่ได้)
func buy_icon_id(iid: String) -> String:
    var e: Dictionary = Items.BUY.get(iid, {})
    if e.has("item"):
        return str(e.item)
    match str(e.get("type", "")):
        "skill":
            return "skill"
    return iid

func _icon_rect(id: String, px: int = 40) -> TextureRect:
    var tr := TextureRect.new()
    tr.texture = icon_tex(id)
    tr.custom_minimum_size = Vector2(px, px)
    tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return tr

func _row(left: String, sub: String, buttons: Array, icon: String = "") -> HBoxContainer:
    var r := HBoxContainer.new()
    if icon_tex(icon) != null:
        r.add_child(_icon_rect(icon))
    var v := VBoxContainer.new()
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_child(_lbl(left, 18, Color(0.95, 0.92, 0.85), true))
    if sub != "":
        v.add_child(_lbl(sub, 14, Color(0.72, 0.7, 0.64)))
    r.add_child(v)
    for b in buttons:
        r.add_child(b)
    return r

## ป้ายชื่อแถว (ข้ามไอคอนด้านซ้ายถ้ามี)
func _row_label(r: HBoxContainer) -> Label:
    for c in r.get_children():
        if c is VBoxContainer:
            return c.get_child(0) as Label
    return null

## ซื้อของ 1 ชิ้นตามข้อมูลร้าน · คืนข้อความผล ("" = ซื้อไม่ได้)
func shop_buy(it: Dictionary) -> String:
    var id := str(it.get("id", ""))
    var price := int(it.get("price", 0))
    if not Items.can_buy(id):
        return ""
    if player.coins < price:
        return "เหรียญไม่พอ (ต้องใช้ %d)" % price
    var e: Dictionary = Items.BUY[id]
    match str(e.type):
        "equip":
            if player.weapon == str(e.item):
                return "ใส่ " + str(it.name) + " อยู่แล้ว"
            # ของใหม่ (คุณภาพขาว) สวมทันที · ของเดิมเข้ากระเป๋า
            var ni: Dictionary = player.make_inst(str(e.item))
            player.gear.append(ni)
            player.equip(ni)
        "bag":
            player.inv_add(str(e.item), 1)
        "trade":
            for k in e.cost:
                if player.inv_count(str(k)) < int(e.cost[k]):
                    return "ของไม่พอ: %s %d/%d" % [Items.item_name(str(k)), player.inv_count(str(k)), int(e.cost[k])]
            for k in e.cost:
                player.inv_take(str(k), int(e.cost[k]))
            player.inv_add(str(e.item), 1)
        "skill":
            if not player.learn_skill(str(e.skill)):
                return "เรียน " + str(it.name) + " แล้ว"
            if mobile != null:
                mobile.refresh_skills()
            player.coins -= price
            return "เรียนสกิล " + str(it.name) + " แล้ว (คอม: กด 1/2/3 · มือถือ: ปุ่มรอบปุ่มตี)"
        "now":
            if player.hp >= player.max_hp and player.mp >= player.max_mp:
                return "เลือดและมานาเต็มอยู่แล้ว"
            player.hp = min(float(player.max_hp), player.hp + float(e.get("hp", 0)))
            player.mp = min(float(player.max_mp), player.mp + float(e.get("mp", 0)))
    player.coins -= price
    return "ซื้อ " + str(it.name) + " แล้ว (-%d เหรียญ)" % price

## ขายของให้ร้าน · n = จำนวน (-1 = ทั้งหมด)
func shop_sell(item_id: String, price: int, n: int) -> String:
    var have: int = player.inv_count(item_id)
    if n < 0:
        n = have
    if have <= 0 or n <= 0:
        return ""
    n = min(n, have)
    player.inv_take(item_id, n)
    player.coins += price * n
    return "ขาย %s ×%d ได้ %d เหรียญ" % [Items.item_name(item_id), n, price * n]

func _shop_msg(t: String, thank: String = "") -> void:
    if t != "":
        field.say_msg(t)
        if thank != "" and room != "":
            rooms.bubble(thank)
    open_shop(cur_shop)

## หน้าร้านแบบเกม 2D (js/031-core.js renderShop v2.5): ซ้าย = ของในร้าน (แตะเพื่อซื้อ) · ขวา = กระเป๋าของเรา (แตะของเพื่อขาย)
## เลือกของในกระเป๋า → แถบขาย (−10 − จำนวน + +10 ทั้งหมด) → ปุ่ม "ขาย ×n ได้ X" · แตะช่องเดิมซ้ำ = +1
var shop_sel := ""
var shop_qty := 1

func _bag_ids() -> Array:
    var ids := []
    for k in ["gel", "stone", "wood"]:
        if player.inv_count(k) > 0:
            ids.append(k)
    for k in player.inv.keys():
        if player.inv_count(str(k)) > 0 and not ids.has(str(k)):
            ids.append(str(k))
    return ids

func _sell_price(sh: Dictionary, iid: String) -> int:
    var alias := "ore" if iid == "gem" else iid  # เกม 2D เรียกเพชร (ก้อน) ว่า ore
    for it in sh.get("sell", []):
        if it is Array and it.size() >= 3 and (str(it[0]) == iid or str(it[0]) == alias):
            return int(it[2])
    return 0

func shop_pick(iid: String) -> void:
    if shop_sel == iid:
        shop_qty = min(shop_qty + 1, player.inv_count(iid))
    else:
        shop_sel = iid
        shop_qty = 1
    open_shop(cur_shop)

func shop_qty_add(d: int) -> void:
    var have: int = player.inv_count(shop_sel)
    shop_qty = have if d == 9999 else clampi(shop_qty + d, 1, max(1, have))
    open_shop(cur_shop)

func shop_sell_ok() -> void:
    var sh: Dictionary = shops_by_id.get(cur_shop, {})
    var m := shop_sell(shop_sel, _sell_price(sh, shop_sel), shop_qty)
    if player.inv_count(shop_sel) <= 0:
        shop_sel = ""
    shop_qty = 1
    _shop_msg(m, "ขอบคุณที่อุดหนุนนะ!")

func sell_gear(g: Dictionary) -> String:
    if not player.gear.has(g):
        return ""
    var pr := Items.gear_price(g)
    if pr <= 0:
        return "ร้านไม่รับซื้อชุดดรอปจากบอส"
    player.gear.erase(g)
    player.coins += pr
    return "ขาย %s ได้ %d เหรียญ" % [Items.inst_name(g), pr]

func close_shop() -> void:
    ui_shop.visible = false
    shop_sel = ""
    shop_qty = 1

func _slot(t: String, cb: Callable, faded: bool, on: bool, icon: String = "") -> Button:
    var b := Button.new()
    b.text = clean(t)
    b.add_theme_font_override("font", font)
    b.add_theme_font_size_override("font_size", 14)
    b.custom_minimum_size = Vector2(88, 64)
    var tx := icon_tex(icon)
    if tx != null:
        b.icon = tx
        b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
        b.add_theme_constant_override("icon_max_width", 40)
        b.custom_minimum_size = Vector2(88, 100)
    b.focus_mode = Control.FOCUS_NONE
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var st := StyleBoxFlat.new()
    st.bg_color = Color(0.16, 0.14, 0.11, 0.95)
    st.border_color = Color(0.49, 0.85, 0.34) if on else Color(0.42, 0.38, 0.3)
    st.set_border_width_all(3 if on else 1)
    st.set_corner_radius_all(6)
    for k in ["normal", "hover", "pressed"]:
        b.add_theme_stylebox_override(k, st)
    if faded:
        b.modulate = Color(1, 1, 1, 0.38)
    b.pressed.connect(cb)
    return b

func open_shop(id: String) -> void:
    var sh: Dictionary = shops_by_id.get(id, {})
    if sh.is_empty():
        return
    if cur_shop != id:
        shop_sel = ""
        shop_qty = 1
    cur_shop = id
    if ui_bag != null:
        ui_bag.visible = false
    for c in ui_shop_body.get_children():
        c.queue_free()
    var ow = sh.get("owner")
    var oname := str(ow.get("name", "")) if ow is Dictionary else ""
    # หัว: ชื่อร้าน · เจ้าของ · เหรียญ · ปุ่มปิด
    var top := HBoxContainer.new()
    var hv := VBoxContainer.new()
    hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(_nowrap(_lbl(str(sh.name), 22, Color(1.0, 0.85, 0.45), true)))
    hv.add_child(_nowrap(_lbl(oname + " · เหรียญของคุณ %d" % player.coins, 15, Color(0.85, 0.82, 0.74))))
    top.add_child(hv)
    var xb := _btn("X", true, close_shop)
    xb.custom_minimum_size = Vector2(44, 34)
    top.add_child(xb)
    ui_shop_body.add_child(top)
    if id == "st_farm":
        ui_shop_body.add_child(_btn("สัตว์ขี่ & สัตว์เลี้ยง", true, func(): steed.open()))
    if id == "gear":
        var smb := _btn(craft.smith_label(), true, func(): craft.open_smith())
        if craft.smith_avail():
            smb.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
        ui_shop_body.add_child(smb)
    var cols := HBoxContainer.new()
    cols.add_theme_constant_override("separation", 12)
    ui_shop_body.add_child(cols)
    # ซ้าย: ของในร้าน
    var lv := VBoxContainer.new()
    lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lv.size_flags_stretch_ratio = 1.0
    lv.add_child(_lbl("ของในร้าน (แตะเพื่อซื้อ)", 15, Color(0.95, 0.9, 0.75), true))
    lv.add_child(HSeparator.new())
    cols.add_child(lv)
    var buy: Array = sh.get("buy", [])
    var shown := 0
    for it in buy:
        if Items.hidden(str(it.id)):
            continue
        shown += 1
        var iid := str(it.id)
        var ok: bool = Items.can_buy(iid)
        var price := int(it.get("price", 0))
        var nm := str(it.get("name", ""))
        var tail := " −%d เหรียญ" % price
        if not ok:
            tail = " · เร็ว ๆ นี้"
        elif Items.BUY[iid].type == "skill" and player.skills.has(str(Items.BUY[iid].skill)):
            tail = " · เรียนแล้ว"
        elif Items.BUY[iid].type == "equip" and player.weapon == str(Items.BUY[iid].item):
            tail = " · ใส่อยู่"
        var note := str(it.get("note", "")) if it.get("note") else ""
        if ok and Items.BUY[iid].type == "trade":
            var parts := []
            for k in Items.BUY[iid].cost:
                parts.append("%s %d (มี %d)" % [Items.item_name(str(k)), int(Items.BUY[iid].cost[k]), player.inv_count(str(k))])
            note = "ใช้ " + " + ".join(parts)
        var item: Dictionary = it
        var b := Button.new()
        b.text = clean(nm + tail) + ("\n" + clean(note) if note != "" else "")
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.add_theme_font_override("font", font_b)
        b.add_theme_font_size_override("font_size", 15)
        b.focus_mode = Control.FOCUS_NONE
        b.custom_minimum_size = Vector2(0, 40)
        var btx := icon_tex(buy_icon_id(iid))
        if btx != null:
            b.icon = btx
            b.add_theme_constant_override("icon_max_width", 36)
        if not ok or player.coins < price:
            b.modulate = Color(1, 1, 1, 0.5)
        b.pressed.connect(func():
            if not Items.can_buy(str(item.id)):
                field.say_msg(clean(str(item.get("name", ""))) + " — ระบบนี้กำลังมา เร็ว ๆ นี้")
                return
            var m := shop_buy(item)
            var good := m.begins_with("ซื้อ") or m.begins_with("เรียนสกิล")
            _shop_msg(m, "ขอบคุณจ้า!" if good else ""))
        lv.add_child(b)
    if shown == 0:
        lv.add_child(_lbl("ร้านนี้ไม่มีของขาย", 14, Color(0.75, 0.72, 0.65)))
    # ขวา: กระเป๋าของเรา
    var rv := VBoxContainer.new()
    rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rv.add_child(_lbl("กระเป๋าของคุณ (แตะของเพื่อขาย)", 15, Color(0.95, 0.9, 0.75), true))
    rv.add_child(HSeparator.new())
    cols.add_child(rv)
    if shop_sel != "" and (player.inv_count(shop_sel) <= 0 or _sell_price(sh, shop_sel) <= 0):
        shop_sel = ""
    if shop_sel != "":
        var have: int = player.inv_count(shop_sel)
        var pr := _sell_price(sh, shop_sel)
        shop_qty = clampi(shop_qty, 1, have)
        var hb := HBoxContainer.new()
        var nl := _lbl("%s · มี ×%d · %d เหรียญ/ชิ้น" % [Items.item_name(shop_sel), have, pr], 15, Color(1, 0.95, 0.8), true)
        nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hb.add_child(nl)
        var cx := _btn("X", true, func(): shop_sel = ""; open_shop(cur_shop))
        cx.custom_minimum_size = Vector2(40, 30)
        hb.add_child(cx)
        rv.add_child(hb)
        var qb := HBoxContainer.new()
        for d in [-10, -1]:
            var dd: int = d
            var bb := _btn(("−%d" % -d) if d == -10 else "−", true, func(): shop_qty_add(dd))
            bb.custom_minimum_size = Vector2(44, 34)
            qb.add_child(bb)
        var ql := _nowrap(_lbl(str(shop_qty), 18, Color(1, 0.9, 0.4), true))
        ql.custom_minimum_size = Vector2(36, 0)
        ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        qb.add_child(ql)
        for d in [1, 10]:
            var dd: int = d
            var bb := _btn("+" if d == 1 else "+10", true, func(): shop_qty_add(dd))
            bb.custom_minimum_size = Vector2(44, 34)
            qb.add_child(bb)
        var ab := _btn("ทั้งหมด", true, func(): shop_qty_add(9999))
        ab.custom_minimum_size = Vector2(70, 34)
        qb.add_child(ab)
        rv.add_child(qb)
        var ok_b := _btn("ขาย ×%d ได้ %d เหรียญ" % [shop_qty, shop_qty * pr], true, shop_sell_ok)
        ok_b.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
        rv.add_child(ok_b)
    else:
        rv.add_child(_lbl("แตะของที่มีราคาเพื่อเลือกขาย · สีจาง = ร้านนี้ไม่รับซื้อ", 13, Color(0.75, 0.72, 0.65)))
    var grid := GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation", 4)
    grid.add_theme_constant_override("v_separation", 4)
    var ids := _bag_ids()
    for iid in ids:
        var pr2 := _sell_price(sh, iid)
        var n: int = player.inv_count(iid)
        var a: String = iid
        var txt := "%s\n×%d" % [Items.item_name(iid), n] + (("  %d เหรียญ" % pr2) if pr2 > 0 else "")
        if pr2 > 0:
            grid.add_child(_slot(txt, func(): shop_pick(a), false, shop_sel == iid, iid))
        else:
            grid.add_child(_slot(txt, func(): field.say_msg("ร้านนี้ไม่รับซื้อของชิ้นนี้"), true, false, iid))
    rv.add_child(grid)
    # ร้านอาวุธรับซื้ออุปกรณ์ในกระเป๋า (ไม่รวมที่สวมอยู่) · ราคา gearPrice × 0.6 (fix31)
    if id == "gear" and not player.gear.is_empty():
        rv.add_child(_lbl("อุปกรณ์ในกระเป๋า (แตะเพื่อขาย)", 14, Color(0.95, 0.9, 0.75), true))
        for it in player.gear:
            var g: Dictionary = it
            var pr3 := Items.gear_price(g)
            if pr3 <= 0:
                continue
            var gb := _slot("%s\n%d เหรียญ" % [Items.inst_name(g), pr3], func(): _shop_msg(sell_gear(g), "ขอบคุณที่อุดหนุนนะ!"), false, false, gear_icon_id(g))
            gb.add_theme_color_override("font_color", Items.QCOLORS[int(g.q)])
            rv.add_child(gb)
    if ids.is_empty():
        rv.add_child(_lbl("กระเป๋าว่างเปล่า — ยังไม่มีอะไรให้ขาย", 14, Color(0.75, 0.72, 0.65)))
    ui_shop.visible = true

## ธนาคาร: ฝาก/ถอนของ (เก็บใน player.bank และเซฟด้วย)
func bank_move(id: String, n: int, deposit: bool) -> String:
    if deposit:
        var have: int = player.inv_count(id)
        n = have if n < 0 else min(n, have)
        if n <= 0:
            return ""
        player.inv_take(id, n)
        player.bank[id] = int(player.bank.get(id, 0)) + n
        return "ฝาก %s ×%d" % [Items.item_name(id), n]
    var st: int = int(player.bank.get(id, 0))
    n = st if n < 0 else min(n, st)
    if n <= 0:
        return ""
    player.bank[id] = st - n
    if player.bank[id] <= 0:
        player.bank.erase(id)
    player.inv_add(id, n)
    return "ถอน %s ×%d" % [Items.item_name(id), n]

func open_bank() -> void:
    cur_shop = "bank"
    for c in ui_shop_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var title := _nowrap(_lbl("ธนาคารเอลโดเรีย", 24, Color(1.0, 0.85, 0.45), true))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    top.add_child(_btn("X", true, close_shop))
    ui_shop_body.add_child(top)
    ui_shop_body.add_child(_lbl("ฝากของไว้ที่ธนาคาร ของปลอดภัยและไม่หาย", 16, Color(0.85, 0.92, 1.0)))
    ui_shop_body.add_child(_lbl("ในกระเป๋า", 20, Color(0.7, 1.0, 0.7), true))
    var ids := ["gel", "stone", "wood"]
    for k in player.inv.keys():
        ids.append(str(k))
    for iid in ids:
        var n: int = player.inv_count(iid)
        if n <= 0:
            continue
        var a: String = iid
        ui_shop_body.add_child(_row("%s ×%d" % [Items.item_name(iid), n], "", [
            _btn("ฝาก 1", true, func(): field.say_msg(bank_move(a, 1, true)); open_bank()),
            _btn("ฝากหมด", true, func(): field.say_msg(bank_move(a, -1, true)); open_bank())], a))
    ui_shop_body.add_child(_lbl("ในธนาคาร", 20, Color(1.0, 0.85, 0.6), true))
    if player.bank.is_empty():
        ui_shop_body.add_child(_lbl("ยังไม่ได้ฝากอะไร", 15, Color(0.75, 0.72, 0.65)))
    for k in player.bank.keys():
        var b: String = str(k)
        ui_shop_body.add_child(_row("%s ×%d" % [Items.item_name(b), int(player.bank[k])], "", [
            _btn("ถอน 1", true, func(): field.say_msg(bank_move(b, 1, false)); open_bank()),
            _btn("ถอนหมด", true, func(): field.say_msg(bank_move(b, -1, false)); open_bank())], b))
    ui_shop.visible = true

## กระเป๋า: ของทั้งหมด + ปุ่มใช้ยา/ม้วนวาป · เปิดด้วยปุ่ม "กระเป๋า" หรือคีย์ B
func toggle_bag() -> void:
    if ui_bag.visible:
        ui_bag.visible = false
        return
    ui_shop.visible = false
    ui_char.visible = false
    refresh_bag()
    ui_bag.visible = true

func refresh_bag() -> void:
    for c in ui_bag_body.get_children():
        c.queue_free()
    var top := HBoxContainer.new()
    var title := _nowrap(_lbl("กระเป๋า", 24, Color(1.0, 0.85, 0.45), true))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    top.add_child(_nowrap(_lbl("เหรียญ %d" % player.coins, 18, Color(1.0, 0.85, 0.4), true)))
    top.add_child(_btn("ปิด X", true, func(): ui_bag.visible = false))
    ui_bag_body.add_child(top)
    ui_bag_body.add_child(_lbl("ATK %d · DEF %d · เลือดสูงสุด %d" % [player.atk(), player.def(), player.max_hp], 17, Color(0.85, 0.92, 1.0), true))
    # ของที่สวมอยู่
    for sl in Items.SLOTS:
        if not player.eq.has(sl):
            continue
        var it: Dictionary = player.eq[sl]
        var ss: String = sl
        var r := _row("%s: %s" % [Items.SLOT_NAMES[sl], Items.inst_name(it)], "คุณภาพ%s · %s %d" % [Items.QNAMES[int(it.q)], Items.stat_label(str(it.k)), Items.inst_stat(it)], [_btn("ถอด", true, func(): field.say_msg(player.unequip(ss)); refresh_bag())], gear_icon_id(it))
        _row_label(r).add_theme_color_override("font_color", Items.QCOLORS[int(it.q)])
        ui_bag_body.add_child(r)
    if player.eq.is_empty():
        ui_bag_body.add_child(_lbl("ยังไม่ได้สวมอะไร (ซื้อดาบที่ร้านอาวุธลุงเหล็ก หรือคราฟที่ทั่งตีเหล็ก)", 15, Color(0.75, 0.72, 0.65)))
    # อุปกรณ์ในกระเป๋า
    for it in player.gear:
        var g: Dictionary = it
        var tool: bool = not Items.SLOT_OF.has(str(g.k))
        var btns := []
        if not tool and not g.get("b", false):
            btns.append(_btn("สวม", true, func(): field.say_msg(player.equip(g)); refresh_bag()))
        var sub := "%s %d" % [Items.stat_label(str(g.k)), Items.inst_stat(g)]
        if tool:
            sub += " · ใช้จากกระเป๋าได้เลย"
        else:
            sub = "คุณภาพ%s · " % Items.QNAMES[int(g.q)] + sub
        if g.get("b", false):
            sub = "แตก — ซ่อมที่ทั่งตีเหล็กก่อนใส่ · " + sub
        if Items.is_boss_tier(int(g.t)):
            sub = "ชุดบอส [%s] ต้อง Lv.%d · " % [Items.RARITY[int(g.t) - Items.BOSS_T0][0], Items.req_lv(int(g.t))] + sub
        var r2 := _row(Items.inst_name(g), sub, btns, gear_icon_id(g))
        _row_label(r2).add_theme_color_override("font_color", Color(1.0, 0.4, 0.35) if g.get("b", false) else Items.QCOLORS[int(g.q)])
        ui_bag_body.add_child(r2)
    var ids := ["gel", "stone", "wood"]
    for k in player.inv.keys():
        ids.append(str(k))
    var any := false
    for iid in ids:
        var n: int = player.inv_count(iid)
        if n <= 0:
            continue
        any = true
        var info: Dictionary = Items.ITEM.get(iid, {})
        var btns := []
        if info.has("use"):
            var use_id: String = iid
            btns.append(_btn("ใช้", true, func():
                var m: String = player.use_item(use_id)
                if m != "":
                    field.say_msg(m)
                refresh_bag()))
        ui_bag_body.add_child(_row("%s ×%d" % [Items.item_name(iid), n], str(info.get("note", "")), btns, iid))
    if not any:
        ui_bag_body.add_child(_lbl("กระเป๋าว่าง — ตีสไลม์ เก็บหิน/กิ่งไม้ในทุ่งหญ้า", 16, Color(0.75, 0.72, 0.65)))

func _panel(cl: CanvasLayer, sb: StyleBox) -> Array:
    var pnl := PanelContainer.new()
    pnl.add_theme_stylebox_override("panel", sb)
    pnl.anchor_left = 0.5
    pnl.anchor_right = 0.5
    pnl.anchor_top = 0.5
    pnl.anchor_bottom = 0.5
    pnl.offset_left = -330
    pnl.offset_right = 330
    pnl.offset_top = -280
    pnl.offset_bottom = 280
    var sc := ScrollContainer.new()
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    pnl.add_child(sc)
    var body := VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 6)
    sc.add_child(body)
    pnl.visible = false
    cl.add_child(pnl)
    return [pnl, body]

## หน้าตัวละคร: แต้มสเตตัส (ปุ่ม +1 / +5) · ค่าที่ได้ · เปิดด้วยปุ่ม "ตัวละคร" หรือคีย์ C
func toggle_char() -> void:
    if ui_char.visible:
        ui_char.visible = false
        return
    ui_shop.visible = false
    ui_bag.visible = false
    refresh_char()
    ui_char.visible = true

func refresh_char() -> void:
    for c in ui_char_body.get_children():
        c.queue_free()
    var p = player
    var top := HBoxContainer.new()
    var title := _nowrap(_lbl("ตัวละคร  Lv.%d" % p.lv, 24, Color(1.0, 0.85, 0.45), true))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    top.add_child(_nowrap(_lbl("แต้มเหลือ %d" % p.sp, 18, Color(0.6, 1.0, 0.6), true)))
    top.add_child(_btn("ปิด X", true, func(): ui_char.visible = false))
    ui_char_body.add_child(top)
    ui_char_body.add_child(_lbl("เลือด %d · มานา %d · ATK %d · DEF %d · คริ %.1f%%" % [p.max_hp, p.max_mp, p.atk(), p.def(), p.crit_rate() * 100.0], 17, Color(0.85, 0.92, 1.0)))
    var C: Dictionary = classes.CLS[p.cls]
    var pl := []
    for ps in classes.PASSIVE.get(p.cls, []):
        pl.append(("[เปิด] " if p.lv >= int(ps.lv) else "[Lv.%d] " % int(ps.lv)) + str(ps.n) + " " + str(ps.d))
    ui_char_body.add_child(_lbl("อาชีพ: %s%s" % [C.n, ("  ·  " + " · ".join(pl)) if pl.size() > 0 else ""], 15, C.col))
    for ln in p.set_b.get("lines", []):
        ui_char_body.add_child(_lbl("โบนัส " + str(ln), 14, Color(1.0, 0.82, 0.45)))
    for k in ["str", "vit", "int", "agi", "end"]:
        var kk: String = k
        var bon: int = p.stat_total(k) - int(p.stats[k])
        ui_char_body.add_child(_row("%s : %d%s" % [p.STAT_NAMES[k], int(p.stats[k]), (" (+%d)" % bon) if bon > 0 else ""], "", [
            _btn("+1", p.sp > 0, func():
                p.stat_add(kk, 1)
                refresh_char()),
            _btn("+5", p.sp >= 5, func():
                p.stat_add(kk, 5)
                refresh_char())]))
    if p.sp <= 0:
        ui_char_body.add_child(_lbl("ได้แต้ม +3 ทุกครั้งที่เลเวลอัป", 15, Color(0.75, 0.72, 0.65)))

func _build_bag_ui(cl: CanvasLayer, sb: StyleBox) -> void:
    ui_bag = PanelContainer.new()
    ui_bag.add_theme_stylebox_override("panel", sb)
    ui_bag.anchor_left = 0.5
    ui_bag.anchor_right = 0.5
    ui_bag.anchor_top = 0.5
    ui_bag.anchor_bottom = 0.5
    ui_bag.offset_left = -330
    ui_bag.offset_right = 330
    ui_bag.offset_top = -280
    ui_bag.offset_bottom = 280
    var sc := ScrollContainer.new()
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    ui_bag.add_child(sc)
    ui_bag_body = VBoxContainer.new()
    ui_bag_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ui_bag_body.add_theme_constant_override("separation", 6)
    sc.add_child(ui_bag_body)
    ui_bag.visible = false
    cl.add_child(ui_bag)

func _num(v) -> String:
    if v is float and v == floor(v):
        return str(int(v))
    return str(v)

const STALL_SHOP := {"แม่ค้าผัก": "st_veg", "แม่ค้าผลไม้": "st_fruit", "คนขายขนมปัง": "st_bread", "ลุงขายผัก": "st_farm"}

func _talk(n) -> void:
    var lines: Array = n.lines
    if lines.size() == 0:
        say(n.npc_name, "...")
    else:
        say(n.npc_name, str(lines[talk_idx % lines.size()]))
    talk_idx += 1
    n.face_to(player.global_position)
    if STALL_SHOP.has(n.npc_name):
        open_shop(STALL_SHOP[n.npc_name])
    elif n.npc_name == "ปรมาจารย์อาชีพ":
        classes.open_menu()

func _npc_at(screen: Vector2):
    var best = null
    var bd := 60.0
    for n in npcs:
        if not cam.is_position_in_frustum(n.global_position):
            continue
        var sp := cam.unproject_position(n.global_position + Vector3(0, 1.2, 0))
        var d := sp.distance_to(screen)
        if d < bd:
            bd = d
            best = n
    return best

func _test_ui(what: String) -> void:
    if what.begins_with("fight"):
        # ทดสอบ: วางสไลม์รอบตัวแล้วสั่งตี
        for i in 3:
            var a := i * 2.1
            var pos := player.position + Vector3(cos(a) * 2.2, 0, sin(a) * 2.2)
            var sl := Node3D.new()
            sl.set_script(load("res://scripts/slime.gd"))
            field.add_child(sl)
            sl.setup(field, 1 + i, pos)
            field.slimes.append(sl)
        player.target_mob = field.slimes[field.slimes.size() - 3]
        shot_frames = int(what.substr(6)) if what.length() > 6 else 70
        _test_auto = true
        time_scale = 0.0
        return
    if what.begins_with("dg:"):
        # ทดสอบภาพ: dg:<ชั้น>[:boss] — ลงดันเจี้ยน (boss = ยืนหน้าห้องบอส)
        var a := what.split(":")
        mine.enter(mine.DG_BASE + int(a[1]))
        mine._process(0.2)
        if a.size() > 2:
            var d: Dictionary = mine.data[mine.cur]
            player.position = mine.tile_w(mine.cur, d.arena.x, d.arena.y + 5)
        return
    if what.begins_with("ride:"):
        # ทดสอบภาพ: ride:<สัตว์ขี่>:<สัตว์เลี้ยง>
        var ra := what.split(":")
        player.cls = "sword"
        player.refresh_model()
        player.lv = 200
        player.coins = 9999999
        steed.buy("mount", ra[1])
        if ra.size() > 2:
            steed.buy("pet", ra[2])
        player.position = field.portal_pos + Vector3(0, 0, 5.0)
        steed.toggle()
        steed._process(0.1)
        cam_dist = 7.0
        return
    if what.begins_with("lb:"):
        # ทดสอบภาพ: lb:<i> — ลานผนึกบอสตำนาน + วงเตือนท่าไม้ตาย
        var li := int(what.split(":")[1])
        player.lv = 120
        player.coins = 99999
        legend.S = {"cd": {}, "day": "", "n": {}}
        rooms.enter("seal113")
        legend.challenge(li)
        var d: Dictionary = mine.data[mine.cur]
        player.position = mine.tile_w(mine.cur, d.arena.x, d.arena.y + 8)
        legend.aggro = true
        legend._ult(mine.boss)
        legend._tick_aoe(0.5)
        return
    if what.begins_with("mine:") or what.begins_with("mineboss:"):
        # ทดสอบภาพ: เข้าเหมือง (mineboss = ยืนหน้าลานบอส)
        var zi := int(what.split(":")[1])
        mine.enter(zi)
        mine._process(0.2)
        if what.begins_with("mineboss:"):
            var d: Dictionary = mine.data[zi]
            player.position = mine.tile_w(zi, d.arena.x, d.arena.y + 7)
        return
    if what.begins_with("gear:"):
        # ทดสอบภาพ: gear:<อาวุธ> — สวมชุดเต็ม (หมวก/เสื้อ/แขน ระดับทอง คุณภาพแดง +9)
        player.weapon = what.substr(5)
        for k in ["helm4", "chest4", "arm4"]:
            var it: Dictionary = player.make_inst(k, 3)
            it.e = 9
            player.gear.append(it)
            player.equip(it)
        player.eq.weapon.q = 3
        player.update_gear_visual()
        cam_dist = 7.0
        return
    if what.begins_with("cls:"):
        # ทดสอบภาพ: cls:<อาชีพ>:<เลเวล>[:ช่องสกิล] — มีอาชีพ + อาวุธประจำสาย + ปุ่มสกิลครบ แล้วกดสกิล
        var a := what.split(":")
        player.lv = int(a[2])
        player.cls = a[1]
        player.weapon = str(classes.CLS[a[1]].w) + "1"
        player.refresh_model()
        player.skills["heal"] = true
        player.recalc_stats()
        player.mp = player.max_mp
        if mobile != null:
            mobile.refresh_skills()
        if a.size() > 3:
            classes.use_slot(int(a[3]))
        return
    if what.begins_with("stn:"):
        # ทดสอบภาพ: stn:<ร้าน>:<ลำดับสถานี>[:enh] — ยืนข้างสถานีแล้วเปิด
        var a := what.split(":")
        rooms.enter(a[1])
        player.position = rooms.station_pos(a[1], int(a[2])) + Vector3(1.6 if int(a[2]) == 0 else -1.6, 0, 0)
        player.wood = 12
        player.inv_add("iron", 8)
        player.inv_add("coal", 3)
        player.inv_add("ingot", 6)
        player.inv_add("estone", 3)
        player.coins = 500
        var h: Dictionary = player.make_inst("helm1", 2)
        h.e = 4
        player.gear.append(h)
        player.equip(h)
        if a.size() > 3:
            craft.anvil_tab = "enh"
        rooms.interact_if_near()
        return
    if what.begins_with("roomshop:"):
        # ทดสอบภาพ: เข้าร้าน ยืนหน้าเคาน์เตอร์ แล้วคุยเปิดหน้าร้าน (มีของในกระเป๋าให้เห็นช่องขาย)
        rooms.enter(what.substr(9))
        var k: Node3D = rooms.keepers[rooms.cur]
        player.position = Vector3(k.position.x, 0, k.position.z + 2.2)
        player.gel = 7
        player.wood = 3
        player.stone = 5
        player.coins = 120
        player.inv_add("hpp", 2)
        rooms.interact()
        shop_pick("gel")
    elif what.begins_with("room:"):
        rooms.enter(what.substr(5))
    elif what.begins_with("shop:"):
        open_shop(what.substr(5))
    elif what.begins_with("talk:"):
        var n = npcs[int(what.substr(5))]
        _talk(n)

# ---------- การควบคุม ----------
func _ground_at(screen: Vector2) -> Variant:
    var from := cam.project_ray_origin(screen)
    var dir := cam.project_ray_normal(screen)
    if abs(dir.y) < 0.0001:
        return null
    var t := -from.y / dir.y
    if t < 0:
        return null
    return from + dir * t

## คลิก/แตะที่จอ: ตีสไลม์ · คุย NPC · เดินไปจุดนั้น
func click_at(pos: Vector2) -> void:
    if room != "":
        ui_dialog.visible = false
        if rooms.keeper_at(pos):
            rooms.walk_to_counter()
            return
        var si: int = rooms.station_at(pos)
        if si >= 0:
            rooms.walk_to_station(si)
            return
        var gr = _ground_at(pos)
        if gr != null and not blocked(gr.x, gr.z):
            player.set_path(PackedVector3Array([Vector3(gr.x, 0, gr.z)]))
        return
    var sl = field.slime_at(pos)
    if sl != null:
        player.target_mob = sl
        talk_target = null
        ui_dialog.visible = false
        return
    player.target_mob = null
    var n = _npc_at(pos)
    if n != null:
        if talk_target == n and player.global_position.distance_to(n.global_position) < 2.8:
            _talk(n)
            return
        talk_target = n
        talk_idx = 0
        var pth := find_path(player.global_position, n.global_position)
        player.set_path(pth)
        return
    talk_target = null
    ui_dialog.visible = false
    var g = _ground_at(pos)
    if g != null:
        var path := find_path(player.global_position, g)
        if path.size() > 0:
            player.set_path(path)
            click_marker.position = path[path.size() - 1] + Vector3(0, 0.05, 0)
            click_marker.visible = true

func _unhandled_input(e: InputEvent) -> void:
    if e is InputEventMouseButton:
        if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
            cam_dist = max(CAM_NEAR if room == "" else 8.0, cam_dist * 0.9)
        elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
            cam_dist = min(CAM_FAR if room == "" else 70.0, cam_dist * 1.1)
        elif e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE:
            rot_drag = e.pressed
            cam_dragging = e.pressed
        elif e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
            if is_mobile and e.device == InputEvent.DEVICE_ID_EMULATION:
                return
            click_at(e.position)
    elif e is InputEventMouseMotion and rot_drag:
        cam_yaw -= e.relative.x * 0.006
        cam_spin = -e.velocity.x * 0.006
        if room != "":
            cam_pitch = clamp(cam_pitch - e.relative.y * 0.004, -1.4, -0.3)
    elif e is InputEventKey and e.pressed and not e.echo:
        match e.keycode:
            KEY_F5: time_of_day = 0.3
            KEY_F6: time_of_day = 0.48
            KEY_F7: time_of_day = 0.72
            KEY_F8: time_of_day = 0.95
            KEY_1, KEY_2, KEY_3, KEY_4:
                var si: int = e.keycode - KEY_1
                var ms: String = classes.use_slot(si)
                if ms != "" and ms != classes.slot_name(player, si): field.say_msg(ms)
            KEY_F: time_scale = 20.0 if time_scale < 20.0 else 1.0
            KEY_G: _set_quality(1 if quality == 2 else 2)
            KEY_J, KEY_SPACE: player.attack()
            KEY_SHIFT: player.dash(_key_dir())
            KEY_B, KEY_I: toggle_bag()
            KEY_C: toggle_char()
            KEY_R: field.say_msg(steed.toggle())
            KEY_H:
                var mh: String = player.use_item("hpp")
                if mh != "": field.say_msg(mh)
            KEY_N:
                var mn: String = player.use_item("mpp")
                if mn != "": field.say_msg(mn)

func _key_dir() -> Vector3:
    var mv := Vector3.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.z -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.z += 1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
    return mv.normalized().rotated(Vector3.UP, cam_yaw) if mv != Vector3.ZERO else Vector3.ZERO

func _set_quality(q: int) -> void:
    quality = q
    var advanced_effects := q >= 2 and not is_mobile and RenderingServer.get_current_rendering_method() == "forward_plus"
    env.volumetric_fog_enabled = advanced_effects
    env.ssao_enabled = advanced_effects
    sun.directional_shadow_max_distance = 120.0 if q >= 2 else 60.0

func _process(delta: float) -> void:
    # เปิดหน้าร้าน/กระเป๋า/ตัวละคร → ซ่อนจอย/ปุ่มตี ไม่ให้ทับหน้าต่าง
    if mobile != null and ui_shop != null:
        mobile.visible = not (ui_shop.visible or ui_bag.visible or ui_char.visible)
    time_of_day = fposmod(time_of_day + delta / day_len * time_scale, 1.0)
    _sky_tick += delta
    if _sky_tick >= (0.5 if is_mobile else 0.1):
        _sky_tick = 0.0
        _update_sky()
    if Input.is_key_pressed(KEY_Q):
        cam_yaw += delta * 1.5
    if Input.is_key_pressed(KEY_E):
        cam_yaw -= delta * 1.5
    var mv := Vector3.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.z -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.z += 1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
    if mv != Vector3.ZERO:
        mv = mv.normalized()
    elif is_mobile and mobile != null and mobile.joy != Vector2.ZERO:
        mv = Vector3(mobile.joy.x, 0, mobile.joy.y)
    if mv != Vector3.ZERO:
        player.drive(mv.rotated(Vector3.UP, cam_yaw), delta)
        click_marker.visible = false
    if click_marker.visible:
        click_marker.rotation.y += delta * 2.0
        if not player.has_path():
            click_marker.visible = false
    if _test_auto and player.target_mob == null:
        player.target_mob = field.nearest_slime(player.position, 14.0)
    _update_cam(delta)
    # เดินถึง NPC ที่คลิกไว้ -> คุย
    if talk_target != null and not ui_dialog.visible and player.global_position.distance_to(talk_target.global_position) < 2.6:
        player.set_path(PackedVector3Array())
        _talk(talk_target)
    # เดินเข้าประตูร้าน -> เปิดหน้าร้าน (เหมือนเกมเดิม)
    if room != "":
        var hh2 := int(time_of_day * 24.0)
        var mm2 := int(fmod(time_of_day * 24.0 * 60.0, 60.0))
        hud.text = "%s · %02d:%02d" % [clean(str(shops_by_id.get(room, {}).get("name", ""))), hh2, mm2]
        _shot_tick()
        return
    if mine.cur >= 0:
        _shot_tick()
        return
    var pp := Vector2((player.position.x - OX) / TS, (player.position.z - OZ) / TS)
    var near := ""
    for d in doors:
        if pp.distance_to(d.p) < 0.9:
            near = d.id
    if near != "" and near != in_door:
        in_door = near
        rooms.enter(near)
        return
    in_door = near
    var msg := ""
    if pp.distance_to(Vector2(22.0, 9.3)) < 1.2:
        msg = "ประตูปราสาท — ทหารยาม: \"พระราชาทรงรอท่านอยู่ ภารกิจจะมาในเร็ว ๆ นี้\""
    elif pp.x < 1.3 and pp.x > -0.5 and pp.y > 15.5 and pp.y < 18.5:
        msg = "« ทางออกสู่ทุ่งหญ้า"
    elif pp.x > 42.7 and pp.y > 15.5 and pp.y < 18.5:
        msg = "ถนนสู่นครวารี » (ขั้นถัดไป)"
    prompt.text = msg
    if quality == 2 and shot_frames < 0 and not is_mobile:
        if Engine.get_frames_per_second() < 28 and Time.get_ticks_msec() > 8000:
            low_fps_t += delta
            if low_fps_t > 4.0:
                _set_quality(1)
        else:
            low_fps_t = 0.0
    var hh := int(time_of_day * 24.0)
    var mm := int(fmod(time_of_day * 24.0 * 60.0, 60.0))
    var place := "ทุ่งหญ้า" if player.position.x < OX else "เมืองเอลโดเรีย"
    if place != _last_place:
        if _last_place != "":
            field.say_msg("เข้าสู่ทุ่งหญ้า — ระวังสไลม์! (ยิ่งไปทางตะวันตกยิ่งเก่ง)" if place == "ทุ่งหญ้า" else "กลับเข้าเมืองเอลโดเรีย", 3.0)
        _last_place = place
    if is_mobile:
        hud.text = "%s · %02d:%02d" % [place, hh, mm]
    else:
        hud.text = "%s · %02d:%02d\nคลิกพื้นเพื่อเดิน · WASD เดิน · J/Space หรือคลิกสไลม์ = ตี · Shift พุ่งหลบ\nคลิกขวาลากหมุนกล้อง · ล้อเมาส์ซูม · F เร่งเวลา" % [place, hh, mm]
    _shot_tick()

func _shot_tick() -> void:
    if shot_frames > 0:
        shot_frames -= 1
        if shot_frames == 0:
            var img := get_viewport().get_texture().get_image()
            img.save_png("user://" + shot_name + ".png")
            print("SHOT ", OS.get_user_data_dir(), "/", shot_name, ".png")
            print("STATS lv=%d xp=%d hp=%d coins=%d gel=%d dead=%s slimes=%d" % [player.lv, player.xp, player.hp, player.coins, player.gel, player.dead, field.slimes.size()])
            get_tree().quit()
