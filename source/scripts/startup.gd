extends CanvasLayer
## เปิดด้วยฉาก 2D เบาก่อนสร้างเมือง พร้อมจดขั้นตอนเผื่อแอปหยุดระหว่างโหลด

const MARKER := "user://startup_state.json"
var status: Label
var progress: ProgressBar
var recovery_mode := false
var previous_stage := ""

func _ready() -> void:
    if FileAccess.file_exists(MARKER):
        var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARKER))
        if old is Dictionary and old.get("loading", false):
            recovery_mode = true
            previous_stage = str(old.get("stage", ""))
    var screen := ColorRect.new()
    screen.color = Color(0.055, 0.07, 0.10)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(screen)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.add_child(center)
    var box := VBoxContainer.new()
    box.custom_minimum_size = Vector2(300, 0)
    box.add_theme_constant_override("separation", 16)
    center.add_child(box)
    var title := Label.new()
    title.text = "ตำนานเอลโดเรีย"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 32)
    box.add_child(title)
    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 20)
    box.add_child(status)
    progress = ProgressBar.new()
    progress.custom_minimum_size = Vector2(300, 18)
    progress.show_percentage = false
    box.add_child(progress)
    if recovery_mode:
        var info := Label.new()
        info.text = "กำลังเปิดด้วยโหมดเบา\nครั้งก่อนหยุดที่: " + previous_stage
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(info)
    _stage("กำลังเริ่มเกม", 0.0)
    print("STARTUP version=0.4-modern os=", OS.get_name(), " recovery=", recovery_mode)
    call_deferred("_load_world")

func _load_world() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var packed: PackedScene = load("res://main.tscn")
    if packed == null:
        status.text = "โหลดเมืองไม่สำเร็จ กรุณาเปิดเกมใหม่"
        push_error("STARTUP cannot load main.tscn")
        return
    var world: Node = packed.instantiate()
    world.set_meta("recovery_mode", recovery_mode)
    world.process_mode = Node.PROCESS_MODE_DISABLED
    world.loading_stage.connect(_stage)
    get_tree().root.add_child(world)
    await world.world_ready
    world.process_mode = Node.PROCESS_MODE_INHERIT
    get_tree().current_scene = world
    _write_marker("เข้าเกมสำเร็จ", false)
    print("STARTUP ready")
    queue_free()

func _stage(message: String, fraction: float) -> void:
    status.text = message
    progress.value = fraction * 100.0
    _write_marker(message, true)
    print("STARTUP stage=", message, " progress=", fraction)

func _write_marker(message: String, loading: bool) -> void:
    var file := FileAccess.open(MARKER, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify({"stage": message, "loading": loading}))
        file.close()
