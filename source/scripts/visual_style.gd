extends RefCounted
## วัสดุใช้ texture ร่วมกัน เงาสัมผัสไม่เพิ่ม shadow pass บนมือถือ
static var _textures := {}
static var _roof_materials := {}
static var _contact_material: StandardMaterial3D
static var _contact_mesh: PlaneMesh

static func normals_enabled() -> bool:
    return not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--mobile"))

static func texture_for(name: String) -> Texture2D:
    if not _textures.has(name):
        _textures[name] = load("res://assets/style/" + name + ".png")
    return _textures[name]

static func surface(color: Color, roughness: float, emission: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.from_hsv(color.h, color.s * 0.65, color.v, color.a)
    material.roughness = roughness
    if emission > 0.0:
        material.albedo_color = color
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission
        return material
    var kind := ""
    if color.s < 0.22 and roughness >= 0.85:
        kind = "stone" if color.v < 0.75 else "plaster"
    elif color.r > color.g * 1.15 and color.g > color.b * 1.1 and color.r < 0.68:
        kind = "wood"
    elif roughness >= 0.85:
        kind = "plaster"
    if kind != "":
        apply_texture(material, kind)
    elif roughness <= 0.45:
        material.metallic = 0.55
    return material

static func apply_texture(material: StandardMaterial3D, kind: String) -> void:
    material.albedo_texture = texture_for(kind + "_color")
    material.normal_enabled = normals_enabled()
    if material.normal_enabled:
        material.normal_texture = texture_for(kind + "_normal")
    material.normal_scale = 0.45 if kind == "stone" or kind == "slate" else 0.22
    material.uv1_scale = Vector3(3, 3, 1)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

static func roof(material: StandardMaterial3D) -> StandardMaterial3D:
    var key := material.get_instance_id()
    if not _roof_materials.has(key):
        var copy: StandardMaterial3D = material.duplicate()
        apply_texture(copy, "slate")
        copy.albedo_color = copy.albedo_color.lightened(0.08)
        copy.roughness = 0.72
        _roof_materials[key] = copy
    return _roof_materials[key]

static func add_contact(parent: Node3D, width: float, depth: float) -> MeshInstance3D:
    if _contact_material == null:
        var gradient := Gradient.new()
        gradient.set_color(0, Color(0.025, 0.035, 0.04, 0.32))
        gradient.set_color(1, Color(0.025, 0.035, 0.04, 0))
        var texture := GradientTexture2D.new()
        texture.width = 64
        texture.height = 64
        texture.gradient = gradient
        texture.fill = GradientTexture2D.FILL_RADIAL
        texture.fill_from = Vector2(0.5, 0.5)
        texture.fill_to = Vector2(1, 0.5)
        _contact_material = StandardMaterial3D.new()
        _contact_material.albedo_texture = texture
        _contact_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        _contact_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        _contact_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
        _contact_mesh = PlaneMesh.new()
        _contact_mesh.size = Vector2.ONE
    var contact := MeshInstance3D.new()
    contact.name = "ContactShadow"
    contact.mesh = _contact_mesh
    contact.material_override = _contact_material
    contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    contact.scale = Vector3(width, 1, depth)
    contact.position.y = 0.035
    parent.add_child(contact)
    return contact
