extends Node3D
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

func build(o: Dictionary) -> void:
    var kind: String = o.get("model", "rogue")
    var ps: PackedScene = _cache.get(kind)
    if ps == null:
        ps = load(FILES[kind])
        _cache[kind] = ps
    inst = ps.instantiate()
    add_child(inst)
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
    var sc: float = o.get("scale", 1.0)
    inst.scale = Vector3.ONE * 0.92 * sc
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
    dead = false
    act_t = 0.0
    cur = ""
    _play(idle_name, 0.1)

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
