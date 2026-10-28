extends SceneTree
## godot --headless --path source --script res://tests/startup_smoke.gd -- --mobile
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("FAIL: " + message)

func _run() -> void:
    var started := Time.get_ticks_msec()
    var marker := FileAccess.open("user://startup_state.json", FileAccess.WRITE)
    var recover := OS.get_cmdline_user_args().has("--recovery-test")
    marker.store_string(JSON.stringify({"loading": recover, "stage": "ทดสอบโหลดค้าง"}))
    marker.close()
    var boot: Node = load("res://startup.tscn").instantiate()
    root.add_child(boot)
    for frame in 300:
        await process_frame
        if current_scene != null and current_scene.get("world_loaded") == true:
            break
    var world: Node = current_scene
    check(world != null and world.get("world_loaded") == true, "startup completed")
    if world == null:
        quit(1)
        return
    check(world.player.body.get_script() != null, "character script compiles and loads")
    if world.player.body.get_script() == null:
        quit(1)
        return
    check(world.is_mobile, "mobile profile selected")
    check(world.recovery_mode == recover, "recovery selected only after interrupted startup")
    check(root.msaa_3d == Viewport.MSAA_DISABLED, "MSAA stays disabled")
    check(not world.sun.shadow_enabled and world.env.sky == null, "mobile skips shadow and sky cubemap")
    check(world.npcs.size() == 19, "all 19 NPCs preserved")
    check(world.field.slimes.size() == 16, "all 16 slimes preserved")
    var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://startup_state.json"))
    check(not state.loading, "successful load clears interrupted marker")
    world.process_mode = Node.PROCESS_MODE_DISABLED
    var p: Node = world.player
    p.position = Vector3(-68, world.ground_y(-68, 0), 0)
    var before: Vector3 = p.position
    p.drive(Vector3.RIGHT, 0.1)
    check(p.position.x > before.x, "walking works in field")
    p.dash(Vector3.RIGHT)
    check(p.dash_t > 0.0, "dash begins")
    p._process(0.1)
    check(p.position.x > before.x + 0.6, "dash moves player")
    p.dash_t = 0.0
    p.hp = 100.0
    p.hurt_by({"lv": 1})
    check(p.hp == 96.0 and p.kx == 0.0 and p.kz == 0.0, "damage preserves no-knockback rule")
    p.stats.str = 5
    p.heading = 0.0
    var s: Node = world.field.slimes[0]
    s.position = p.position + Vector3(0, 0, 1.4)
    s.lv = 1
    s.hp = 3
    var xp_before: int = p.xp
    world.field.melee(p, false, world.field.new_attack())
    check(s.dead and p.xp == xp_before + 5, "combat grants same XP")
    check(not world.field.drops.is_empty(), "combat still creates loot")
    world.open_shop("gear")
    check(world.ui_shop.visible, "shop UI opens")
    print("SMOKE recovery=", recover, " failures=", failures, " load_ms=", Time.get_ticks_msec() - started)
    quit(0 if failures == 0 else 1)
