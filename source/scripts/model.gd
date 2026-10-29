extends Node3D
const VisualStyle = preload("res://scripts/visual_style.gd")
## ตัวละครโมเดล 3D มีโครงกระดูกและท่าทางจริง (KayKit Adventurers, CC0)
## ใช้แทนหุ่นบล็อกเดิม: build(o) / animate(delta, speed) / action(name, dur)

const FILES := {
    "knight": "res://assets/chars/Knight.glb",
    "barbarian": "res://assets/chars/Barbarian.glb",
    "mage": "res://assets/chars/Mage.glb",
    "rogue": "res://assets/chars/Rogue.glb",
    "hooded": "res://assets/chars/Rogue_Hooded.glb",
}
const LOOPS := ["Idle", "Walking_A", "Walking_B", "Running_A", "Unarmed_Idle", "2H_Melee_Idle", "Sit_Chair_Idle", "Blocking", "Spellcasting"]
static var _cache := {}

var inst: Node3D
var ap: AnimationPlayer
var cur := ""
var act_t := 0.0
var idle_name := "Idle"
var dead := false
var roll_pivot: Node3D
var base_scale := Vector3.ONE

func build(o: Dictionary) -> void:
    var kind: String = o.get("model", "rogue")
    var ps: PackedScene = _cache.get(kind)
    if ps == null:
        ps = load(FILES[kind])
        _cache[kind] = ps
    inst = ps.instantiate()
    roll_pivot = Node3D.new()
    add_child(roll_pivot)
    roll_pivot.add_child(inst)
    ap = inst.get_node("AnimationPlayer")
    for n in LOOPS:
        if ap.has_animation(n):
            ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
    # เก็บอาวุธ/ของในมือที่ไม่ใช้ ให้เหลือเฉพาะที่ระบุ
    var keep: Array = o.get("keep", [])
    var hide_all: bool = o.get("hide_items", true)
    var sk := inst.get_node("Rig/Skeleton3D")
    for c in sk.get_children():
        if c is BoneAttachment3D:
            for m in c.get_children():
                if hide_all and not keep.has(String(m.name)):
                    m.visible = false
    # สีเสื้อผ้าให้แต่ละคนต่างกัน (ผสมกับลายผ้าเดิม)
    if o.has("tint"):
        var tint: Color = o.tint
        for m in sk.get_children():
            if m is MeshInstance3D and not String(m.name).ends_with("_Head"):
                for si in m.mesh.get_surface_count():
                    var base: Material = m.mesh.surface_get_material(si)
                    if base is StandardMaterial3D:
                        var dup: StandardMaterial3D = base.duplicate()
                        dup.albedo_color = Color(1, 1, 1).lerp(tint, 0.45)
                        m.set_surface_override_material(si, dup)
    _finish_materials(sk, kind)
    var head: int = sk.find_bone("head")
    if head >= 0:
        sk.set_bone_pose_scale(head, Vector3.ONE * 0.84)
    var sc: float = o.get("scale", 1.0)
    inst.scale = Vector3.ONE * 0.92 * sc
    base_scale = inst.scale
    idle_name = o.get("idle", "Idle")
    _play(idle_name, 0.0)

func _play(n: String, blend: float = 0.15, spd: float = 1.0) -> void:
    if cur == n and ap.is_playing():
        return
    cur = n
    ap.play(n, blend, spd)

## ท่าครั้งเดียว (ฟัน/โดนตี/ตาย) ยืดหดความเร็วให้จบใน dur วินาที
func action(n: String, dur: float = 0.0) -> void:
    if not ap.has_animation(n):
        return
    var ln := ap.get_animation(n).length
    var spd := 1.0
    if dur > 0.0:
        spd = ln / dur
    cur = n
    ap.play(n, 0.08, spd)
    ap.seek(0.0, true)
    act_t = dur if dur > 0.0 else ln
    if n.begins_with("Death"):
        dead = true

func revive() -> void:
    end_roll()
    dead = false
    act_t = 0.0
    cur = ""
    _play(idle_name, 0.1)

func begin_roll(duration: float) -> void:
    action("Dodge_Forward", duration)
    update_roll(0.0)

