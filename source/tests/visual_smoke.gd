extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("FAIL: " + message)
func _run() -> void:
    var world: Node = load("res://main.tscn").instantiate()
    world.process_mode = Node.PROCESS_MODE_DISABLED
    root.add_child(world)
    await world.world_ready
    var style = load("res://scripts/visual_style.gd")
    var stone: StandardMaterial3D = world.M(Color(0.5, 0.5, 0.5), 0.95)
    check(stone.albedo_texture != null, "stone uses real shared texture")
    check(not stone.normal_enabled and not style.normals_enabled(), "mobile skips normal map sampling")
    check(stone == world.M(Color(0.5, 0.5, 0.5), 0.95), "material cache stays shared")
    check(world.player.has_node("ContactShadow"), "player has contact shadow")
    var skeleton: Skeleton3D = world.player.body.inst.get_node("Rig/Skeleton3D")
    check(is_equal_approx(skeleton.get_bone_pose_scale(skeleton.find_bone("head")).x, 0.84), "head proportions refined without changing rig")
    check(world.field.hud_card is PanelContainer, "compact HUD card exists")
    check(not world.sun.shadow_enabled and world.env.sky == null, "expensive mobile effects stay disabled")
    check(world.npcs.size() == 19 and world.field.slimes.size() == 16, "world population preserved")
    print("VISUAL failures=", failures, " shared_textures=", style._textures.size())
    quit(0 if failures == 0 else 1)
