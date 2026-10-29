extends SceneTree
const Kit = preload("res://scripts/item_model_kit.gd")
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var vp = SubViewport.new()
    vp.size = Vector2i(1500,900)
    vp.own_world_3d = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var env = WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("17222b")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("a7bed0")
    env.environment.ambient_light_energy = 0.65
    vp.add_child(env)
    for angle in [Vector3(-0.5,-0.5,0),Vector3(0.3,2.8,0)]:
        var sun = DirectionalLight3D.new()
        sun.rotation = angle
        sun.light_energy = 1.5
        vp.add_child(sun)
    var cam = Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = 12.3
    cam.position = Vector3(0,0,12)
    vp.add_child(cam)
    for i in Kit.IDS.size():
        var id = Kit.IDS[i]
        var n = Kit.instance(id)
        n.position = Vector3((i%6-2.5)*2, (1-i/6)*2.25+0.2, 0)
        n.rotation = Vector3(0.15,-0.35,-0.25)
        if id == "coin": n.rotation.x = 1.1
        if id == "bow": n.rotation.x = 0.85
        vp.add_child(n)
        var label = Label3D.new()
        label.text = id.to_upper()
        label.font_size = 36
        label.pixel_size = 0.006
        label.position = Vector3(n.position.x,n.position.y-0.94,0)
        vp.add_child(label)
    for i in 8: await process_frame
    await RenderingServer.frame_post_draw
    vp.get_texture().get_image().save_png("user://item-models-preview.png")
    quit()
