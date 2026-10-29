extends RefCounted
## Shared, opaque 3D item meshes. Pivot is the grip for weapons, centre for loot.
const Nature = preload("res://scripts/nature_kit.gd")
const IDS = ["sword", "dagger", "staff", "bow", "axe", "pick", "hpp", "mpp", "scroll", "wood", "stone", "iron", "copper", "silver", "gold", "diamond", "coin", "gel"]
static var cache: Dictionary = {}
var parts: Dictionary = {}

func material(key: String) -> Material:
    var palette = {"steel": Color("899ba6"), "edge": Color("d4dde0"), "brass": Color("a88949"), "wood": Color("62422a"), "leather": Color("302b28"), "paper": Color("cbb992"), "red": Color("7e2634"), "blue": Color("245873"), "cork": Color("8a6943"), "gel": Color("5b939a")}
    var m = StandardMaterial3D.new()
    m.albedo_color = palette.get(key, Color.WHITE)
    m.metallic = 0.8 if key in ["steel", "edge", "brass"] else 0.0
    m.roughness = 0.32 if m.metallic > 0 else (0.18 if key in ["red", "blue", "gel"] else 0.85)
    if key in ["wood", "leather", "paper", "cork", "steel", "edge", "brass"]:
        var textured = ShaderMaterial.new()
        var shader = Shader.new()
        shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color;
