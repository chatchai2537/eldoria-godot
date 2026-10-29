extends Node3D
## สัตว์/โครงกระดูกที่ผู้เล่นเรียกมาช่วยสู้ (เนโครแมนเซอร์ · ผู้อัญเชิญสัตว์ — js/056-fix25.js)
## เดินตามผู้เล่น · เจอศัตรูในระยะ 12 → วิ่งไปตี (ใช้ดาเมจของผู้เล่น × ตัวคูณ) · หมดเวลาแล้วหายไป

var town
var kind := "skeleton"
var mult := 0.6
var life := 25.0
var cd := 0.0
var t := 0.0
var vis: Node3D
var target = null
const SPEC := {
    "skeleton": {"spd": 5.0, "range": 1.4, "rate": 1.0, "col": Color(0.88, 0.86, 0.78), "size": 1.0},
    "wolf": {"spd": 7.0, "range": 1.3, "rate": 0.8, "col": Color(0.55, 0.5, 0.45), "size": 1.0},
    "bear": {"spd": 4.0, "range": 1.8, "rate": 1.4, "col": Color(0.42, 0.28, 0.16), "size": 1.4},
    "lion": {"spd": 6.5, "range": 2.0, "rate": 0.9, "col": Color(1.0, 0.82, 0.3), "size": 1.7},
}

func setup(tn, k: String, m: float, sec: float, pos: Vector3) -> void:
    town = tn
    kind = k
    mult = m
    life = sec
    position = pos
    vis = Node3D.new()
    add_child(vis)
    var c: Color = SPEC[k].col
    var mat: Material = town.M(c, 0.6, 0.6 if k == "lion" else 0.0)
    if k == "skeleton":
        town.box(vis, Vector3(0.45, 0.6, 0.28), Vector3(0, 1.0, 0), mat)
        town.box(vis, Vector3(0.34, 0.34, 0.32), Vector3(0, 1.5, 0.04), mat)
        town.box(vis, Vector3(0.36, 0.7, 0.2), Vector3(0, 0.35, 0), mat)
        town.box(vis, Vector3(0.06, 0.08, 0.7), Vector3(0.3, 0.8, 0.35), town.M(Color(0.7, 0.75, 0.8), 0.3))
        town.box(vis, Vector3(0.24, 0.05, 0.05), Vector3(0, 1.54, 0.21), town.M(Color(0.4, 1.0, 0.6), 0.3, 3.0))
    else:
        town.box(vis, Vector3(0.5, 0.45, 1.0), Vector3(0, 0.6, 0), mat)
        town.box(vis, Vector3(0.4, 0.38, 0.42), Vector3(0, 0.85, 0.6), mat)
        town.box(vis, Vector3(0.44, 0.42, 0.85), Vector3(0, 0.2, 0), town.M(c.darkened(0.25), 0.7))
        if k == "lion":
            town.box(vis, Vector3(0.65, 0.6, 0.3), Vector3(0, 0.9, 0.45), town.M(Color(0.9, 0.55, 0.15), 0.6, 0.4))
    vis.scale = Vector3.ONE * float(SPEC[k].size)

func _process(delta: float) -> void:
    life -= delta
    t += delta
    cd -= delta
    if life <= 0.0 or town == null:
        queue_free()
        return
    var p = town.player
    if p.dead:
        queue_free()
        return
    # ไกลผู้เล่นมาก (วาป/เปลี่ยนฉาก) → ตามไปทันที
    if position.distance_to(p.position) > 25.0:
        position = p.position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
    if target == null or not is_instance_valid(target) or target.dead or target.position.distance_to(p.position) > 14.0:
        target = town.field.nearest_slime(position, 12.0)
    var S: Dictionary = SPEC[kind]
    var goal: Vector3 = p.position + Vector3(1.5, 0, 1.0)
    if target != null:
        goal = target.position
    var to := Vector3(goal.x - position.x, 0, goal.z - position.z)
    var d := to.length()
    var stop: float = float(S.range) if target != null else 2.0
    if d > stop:
        var step := to.normalized() * float(S.spd) * delta
        if not town.blocked(position.x + step.x, position.z + step.z):
            position += step
        vis.rotation.y = atan2(to.x, to.z)
        vis.position.y = abs(sin(t * 10.0)) * 0.08
    elif target != null and cd <= 0.0:
        cd = float(S.rate)
        vis.rotation.y = atan2(to.x, to.z)
        town.field.hit_slime(target, p, mult)
    position.y = town.ground_y(position.x, position.z)
