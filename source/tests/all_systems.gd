extends SceneTree
## เทสทุกระบบแบบผู้เล่น (เมือง · ร้าน · คุย · เดิน/หาทาง · ทุ่งหญ้า · เก็บของ · สไลม์ · ตี · ดรอป · EXP · เลเวล · ตาย/ฟื้น · มือถือ)
## รัน: godot --headless --path source --script res://tests/all_systems.gd -- --mobile
## ผ่าน = บรรทัดสุดท้าย "ALL failures=0" · พัง = บรรทัด "FAIL: ..." บอกว่าระบบไหน
var failures := 0
var checks := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("FAIL: " + message)

func tick(world: Node, n: int, dt: float = 1.0 / 30.0) -> void:
    for i in n:
        world.player._process(dt)
        world.field._process(dt)
        for s in world.field.slimes:
            if is_instance_valid(s):
                s._process(dt)

func path_ok(world: Node, pth: PackedVector3Array) -> bool:
    if pth.size() == 0:
        return false
    for p in pth:
        if world.blocked(p.x, p.z):
            return false
    return true

func _run() -> void:
    var marker := FileAccess.open("user://startup_state.json", FileAccess.WRITE)
    marker.store_string(JSON.stringify({"loading": false, "stage": "all_systems"}))
    marker.close()
    var boot: Node = load("res://startup.tscn").instantiate()
    root.add_child(boot)
    for frame in 400:
        await process_frame
        if current_scene != null and current_scene.get("world_loaded") == true:
            break
    var world: Node = current_scene
    check(world != null and world.get("world_loaded") == true, "โหลดเกมจนจบ")
    if world == null or world.get("world_loaded") != true:
        print("ALL failures=%d" % failures)
        quit(1)
        return
    world.process_mode = Node.PROCESS_MODE_DISABLED
    var p: Node = world.player
    var f: Node = world.field

    # ---------- เมือง ----------
    check(world.TD.shops.size() == 15, "ร้านค้า/แผงในเมืองครบ 15 ตามข้อมูลเกม 2D ได้ %d" % world.TD.shops.size())
    check(world.npcs.size() == 19, "NPC ครบ 19")
    check(world.doors.size() > 0, "มีประตูร้าน")
    world.open_shop("gear")
    check(world.ui_shop.visible, "เปิดหน้าร้านอาวุธได้")
    world.ui_shop.visible = false
    world._talk(world.npcs[0])
    check(world.ui_dialog.visible and world.ui_dtext.text.length() > 0, "คุยกับ NPC ได้")
    world.ui_dialog.visible = false
    var spawn: Vector3 = world.tw(world.SPAWN.x, world.SPAWN.y)
    check(not world.blocked(spawn.x, spawn.z), "จุดเกิดเดินได้")
    var d0: Dictionary = world.doors[0]
    var door_w: Vector3 = world.tw(d0.p.x, d0.p.y)
    check(path_ok(world, world.find_path(spawn, door_w)), "หาทางจากจุดเกิดไปประตูร้านได้ ไม่ทะลุกำแพง")

    # ---------- ทุ่งหญ้า (ผังเกม 2D) ----------
    check(world.frows.size() == 44 and (world.frows[0] as String).length() == 60, "แผนที่ทุ่ง 60×44")
    check(world.FD.trees.size() > 50, "ต้นไม้ในทุ่งตามผังเกม 2D")
    var water := Vector2i(-1, -1)
    var tree := Vector2i(-1, -1)
    var grass_far := Vector2i(-1, -1)
    for y in world.FH:
        for x in world.FW:
            var t: int = world.ftile(x, y)
            if t == world.F_WATER and water.x < 0:
                water = Vector2i(x, y)
            if t == world.F_TREE and tree.x < 0:
                tree = Vector2i(x, y)
            if t == world.F_GRASS and x < 12 and grass_far.x < 0 and y > 4 and y < 10:
                grass_far = Vector2i(x, y)
    var wpos: Vector3 = world.fw(water.x + 0.5, water.y + 0.5)
    var tpos: Vector3 = world.fw(tree.x + 0.5, tree.y + 0.5)
    var gpos: Vector3 = world.fw(grass_far.x + 0.5, grass_far.y + 0.5)
    check(world.blocked(wpos.x, wpos.z), "น้ำเดินไม่ได้")
    check(world.blocked(tpos.x, tpos.z), "ต้นไม้เดินทะลุไม่ได้")
    check(not world.blocked(gpos.x, gpos.z), "หญ้าเดินได้")
    check(world.ground_y(wpos.x, wpos.z) < -0.5, "บ่อน้ำเป็นแอ่ง")
    check(abs(world.ground_y(gpos.x, gpos.z)) < 0.2, "พื้นหญ้าราบ")
    var to_field: PackedVector3Array = world.find_path(spawn, gpos)
    check(path_ok(world, to_field), "หาทางจากเมืองผ่านประตูตะวันตกไปทุ่งไกลได้ (%d จุด)" % to_field.size())
    var back: PackedVector3Array = world.find_path(gpos, spawn)
    check(path_ok(world, back), "หาทางจากทุ่งกลับเข้าเมืองได้")
    # เดินตามทางจริงจนถึง (ทดสอบชนกำแพง/ติด)
    p.position = spawn
    p.set_path(to_field)
    tick(world, 30 * 60)
    check(Vector2(p.position.x - gpos.x, p.position.z - gpos.z).length() < 1.5, "เดินจากเมืองไปถึงทุ่งไกลจริง (ห่าง %.1f)" % Vector2(p.position.x - gpos.x, p.position.z - gpos.z).length())

    # ---------- สไลม์ ----------
    var alive := 0
    var bad_pos := 0
    var bad_lv := 0
    for s in f.slimes:
        if is_instance_valid(s) and not s.dead:
            alive += 1
            if world.blocked(s.position.x, s.position.z) or not f.in_field(s.position.x, s.position.z):
                bad_pos += 1
    check(alive == 16, "สไลม์ 16 ตัว (ได้ %d)" % alive)
    check(bad_pos == 0, "สไลม์ไม่อยู่ในน้ำ/ต้นไม้/นอกทุ่ง (ผิด %d)" % bad_pos)
    check(f.lv_at(world.fw(55, 20).x) == 1 and f.lv_at(world.fw(3, 20).x) == 5, "เลเวลสไลม์ตามระยะ (ใกล้เมือง 1 · ไกลสุด 5)")

    # ---------- เก็บหิน/กิ่งไม้ ----------
    check(f.pickups.size() == 34, "หิน/กิ่งไม้บนทุ่ง 34 ชิ้น (ได้ %d)" % f.pickups.size())
    var q: Dictionary = f.pickups[0]
    var before_items: int = p.stone + p.wood
    p.position = Vector3(q.n.position.x, 0, q.n.position.z)
    f._update_world(0.016)
    check(p.stone + p.wood == before_items + 1, "เดินทับแล้วเก็บหิน/ไม้ได้")
    p.position = f.portal_pos
    f._update_world(0.016)
    check(world.prompt.text.find("ประตูมิติ") >= 0, "เดินใกล้ประตูมิติมีข้อความ")

    # ---------- ตี · ดรอป · EXP ----------
    var stand: Vector3 = world.fw(55.5, 22.5)
    p.position = stand
    p.heading = 0.0
    p.body.rotation.y = 0.0
    var sl: Node = f.slimes[0]
    sl.position = stand + Vector3(0, 0, 1.3)
    sl.lv = 1
    sl.hp = 3
    sl.max_hp = 3
    var xp0: int = p.xp + p.lv * 100000
    var coins0: int = p.coins
    p.set_attack_held(true)
    for i in 90:
        sl.position = stand + Vector3(0, 0, 1.3)
        p._process(1.0 / 30.0)
        f._process(1.0 / 30.0)
        if sl.dead:
            break
    p.set_attack_held(false)
    check(sl.dead, "กดค้างตีสไลม์ Lv.1 จนแตก")
    check(p.xp + p.lv * 100000 > xp0, "ได้ EXP จากสไลม์")
    check(f.drops.size() > 0, "สไลม์แตกแล้วมีของดรอป")
    p.position = stand + Vector3(0, 0, 1.3)
    tick(world, 90)
    check(p.coins > coins0, "เดินใกล้แล้วดูดเหรียญเข้ากระเป๋า")
    check(Vector2(p.position.x - stand.x, p.position.z - stand.z - 1.3).length() < 0.01, "ยืนเก็บของไม่เคลื่อนที่")

    # ---------- โดนตี · ไม่กระเด็น · ตาย/ฟื้น ----------
    p.iframe = 0.0
    p.hp = 100.0
    var pos0: Vector3 = p.position
    p.hurt_by({"lv": 1})
    check(p.hp == 96.0, "สไลม์ Lv.1 ตีเลือด -4")
    check(p.kx == 0.0 and p.kz == 0.0 and p.position == pos0, "โดนตีไม่กระเด็น")
    p.iframe = 0.0
    p.hp = 1.0
    p.hurt_by({"lv": 1})
    check(p.dead, "เลือดหมดแล้วล้ม")
    tick(world, 100)
    check(not p.dead and p.hp == p.max_hp, "ฟื้นเลือดเต็ม")
    check(p.position.distance_to(world.tw(7.5, 23.5)) < 0.1, "ฟื้นที่วิหารแห่งแสง")

    # ---------- เลเวลอัป ----------
    var lv0: int = p.lv
    var sp0: int = p.sp
    p.gain_xp(p.need(p.lv) - p.xp)
    check(p.lv == lv0 + 1 and p.sp == sp0 + 3, "EXP เต็มแล้วเลเวลอัป + แต้มสเตตัส 3")

    # ---------- มือถือ ----------
    if world.mobile != null:
        var m: Node = world.mobile
        var vs: Vector2 = m.root.get_viewport_rect().size
        var t1 := InputEventScreenTouch.new()
        t1.index = 3
        t1.pressed = true
        t1.position = Vector2(vs.x * 0.15, vs.y * 0.7)
        m._input(t1)
        var d1 := InputEventScreenDrag.new()
        d1.index = 3
        d1.position = t1.position + Vector2(50, 0)
        d1.relative = Vector2(50, 0)
        m._input(d1)
        check(m.joy.x > 0.5, "มือถือ: ลากจอยแล้วมีทิศเดิน")
        t1.pressed = false
        m._input(t1)
        check(m.joy == Vector2.ZERO, "มือถือ: ปล่อยจอยแล้วหยุด")
        var t2 := InputEventScreenTouch.new()
        t2.index = 4
        t2.pressed = true
        t2.position = m.atk.position + m.atk.size * 0.5
        p.at = -1.0
        p.dash_t = 0.0
        m._input(t2)
        check(p.at >= 0.0 or p.attack_held, "มือถือ: กดปุ่มตีแล้วตี")
        t2.pressed = false
        m._input(t2)
        p.attack_held = false
    else:
        check(false, "ต้องรันด้วย --mobile เพื่อเทสปุ่มมือถือ")

    print("ALL checks=%d failures=%d" % [checks, failures])
    quit(1 if failures > 0 else 0)
