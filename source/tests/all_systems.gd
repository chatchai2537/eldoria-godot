extends SceneTree
## เทสทุกระบบแบบผู้เล่น (เมือง · ร้าน · คุย · เดิน/หาทาง · ทุ่งหญ้า · เก็บของ · สไลม์ · ตี · ดรอป · EXP · เลเวล · ตาย/ฟื้น · มือถือ)
## รัน: godot --headless --path source --script res://tests/all_systems.gd -- --mobile
## ผ่าน = บรรทัดสุดท้าย "ALL failures=0" · พัง = บรรทัด "FAIL: ..." บอกว่าระบบไหน
const Mob = preload("res://scripts/mob.gd")
const Items = preload("res://scripts/items.gd")
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
    # หน้าร้านแบบเกม 2D: แตะของในกระเป๋า → แถบขาย → ปรับจำนวน → ขาย
    p.gel = 12
    var c1: int = p.coins
    world.open_shop("store")
    world.shop_pick("gel")
    world.shop_pick("gel")
    check(world.shop_sel == "gel" and world.shop_qty == 2, "หน้าร้าน: แตะเจลในกระเป๋า 2 ครั้ง = เลือกขาย 2")
    world.shop_qty_add(10)
    check(world.shop_qty == 12, "หน้าร้าน: +10 ไม่เกินที่มี")
    world.shop_qty_add(-1)
    world.shop_sell_ok()
    check(p.gel == 1 and p.coins == c1 + 22 and world.shop_qty == 1, "หน้าร้าน: กดขาย ×11 ได้เหรียญถูก")
    world.shop_qty_add(9999)
    check(world.shop_qty == 1, "หน้าร้าน: ปุ่มทั้งหมด")
    world.close_shop()
    p.gel = 0
    p.inv_add("scroll", 1)
    p.position = world.tw(10, 20)
    check(p.use_item("scroll").find("นอกเมือง") >= 0 and p.inv_count("scroll") == 1, "ม้วนวาปใช้ในเมืองไม่ได้")
    p.position = gpos
    p.use_item("scroll")
    check(p.inv_count("scroll") == 0 and not world.in_field_rect(p.position.x, p.position.z, 0.0), "ม้วนวาปจากทุ่งกลับเมือง")
    world.toggle_bag()
    check(world.ui_bag.visible, "เปิดกระเป๋าได้")
    # 0.31 กระเป๋าแบบช่องเกม 2D: ช่องสวม 7 ช่อง · ของเป็นช่อง 52px · แตะ = การ์ดรายละเอียด · สวม/ถอด/ใช้จากการ์ด
    var slots_of := func() -> Array:
        return world.ui_bag_body.find_children("*", "Button", true, false).filter(func(b): return (b as Button).custom_minimum_size == Vector2(world.SLOT_PX, world.SLOT_PX))
    check(slots_of.call().size() >= 7 + 8, "กระเป๋า: มีช่องสวม 7 + ตารางช่องของ")
    p.inv_add("helm1", 1)
    p.inv_add("hpp", 2)
    world.refresh_bag()
    var hg: Dictionary = {}
    for g0 in p.gear:
        if str(g0.k) == "helm":
            hg = g0
    world._bag_pick({"t": "gear", "g": hg})
    var card_btns: Array = world.ui_bag_body.find_children("*", "PanelContainer", true, false).filter(func(n): return n.has_meta("bag_card"))
    check(card_btns.size() == 1, "กระเป๋า: แตะช่องอุปกรณ์ = การ์ดรายละเอียด")
    for b in card_btns[0].find_children("*", "Button", true, false):
        if (b as Button).text == "สวม":
            (b as Button).pressed.emit()
    check(p.eq.has("helm") and world.bag_sel.is_empty(), "กระเป๋า: กดสวมจากการ์ด")
    world._bag_pick({"t": "eq", "sl": "helm"})
    for b in world.ui_bag_body.find_children("*", "Button", true, false):
        if (b as Button).text == "ถอด":
            (b as Button).pressed.emit()
    check(not p.eq.has("helm"), "กระเป๋า: กดถอดจากการ์ดช่องสวม")
    p.hp = 10.0
    world._bag_pick({"t": "mat", "k": "hpp"})
    for b in world.ui_bag_body.find_children("*", "Button", true, false):
        if (b as Button).text == "ใช้":
            (b as Button).pressed.emit()
            break
    check(p.inv_count("hpp") == 1, "กระเป๋า: กดใช้ยาจากการ์ด")
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
        p.inv_add("axe0", -p.inv_count("axe0"))
        var hp_t: int = small.hp
        check(f.try_chop(p) and small.hp == hp_t, "ตัดไม้: ไม่มีขวานฟันต้นไม้ไม่ได้")
        p.inv_add("axe0", 1)
        f.try_chop(p)
        check(small.hp == hp_t - 1, "ตัดไม้: มีขวานฟันได้ทีละ 1")
        # 0.28: ถือคทา (สายยิงไกล) ก็ตัดไม้ได้ · ขวานโผล่ในมือแทนอาวุธ แล้วกลับเป็นอาวุธเดิม
        var w_keep = p.eq.get("weapon")
        p.weapon = "staff1"
        p.at = -1.0
        p.dead = false
        p.stun = 0.0
        p.dash_t = 0.0
        p.attack()
        var items_now: Dictionary = p.body._item_nodes()
        check(p.tool_t > 0.0 and items_now.has("1H_Axe") and items_now["1H_Axe"].visible and not items_now["2H_Staff"].visible, "ตัดไม้: ขวานโผล่ในมือแทนคทา")
        check(not small.alive, "ต้นไม้เล็ก (2 ที) ล้ม · สายยิงไกลกดตีหน้าต้นไม้ = ตัดไม้")
        p.tool_t = 0.01
        p._process(0.05)
        check(items_now.has("1H_Axe") and not items_now["1H_Axe"].visible and items_now["2H_Staff"].visible, "ตัดไม้เสร็จ: เก็บขวาน คทากลับมา")
        if w_keep == null:
            p.eq.erase("weapon")
        else:
            p.eq["weapon"] = w_keep
        p.update_gear_visual()
        p.at = -1.0
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
        world._update_cam(5.0)
        var ro: Vector3 = world.rooms.origin(rid)
        var cp: Vector3 = world.cam.global_position
        check(cp.y < world.rooms.WALL_H and cp.z < ro.z + world.rooms.IH * world.rooms.TS and cp.x > ro.x and cp.x < ro.x + world.rooms.IW * world.rooms.TS, "กล้องอยู่ในห้อง มีเพดาน/ผนังรอบ " + rid)
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
            check(world.rooms.bubble_text() != "", "กดตีหน้าเคาน์เตอร์แล้วคุยกับเจ้าของ " + rid)
        check(world.rooms.bubble_text() != "", "เจ้าของร้านพูดลอยเหนือหัว (แบบเกม 2D) " + rid)
        check(not world.ui_dialog.visible, "คุยในร้านไม่ใช้กล่องข้อความใหญ่ " + rid)
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
    world.mobile.refresh_skills() if world.mobile != null else null
    check(world.mobile == null or world.mobile.skill_btns[1].visible, "มือถือ: ปุ่มสกิลขึ้นหลังเรียน")
    p.position = stand
    p.heading = 0.0
    p.mp = 50.0
    var tgt: Node = f.slimes[1]
    for other in f.slimes:   # กันสไลม์ตัวอื่นเดินมาขวางทางลูกไฟ (ผลสุ่มเปลี่ยนเมื่อเพิ่มเสียงที่สุ่มแบบ)
        if other != tgt:
            other.position = stand + Vector3(40, 0, 40)
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

    # ---------- ประตูมิติ · เหมือง 5 แห่ง ----------
    var mn: Node = world.mine
    p.dead = false
    p.stun = 0.0
    p.dash_t = 0.0
    p.at = -1.0
    p.hp = p.max_hp
    p.position = world.field.portal_pos + Vector3(0, 0, 2.0)
    world.ui_shop.visible = false
    p.attack()
    check(world.ui_shop.visible and world.cur_shop == "portal", "ประตูมิติ: กดตีแล้วขึ้นเมนูเลือกเหมือง 5 แห่ง")
    world.close_shop()
    for zi in 5:
        var zd: Dictionary = mn.gen(zi)
        var reach := true
        for o in zd.ores:
            if zd.m[o.ty * mn.ZW + o.tx] != mn.FL:
                reach = false
        check(zd.ores.size() > 40 and reach and zd.floor.size() > 400, "เหมือง %d: แผนที่มีพื้น/แร่ครบ" % zi)
        check(zd.m[zd.arena.y * mn.ZW + zd.arena.x] == mn.FL, "เหมือง %d: ลานบอสเดินถึงได้" % zi)
    mn.enter(0)
    check(mn.cur == 0 and not world.blocked(p.position.x, p.position.z), "เข้าเหมืองเหล็ก: ยืนบนพื้นได้")
    check(mn.mobs.size() >= 8, "เหมือง: มีมอนเกิด")
    var stb := Mob.stats(5, "beetle", false, false)
    check(stb.x == 83 and stb.y == 21, "มอนเหมือง: เลือด/ตีตามสูตรเกม 2D + fix119 (ด้วง Lv5 = 83/21)")
    var lvcap := true
    for mmb in mn.mobs:
        if not mmb.boss and mmb.lv > max(5, p.lv + 2):
            lvcap = false
    check(lvcap, "มอนเหมือง: เลเวลไม่เกินผู้เล่น +2 (fix119)")
    mn._process(0.2)
    check(mn.boss != null and mn.boss.boss, "เหมือง: บอสเกิดที่ลานบอส")
    # ขุดแร่
    var zd0: Dictionary = mn.data[0]
    var ore: Dictionary = {}
    for o in zd0.ores:
        if o.kind == "stone" or o.kind == "iron":
            ore = o
            break
    var ow: Vector3 = mn.tile_w(0, ore.tx, ore.ty)
    p.position = ow + Vector3(0, 0, 1.6)
    p.heading = PI
    p.inv_add("pick0", -p.inv_count("pick0"))
    check(mn.ore_in_front(p) == ore, "ขุดแร่: หันหน้าเข้าก้อนแร่")
    mn.try_mine(p)
    check(ore.hp == ore.max, "ขุดแร่: ไม่มีที่ขุดแร่ ขุดไม่ได้")
    p.inv_add("pick0", 1)
    var tries := 0
    while ore.alive and tries < 20:
        mn.try_mine(p)
        tries += 1
    check(not ore.alive and tries == ore.max, "ขุดแร่: ตี %d ครั้งแร่แตก" % ore.max)
    check(not world.blocked(ow.x, ow.z), "ขุดแร่: แร่แตกแล้วเดินผ่านได้")
    var have0: int = p.inv_count(str(mn.OREK[ore.kind].drop))
    tick(world, 60)
    check(p.inv_count(str(mn.OREK[ore.kind].drop)) > have0, "ขุดแร่: เก็บแร่เข้ากระเป๋า")
    ore.regen = 0.01
    p.position = ow + Vector3(0, 0, 6.0)
    mn._process(0.05)
    check(ore.alive and ore.hp == ore.max, "ขุดแร่: แร่งอกใหม่")
    p.position = ow + Vector3(0, 0, 1.6)
    p.heading = PI
    p.at = -1.0
    p.attack()
    var pick_n = p.body._item_nodes().get("Tool_Pick")
    check(ore.hp < ore.max and pick_n != null and pick_n.visible and p.body.cur == "1H_Melee_Attack_Chop", "ขุดแร่: พลั่วขุดโผล่ในมือ ท่าสับ")
    p.tool_t = 0.01
    p._process(0.05)
    check(not pick_n.visible, "ขุดแร่เสร็จ: เก็บพลั่ว")
    p.at = -1.0
    # แร่ทองแดงต้องใช้ที่ขุดระดับสูงกว่า
    mn.leave(false)
    mn.enter(1)
    var cu: Dictionary = {}
    for o in mn.data[1].ores:
        if o.kind == "copper":
            cu = o
            break
    p.position = mn.tile_w(1, cu.tx, cu.ty) + Vector3(0, 0, 1.6)
    p.heading = PI
    mn.try_mine(p)
    check(cu.hp == cu.max and world.field.msg.text.find("ต้องใช้") >= 0, "ขุดแร่: ทองแดงต้องใช้ที่ขุดแร่เหล็กขึ้นไป")
    mn.leave(false)
    mn.enter(0)
    mn._process(0.2)
    # ตีมอน (ฟันธรรมดาใช้ระบบเดียวกับสไลม์) · มอนตาย = เหรียญ + EXP
    var mb = null
    for m in mn.mobs:
        if not m.boss:
            mb = m
            break
    mb.hp = 1
    p.position = mb.position + Vector3(0, 0, 1.0)
    p.heading = PI
    var cbefore: int = p.coins
    var xbefore: int = p.xp + p.lv * 100000
    world.field.hit_slime(mb, p, 1.0)
    check(mb.dead and p.coins > cbefore and p.xp + p.lv * 100000 > xbefore, "มอนเหมือง: ตีตายได้เหรียญ + EXP")
    # มอนตีผู้เล่น (ลดด้วยป้องกัน · ไม่กระเด็น) · กลิ้งหลบได้
    var hp0: float = p.hp
    var mpos0: Vector3 = p.position
    p.iframe = 0.0
    p.hurt_mob(20, "ทดสอบ")
    check(p.hp < hp0 and p.position == mpos0, "มอนเหมือง: โดนตีเลือดลด ไม่กระเด็น")
    var hp1: float = p.hp
    p.iframe = 0.5
    p.hurt_mob(20, "ทดสอบ")
    check(p.hp == hp1, "มอนเหมือง: ช่วงอมตะ (กลิ้ง) ไม่โดน")
    p.hp = p.max_hp
    # บอสทุบพื้น: วงเตือนก่อนโดน
    var bs = mn.boss
    bs.st = "slamWU"
    bs.stt = 0.5
    bs.tg = bs.position
    bs.aggro = true
    p.position = bs.position + Vector3(0, 0, 20.0)
    bs._process(0.1)
    check(bs.ring.visible, "บอส: มีวงเตือนก่อนทุบพื้น")
    # ออกทางวงเวท
    p.position = mn.exit_pos(0)
    mn._process(0.05)
    check(mn.cur == -1 and p.position.distance_to(world.field.portal_pos) < 4.0, "ออกจากเหมืองทางวงเวท กลับมาหน้าประตูมิติ")
    check(world.field.extra.is_empty() and mn.mobs.is_empty(), "ออกจากเหมืองแล้วมอนหายหมด")
    # ตายในเหมือง → ฟื้นที่วิหาร
    mn.enter(0)
    p.hp = 1
    p.iframe = 0.0
    p.inv.erase("phoenix")
    p.hurt_mob(999, "ทดสอบ")
    check(p.dead, "ตายในเหมือง")
    p._revive()
    check(mn.cur == -1 and p.position.distance_to(world.tw(7.5, 23.5)) < 0.1, "ตายในเหมืองแล้วฟื้นที่วิหารในเมือง")

    # ---------- คราฟ · ตีบวก · ซ่อม · ปรุงยา ----------
    var cr: Node = world.craft
    p.dead = false
    p.wood = 9
    check(cr.burn_coal(-1).find("+4") >= 0 and p.inv_count("coal") >= 4 and p.wood == 1, "เตาหลอม: เผาไม้ 8 ได้ถ่าน 4")
    p.inv_add("iron", 6 - p.inv_count("iron"))
    var c0n: int = p.inv_count("coal")
    cr.smelt(1, -1)
    check(p.inv_count("ingot") >= 3 and p.inv_count("iron") == 0 and p.inv_count("coal") == c0n - 3, "เตาหลอม: แร่เหล็ก 6 + ถ่าน 3 = แท่งเหล็ก 3")
    check(cr.smelt(1, 1).find("ไม่พอ") >= 0 or cr.smelt(1, 1).find("ถ่าน") >= 0, "เตาหลอม: แร่หมดหลอมไม่ได้")
    check(cr.roll_quality("helm", 0.5) == 3 and cr.roll_quality("helm", 5.0) == 2 and cr.roll_quality("helm", 20.0) == 1 and cr.roll_quality("helm", 50.0) == 0, "คราฟ: สุ่มคุณภาพ แดง/ม่วง/เขียว/ขาว ตามโอกาส")
    check(cr.roll_quality("pick", 0.5) == 0, "คราฟ: ขวาน/ที่ขุดไม่สุ่มคุณภาพ")
    var q0 := {"k": "sword", "t": 1, "q": 0, "e": 0}
    var q3 := {"k": "sword", "t": 1, "q": 3, "e": 0}
    check(Items.inst_stat(q3) > Items.inst_stat(q0), "คราฟ: คุณภาพสูงสเตตัสสูงกว่า")
    # ตำราช่าง (SMQ): ต้องปลดล็อกระดับก่อนคราฟ
    var sm_lv0: int = p.lv
    p.smith_u = 0
    p.smith_q = 0
    var sm_ing0: int = p.inv_count("ingot")
    p.inv_add("ingot", 10)
    p.wood = 10
    check(cr.craft("helm", 1).contains("ตำรา"), "ตำราช่าง: ยังไม่ได้ตำราเหล็ก คราฟเหล็กไม่ได้")
    p.lv = 3
    check(cr.smith_act().contains("Lv.5") and not cr.smith_avail(), "ตำราช่าง: เลเวลไม่ถึงยังไม่สอน")
    p.lv = 6
    check(cr.smith_avail() and cr.smith_label().begins_with("!"), "ตำราช่าง: ถึงเลเวลแล้วขึ้นเครื่องหมาย !")
    check(cr.smith_act().contains("ปีกค้างคาว") and p.smith_q == 1, "ตำราช่าง: รับเควส (บอกของที่ต้องหา)")
    check(cr.smith_act().contains("ยังขาด") and p.smith_u == 0, "ตำราช่าง: ของไม่ครบยังไม่ปลด")
    p.inv_add("wing", 4)
    var sm_ing: int = p.inv_count("ingot")
    check(cr.smith_act().contains("เหล็กได้แล้ว") and p.smith_u == 1 and p.inv_count("ingot") == sm_ing - 6 and p.inv_count("wing") == 0, "ตำราช่าง: ส่งของครบ ปลดล็อกเหล็ก (ใช้แท่งเหล็ก 6 ปีก 4)")
    world.open_shop("gear")
    var sm_has := false
    for sm_b in world.ui_shop_body.find_children("*", "Button", true, false):
        if (sm_b as Button).text.contains("ตำราช่าง"):
            sm_has = true
    check(sm_has, "ตำราช่าง: ปุ่มในหน้าร้านอาวุธ")
    cr.open_smith()
    check(world.cur_shop == "altar" or world.ui_shop.visible, "ตำราช่าง: เปิดหน้าตำรา")
    world.close_shop()
    p.lv = sm_lv0
    p.inv_take("ingot", p.inv_count("ingot"))
    p.inv_add("ingot", sm_ing0)
    p.inv_add("ingot", 10)
    p.wood = 10
    var gear_n: int = p.gear.size()
    var cm: String = cr.craft("pick", 1)
    check(p.gear.size() == gear_n + 1 and p.inv_count("pick1") >= 1 and cm.find("สำเร็จ") >= 0, "ทั่ง: คราฟที่ขุดแร่เหล็ก")
    cr.craft("helm", 1)
    var helm: Dictionary = p.gear.back()
    var dfa: int = p.def()
    p.equip(helm)
    check(p.eq.has("helm") and p.def() > dfa, "สวมหมวกแล้วป้องกันเพิ่ม")
    cr.craft("neck", 1)
    var hp0m: int = p.max_hp
    p.equip(p.gear.back())
    check(p.max_hp > hp0m, "สวมสร้อยแล้วเลือดสูงสุดเพิ่ม")
    p.inv_add("ingot", -p.inv_count("ingot"))
    check(cr.craft("chest", 1).find("ไม่พอ") >= 0, "ทั่ง: วัสดุไม่พอคราฟไม่ได้")
    # ตีบวก
    p.coins = 100000
    p.inv_add("estone", 40)
    var at0: int = Items.inst_stat(helm)
    cr.enhance(helm, 0.0)
    check(int(helm.e) == 1 and Items.inst_stat(helm) > at0 and p.coins == 100000 - 100, "ตีบวก: สำเร็จ +1 ค่าเพิ่ม เสีย 100 เหรียญ")
    cr.enhance(helm, 99.9)
    check(int(helm.e) == 1 and not helm.b, "ตีบวก: พลาดต่ำกว่า +5 ของไม่แตก")
    helm.e = 5
    p.inv_add("bless", 1)
    cr.enhance(helm, 99.9)
    check(int(helm.e) == 5 and not helm.b and p.inv_count("bless") == 0, "ตีบวก: พลาด +5 มีหินอวยพร ของไม่แตก")
    cr.enhance(helm, 99.9)
    check(helm.b and not p.eq.has("helm") and p.gear.has(helm), "ตีบวก: พลาด +5 ไม่มีหินอวยพร ของแตก ถอดเข้ากระเป๋า")
    check(p.equip(helm).find("แตก") >= 0 and not p.eq.has("helm"), "ของแตกใส่ไม่ได้")
    check(cr.enhance(helm, 0.0).find("แตก") >= 0, "ของแตกตีบวกไม่ได้")
    p.inv_add("ingot", 1)
    cr.repair(helm)
    check(not helm.b and p.equip(helm).find("สวม") >= 0, "ซ่อมแล้วใส่ได้")
    # ปรุงยา
    p.inv_add("bottle", 1)
    p.gel = 1
    p.wood = 1
    var hpp0: int = p.inv_count("hpp")
    cr.brew("hpp")
    check(p.inv_count("hpp") == hpp0 + 1 and p.gel == 0, "หม้อปรุงยา: ปรุงยาเลือด")
    # สถานีในร้าน
    world.ui_shop.visible = false
    world.in_door = ""
    world.rooms.enter("gear")
    var fpos: Vector3 = world.rooms.station_pos("gear", 0)
    p.position = fpos + Vector3(1.6, 0, 0)
    p.stun = 0.0
    p.dash_t = 0.0
    p.attack()
    check(world.ui_shop.visible and world.cur_shop == "stn_furnace", "ร้านอาวุธ: กดตีข้างเตาหลอม = เปิดเตาหลอม")
    world.close_shop()
    p.position = world.rooms.station_pos("gear", 1) + Vector3(-1.6, 0, 0)
    p.attack()
    check(world.ui_shop.visible and world.cur_shop == "stn_anvil", "ร้านอาวุธ: กดตีข้างทั่ง = เปิดทั่งตีเหล็ก")
    world.craft.anvil_tab = "enh"
    world.craft.open("anvil")
    world.close_shop()
    world.craft.anvil_tab = "craft"
    world.rooms.leave()
    world.rooms.enter("potion")
    p.position = world.rooms.station_pos("potion", 0) + Vector3(1.6, 0, 0)
    p.attack()
    check(world.cur_shop == "stn_cauldron", "ร้านยา: กดตีข้างหม้อ = เปิดหม้อปรุงยา")
    world.close_shop()
    world.rooms.leave()
    # กิลด์: แลกหินเสริมพลัง
    p.inv_add("core", 2)
    p.inv_add("dust", 2)
    var es0: int = p.inv_count("estone")
    var gx: Dictionary = {}
    for it in world.shops_by_id["guild"].buy:
        if it.id == "gx_estone":
            gx = it
    world.shop_buy(gx)
    check(p.inv_count("estone") == es0 + 1 and p.inv_count("core") == 0, "กิลด์: แลกแกนหินเวท 2 + ผงวิญญาณ 2 = หินเสริมพลัง")
    check(world.shop_buy(gx).find("ไม่พอ") >= 0, "กิลด์: ของไม่พอแลกไม่ได้")
    # ที่ขุดเหล็กขุดทองแดงได้
    mn.enter(1)
    var cu2: Dictionary = {}
    for o in mn.data[1].ores:
        if o.kind == "copper" and o.alive:
            cu2 = o
            break
    p.position = mn.tile_w(1, cu2.tx, cu2.ty) + Vector3(0, 0, 1.6)
    p.heading = PI
    mn.try_mine(p)
    check(cu2.hp < cu2.max, "ที่ขุดแร่เหล็ก (คราฟ) ขุดทองแดงได้")
    # บอสตาย = หินเสริมพลัง (fix31)
    mn._process(0.2)
    var nd: int = world.field.drops.size()
    mn.mob_killed(mn.boss)
    var got_es := false
    for i in range(nd, world.field.drops.size()):
        if world.field.drops[i].k == "estone":
            got_es = true
    check(got_es and mn.boss == null, "บอสเหมืองดรอปหินเสริมพลัง")
    mn.leave(false)
    # เซฟ/โหลดอุปกรณ์ + เซฟรุ่นเก่า
    p.save_enabled = true
    p.save_path = "user://test_save3.json"
    p.save_game()
    var eq_n: int = p.eq.size()
    var g_n: int = p.gear.size()
    var helm_e: int = int(p.eq.helm.e)
    p.eq = {}
    p.gear = []
    p.load_game()
    check(p.eq.size() == eq_n and p.gear.size() == g_n and int(p.eq.helm.e) == helm_e, "เซฟ/โหลด: อุปกรณ์ที่สวม + ในกระเป๋า + ระดับตีบวก")
    var f3 := FileAccess.open("user://test_save3.json", FileAccess.WRITE)
    f3.store_string(JSON.stringify({"v": 1, "lv": 3, "weapon": "sword0", "weapon_tier": 2, "inv": {"axe0": 1, "hpp": 1}}))
    f3.close()
    p.load_game()
    check(p.weapon == "sword2" and p.weapon_tier == 2 and p.inv_count("axe0") == 1 and not p.best_tool("axe").is_empty(), "โหลดเซฟรุ่นเก่า: ดาบ/ขวานแปลงเป็นอุปกรณ์")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save3.json"))
    p.save_enabled = false

    # ---------- อาชีพ (Lv.10) · สกิลอาชีพ · พาสซีฟ ----------
    var cl: Node = world.classes
    p.dead = false
    p.cls = "none"
    p.lv = 9
    p.coins = 1000
    check(cl.pick("sword").find("Lv.10") >= 0 and p.cls == "none", "อาชีพ: ต่ำกว่า Lv.10 เลือกไม่ได้")
    p.lv = 10
    var cvit0: int = p.stat_total("vit")
    var cstr0: int = p.stat_total("str")
    cl.pick("sword")
    check(p.cls == "sword" and p.coins == 1000, "อาชีพ: เลือกนักดาบครั้งแรกฟรี")
    check(p.stat_total("vit") == cvit0 + 5 and p.stat_total("str") == cstr0 + 2 + 3, "นักดาบ: VIT +2+Lv/3 · STR +Lv/5 · พาสซีฟ Lv.10 STR +3")
    world.close_shop()
    check(cl.slot_name(p, 0) == "กระทืบปฐพี" and cl.slot_name(p, 1) == "", "นักดาบ Lv.10: ปลดล็อกสกิลที่ 1 (Lv.5) ยังไม่ปลดสกิลที่ 2 (Lv.15)")
    # ในเมืองใช้ไม่ได้ · ต้องถืออาวุธประจำสาย
    p.position = world.tw(22, 20)
    p.weapon = "staff0"
    check(cl.use_class(0).find("ต้องถือดาบ") >= 0, "สกิลอาชีพ: ต้องถืออาวุธประจำสาย")
    p.weapon = "sword0"
    check(cl.use_class(0).find("ในเมือง") >= 0, "สกิลอาชีพ: ใช้ในเมืองไม่ได้")
    # ในทุ่ง: กระทืบปฐพีโดนสไลม์ + มึนงง
    p.position = world.fw(20.5, 20.5)
    var sl2 := Node3D.new()
    sl2.set_script(load("res://scripts/slime.gd"))
    world.field.add_child(sl2)
    sl2.setup(world.field, 1, p.position + Vector3(1.5, 0, 0))
    sl2.hp = 999
    sl2.max_hp = 999
    world.field.slimes.append(sl2)
    p.mp = p.max_mp
    p.stun = 0.0
    p.dash_t = 0.0
    p.xp = 0
    var mp0: float = p.mp
    var ucr: String = cl.use_class(0)
    check(ucr == "กระทืบปฐพี" and p.mp == mp0 - 15 and cl.cd[0] > 0.0, "นักดาบ: กระทืบปฐพี ใช้มานา 15 + คูลดาวน์")
    check(sl2.hp < 999 and sl2.stun_t > 1.0, "นักดาบ: กระทืบปฐพีโดนรอบตัว + มึนงง")
    var sx0: Vector3 = sl2.position
    sl2._process(0.5)
    check(sl2.position == sx0, "สไลม์มึนงงแล้วไม่ขยับ")
    check(cl.use_class(0).find("ยังไม่พร้อม") >= 0, "สกิลอาชีพ: ติดคูลดาวน์ใช้ซ้ำไม่ได้")
    # เปลี่ยนเป็นนักเวท 500 · สกิลสามจังหวะ
    cl.pick("mage")
    check(p.cls == "mage" and p.coins == 500, "เปลี่ยนอาชีพเสีย 500 เหรียญ")
    world.close_shop()
    p.lv = 15
    p.recalc_stats()
    p.weapon = "staff0"
    p.mp = 999
    p.max_mp = 999
    cl.cd = [0.0, 0.0, 0.0]
    cl.step = 0
    cl.use_class(1)
    check(cl.step == 1 and cl.cd[1] == 0.0, "เวทธาตุสามสาย: จังหวะที่ 1")
    cl.use_class(1)
    cl.use_class(1)
    check(cl.step == 0 and cl.cd[1] > 0.0, "เวทธาตุสามสาย: ครบ 3 จังหวะแล้วติดคูลดาวน์")
    cl.use_class(0)
    check(cl.pers.size() > 0, "วงแหวนเพลิง: มีวงไฟต่อเนื่อง")
    var hpw: int = sl2.hp
    sl2.position = p.position + Vector3(1.0, 0, 0)
    sl2.stun_t = 5.0
    cl._process(0.6)
    check(sl2.hp < hpw, "วงแหวนเพลิง: เผาศัตรูในวงต่อเนื่อง")
    cl.pers.clear()
    check(p.crit_rate() < 0.2, "นักเวทไม่ได้คริของนักธนู")
    sl2.queue_free()
    world.field.slimes.erase(sl2)
    # เซฟอาชีพ
    p.save_enabled = true
    p.save_path = "user://test_save4.json"
    p.save_game()
    p.cls = "none"
    p.load_game()
    check(p.cls == "mage", "เซฟ/โหลด: อาชีพ")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save4.json"))
    p.save_enabled = false
    # ปรมาจารย์อาชีพ: คุยแล้วเปิดเมนู
    for n in world.npcs:
        if n.npc_name == "ปรมาจารย์อาชีพ":
            world._talk(n)
    check(world.ui_shop.visible and world.cur_shop == "class", "คุยกับปรมาจารย์อาชีพแล้วเปิดเมนูเลือกอาชีพ")
    world.close_shop()
    world.ui_dialog.visible = false
    p.cls = "none"
    p.lv = 1
    p.recalc_stats()

    # ---------- เนื้อเรื่อง บทนำ-บท 3 ----------
    var sto: Node = world.story
    sto.reset()
    p.dead = false
    p.cls = "none"
    p.lv = 1
    p.recalc_stats()
    p.position = world.tw(10, 20)
    check(sto.guide_target().distance_to(world.tw(22.0, 9.3)) < 0.1, "เนื้อเรื่อง: ลูกศรชี้ไปปราสาทตอนเริ่ม")
    p.inv_add("sword0", -p.inv_count("sword0"))
    p.weapon = ""
    var cs0: int = p.coins
    world.in_door = ""
    world.rooms.enter("hall")
    var kg: Node3D = world.rooms.keepers["hall"]
    p.position = Vector3(kg.position.x, 0, kg.position.z + 2.2)
    p.stun = 0.0
    p.dash_t = 0.0
    p.attack()
    check(world.cur_shop == "king" and world.ui_shop.visible, "เนื้อเรื่อง: คุยกับพระราชาในท้องพระโรง")
    check(int(sto.S.ch) == 1 and p.coins == cs0 + 50 and p.weapon == "sword0" and p.inv_count("pick0") >= 1, "บทนำ: ได้รางวัล ดาบ/ขวาน/ที่ขุด + 50 เหรียญ แล้วไปบทที่ 1")
    world.close_shop()
    world.rooms.leave()
    for i in 7:
        sto.on_slime()
    sto._process(0.6)
    check(sto.S.st == "active" and sto.need()[0] == 7, "บทที่ 1: นับสไลม์ 7/8 ยังไม่สำเร็จ")
    var sl3 := Node3D.new()
    sl3.set_script(load("res://scripts/slime.gd"))
    world.field.add_child(sl3)
    sl3.setup(world.field, 1, world.fw(20.5, 20.5))
    world.field.slimes.append(sl3)
    sl3.hp = 1
    world.field.hit_slime(sl3, p, 5.0)
    sto._process(0.6)
    check(sto.S.st == "report" and sto.tracker.text.find("รายงาน") >= 0, "บทที่ 1: ฆ่าสไลม์ครบ 8 → กลับไปรายงาน")
    p.position = world.tw(10, 20)
    check(sto.guide_target().distance_to(world.tw(22.0, 9.3)) < 0.1, "เนื้อเรื่อง: สำเร็จแล้วลูกศรชี้กลับปราสาท")
    sto.king_talk()
    check(int(sto.S.ch) == 2 and sto.S.st == "active", "รายงานแล้วได้บทที่ 2")
    world.close_shop()
    p.lv = 5
    check(not sto.done(), "บทที่ 2: Lv.5 แต่ยังไม่มีอาวุธเหล็ก ยังไม่สำเร็จ")
    p.weapon = "sword1"
    check(sto.done(), "บทที่ 2: Lv.5 + ดาบเหล็ก = สำเร็จ")
    sto._process(0.6)
    sto.king_talk()
    world.close_shop()
    p.lv = 10
    world.classes.pick("archer")
    world.close_shop()
    check(sto.done(), "บทที่ 3: เลือกอาชีพแล้วสำเร็จ")
    sto._process(0.6)
    sto.king_talk()
    world.close_shop()
    check(int(sto.S.ch) == 4, "ไปถึงบทที่ 4")
    p.save_enabled = true
    p.save_path = "user://test_save5.json"
    p.save_game()
    sto.reset()
    p.load_game()
    check(int(sto.S.ch) == 4 and int(sto.S.slime) >= 8, "เซฟ/โหลด: เนื้อเรื่อง")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save5.json"))
    p.save_enabled = false
    sto.open_journal()
    check(world.cur_shop == "journal", "เปิดบันทึกเนื้อเรื่องได้")
    world.close_shop()
    p.cls = "none"
    p.lv = 1
    p.recalc_stats()

    # ---------- ดันเจี้ยนร้อยชั้น ----------
    var dm: Node = world.mine
    p.dead = false
    p.hp = p.max_hp
    p.dg_max = 1
    p.position = world.field.dungeon_pos + Vector3(0, 0, 3.0)
    p.stun = 0.0
    p.dash_t = 0.0
    p.at = -1.0
    p.attack()
    check(world.ui_shop.visible and world.cur_shop == "dg", "ประตูดันเจี้ยน: กดตีแล้วขึ้นเมนูเลือกชั้น")
    world.close_shop()
    for fl in [1, 25, 60]:
        var dd: Dictionary = dm.gen_dungeon(dm.DG_BASE + fl)
        var Wd: int = dd.W
        check(dd.m[dd.arena.y * Wd + dd.arena.x] == dm.FL and dd.m[dd.ent.y * Wd + dd.ent.x] == dm.FL and dd.m[(dd.ent.y + 2) * Wd + dd.ent.x] == dm.FL and dd.boss_room != dd.ent_room, "ดันเจี้ยนชั้น %d: ทางเข้า/ห้องบอส/วงเวทอยู่บนพื้นที่เดินถึง" % fl)
        dm.data.erase(dm.DG_BASE + fl)
    dm.enter(dm.DG_BASE + 1)
    dm._process(0.2)
    check(dm.cur == dm.DG_BASE + 1 and dm.mobs.size() >= 10 and dm.boss != null, "ลงดันเจี้ยนชั้น 1: มีฝูงมอน + บอส")
    check(not world.blocked(p.position.x, p.position.z), "ดันเจี้ยน: จุดเกิดเดินได้")
    var stb2 := Mob.stats(3, "skeleton", false, false)
    check(stb2.x > 0 and dm.zdef(dm.cur).mobs.size() == 3, "ดันเจี้ยนชั้น 1: มอนโครงกระดูก/ซอมบี้/ค้างคาว")
    dm.mob_killed(dm.boss)
    check(not dm.chest.is_empty() and p.dg_max == 2 and int(world.story.S.dg) >= 1, "ชนะบอสชั้น 1: กล่องสมบัติ + เปิดชั้น 2 + นับเนื้อเรื่อง")
    p.position = dm.chest.pos + Vector3(0, 0, 1.5)
    var cb: int = p.coins
    var nd2: int = world.field.drops.size()
    p.attack()
    var es := false
    for i in range(nd2, world.field.drops.size()):
        if world.field.drops[i].k == "estone":
            es = true
    check(dm.chest.open and p.coins > cb and es, "เปิดกล่องสมบัติ: เหรียญ + หินเสริมพลัง")
    p.attack()
    check(dm.cur == dm.DG_BASE + 2, "กดที่กล่องอีกครั้ง = ลงชั้น 2")
    p.position = dm.exit_pos(dm.cur)
    dm._process(0.05)
    check(dm.cur == dm.DG_BASE + 1, "วงเวทในดันชั้น 2 = ขึ้นชั้น 1")
    p.position = dm.exit_pos(dm.cur)
    dm._process(0.05)
    check(dm.cur == -1 and p.position.distance_to(world.field.dungeon_pos) < 5.0, "วงเวทชั้น 1 = ออกมาหน้าประตูดันเจี้ยน")
    dm.enter(dm.DG_BASE + 2)
    p.inv_add("scroll", 1)
    p.use_item("scroll")
    check(dm.cur == -1 and not world.in_field_rect(p.position.x, p.position.z, 0.0) and p.position.x < 100.0, "ม้วนวาปในดันเจี้ยน = กลับเมือง")
    world.story.S.ch = 4
    world.story.S.st = "active"
    world.story.on_floor(5)
    check(world.story.done(), "บทที่ 4: พิชิตดันเจี้ยนชั้น 5 แล้วสำเร็จ")
    world.story.reset()
    p.save_enabled = true
    p.save_path = "user://test_save6.json"
    p.save_game()
    p.dg_max = 1
    p.load_game()
    check(p.dg_max == 2, "เซฟ/โหลด: ชั้นดันเจี้ยนที่ปลดล็อก")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save6.json"))
    p.save_enabled = false

    # ---------- กิลด์: บอร์ดเควส ----------
    var gd: Node = world.guild
    gd.load_state({})
    world.story.reset()
    p.lv = 5
    world.rooms.enter("guild")
    var gk: Node3D = world.rooms.keepers["guild"]
    p.position = Vector3(gk.position.x, 0, gk.position.z + 2.2)
    p.attack()
    check(world.cur_shop == "quest" and gd.Q.offer.size() == 4, "กิลด์: คุยกับเจ้าหน้าที่แล้วเปิดบอร์ดเควส 4 เควส")
    world.close_shop()
    world.rooms.leave()
    gd.Q.offer[0] = {"t": "kill", "k": "slime", "d": "กำจัดสไลม์ 2 ตัว", "n": 2, "c": 0, "coin": 60, "xp": 10, "es": 1}
    gd.Q.offer[1] = {"t": "item", "k": "gel", "d": "ส่งเจลสไลม์ 3 ชิ้น", "n": 3, "c": 0, "coin": 60, "xp": 10, "es": 0}
    gd.Q.offer[2] = {"t": "mine", "k": "", "d": "ขุดแร่ 1 ก้อน", "n": 1, "c": 0, "coin": 60, "xp": 10, "es": 0}
    gd.take(0)
    gd.take(0)
    gd.take(0)
    check(gd.take(0).find("สูงสุด") >= 0 and gd.Q.act.size() == 3, "กิลด์: รับเควสได้สูงสุด 3")
    gd.event("kill", "slime")
    gd.event("kill", "bat")
    check(int(gd.Q.act[0].c) == 1 and not gd.is_ok(gd.Q.act[0]), "เควสฆ่า: นับเฉพาะมอนที่ตรง")
    gd.event("kill", "slime")
    var cq: int = p.coins
    var es0q: int = p.inv_count("estone")
    gd.claim(0)
    check(p.coins == cq + 60 and p.inv_count("estone") == es0q + 1 and int(gd.Q.done) == 1 and int(world.story.S.guild) == 1, "เควส: รับรางวัล เหรียญ+หินเสริมพลัง + นับเนื้อเรื่องบท 6")
    p.gel = 2
    check(gd.claim(0).find("ยังไม่") >= 0, "เควสส่งของ: ของไม่ครบรับรางวัลไม่ได้")
    p.gel = 5
    gd.claim(0)
    check(p.gel == 2 and int(gd.Q.done) == 2, "เควสส่งของ: ส่งแล้วของหายจากกระเป๋า")
    gd.event("mine")
    check(gd.is_ok(gd.Q.act[0]), "เควสขุดแร่: ขุดแตกแล้วนับ")
    p.save_enabled = true
    p.save_path = "user://test_save7.json"
    p.save_game()
    gd.load_state({})
    p.load_game()
    check(int(gd.Q.done) == 2 and gd.Q.act.size() == 1, "เซฟ/โหลด: เควสกิลด์")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save7.json"))
    p.save_enabled = false
    world.story.reset()

    # ---------- ขายอุปกรณ์ · อุปกรณ์บนตัว ----------
    p.gear = []
    p.eq = {}
    p.inv_add("chest1", 1)
    var cg: int = p.coins
    world.open_shop("gear")
    world.sell_gear(p.gear[0])
    check(p.gear.is_empty() and p.coins == cg + 20, "ร้านอาวุธรับซื้ออุปกรณ์ (เสื้อเหล็ก 20 เหรียญ)")
    world.close_shop()
    p.weapon = "staff2"
    var bd: Dictionary = p.body._item_nodes()
    check(bd.has("2H_Staff") and bd["2H_Staff"].visible and not bd["1H_Sword"].visible, "ถือคทาแล้วเห็นคทาในมือ (ไม่เห็นดาบ)")
    var hm: Dictionary = p.make_inst("helm1")
    p.gear.append(hm)
    p.equip(hm)
    check(bd["Knight_Helmet"].visible, "สวมหมวกแล้วเห็นหมวกบนหัว")
    p.unequip("helm")
    check(not bd["Knight_Helmet"].visible, "ถอดหมวกแล้วหมวกหาย")
    p.gear = []
    p.eq = {}
    p.update_gear_visual()

    # ---------- 11 อาชีพ: ใช้สกิลครบทุกท่า ----------
    var cl2: Node = world.classes
    p.dead = false
    p.lv = 35
    p.position = world.fw(20.5, 20.5)
    var dummy := Node3D.new()
    dummy.set_script(load("res://scripts/slime.gd"))
    world.field.add_child(dummy)
    dummy.setup(world.field, 1, p.position + Vector3(0, 0, 1.8))
    world.field.slimes.append(dummy)
    p.lv = 40
    for ck in cl2.CLASS_ORDER:
        p.cls = "none"
        p.coins = 0
        if not cl2.BASES.has(ck):
            cl2.pick(cl2.base_of(ck))   # สายย่อย: ต้องเป็นสายหลักก่อน แล้วเลื่อนขั้นฟรี
        cl2.pick(ck)
        world.close_shop()
        p.weapon = {"sword": "sword1", "staff": "staff1", "bow": "bow1"}[cl2.CLS[ck].w]
        p.recalc_stats()
        dummy.hp = 99999
        dummy.max_hp = 99999
        dummy.dead = false
        dummy.position = p.position + Vector3(0, 0, 1.8)
        p.heading = 0.0
        var used := 0
        for i in 3:
            cl2.cd = [0.0, 0.0, 0.0]
            cl2.step = 0
            for k in (3 if i == 1 else 1):
                p.mp = 9999
                p.max_mp = 9999
                p.stun = 0.0
                p.dash_t = 0.0
                p.dead = false
                if cl2.use_class(i) == str(cl2.SK[ck][i].n):
                    used += 1
        for k in 30:
            cl2._process(0.1)
            world.field._process(0.05)
        check(p.cls == ck and used == 5 and dummy.hp < 99999, "อาชีพ %s: ใช้สกิลครบ 5 ครั้ง (รวมจังหวะ) โดนเป้า" % cl2.CLS[ck].n)
        cl2.pers.clear()
        p.position = world.fw(20.5, 20.5)
    # ---------- อาชีพ 4 สาย + เลื่อนขั้น (0.27) ----------
    var vis_of := func(n: String) -> bool:
        var L: Dictionary = p.body._item_nodes()
        return L.has(n) and (L[n] as Node3D).visible
    p.cls = "none"
    p.coins = 1000
    p.lv = 40
    cl2.pick("paladin")
    check(p.cls == "none", "4 สาย: ยังไม่มีอาชีพ เลื่อนขั้นเป็นพาลาดินตรงๆ ไม่ได้")
    check(cl2.BASES.size() == 4 and cl2.CLASS_ORDER.size() == 12, "4 สาย: สายหลัก 4 + สายย่อย 8 = 12 สกิลชุด")
    p.lv = 10
    cl2.pick("rogue")
    check(p.cls == "rogue" and p.model_kind == "rogue" and p.coins == 1000, "โจร: เลือกฟรี โมเดลเปลี่ยนเป็นโจร")
    p.weapon = "sword1"
    p.eq["arm"] = p.make_inst("arm1")
    p.update_gear_visual()
    check(vis_of.call("Knife") and vis_of.call("Knife_Offhand") and not vis_of.call("Round_Shield") and not vis_of.call("1H_Sword"), "โจร: ถือมีดคู่ ไม่มีโล่ แม้ใส่เกราะแขน")
    check(p.attack_anim().begins_with("Dualwield"), "โจร: ท่าตีมีดคู่")
    p.lv = 39
    cl2.pick("ninja")
    check(p.cls == "rogue", "เลื่อนขั้น: Lv.39 ยังเลื่อนไม่ได้")
    p.lv = 40
    cl2.pick("ninja")
    check(p.cls == "ninja" and p.coins == 1000 and p.model_kind == "rogue", "เลื่อนขั้น: Lv.40 โจร → นินจา ฟรี โมเดลโจรเดิม")
    cl2.pick("paladin")
    check(p.cls == "ninja", "เลื่อนขั้น: ข้ามสายไปพาลาดินไม่ได้")
    cl2.pick("monk")
    check(p.cls == "monk" and p.coins == 500, "เลื่อนขั้น: สลับสายย่อยเสีย 500")
    cl2.pick("archer")
    p.weapon = "bow1"
    check(p.cls == "archer" and p.model_kind == "hooded" and vis_of.call("1H_Crossbow"), "นักหน้าไม้: โมเดลฮู้ด ถือหน้าไม้")
    p.coins = 500
    cl2.pick("sniper")
    check(p.cls == "sniper" and vis_of.call("2H_Crossbow") and not vis_of.call("1H_Crossbow"), "สไนเปอร์: หน้าไม้สองมือ")
    check(cl2.CLS.summoner.w == "bow" and cl2.base_of("summoner") == "archer", "พรานอสูร: อยู่สายหน้าไม้ ใช้หน้าไม้")
    p.coins = 1000
    cl2.pick("sword")
    p.weapon = "sword1"
    p.update_gear_visual()
    check(p.model_kind == "knight" and vis_of.call("1H_Sword") and vis_of.call("Round_Shield"), "อัศวิน: ดาบ + โล่")
    cl2.pick("dragoon")
    check(p.model_kind == "barbarian" and vis_of.call("2H_Axe"), "อัศวินมังกร: โมเดลคนเถื่อน ขวานสองมือ")
    p.coins = 1000
    cl2.pick("mage")
    p.weapon = "staff1"
    check(p.model_kind == "mage" and vis_of.call("2H_Staff") and vis_of.call("Spellbook"), "นักเวท: คทา + คัมภีร์ (ช่องแขน)")
    p.eq.erase("arm")
    p.cls = "summoner"
    p.save_enabled = true
    p.save_path = "user://test_save_cls.json"
    p.save_game()
    p.cls = "none"
    p.load_game()
    check(p.cls == "summoner" and p.model_kind == "hooded", "เซฟเก่า: อาชีพเดิมโหลดได้ โมเดลตามสาย")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save_cls.json"))
    p.save_enabled = false
    var xr := func(m) -> bool:
        var mi := m as MeshInstance3D
        var mt = mi.get_surface_override_material(0)
        return mi.visible and mt is StandardMaterial3D and mt.stencil_mode == BaseMaterial3D.STENCIL_MODE_XRAY
    var body_meshes: Array = p.body.inst.find_children("*", "MeshInstance3D", true, false)
    check(body_meshes.all(func(m): return not (m as MeshInstance3D).visible or xr.call(m)), "กล้อง ROM: ทุกชิ้นของตัวละครมีเงาทะลุตึก (stencil) หลังเปลี่ยนโมเดล")
    check(body_meshes.all(func(m): return (m as MeshInstance3D).material_overlay == null), "กล้อง ROM: ไม่ใช้ overlay ที่ทำแขนตัวเองเป็นสีฟ้า")
    # ---------- ชุดประจำอาชีพ (0.29) ----------
    var It = load("res://scripts/items.gd")
    var e4 := {"weapon": p.make_inst("sword2"), "helm": p.make_inst("helm2"), "chest": p.make_inst("chest2"), "arm": p.make_inst("arm2")}
    var si4: Dictionary = It.set_info(e4, "sword")
    check(int(si4.st.get("vit", 0)) >= 6 and int(si4.st.get("str", 0)) >= 6 and float(si4.hp) >= 0.05 and str(si4.lines).find("ชุดอัศวิน") >= 0, "ชุดอาชีพ: อัศวินครบ 4 ชิ้น ได้ VIT/STR + เลือด 5%")
    var si4m: Dictionary = It.set_info(e4, "mage")
    check(str(si4m.lines).find("ชุดจอมเวท") >= 0 and str(si4m.lines).find("3/4") >= 0 and float(si4m.dmg) == 0.0, "ชุดอาชีพ: นักเวทถือดาบ อาวุธไม่นับ (3/4)")
    var e2 := {"helm": p.make_inst("helm1"), "chest": p.make_inst("chest1")}
    var si2: Dictionary = It.set_info(e2, "rogue")
    check(int(si2.st.get("agi", 0)) == 3 and float(si2.dmg) == 0.0, "ชุดอาชีพ: โจร 2 ชิ้น ได้ AGI ยังไม่ได้ดาเมจ")
    check(It.inst_name(p.make_inst("arm1"), "rogue").begins_with("มีดซ้าย") and It.inst_name(p.make_inst("arm1"), "archer").begins_with("ซองลูกศร") and It.inst_name(p.make_inst("arm1"), "sword").begins_with("โล่"), "ชุดอาชีพ: ช่องมือรองชื่อตามอาชีพ")
    p.coins = 2000
    p.cls = "none"
    p.lv = 40
    cl2.pick("sword")
    cl2.pick("paladin")
    for k in e4:
        p.eq[k] = e4[k]
    p.recalc_stats()
    check(str(p.set_b.lines).find("ชุดอัศวิน") >= 0, "ชุดอาชีพ: พาลาดินใช้ชุดของสายอัศวิน")
    p.eq.weapon.e = 10
    p.update_gear_visual()
    check(p.aura != null and p.aura.visible, "ตีบวก +10: มีออร่ารอบตัว")
    p.eq.weapon.e = 9
    p.update_gear_visual()
    check(not p.aura.visible, "ตีบวก +9: ยังไม่มีออร่า")
    p.coins = 2000
    cl2.pick("rogue")
    p.update_gear_visual()
    check(vis_of.call("Knife") and vis_of.call("Knife_Offhand"), "โจร: มีดซ้ายมาจากช่องมือรอง")
    p.eq.erase("arm")
    p.update_gear_visual()
    check(vis_of.call("Knife") and not vis_of.call("Knife_Offhand"), "โจร: ถอดมือรอง เหลือมีดเดียว")
    p.coins = 2000
    cl2.pick("archer")
    p.eq["arm"] = p.make_inst("arm1")
    p.update_gear_visual()
    check(vis_of.call("Quiver"), "นักหน้าไม้: ซองลูกศรบนหลัง (ช่องมือรอง)")
    for k in ["weapon", "helm", "chest", "arm"]:
        p.eq.erase(k)
    p.update_gear_visual()
    p.recalc_stats()
    # ---------- หน้าต่างอาชีพแบบการ์ด + ภาพสกิล + ชื่อมีด (0.30) ----------
    var cards_of := func() -> Array:
        return world.ui_shop_body.find_children("*", "PanelContainer", true, false).filter(func(n): return n.has_meta("cls"))
    p.cls = "none"
    p.lv = 10
    p.recalc_stats()
    cl2.open_menu()
    var cds: Array = cards_of.call()
    check(cds.size() == 4 and cds.all(func(c): return c.find_children("*", "TextureRect", true, false).filter(func(r): return r.texture != null).size() >= 4), "หน้าต่างอาชีพ: การ์ด 4 สายหลัก มีภาพหน้าอาชีพ + ภาพสกิล 3 รูป")
    p.coins = 1000
    cl2.pick("sword")
    p.lv = 40
    cl2.open_menu()
    var keys: Array = cards_of.call().map(func(c): return c.get_meta("cls"))
    check(keys.has("paladin") and keys.has("dragoon") and keys.size() == 6, "หน้าต่างอาชีพ: อัศวิน Lv.40 เห็นการ์ดเลื่อนขั้น 2 ใบ + สายหลัก 4")
    world.close_shop()
    var miss := []
    for ck in cl2.CLASS_ORDER:
        for i in 3:
            if world.icon_tex("sk_%s_%d" % [ck, i]) == null:
                miss.append("%s%d" % [ck, i])
        if world.icon_tex("cls_" + ck) == null:
            miss.append("cls_" + ck)
    for bk in ["whirl", "fireball", "heal"]:
        if world.icon_tex("sk_" + bk) == null:
            miss.append(bk)
    check(miss.is_empty(), "ภาพสกิลครบ 39 + ภาพหน้าอาชีพ 12 (ขาด: %s)" % str(miss))
    if world.mobile != null:
        world.mobile.refresh_skills()
        var sb0: Panel = world.mobile.skill_btns[0]
        check(sb0.visible and (sb0.get_node("Icon") as TextureRect).texture != null, "ปุ่มสกิลมือถือมีรูปสกิล")
    p.coins = 1000
    cl2.pick("rogue")
    check(It.item_name("sword2") == "มีดทองแดง" and It.inst_name(p.make_inst("sword2")) == "มีดทองแดง", "โจร: อาวุธชื่อมีด")
    check(cl2.use_class(0).find("มีด") >= 0 or p.eq.has("weapon"), "โจร: ข้อความต้องถือมีด")
    p.coins = 1000
    cl2.pick("sword")
    check(It.item_name("sword2") == "ดาบทองแดง", "อัศวิน: อาวุธชื่อดาบ")
    p.cls = "none"
    p.recalc_stats()
    # ---------- ระบบเสียง (0.32) ----------
    var sx = world.sfx
    check(sx != null and sx.streams("chop").size() == 3 and sx.streams("step_grass").size() == 4 and sx.streams("level_up").size() == 1, "เสียง: โหลดเสียงหลายแบบ (ตัดไม้ 3 · เท้าหญ้า 4 · เลเวลอัป)")
    var miss_s := []
    for sn in ["swing", "swing_heavy", "hit_flesh", "hit_metal", "slime_hop", "slime_die", "hurt", "roll", "bow", "magic", "chop", "mine", "die", "fireball", "boom", "heal", "tree_fall", "rock_break", "pickup", "coin", "splash", "ui_click", "ui_open", "ui_close", "buy", "level_up", "warp", "door", "amb_field", "amb_town", "amb_night", "amb_mine", "step_stone", "step_dirt"]:
        if sx.streams(sn).is_empty():
            miss_s.append(sn)
    check(miss_s.is_empty(), "เสียง: ไฟล์ครบทุกเหตุการณ์ (ขาด %s)" % str(miss_s))
    var tod0: float = world.time_of_day
    world.time_of_day = 0.45
    p.position = world.tw(10, 20)
    check(sx.ambient_name() == "amb_town" and sx.step_surface() == "step_stone", "เสียง: ในเมืองกลางวัน = บรรยากาศเมือง เท้าบนหิน")
    p.position = world.fw(20.5, 20.5)
    check(sx.ambient_name() == "amb_field" and sx.step_surface() == "step_grass", "เสียง: ทุ่งหญ้า = ลม+นก เท้าบนหญ้า")
    world.time_of_day = 0.95
    check(sx.ambient_name() == "amb_night", "เสียง: กลางคืน = จิ้งหรีด")
    world.time_of_day = tod0
    sx._last.clear()
    sx._last_pos = p.position
    sx._step_acc = 0.0
    p.position += Vector3(1.4, 0, 0)
    sx._steps(0.5)
    check(sx._last.has("step_grass"), "เสียง: เดินครบก้าวมีเสียงเท้า")
    sx._last.clear()
    p.at = -1.0
    p.dead = false
    p.stun = 0.0
    p.dash_t = 0.0
    p.weapon = "sword1"
    var pos_keep: Vector3 = p.position
    p.position = world.tw(10, 20)
    world._update_cam(1.0)
    p.attack()
    p.position = pos_keep
    check(sx._last.has("swing"), "เสียง: ฟันดาบมีเสียงหวือ")
    var m0: bool = sx.muted
    sx.toggle_mute()
    check(AudioServer.is_bus_mute(0) == (not m0), "เสียง: ปุ่มปิด/เปิดเสียง")
    sx.toggle_mute()
    p.at = -1.0
    # ---------- ภาพ 0.24-0.26 ----------
    check(world.field.slimes.size() > 0 and world.field.slimes[0].body.mesh is ArrayMesh, "สไลม์ทรงหยดน้ำ (ArrayMesh)")
    check(world.fade_blds.size() >= 11, "อาคารใหม่ลงทะเบียนจางเมื่อบังกล้อง")
    var cd0: float = world.cam_dist
    world.cam_dist = world.CAM_FAR
    world._update_cam(1.0)
    var hi: float = world.cam.global_position.y - p.global_position.y
    world.cam_dist = world.CAM_NEAR
    world._update_cam(1.0)
    var lo: float = world.cam.global_position.y - p.global_position.y
    check(hi / world.CAM_FAR > lo / world.CAM_NEAR, "กล้อง ROM: ซูมออก = มองจากบนมากขึ้น")
    world.cam_dist = cd0
    p.cls = "paladin"
    p.iframe = 0.0
    var ph: float = p.hp
    p.hurt_mob(100, "ทดสอบ")
    var lost1: float = ph - p.hp
    p.cls = "sword"
    p.iframe = 0.0
    ph = p.hp
    p.hurt_mob(100, "ทดสอบ")
    check(lost1 < ph - p.hp, "พาลาดิน: ได้รับดาเมจน้อยกว่า (ลด 15%)")
    p.hp = p.max_hp
    p.cls = "necro"
    p.weapon = "staff1"
    cl2.cd = [0.0, 0.0, 0.0]
    for a2 in cl2.allies:
        if is_instance_valid(a2):
            a2.queue_free()
    cl2.allies.clear()
    p.mp = 9999
    cl2.use_class(0)
    check(cl2.allies.size() == 2, "เนโครแมนเซอร์: ปลุกโครงกระดูก 2 ตัว")
    var a0 = cl2.allies[0]
    a0.position = dummy.position + Vector3(1.0, 0, 0)
    dummy.hp = 99999
    a0._process(0.1)
    a0._process(0.1)
    check(dummy.hp < 99999, "โครงกระดูกที่เรียกมาตีศัตรู")
    for a2 in cl2.allies:
        if is_instance_valid(a2):
            a2.queue_free()
    cl2.allies.clear()
    cl2.bless_t = 0.0
    cl2.aegis_t = 0.0
    cl2.zen_t = 0.0
    dummy.queue_free()
    world.field.slimes.erase(dummy)
    p.cls = "none"
    p.lv = 1
    p.recalc_stats()
    p.hp = p.max_hp
    p.mp = p.max_mp

    # ---------- แผนที่เล็ก ----------
    var mm: Control = world.minimap
    p.position = world.fw(20.5, 20.5)
    mm._process(0.3)
    check(mm.key == "world" and mm.tex != null and mm.visible, "แผนที่เล็ก: โลกภายนอก")
    var pxw: Vector2 = mm._to_px(p.position)
    check(pxw.x > 0 and pxw.y > 0 and pxw.x < mm.offset_right - mm.offset_left, "แผนที่เล็ก: จุดผู้เล่นอยู่ในกรอบ")
    world.mine.enter(0)
    mm._process(0.3)
    check(mm.key == "mine0" and mm.size_px == Vector2i(62, 44), "แผนที่เล็ก: เปลี่ยนเป็นแผนที่เหมือง")
    world.mine.leave(false)
    world.rooms.enter("gear")
    mm._process(0.3)
    check(not mm.visible, "แผนที่เล็ก: ซ่อนตอนอยู่ในร้าน")
    world.rooms.leave()
    mm._process(0.3)

    # ---------- ตกปลา ----------
    var fsh: Node = world.fishing
    # หาจุดริมน้ำในทุ่ง: ช่องหญ้าที่ช่องถัดไปทางขวาเป็นน้ำ
    var fspot := Vector2i(-1, -1)
    for ty in range(2, world.FH - 2):
        for tx in range(2, world.FW - 3):
            if fspot.x < 0 and world.ftile(tx, ty) == world.F_GRASS and world.ftile(tx + 1, ty) == world.F_WATER and not world.blocked(world.fw(tx + 0.5, ty + 0.5).x, world.fw(tx + 0.5, ty + 0.5).z):
                fspot = Vector2i(tx, ty)
    check(fspot.x >= 0, "ตกปลา: มีริมน้ำในทุ่ง")
    p.dead = false
    p.stun = 0.0
    p.dash_t = 0.0
    p.at = -1.0
    p.position = world.fw(fspot.x + 0.7, fspot.y + 0.5)
    p.heading = PI / 2.0
    for fsl in world.field.slimes:
        if is_instance_valid(fsl) and fsl.position.distance_to(p.position) < 4.0:
            fsl.position += Vector3(30, 0, 0)
    p.inv_add("rod", -p.inv_count("rod"))
    p.inv_add("rod2", -p.inv_count("rod2"))
    check(not fsh.try_start(p), "ตกปลา: ไม่มีคันเบ็ดตกไม่ได้")
    p.inv_add("rod", 1)
    check(fsh.water_ahead(p) != Vector3.INF, "ตกปลา: หันเข้าน้ำแล้วเจอน้ำ")
    p.attack()
    check(fsh.st == "cast", "ตกปลา: กดตีริมน้ำ = เหวี่ยงเบ็ด")
    fsh._process(0.6)
    check(fsh.st == "wait", "ตกปลา: รอปลา")
    fsh.t = fsh.wait + 0.01
    fsh._process(0.01)
    check(fsh.st == "bite", "ตกปลา: ปลากินเบ็ด")
    p.attack()
    check(fsh.st == "reel", "ตกปลา: กดตีทัน = เริ่มดึง")
    var ffish0: String = fsh.fish
    var fhave0: int = p.inv_count(ffish0)
    for k in fsh.need:
        fsh.cur = fsh.zc
        fsh.press()
    check(fsh.st == "" and p.inv_count(ffish0) == fhave0 + 1, "ตกปลา: ดึงตรงช่องเขียวครบ = ได้ปลา")
    fsh.try_start(p)
    fsh._process(0.6)
    p.position += Vector3(1.0, 0, 0)
    fsh._process(0.05)
    check(fsh.st == "", "ตกปลา: ขยับตัว = เลิกตก")
    fsh.rod = 1
    check(fsh.pick_fish(0.0) == "carp" and fsh.pick_fish(99.9) == "dragon", "ตกปลา: สุ่มปลาตามน้ำหนัก (ตะเพียนมากสุด มังกรน้อยสุด)")
    p.inv_add("salmon", 1)
    check(p.use_item("salmon").find("แล้ว") >= 0, "กินปลาแซลมอนได้ (มานา + INT)")

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

    # ---- ชุดบอส (fix59) · โบนัสชุด (fix111) · แท่นผนึกอสูร/บอสตำนาน (fix62/64/113/118) ----
    var lp = world.player
    var lg = world.legend
    var lmn = world.mine
    if lmn.cur >= 0:
        lmn.leave(false)
    if world.room != "":
        world.rooms.leave()
    check(Items.is_gear("sword10") and Items.gear_kind("sword10") == "sword" and Items.gear_tier("sword10") == 10 and Items.is_gear("ring6"), "ชุดบอส: ไอดีเลขสองหลัก sword10 อ่านถูก")
    check(not Items.is_gear("axe7") and not Items.is_gear("pick11") and not Items.is_gear("sword12") and Items.is_gear("pick5"), "ชุดบอส: ไม่มีขวาน/ที่ขุดชุดบอส · ระดับเกินไม่นับ")
    check(Items.inst_stat({"k": "sword", "t": 10, "q": 0, "e": 0}) == 30 and Items.inst_stat({"k": "neck", "t": 11, "q": 0, "e": 0}) == 310 and Items.inst_stat({"k": "chest", "t": 6, "q": 0, "e": 0}) == 5, "ชุดบอส: ค่าพลังตามเกม 2D (B59 st)")
    check(Items.gear_price({"k": "sword", "t": 8, "q": 0, "e": 0}) == 0 and Items.req_lv(9) == 65 and Items.req_lv(3) == 0, "ชุดบอส: ขายร้านไม่ได้ · ต้องถึงเลเวลชุด")
    check(Items.item_name("helm7") == "หมวกเกล็ดอสรพิษ" and Items.item_name("lbm2").contains("หมาป่าเหมันต์"), "ชุดบอส: ชื่อชิ้น + ตราอสูร")
    var lg_lv0: int = lp.lv
    lp.lv = 5
    var lg_s = lp.make_inst("sword6")
    lp.gear.append(lg_s)
    check(lp.equip(lg_s).contains("Lv.10") and lp.gear.has(lg_s), "ชุดบอส: เลเวลไม่ถึงสวมไม่ได้")
    lp.lv = 40
    var lg_eq0: Dictionary = lp.eq.duplicate()
    var lg_hp0: int = lp.max_hp
    var lg_vit0: int = lp.stat_total("vit")
    for lg_k in ["sword", "helm", "chest", "pants", "arm", "neck", "ring"]:
        var lg_it = lg_s if lg_k == "sword" else lp.make_inst(lg_k + "6")
        if lg_k != "sword":
            lp.gear.append(lg_it)
        lp.equip(lg_it)
    check(lp.set_b.lines.size() == 2 and lp.stat_total("vit") == lg_vit0 + 8 and lp.dmg_mult() > 1.05, "โบนัสชุด: 7 ชิ้น = ขั้น 1+2 + ครบชุด · สร้อย+แหวนชุดเดียวกัน (VIT +8 · ดาเมจ +%)")
    check(lp.max_hp > lg_hp0, "โบนัสชุด: เลือดสูงสุดเพิ่ม")
    lp.unequip("ring")
    lp.unequip("neck")
    lp.unequip("arm")
    check(lp.set_b.lines.size() == 1 and lp.dmg_mult() == 1.0 and lp.stat_total("vit") == lg_vit0 + 3, "โบนัสชุด: 4 ชิ้น = ขั้น 1 อย่างเดียว")
    lp.unequip("pants")
    lp.unequip("chest")
    check(lp.set_b.lines.is_empty(), "โบนัสชุด: 2 ชิ้นไม่มีโบนัส")
    # ห้องหอผนึก → แท่นผนึก
    world.ui_shop.visible = false
    world.in_door = ""
    world.rooms.enter("seal113")
    lp.position = world.rooms.station_pos("seal113", 0) + Vector3(1.6, 0, 0)
    lp.stun = 0.0
    lp.dash_t = 0.0
    lp.attack()
    check(world.ui_shop.visible and world.cur_shop == "altar", "แท่นผนึก: กดตีข้างแท่น = เปิดหน้าบอสตำนาน")
    var lg_txt := ""
    for lg_n in world.ui_shop_body.find_children("*", "Label", true, false):
        lg_txt += (lg_n as Label).text + "|"
    check(lg_txt.contains("ราชาพฤกษาหนาม") and lg_txt.contains("จักรพรรดิเงานิรันดร์") and lg_txt.contains("วันนี้ลงได้อีก 2/2"), "แท่นผนึก: แสดงบอส 6 ตัว + โควตาวันละ 2")
    lp.lv = 10
    check(lg.challenge(0).contains("Lv.20"), "แท่นผนึก: เลเวลไม่ถึงเข้าไม่ได้")
    lp.lv = 30
    lp.coins = 100
    check(lg.challenge(0).contains("เหรียญไม่พอ"), "แท่นผนึก: เหรียญไม่พอเข้าไม่ได้")
    lp.coins = 20000
    lg.S = {"cd": {}, "day": "", "n": {}}
    check(lg.challenge(0) == "" and lmn.cur == lmn.LB_BASE and world.room == "" and lp.coins == 17000, "บอสตำนาน: จ่ายค่าท้า 3000 เข้าลานผนึก")
    var lg_b = lmn.boss
    check(lg_b != null and lg_b.boss and lg_b.lv == 23 and lg_b.max_hp > 6 * 1000, "บอสตำนาน: บอส Lv.23 เลือด ×6")
    check(lg.left_today(0) == 1, "บอสตำนาน: นับโควตาตอนจ่ายค่าท้า")
    # วงเตือน: ยืนในวง = โดน % เลือดสูงสุด · กลิ้ง (อมตะ) = ไม่โดน
    lp.position = lg_b.position + Vector3(0, 0, 8.0)
    lp.hp = lp.max_hp
    lp.iframe = 0.0
    lg.aoe(lp.position, 46.0, 0.3, "thorn")
    lg._tick_aoe(0.2)
    check(lp.hp == lp.max_hp, "บอสตำนาน: ก่อนวงลงยังไม่โดน")
    lg._tick_aoe(0.2)
    check(lp.hp < lp.max_hp and lp.hp > lp.max_hp * 0.6, "บอสตำนาน: วงลงโดนประมาณ 25% เลือด")
    var lg_h1: float = lp.hp
    lp.iframe = 1.0
    lg.aoe(lp.position, 46.0, 0.1, "fire")
    lg._tick_aoe(0.2)
    check(lp.hp == lg_h1, "บอสตำนาน: กลิ้งหลบ (อมตะ) ไม่โดนวง")
    lp.iframe = 0.0
    lg.aoe(lp.position + Vector3(10, 0, 0), 46.0, 0.1, "fire")
    lg._tick_aoe(0.2)
    check(lp.hp == lg_h1, "บอสตำนาน: ยืนนอกวงไม่โดน")
    lg._clear_aoe()
    # ท่าไม้ตายทุกตัว + เรียกสมุน + คลั่ง
    lg.aggro = true
    var lg_ok := true
    for lg_i in 6:
        lg.act = lg_i
        lg._ult(lg_b)
        lg._tick_aoe(1.3)
        if lg.aoes.is_empty():
            lg_ok = false
        lg._clear_aoe()
    lg.act = 0
    check(lg_ok, "บอสตำนาน: ท่าไม้ตายครบ 6 แบบ (สร้างวงเตือน)")
    lp.hp = lp.max_hp
    var lg_n0: int = lmn.mobs.size()
    lg.summon(lg_b)
    check(lmn.mobs.size() > lg_n0, "บอสตำนาน: เรียกสมุน")
    var lg_a0: int = lg_b.atk_v
    lg_b.hp = int(lg_b.max_hp * 0.2)
    lg.tick(0.1)
    check(lg.rage and lg_b.atk_v > lg_a0 and lg.hud_text().contains("คลั่ง"), "บอสตำนาน: เลือด < 30% คลั่ง ตีแรงขึ้น")
    # ชนะ
    lg._clear_aoe()
    lp.hp = lp.max_hp
    lg_b.hp = 1
    var lg_c0: int = lp.coins
    world.field.hit_slime(lg_b, lp, 50.0)
    check(lg_b.dead and lg.won == 1 and lp.inv_count("lbm0") >= 1 and lp.coins >= lg_c0 + 3600, "บอสตำนาน: ชนะได้ตราอสูร + เหรียญ ×1.2")
    check(world.ui_shop.visible and world.cur_shop == "altar", "บอสตำนาน: ชนะแล้วขึ้นหน้าต่างรางวัล")
    check(lg.cd_left(0) > 1700, "บอสตำนาน: ชนะแล้วพัก 30 นาที")
    world.close_shop()
    lp.position = lmn.exit_pos(lmn.cur)
    lmn._process(0.1)
    check(lmn.cur < 0 and world.room == "seal113" and lg.act < 0, "บอสตำนาน: เดินเข้าวงเวท = กลับหอผนึก (ที่เข้ามา)")
    check(lg.challenge(0).contains("นาที"), "บอสตำนาน: ช่วงพักเข้าซ้ำไม่ได้")
    lg.S.cd = {}
    lg.S.n["0"] = 2
    check(lg.challenge(0).contains("ครบ 2 ครั้ง"), "บอสตำนาน: เกินวันละ 2 ครั้งเข้าไม่ได้")
    # หมดเวลา → ถูกส่งออก
    lg.S.n = {}
    lp.coins = 20000
    world.rooms.leave()
    world.rooms.enter("seal113")
    lp.lv = 60
    lg.challenge(1)
    check(lmn.cur == lmn.LB_BASE + 1 and lmn.boss.f == "drake", "บอสตำนาน: ตัวที่ 2 นาคราช")
    lg.el = 479.9
    lg.tick(0.2)
    check(lmn.cur < 0 and world.room == "seal113", "บอสตำนาน: หมดเวลา 8 นาที ถูกส่งกลับหอผนึก")
    # ตาย/วาปออกจากลาน (ไม่กลับหอ) ล้างสถานะ
    lp.coins = 20000
    lg.S.n = {}
    world.rooms.leave()
    world.rooms.enter("seal113")
    check(lg.challenge(2) == "" and lmn.cur == lmn.LB_BASE + 2, "บอสตำนาน: ตัวที่ 3 หมาป่าเหมันต์")
    lg.S.n = {}
    lmn.leave(false)
    check(lmn.cur < 0 and lg.act < 0 and lg.aoes.is_empty(), "บอสตำนาน: ออกแบบตาย/วาป ล้างสถานะ")
    # แลกตรา 10 อัน
    lp.inv_add("lbm4", 10)
    var lg_g0: int = lp.gear.size()
    check(lg.trade(4, "chest").contains("เสื้อเกราะมังกรโลหิต") and lp.inv_count("lbm4") == 0 and lp.gear.size() == lg_g0 + 1 and int(lp.gear.back().t) == 10, "แลกตรา: 10 อัน = ชิ้นที่เลือก")
    check(lg.trade(4, "ring").contains("ไม่พอ"), "แลกตรา: ตราไม่พอแลกไม่ได้")
    world.rooms.leave()
    world.rooms.enter("seal113")
    lg.pick_piece(4)
    check(world.cur_shop == "altar" and world.ui_shop_body.get_child_count() >= 10, "แลกตรา: หน้าเลือกชิ้น 9 ชนิด")
    world.close_shop()
    world.rooms.leave()
    # บอสทั่วไปดรอปชุดบอสตามเลเวล
    check(lg.pick_set(15) == 0 and lg.pick_set(55) == 2 and lg.pick_set(130) == 5, "ชุดบอส: บอสเลเวลไหนดรอปชุดไหน (pick59)")
    var lg_g1: int = lp.gear.size()
    lg.drop_piece(3, "ทดสอบ")
    check(lp.gear.size() == lg_g1 + 1 and int(lp.gear.back().t) == 9, "ชุดบอส: ดรอปชิ้นเข้ากระเป๋าทันที")
    # เซฟ/โหลดสถานะแท่นผนึก + ของชุดบอส
    lg.S = {"cd": {"3": 123}, "day": "2026-10-29", "n": {"1": 2}}
    var lg_sv: Dictionary = lg.S.duplicate(true)
    lg.load_state(JSON.parse_string(JSON.stringify(lg_sv)))
    check(int(lg.S.cd["3"]) == 123 and int(lg.S.n["1"]) == 2, "แท่นผนึก: เซฟ/โหลดคูลดาวน์ + โควตา")
    check(int(lp._clean_inst({"k": "sword", "t": 11}).t) == 11 and int(lp._clean_inst({"k": "pick", "t": 9}).t) == 5, "ชุดบอส: โหลดเซฟเก็บระดับชุดบอสได้")
    lg.S = {"cd": {}, "day": "", "n": {}}
    for lg_sl in lp.eq.keys():
        lp.unequip(str(lg_sl))
    for lg_sl in lg_eq0:
        lp.equip(lg_eq0[lg_sl])
    lp.lv = lg_lv0

    # ---- สัตว์ขี่ / สัตว์เลี้ยง (ANIMS · MOUNTS · PET · fix7 · fix75) ----
    var st_p = world.player
    var st = world.steed
    if world.mine.cur >= 0:
        world.mine.leave(false)
    if world.room != "":
        world.rooms.leave()
    var st_cls0: String = st_p.cls
    var st_lv0: int = st_p.lv
    st.load_state({})
    check(st.toggle().contains("ยังไม่มี"), "สัตว์ขี่: ยังไม่มีขี่ไม่ได้")
    st_p.cls = "none"
    st_p.coins = 1000000
    check(st.buy("mount", "horse").contains("เลือกอาชีพ"), "สัตว์ขี่: ยังไม่เลือกอาชีพ ลุงไม่ขาย")
    st_p.cls = "sword"
    st_p.lv = 20
    check(st.buy("mount", "unicorn").contains("Lv.40") and st.buy("mount", "wolf").contains("ชั้น 100"), "สัตว์ขี่: เลเวลไม่ถึง/ยังไม่ปราบบอสสุดท้าย ซื้อไม่ได้")
    check(st.buy("mount", "horse").contains("ได้ม้าศึก") and st_p.coins == 1000000 - 6000 and st.S.mount == "horse", "สัตว์ขี่: ซื้อม้าศึก 6000")
    var st_m0: float = st_p.move_mult()
    check(st.toggle().contains("ขี่") and st.riding() and absf(st_p.move_mult() - st_m0 * 1.3) < 0.01, "สัตว์ขี่: ขี่แล้วเร็วขึ้น ×1.3")
    check(st.mount_node != null and st_p.body.riding and st_p.body.position.y > 0.5, "สัตว์ขี่: มีโมเดลสัตว์ใต้ตัว นั่งบนอาน")
    var st_pos0: Vector3 = st_p.position
    st_p.drive(Vector3(1, 0, 0), 0.1)
    st_p.position = st_pos0
    st_p.at = -1.0
    st_p.stun = 0.0
    st_p.dash_t = 0.0
    st_p.attack()
    check(not st.riding() and st_p.body.position.y == 0.0, "สัตว์ขี่: ตี = ลงจากหลัง")
    st.toggle()
    world.rooms.enter("store")
    st._process(0.1)
    check(not st.riding(), "สัตว์ขี่: เข้าร้านลงจากหลังอัตโนมัติ")
    check(st.toggle().contains("อาคาร"), "สัตว์ขี่: ขี่ในอาคารไม่ได้")
    world.rooms.leave()
    st_p.lv = 200
    st_p.coins = 2000000
    st.buy("mount", "dgold")
    st.toggle()
    check(st_p.move_mult() <= 2.05 and st.mount_node.get_node_or_null("wingL") != null, "สัตว์ขี่: มังกรทองมีปีก · ความเร็วรวมไม่เกิน ×2.05")
    check(st.use("mount", "horse").contains("ม้าศึก") and st.mount_key == "horse", "สัตว์ขี่: สลับตัวที่ขี่")
    st.dismount()
    # สัตว์เลี้ยง
    var st_str0: int = st_p.stat_total("str")
    check(st.buy("pet", "dog").contains("หมาชิบะ") and st.pet_node != null and st_p.stat_total("str") == st_str0 + 2, "สัตว์เลี้ยง: ซื้อหมาชิบะ ตามตัว + STR+2")
    check(st.magnet() > 9.0, "สัตว์เลี้ยง: ดูดของดรอปจากไกลขึ้น")
    st_p.position = Vector3(world.field.portal_pos.x, 0, world.field.portal_pos.z + 6.0)
    st.pet_node.position = st_p.position + Vector3(8, 0, 0)
    st._process(1.0)
    check(st.pet_node.position.distance_to(st_p.position) < 8.0, "สัตว์เลี้ยง: เดินตามผู้เล่น")
    st.buy("pet", "owl")
    check(st.S.pet == "owl" and st_p.stat_total("str") == st_str0 and st_p.stat_total("int") >= 4, "สัตว์เลี้ยง: เปลี่ยนตัว โบนัสเปลี่ยนตาม")
    st.use("pet", "owl")
    check(st.S.pet == "" and st.magnet() < 5.0, "สัตว์เลี้ยง: ให้พักที่บ้าน")
    # หน้าร้าน
    world.open_shop("st_farm")
    var st_has := false
    for st_b in world.ui_shop_body.find_children("*", "Button", true, false):
        if (st_b as Button).text.contains("สัตว์ขี่"):
            st_has = true
    check(st_has, "สัตว์ขี่: ปุ่มในแผงลุงขายผัก")
    st.tab = "pet"
    st.open()
    check(world.cur_shop == "steed" and world.ui_shop_body.get_child_count() >= 9, "สัตว์เลี้ยง: หน้าร้านสัตว์ 7 ตัว")
    world.close_shop()
    # เซฟ/โหลด
    st.use("pet", "dog")
    st.toggle()
    var st_sv: Dictionary = JSON.parse_string(JSON.stringify(st.S))
    st.load_state({})
    st.load_state(st_sv)
    check(st.S.mounts.size() == 2 and st.S.pet == "dog" and st.riding(), "สัตว์ขี่: เซฟ/โหลด (ที่มี · ตัวที่ใช้ · กำลังขี่)")
    st.load_state({"mounts": ["ม้าปลอม"], "mount": "ม้าปลอม", "pet": "x"})
    st._sync()
    check(st.S.mounts.is_empty() and not st.riding() and st.mount_node == null and st.pet_node == null, "สัตว์ขี่: เซฟเสียไม่พัง")
    st_p.cls = st_cls0
    st_p.lv = st_lv0
    st_p.recalc_stats()

    # ---- ไอคอนไอเท็ม (ถ่ายจากโมเดล 3D) ----
    var ic_miss := []
    for ic_k in Items.ITEM.keys():
        if world.icon_tex(str(ic_k)) == null:
            ic_miss.append(str(ic_k))
    for ic_k in Items.KIND_ORDER:
        for ic_t in 6:
            if world.icon_tex("%s%d" % [ic_k, ic_t]) == null:
                ic_miss.append("%s%d" % [ic_k, ic_t])
    check(ic_miss.is_empty(), "ไอคอน: ไอเท็มทุกชิ้น + อุปกรณ์ทุกชนิดทุกระดับมีรูป (ขาด %s)" % str(ic_miss))
    var ic_buy_miss := []
    for ic_b in Items.BUY.keys():
        if Items.can_buy(str(ic_b)) and not Items.hidden(str(ic_b)) and world.icon_tex(world.buy_icon_id(str(ic_b))) == null:
            ic_buy_miss.append(str(ic_b))
    check(ic_buy_miss.is_empty(), "ไอคอน: ของในร้านที่ซื้อได้มีรูปครบ (ขาด %s)" % str(ic_buy_miss))
    check(world.icon_tex("ไม่มีจริง") == null, "ไอคอน: id ที่ไม่มีคืน null ไม่พัง")
    var ic_img: Image = world.icon_tex("sword3").get_image()
    check(ic_img.get_width() == 96 and ic_img.get_pixel(0, 0).a < 0.05 and ic_img.get_pixel(48, 48).a > 0.5, "ไอคอน: 96×96 พื้นโปร่งใส มีรูปตรงกลาง")
    world.player.inv_add("iron", 3)
    world.open_shop("store")
    await process_frame
    var ic_cnt := 0
    for ic_n in world.ui_shop_body.find_children("*", "Button", true, false):
        if (ic_n as Button).icon != null:
            ic_cnt += 1
    check(ic_cnt >= 4, "ไอคอน: หน้าร้านแสดงรูปบนปุ่มของ (%d ปุ่ม)" % ic_cnt)
    world.close_shop()
    world.refresh_bag()
    await process_frame
    check(world.ui_bag_body.find_children("*", "Button", true, false).filter(func(b): return (b as Button).icon != null).size() >= 1, "ไอคอน: กระเป๋าแสดงรูปของ (ช่องแบบเกม 2D)")
    world.craft.open("furnace")
    await process_frame
    var ic_cf := 0
    for ic_n in world.ui_shop_body.find_children("*", "Button", true, false):
        if (ic_n as Button).icon != null:
            ic_cf += 1
    check(ic_cf >= 5, "ไอคอน: เตาหลอมแสดงรูปแท่งโลหะ (%d)" % ic_cf)
    world.close_shop()

    # ภาพธรรมชาติ: ตรวจต้นไม้ที่ผูกกับฉากจริงและ mesh ที่ใช้ล้ม
    var nature_species := {}
    for tree_info in f.trees:
        nature_species[int(tree_info.get("species", -1))] = true
    check(nature_species.has(0) and nature_species.has(1) and nature_species.has(2) and not nature_species.has(-1), "ธรรมชาติ: ต้นไม้ในทุ่งมีโอ๊ก สน เบิร์ช ครบสามแบบ")
    var tree_info: Dictionary = f.trees[0]
    var falling_visual: Node3D = f._falling_tree(tree_info)
    check(falling_visual.get_child(0).mesh == tree_info.parts[0][0].mesh, "ธรรมชาติ: ต้นล้มใช้รูปทรงเดียวกับต้นที่ยืน")
    falling_visual.free()
    var kit = load("res://scripts/nature_kit.gd")
    for species in 3:
        var pair: Array = kit.tree(species)
        check(pair[0] == kit.tree(species)[0] and pair[1] == kit.tree(species)[1], "ธรรมชาติ: แชร์ mesh ต้นไม้ ไม่สร้างซ้ำทุกต้น")
        check((pair[0].get_faces().size() + pair[1].get_faces().size()) / 3 <= 5000, "ธรรมชาติ: งบสามเหลี่ยมต่อต้นไม่เกิน 5000")
    check(kit.rock() == kit.rock(), "ธรรมชาติ: แชร์ mesh แร่ระหว่างก้อน")

    print("ALL checks=%d failures=%d" % [checks, failures])
    quit(1 if failures > 0 else 0)
