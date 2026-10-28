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

    # ---------- สเตตัส · หน้าตัวละคร ----------
    var lvA: int = p.lv
    var hpA: int = p.max_hp
    var spA: int = p.sp
    p.gain_xp(p.need(p.lv) - p.xp + p.need(p.lv + 1))
    check(p.lv == lvA + 2 and p.sp == spA + 6, "ขึ้น 2 เลเวลรวดได้แต้ม 6")
    check(p.max_hp == hpA + 30, "เลเวลอัปเลือดสูงสุด +15/เลเวล (ได้ %d จาก %d)" % [p.max_hp, hpA])
    var hpB: int = p.max_hp
    var mpB: int = p.max_mp
    check(p.stat_add("vit", 2) == 2 and p.max_hp == hpB + 24 and p.stats.vit == 2, "อัป VIT +2 เลือดสูงสุด +24")
    check(p.stat_add("int", 1) == 1 and p.max_mp == mpB + 6, "อัป INT +1 มานาสูงสุด +6")
    var str0: int = p.atk()
    p.stat_add("str", 1)
    check(p.atk() == str0 + 1, "อัป STR +1 โจมตี +1")
    var spC: int = p.sp
    p.sp = 0
    check(p.stat_add("agi", 1) == 0, "ไม่มีแต้มอัปไม่ได้")
    p.sp = spC
    world.toggle_char()
    check(world.ui_char.visible, "เปิดหน้าตัวละครได้")
    world.toggle_char()

    # ---------- เซฟ/โหลด ----------
    p.save_path = "user://test_save.json"
    p.save_enabled = true
    p.coins = 321
    p.inv_add("hpp", 2)
    p.weapon = "sword0"
    p.stats.agi = 7
    var lvS: int = p.lv
    check(p.save_game(), "เซฟเกมได้")
    p.coins = 0
    p.inv = {}
    p.weapon = ""
    p.stats.agi = 0
    p.lv = 1
    check(p.load_game(), "โหลดเซฟได้")
    check(p.coins == 321 and p.inv_count("hpp") == 2 and p.weapon == "sword0" and p.stats.agi == 7 and p.lv == lvS, "โหลดแล้วเหรียญ/ของ/อาวุธ/สเตตัส/เลเวลกลับมาครบ")
    check(p.max_hp == 100 + (p.lv - 1) * 15 + p.stats.vit * 12, "โหลดแล้วคำนวณเลือดสูงสุดใหม่ถูก")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.json"))
    p.save_enabled = false

    # ---------- ร้านค้า · กระเป๋า ----------
    p.weapon = ""
    p.weapon_tier = 0
    p.inv = {}
    var gear: Dictionary = world.shops_by_id["gear"]
    var sword_it: Dictionary = {}
    for it in gear.buy:
        if it.id == "g_sword0":
            sword_it = it
    p.coins = 10
    check(world.shop_buy(sword_it).find("ไม่พอ") >= 0 and p.weapon == "", "ร้าน: เหรียญไม่พอซื้อไม่ได้")
    p.coins = 100
    var atk_before: int = p.atk()
    world.shop_buy(sword_it)
    check(p.weapon == "sword0" and p.coins == 75, "ร้าน: ซื้อดาบหิน 25 เหรียญแล้วใส่ทันที")
    check(p.atk() == atk_before, "ร้าน: ดาบหินธรรมดาโจมตี +0 ตามเกม 2D")
    p.weapon_tier = 2
    check(p.atk() == atk_before + 3, "ดาบระดับ 2 โจมตี +3 ตาม SWATK")
    p.weapon_tier = 0
    var pot: Dictionary = world.shops_by_id["potion"]
    var hpp_it: Dictionary = {}
    for it in pot.buy:
        if it.id == "buyhpp":
            hpp_it = it
    world.shop_buy(hpp_it)
    check(p.inv_count("hpp") == 1 and p.coins == 45, "ร้านยา: ซื้อยาเลือดเข้ากระเป๋า")
    p.hp = 10.0
    p.use_item("hpp")
    check(p.hp == 70.0 and p.inv_count("hpp") == 0, "กระเป๋า: ใช้ยาเลือด +60")
    var phx := false
    for it in pot.buy:
        if it.id == "phoenix":
            phx = world.Items.can_buy("phoenix")
    check(phx, "ร้านยา: ขนนกฟีนิกซ์ขายได้")
    p.inv_add("phoenix", 1)
    p.iframe = 0.0
    p.hp = 1.0
    p.hurt_by({"lv": 1})
    check(not p.dead and p.hp == p.max_hp and p.inv_count("phoenix") == 0, "ขนนกฟีนิกซ์: ล้มแล้วฟื้นทันที")
    p.gel = 3
    p.wood = 2
    var c0: int = p.coins
    world.shop_sell("gel", 2, -1)
    world.shop_sell("wood", 2, 1)
    check(p.gel == 0 and p.wood == 1 and p.coins == c0 + 8, "ร้านชำ: ขายเจลหมด + ไม้ 1 ได้เหรียญถูก")
    check(world.shop_sell("gel", 2, 1) == "", "ขายของที่ไม่มีไม่ได้")
    world.open_shop("store")
    check(world.ui_shop.visible and world.cur_shop == "store", "เปิดร้านชำมีปุ่มซื้อขาย")
    world.ui_shop.visible = false
    p.inv_add("scroll", 1)
    p.position = world.tw(10, 20)
    check(p.use_item("scroll").find("นอกเมือง") >= 0 and p.inv_count("scroll") == 1, "ม้วนวาปใช้ในเมืองไม่ได้")
    p.position = gpos
    p.use_item("scroll")
    check(p.inv_count("scroll") == 0 and not world.in_field_rect(p.position.x, p.position.z, 0.0), "ม้วนวาปจากทุ่งกลับเมือง")
    world.toggle_bag()
    check(world.ui_bag.visible, "เปิดกระเป๋าได้")
    world.toggle_bag()
    check(not world.ui_bag.visible, "ปิดกระเป๋าได้")

    # ---------- ตัดไม้ ----------
    var small = null
    var edge = null
    for tr in f.trees:
        if tr.border and edge == null:
            edge = tr
        if not tr.border and tr.sz == 0 and small == null:
            var ok_spot := false
            for o in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
                if not world.ftile_solid(world.ftile(tr.tx + o.x, tr.ty + o.y)):
                    ok_spot = true
            if ok_spot:
                small = tr
    check(small != null and edge != null, "มีต้นไม้เล็กและต้นไม้ขอบทุ่งให้ทดสอบ")
    if small != null:
        var stand_t := Vector2i(-1, -1)
        for o in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
            if stand_t.x < 0 and not world.ftile_solid(world.ftile(small.tx + o.x, small.ty + o.y)):
                stand_t = Vector2i(small.tx + o.x, small.ty + o.y)
        p.position = world.fw(stand_t.x + 0.5, stand_t.y + 0.5)
        p.heading = atan2(small.pos.x - p.position.x, small.pos.z - p.position.z)
        p.inv.erase("axe0")
        var hp_t: int = small.hp
        check(f.try_chop(p) and small.hp == hp_t, "ตัดไม้: ไม่มีขวานฟันต้นไม้ไม่ได้")
        p.inv_add("axe0", 1)
        f.try_chop(p)
        check(small.hp == hp_t - 1, "ตัดไม้: มีขวานฟันได้ทีละ 1")
        f.try_chop(p)
        check(not small.alive, "ต้นไม้เล็ก (2 ที) ล้ม")
        var tp: Vector3 = world.fw(small.tx + 0.5, small.ty + 0.5)
        check(not world.blocked(tp.x, tp.z), "ตอไม้เดินผ่านได้")
        var wood0: int = p.wood
        for i in 45:
            f._update_trees(1.0 / 30.0)
        check(f.drops.size() > 0, "ต้นไม้ล้มแล้วไม้หล่น")
        for d in f.drops:
            d.n.position = p.position
            d.t = 1.0
        for i in 30:
            f._process(1.0 / 30.0)
        check(p.wood >= wood0 + 1, "เก็บไม้จากต้นที่ล้มได้")
        p.position = world.tw(10, 20)
        small.regrow = 0.01
        f._update_trees(0.05)
        check(small.alive and world.blocked(tp.x, tp.z), "ต้นไม้งอกใหม่และกลับมาขวางทาง")
    if edge != null:
        p.position = world.fw(clampi(edge.tx, 1, 58) + 0.5, clampi(edge.ty, 1, 42) + 0.5)
        p.heading = atan2(edge.pos.x - p.position.x, edge.pos.z - p.position.z)
        var eh: int = edge.hp
        f.try_chop(p)
        check(edge.hp == eh, "ต้นไม้ขอบทุ่งตัดไม่ได้")

    # ---------- ห้องในร้าน · ร้านทุกร้าน ----------
    var room_ids := ["gear", "potion", "inn", "skill", "store", "guild", "fashion", "bank", "ware", "seal113", "hall"]
    for rid in room_ids:
        var door = null
        for d in world.doors:
            if d.id == rid:
                door = d
        check(door != null, "มีประตู " + rid)
        if door == null:
            continue
        world.in_door = ""
        p.stun = 0.0
        p.dash_t = 0.0
        p.position = world.tw(door.p.x, door.p.y)
        world._process(0.016)
        check(world.room == rid, "เดินชนประตูแล้วเข้าไปในร้าน " + rid)
        check(world.rooms.IW * world.rooms.TS < 32.0, "ห้องขนาดเท่าเกม 2D (ไม่ใหญ่เกิน) " + rid)
        check(not world.blocked(p.position.x, p.position.z), "จุดเกิดในร้านเดินได้ " + rid)
        var k: Node3D = world.rooms.keepers[rid]
        p.position = Vector3(k.position.x, 0, k.position.z + 2.2)
        check(world.rooms.near_counter(), "ยืนหน้าเคาน์เตอร์ได้ " + rid)
        world.ui_shop.visible = false
        world.ui_dialog.visible = false
        p.attack()
        var sh: Dictionary = world.shops_by_id[rid]
        var has_trade: bool = (sh.get("buy", []) as Array).size() > 0 or (sh.get("sell", []) as Array).size() > 0 or rid == "bank"
        if has_trade:
            check(world.ui_shop.visible, "กดตีหน้าเคาน์เตอร์แล้วเปิดหน้าร้าน " + rid)
        else:
            check(world.ui_dialog.visible, "กดตีหน้าเคาน์เตอร์แล้วคุยกับเจ้าของ " + rid)
        world.ui_shop.visible = false
        world.ui_dialog.visible = false
        check(world.blocked(k.position.x, k.position.z + 1.1), "เคาน์เตอร์เดินผ่านไม่ได้ " + rid)
        var o: Vector3 = world.rooms.origin(rid)
        p.position = o + Vector3(13 * world.rooms.TS, 0, 14 * world.rooms.TS - 0.05)
        world.rooms._process(0.016)
        check(world.room == "" and p.position.x < 100.0, "เดินลงทางออกแล้วออกมาข้างนอก " + rid)
        check(not world.blocked(p.position.x, p.position.z), "ออกมายืนตรงที่เดินได้ " + rid)

    # ---------- สกิล · อาหาร · อาวุธยิงไกล · ธนาคาร ----------
    p.coins = 1000
    p.inv = {}
    p.skills = {}
    var sk_shop: Dictionary = world.shops_by_id["skill"]
    for it in sk_shop.buy:
        world.shop_buy(it)
    check(p.skills.size() == 3 and p.coins == 1000 - 60 - 80 - 100, "ร้านสกิล: เรียนครบ 3 สกิลราคาถูก")
    check(world.shop_buy(sk_shop.buy[0]).find("แล้ว") >= 0 and p.coins == 760, "เรียนซ้ำไม่เสียเงิน")
    check(world.mobile == null or world.mobile.skill_btns["fireball"].visible, "มือถือ: ปุ่มสกิลขึ้นหลังเรียน")
    p.position = stand
    p.heading = 0.0
    p.mp = 50.0
    var tgt: Node = f.slimes[1]
    tgt.position = stand + Vector3(0, 0, 6.0)
    tgt.dead = false
    tgt.hp = 99
    tgt.max_hp = 99
    var hp_s: int = tgt.hp
    check(p.use_skill("fireball") == "ลูกไฟ" and p.mp == 42.0, "ใช้ลูกไฟ เสียมานา 8")
    for i in 30:
        tgt.position = stand + Vector3(0, 0, 6.0)
        f._update_projectiles(1.0 / 30.0)
    check(tgt.hp < hp_s, "ลูกไฟพุ่งไปโดนสไลม์")
    check(p.use_skill("fireball").find("ยังไม่พร้อม") >= 0, "สกิลติดคูลดาวน์")
    tgt.position = stand + Vector3(1.5, 0, 0)
    var hp_w: int = tgt.hp
    p.use_skill("whirl")
    check(tgt.hp < hp_w, "ฟันวงพายุโดนรอบตัว")
    p.hp = 10.0
    p.use_skill("heal")
    check(p.hp > 10.0, "เยียวยาฟื้นเลือด")
    tgt.hp = 0
    tgt.dead = true
    var fs: Dictionary = world.shops_by_id["st_bread"]
    for it in fs.buy:
        if it.id == "f_pie":
            world.shop_buy(it)
    var atk_p: int = p.atk()
    p.use_item("f_pie")
    check(p.atk() == atk_p + 4, "กินพายเนื้อ STR +4")
    p._process(181.0)
    check(p.atk() == atk_p, "บัฟหมดเวลาแล้ว STR กลับเท่าเดิม")
    for it in world.shops_by_id["st_farm"].buy:
        check(not world.Items.hidden(str(it.id)) or str(it.note).find("ที่ดิน") >= 0, "ของที่ดินผู้กล้า (เลิกแล้ว) ซ่อน: " + str(it.id))
    var gs: Dictionary = world.shops_by_id["gear"]
    for it in gs.buy:
        if it.id == "g_staff0":
            world.shop_buy(it)
    check(p.weapon == "staff0" and p.is_ranged(), "ซื้อคทาแล้วยิงไกล")
    p.at = -1.0
    var np0: int = f.projectiles.size()
    p.attack()
    check(f.projectiles.size() == np0 + 1, "ถือคทากดตีแล้วยิงลูกเวท")
    p.weapon = ""
    p.at = -1.0
    p.wood = 5
    check(world.bank_move("wood", 3, true) != "" and p.wood == 2 and int(p.bank.wood) == 3, "ธนาคาร: ฝากไม้ 3")
    check(world.bank_move("wood", -1, false) != "" and p.wood == 5 and not p.bank.has("wood"), "ธนาคาร: ถอนหมด")
    p.bank["gel"] = 4
    p.save_path = "user://test_save2.json"
    p.save_enabled = true
    p.save_game()
    p.bank = {}
    p.skills = {}
    p.load_game()
    check(int(p.bank.get("gel", 0)) == 4 and p.skills.size() == 3, "เซฟจำของในธนาคารและสกิลที่เรียน")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save2.json"))
    p.save_enabled = false

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
