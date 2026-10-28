extends Node3D
## ชาวเมือง (ข้อมูลจริงจาก NPC_DATA ของเกมเว็บ): ยืนประจำที่ หรือเดินวนใกล้จุดของตัวเอง · มีป้ายชื่อ · คุยได้

var town
var body: Node3D
var npc_name := ""
var lines: Array = []
var fixed := true
var home := Vector3.ZERO
var radius := 2.0
var target := Vector3.ZERO
var wait := 0.0
var heading := 0.0
var speed := 1.4
var talk_t := 0.0

func setup(t, d: Dictionary, ls: Array) -> void:
    town = t
    npc_name = d.name
    lines = ls
    fixed = d.fixed
    radius = float(d.r) if d.get("r") != null else 1.5
    position = town.tw(float(d.x), float(d.y))
    home = position
    body = Node3D.new()
    body.set_script(load("res://scripts/model.gd"))
    add_child(body)
    var shirt := Color.html(d.c) if d.get("c") else Color(0.5, 0.4, 0.3)
    var n: String = d.name
    var o := {"model": "rogue", "tint": shirt, "idle": "Unarmed_Idle"}
    if n == "ทหารยาม":
        o = {"model": "knight", "keep": ["1H_Sword", "Round_Shield", "Knight_Helmet", "Knight_Cape"], "idle": "Idle"}
    elif n == "นักบวชแห่งแสง" or n == "ปรมาจารย์อาชีพ":
        o = {"model": "mage", "keep": ["2H_Staff", "Mage_Hat", "Mage_Cape"], "tint": shirt, "idle": "Idle"}
    elif n == "คุณยาย":
        o = {"model": "mage", "tint": shirt, "idle": "Unarmed_Idle"}
    elif n == "ช่างตีเหล็ก" or n.begins_with("บอริน"):
        o = {"model": "barbarian", "keep": ["1H_Axe"], "idle": "Idle"}
    elif n.begins_with("เด็ก"):
        o = {"model": "rogue", "tint": shirt, "scale": 0.7, "idle": "Unarmed_Idle"}
    elif n == "ชาวนา" or n == "ลุงขายผัก" or n == "นักเดินทาง":
        o = {"model": "hooded", "tint": shirt, "idle": "Unarmed_Idle"}
    elif n == "ทหารฝึก" or n.find("ฝึก") >= 0:
        o = {"model": "barbarian", "keep": ["1H_Axe", "Round_Shield"], "idle": "Idle"}
    body.build(o)
    var l := Label3D.new()
    l.text = n
    l.font = town.font
    l.font_size = 40
    l.pixel_size = 0.011
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.outline_size = 10
    l.outline_modulate = Color(0, 0, 0, 0.85)
    l.modulate = Color(1, 1, 0.8)
    l.position = Vector3(0, 2.75 * (0.8 if n.begins_with("เด็ก") else 1.0), 0)
    add_child(l)
    wait = randf_range(0.0, 3.0)
    target = position
    heading = 0.0

func face_to(p: Vector3) -> void:
    var d := p - global_position
    heading = atan2(d.x, d.z)
    body.rotation.y = heading
    talk_t = 4.0

func _process(delta: float) -> void:
    var spd := 0.0
    if talk_t > 0.0:
        talk_t -= delta
    elif not fixed:
        if wait > 0.0:
            wait -= delta
        else:
            var d := Vector3(target.x - position.x, 0, target.z - position.z)
            if d.length() < 0.2:
                wait = randf_range(2.0, 6.0)
                for i in 8:
                    var a := randf() * TAU
                    var r: float = randf() * radius * 2.0
                    var p := home + Vector3(cos(a) * r, 0, sin(a) * r)
                    if not town.blocked(p.x, p.z):
                        target = p
                        break
            else:
                var dir := d.normalized()
                var nx := position + dir * speed * delta
                if town.blocked(nx.x + dir.x * 0.4, nx.z + dir.z * 0.4):
                    target = position
                else:
                    position = nx
                    spd = speed
                    heading = lerp_angle(heading, atan2(dir.x, dir.z), min(1.0, delta * 8.0))
                    body.rotation.y = heading
    body.animate(delta, spd * 1.8)