uniform float metalness;
uniform float base_roughness;
uniform float grain_scale;
varying vec3 local_pos;
void vertex(){local_pos=VERTEX;}
void fragment(){
    float grain = sin(local_pos.x*grain_scale + sin(local_pos.y*13.0)*2.0 + local_pos.z*grain_scale);
    float pores = fract(sin(dot(floor(local_pos*550.0),vec3(12.98,78.23,42.12)))*43758.54);
    ALBEDO=base_color.rgb*(0.91+0.07*grain+0.07*pores);
    METALLIC=metalness;
    ROUGHNESS=clamp(base_roughness+0.1*grain,0.15,0.95);
}"""
        textured.shader = shader
        textured.set_shader_parameter("base_color", m.albedo_color)
        textured.set_shader_parameter("metalness", m.metallic)
        textured.set_shader_parameter("base_roughness", m.roughness)
        textured.set_shader_parameter("grain_scale", 240.0 if m.metallic > 0 else 110.0)
        return textured
    return m

func add(mesh: Mesh, key: String, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> void:
    if not parts.has(key):
        var st = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        parts[key] = st
    parts[key].append_from(mesh, 0, Transform3D(Basis.from_euler(rot).scaled(scale), pos))

func rod(a: Vector3, b: Vector3, radius: float, key: String, tip: float = -1.0) -> void:
    var c = CylinderMesh.new()
    c.top_radius = radius if tip < 0 else tip
    c.bottom_radius = radius
    c.height = a.distance_to(b)
    c.radial_segments = 10
    c.rings = 0
    var q = Quaternion(Vector3.UP, (b-a).normalized())
    add(c, key, (a+b)*0.5, q.get_euler())

func ball(at: Vector3, radius: float, scale: Vector3, key: String) -> void:
    var s = SphereMesh.new()
    s.radius = radius
    s.height = radius*2
    s.radial_segments = 16
    s.rings = 8
    add(s, key, at, Vector3.ZERO, scale)

func box(size: Vector3, at: Vector3, key: String, rot: Vector3 = Vector3.ZERO) -> void:
    var b = BoxMesh.new()
    b.size = size
    add(b, key, at, rot)

func blade(outline: Array, depth: float, key: String) -> void:
    # Raised central ridge and sharpened perimeter, actual geometry on both faces.
    var area = 0.0
    for i in outline.size():
        var a: Vector3 = outline[i]
        var b: Vector3 = outline[(i+1)%outline.size()]
        area += a.x*b.y-b.x*a.y
    if area < 0: outline.reverse()
    var center = Vector3.ZERO
    for p in outline: center += p
    center /= outline.size()
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for sign_z in [-1.0, 1.0]:
        for i in outline.size():
            var a: Vector3 = outline[i]
            var b: Vector3 = outline[(i+1)%outline.size()]
            var c = center + Vector3(0, 0, depth*sign_z)
            var verts = [a,b,c] if sign_z > 0 else [b,a,c]
            for v in verts:
                st.set_uv(Vector2(v.x,v.y))
                st.add_vertex(v)
    st.generate_normals()
    st.index()
    add(st.commit(), key)

func build(id: String) -> ArrayMesh:
    if id in ["sword", "dagger"]:
        var length = 0.86 if id == "sword" else 0.43
        blade([Vector3(-0.075,0.18,0),Vector3(0.075,0.18,0),Vector3(0.065,length,0),Vector3(0,length+0.19,0),Vector3(-0.065,length,0)],0.027,"edge")
        rod(Vector3(0,-0.22,0),Vector3(0,0.17,0),0.047,"leather")
        for i in 9: rod(Vector3(0,-0.2+i*0.039,0),Vector3(0,-0.19+i*0.039,0),0.05,"wood")
        rod(Vector3(-0.2,0.16,0),Vector3(0.2,0.16,0),0.035,"steel")
        ball(Vector3(0,-0.25,0),0.065,Vector3(1,0.8,0.65),"brass")
    elif id in ["axe", "pick", "staff"]:
        rod(Vector3(0,-0.5,0),Vector3(0,0.6,0),0.043,"wood",0.035)
        for i in 8: rod(Vector3(0,-0.42+i*0.032,0),Vector3(0,-0.4+i*0.032,0),0.047,"leather")
        rod(Vector3(0,0.38,0),Vector3(0,0.5,0),0.068,"steel")
        if id == "axe":
            blade([Vector3(-0.05,0.62,0),Vector3(0.31,0.73,0),Vector3(0.4,0.56,0),Vector3(0.4,0.32,0),Vector3(0.13,0.33,0),Vector3(-0.05,0.4,0)],0.065,"steel")
        elif id == "pick":
            blade([Vector3(-0.46,0.3,0),Vector3(-0.25,0.58,0),Vector3(0.25,0.58,0),Vector3(0.46,0.3,0),Vector3(0.17,0.46,0),Vector3(-0.17,0.46,0)],0.055,"edge")
        else:
            ball(Vector3(0,0.69,0),0.14,Vector3(0.75,1.3,0.75),"blue")
            for x in [-1,1]: rod(Vector3(x*0.03,0.5,0),Vector3(x*0.12,0.75,0),0.023,"brass",0.01)
    elif id == "bow":
        box(Vector3(0.11,0.11,0.8),Vector3.ZERO,"wood")
        box(Vector3(0.13,0.19,0.25),Vector3(0,-0.06,0.3),"leather",Vector3(-0.25,0,0))
        for s in [-1,1]:
            rod(Vector3(0,0,-0.24),Vector3(s*0.31,0,-0.17),0.036,"steel",0.025)
            rod(Vector3(s*0.31,0,-0.17),Vector3(s*0.5,0,-0.05),0.025,"steel",0.012)
            rod(Vector3(s*0.5,0,-0.05),Vector3(0,0,0.2),0.006,"paper")
        rod(Vector3(0,0.09,0.18),Vector3(0,0.09,-0.5),0.012,"wood")
        ball(Vector3(0,0.09,-0.5),0.04,Vector3(0.6,0.4,1.6),"edge")
    elif id in ["hpp", "mpp"]:
        var color = "red" if id == "hpp" else "blue"
        ball(Vector3(0,-0.08,0),0.24,Vector3(0.9,1.1,0.9),color)
        rod(Vector3(0,0.1,0),Vector3(0,0.29,0),0.085,color,0.075)
        rod(Vector3(0,0.25,0),Vector3(0,0.28,0),0.098,"brass")
        rod(Vector3(0,0.28,0),Vector3(0,0.35,0),0.072,"cork",0.08)
        box(Vector3(0.17,0.16,0.018),Vector3(0,-0.06,0.225),"paper")
        box(Vector3(0.08,0.022,0.022),Vector3(0,-0.06,0.24),color)
        if id == "hpp": box(Vector3(0.022,0.08,0.022),Vector3(0,-0.06,0.24),color)
    elif id == "scroll":
        box(Vector3(0.48,0.6,0.025),Vector3.ZERO,"paper")
        for y in [-0.3,0.3]: rod(Vector3(-0.29,y,0),Vector3(0.29,y,0),0.065,"paper")
        box(Vector3(0.05,0.61,0.04),Vector3.ZERO,"leather")
        ball(Vector3(0,-0.03,0.045),0.065,Vector3(1,1,0.25),"red")
    elif id == "wood":
        rod(Vector3(-0.42,0,0),Vector3(0.42,0,0),0.18,"wood",0.15)
        for x in [-0.425,0.425]:
            rod(Vector3(x-0.003,0,0),Vector3(x+0.003,0,0),0.145,"paper")
        for i in 8:
            var angle = i*TAU/8
            rod(Vector3(-0.4,cos(angle)*0.17,sin(angle)*0.17),Vector3(0.4,cos(angle)*0.145,sin(angle)*0.145),0.015,"leather")
    elif id in ["stone","iron","copper","silver","gold","diamond"]:
        add(Nature.rock(), "ore",Vector3.ZERO,Vector3.ZERO,Vector3.ONE*0.5)
    elif id == "coin":
        rod(Vector3(0,-0.028,0),Vector3(0,0.028,0),0.24,"brass")
        rod(Vector3(0,0.028,0),Vector3(0,0.034,0),0.19,"steel")
        box(Vector3(0.07,0.015,0.22),Vector3(0,0.045,0),"brass")
    elif id == "gel":
        ball(Vector3.ZERO,0.25,Vector3(1,0.55,1),"gel")
        for i in 3: ball(Vector3(i*0.12-0.1,0.08,0),0.09,Vector3.ONE,"blue")
    var result = ArrayMesh.new()
    for key in parts:
        var st: SurfaceTool = parts[key]
        st.index()
        st.commit(result)
        var mat = Nature.ore_material(id) if key == "ore" else material(key)
        result.surface_set_material(result.get_surface_count()-1,mat)
    return result

static func mesh(id: String) -> ArrayMesh:
    if not IDS.has(id): return null
    if not cache.has(id): cache[id] = new().build(id)
    return cache[id]

static func instance(id: String) -> MeshInstance3D:
    var n = MeshInstance3D.new()
    n.name = id
    n.mesh = mesh(id)
    return n
