extends SceneTree
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("FAIL: " + message)

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    var world: Node = packed.instantiate()
    world.process_mode = Node.PROCESS_MODE_DISABLED
    root.add_child(world)
    await world.world_ready
    var p: Node = world.player
    p.position = Vector3(-55, world.ground_y(-55, 0), 0)
    var start: Vector3 = p.position
    p.set_attack_held(true)
    var first_id: int = p.cur_atk
    for i in 45:
        p._process(1.0 / 30.0)
        check(p.body.cur == "1H_Melee_Attack_Slice_Diagonal", "every repeated attack uses normal slash")
    check(p.cur_atk >= first_id + 3, "holding repeats attacks")
    check(p.position.is_equal_approx(start), "held attack stays in place")
    p.set_attack_held(false)
    for i in 20:
        p._process(1.0 / 30.0)
    var released_id: int = p.cur_atk
    for i in 30:
        p._process(1.0 / 30.0)
    check(p.cur_atk == released_id and p.at < 0.0, "release stops repeating")
    p.attack()
    p.dash(Vector3.RIGHT)
    check(p.at < 0.0 and p.dash_t > 0.0, "roll can interrupt an attack")
    p._process(0.25)
    check(p.position.x > start.x + 1.0 and p.position.x < start.x + 1.3, "roll moves smoothly over half a second")
    check(p.body.roll_pivot.basis.y.y < -0.9, "roll visually turns body upside down halfway")
    check(p.iframe > 0.0, "roll protects player")
    p._process(0.25)
    check(is_equal_approx(p.position.x, start.x + 2.3), "roll covers intended short distance")
    check(p.body.roll_pivot.transform.is_equal_approx(Transform3D.IDENTITY), "roll restores upright body")
    check(p.body.inst.position.is_zero_approx(), "roll restores model position")
    var slime: Node = world.field.slimes[0]
    var mesh_level: int = slime.lv
    slime.lv = 1
    slime.hp = 20
    slime.max_hp = 20
    slime.position = p.position + Vector3(0, 0, 0.8)
    var slime_start: Vector3 = slime.position
    slime.take_hit(1, p.position)
    check(slime.position.is_equal_approx(slime_start), "hit does not push monster")
    slime.hurt = 0.0
    slime.cool = 0.0
    slime.t = 0.7
    p.iframe = 0.0
    p.hp = 100.0
    slime._process(0.05)
    check(p.hp == 96.0, "monster still attacks")
    check(Vector2(slime.position.x, slime.position.z).is_equal_approx(Vector2(slime_start.x, slime_start.z)), "monster does not recoil after attacking")
    var other: Node = Node3D.new()
    other.set_script(load("res://scripts/slime.gd"))
    world.field.add_child(other)
    other.setup(world.field, mesh_level, slime.position + Vector3(5, 0, 0))
    check(other.body.mesh == slime.body.mesh, "respawn reuses body geometry")
    other.queue_free()
    var touch := InputEventScreenTouch.new()
    touch.index = 7
    touch.position = world.mobile.atk.position + world.mobile.atk.size * 0.5
    touch.pressed = true
    world.mobile._input(touch)
    check(p.attack_held, "touch press holds attack")
    touch.pressed = false
    world.mobile._input(touch)
    check(not p.attack_held and world.mobile.attack_touch_id == -1, "touch release clears attack finger")
    print("COMBAT failures=", failures, " attacks=", released_id, " roll_distance=2.3")
    quit(0 if failures == 0 else 1)
