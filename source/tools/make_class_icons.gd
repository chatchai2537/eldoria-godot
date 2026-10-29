extends SceneTree
## ภาพหน้าอาชีพ 12 สาย (0.30) จากโมเดล 3D จริง → assets/icons/cls_<อาชีพ>.png (160×160 พื้นโปร่งใส)
## รัน: xvfb-run godot --path source --rendering-driver opengl3 --script res://tools/make_class_icons.gd
const Skills = preload("res://scripts/skills.gd")
const OUT := "res://assets/icons/"
## ของที่โชว์ต่ออาชีพ [ไฟล์ต้นทาง, ชิ้น] — ตาม player.gd GEAR_SLOTS / _weapon_items
const SHOW := {
    "sword": [["knight", "1H_Sword"], ["knight", "Round_Shield"], ["knight", "Knight_Helmet"], ["knight", "Knight_Cape"]],
    "paladin": [["knight", "1H_Sword"], ["knight", "Badge_Shield"], ["knight", "Knight_Helmet"], ["knight", "Knight_Cape"]],
    "dragoon": [["barbarian", "2H_Axe"], ["barbarian", "Barbarian_Hat"], ["barbarian", "Barbarian_Cape"]],
    "archer": [["rogue", "1H_Crossbow"], ["rogue", "Rogue_Cape"]],
    "sniper": [["rogue", "2H_Crossbow"], ["rogue", "Rogue_Cape"]],
    "summoner": [["rogue", "1H_Crossbow"], ["rogue", "Rogue_Cape"]],
    "mage": [["mage", "2H_Staff"], ["mage", "Mage_Hat"], ["mage", "Mage_Cape"], ["mage", "Spellbook"]],
    "cleric": [["mage", "1H_Wand"], ["mage", "Spellbook_open"], ["mage", "Mage_Cape"]],
    "necro": [["mage", "2H_Staff"], ["mage", "Mage_Hat"], ["mage", "Mage_Cape"]],
    "rogue": [["rogue", "Knife"], ["rogue", "Knife_Offhand"], ["rogue", "Rogue_Cape"]],
    "ninja": [["rogue", "Knife"], ["rogue", "Throwable"], ["rogue", "Rogue_Cape"]],
    "monk": [["rogue", "Rogue_Cape"]],
}
## สีย้อมเสื้อผ้าเล็กน้อยให้สายย่อยต่างจากสายหลัก
const TINT := {"paladin": Color(1.0, 0.95, 0.75), "necro": Color(0.55, 0.9, 0.65), "cleric": Color(0.85, 0.95, 1.0), "ninja": Color(0.55, 0.6, 0.85), "monk": Color(1.0, 0.75, 0.45), "sniper": Color(0.95, 0.85, 0.45), "summoner": Color(0.7, 0.9, 0.5)}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var vp := SubViewport.new()
    vp.size = Vector2i(160, 160)
    vp.transparent_bg = true
    vp.own_world_3d = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_CLEAR_COLOR
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(1, 1, 1)
    e.ambient_light_energy = 0.6
    env.environment = e
    vp.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(-0.7, 0.5, 0)
    sun.light_energy = 1.3
    vp.add_child(sun)
    var cam := Camera3D.new()
    cam.fov = 30.0
    vp.add_child(cam)
    cam.position = Vector3(0.9, 1.75, 3.4)
    cam.look_at(Vector3(0.05, 1.05, 0))
    var cls_tool = Skills.new()
    var n := 0
    for k in Skills.CLASS_ORDER:
        var body := Node3D.new()
        body.set_script(load("res://scripts/model.gd"))
        vp.add_child(body)
        var o := {"model": cls_tool.model_of(k), "keep": []}
        if TINT.has(k):
            o["tint"] = TINT[k]
        body.build(o)
        body.rotation.y = 0.35
        for it in SHOW.get(k, []):
            body.borrow_item(str(it[0]), str(it[1]))
            body.show_item(str(it[1]), true)
        if k == "monk":
            body._play("Unarmed_Idle", 0.0)
        for i in 8:
            await process_frame
        vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "cls_%s.png" % k))
        body.free()
        n += 1
    cls_tool.free()
    print("class icons: ", n)
    quit(0)