func update_roll(progress: float) -> void:
    var u := clampf(progress, 0.0, 1.0)
    var tuck := sin(u * PI)
    roll_pivot.position.y = 0.75 + tuck * 0.25
    roll_pivot.rotation.x = TAU * u
    inst.position.y = -0.75
    inst.scale = base_scale * Vector3(1.0, 1.0 - tuck * 0.3, 1.0)

func end_roll() -> void:
    if roll_pivot == null:
        return
    roll_pivot.transform = Transform3D.IDENTITY
    inst.position = Vector3.ZERO
    inst.scale = base_scale

func animate(delta: float, speed: float) -> void:
    if dead:
        return
    if act_t > 0.0:
        act_t -= delta
        return
    if speed > 4.5:
        _play("Running_A", 0.18, speed / 6.5)
    elif speed > 0.1:
        _play("Walking_A", 0.18, max(0.7, speed / 2.2))
    else:
        _play(idle_name, 0.2)

func _finish_materials(skeleton: Skeleton3D, kind: String) -> void:
    for node in skeleton.get_children():
        if node is MeshInstance3D:
            for surface in node.mesh.get_surface_count():
                var source: Material = node.get_active_material(surface)
                if source is StandardMaterial3D:
                    var material: StandardMaterial3D = source.duplicate()
                    material.roughness = 0.46 if kind == "knight" else 0.86
                    material.metallic = 0.6 if kind == "knight" and not "Head" in node.name else 0.0
                    material.normal_enabled = VisualStyle.normals_enabled()
                    if material.normal_enabled:
                        material.normal_texture = VisualStyle.texture_for("plaster_normal")
                    material.normal_scale = 0.12
                    node.set_surface_override_material(surface, material)

# ---------- ของที่ถือ/สวม (แสดงอุปกรณ์บนตัว) ----------
var _items := {}   # ชื่อ -> MeshInstance3D

func _item_nodes() -> Dictionary:
    if _items.is_empty():
        var sk := inst.get_node("Rig/Skeleton3D")
        for c in sk.get_children():
            if c is BoneAttachment3D:
                for m in c.get_children():
                    _items[String(m.name)] = m
    return _items

## ยืมของจากโมเดลอื่น (เช่น คทาของนักเวท · หน้าไม้ของโจร) มาติดมือขวา/ซ้าย
func borrow_item(kind: String, item: String) -> MeshInstance3D:
    var L := _item_nodes()
    if L.has(item):
        return L[item]
    var ps: PackedScene = _cache.get(kind)
    if ps == null:
        ps = load(FILES[kind])
        _cache[kind] = ps
    var other: Node = ps.instantiate()
    var osk := other.get_node("Rig/Skeleton3D")
    var found: MeshInstance3D = null
    var bone := ""
    for c in osk.get_children():
        if c is BoneAttachment3D:
            for m in c.get_children():
                if String(m.name) == item:
                    found = m
                    bone = c.bone_name
    if found == null:
        other.free()
        return null
    var sk := inst.get_node("Rig/Skeleton3D")
    var att: BoneAttachment3D = null
    for c in sk.get_children():
        if c is BoneAttachment3D and c.bone_name == bone:
            att = c
    if att == null:
        other.free()
        return null
    var dup: MeshInstance3D = found.duplicate()
    other.free()
    att.add_child(dup)
    dup.visible = false
    L[item] = dup
    return dup

## เปิด/ปิดของ 1 ชิ้น · tint = สีวัสดุตามระดับ · glow = เรืองแสง (คุณภาพสูง)
func show_item(item: String, on: bool, tint: Color = Color(0, 0, 0, 0), glow: float = 0.0, mix: float = 0.65) -> void:
    var L := _item_nodes()
    if not L.has(item):
        return
    var m: MeshInstance3D = L[item]
    m.visible = on
    if not on or tint.a <= 0.0:
        return
    for si in m.mesh.get_surface_count():
        var base: Material = m.mesh.surface_get_material(si)
        if base is StandardMaterial3D:
            var mt: StandardMaterial3D = base.duplicate()
            mt.albedo_color = Color(1, 1, 1).lerp(tint, mix)
            mt.metallic = 0.5
            mt.roughness = 0.35
            if glow > 0.0:
                mt.emission_enabled = true
                mt.emission = tint
                mt.emission_energy_multiplier = glow
            m.set_surface_override_material(si, mt)
