extends RefCounted
## Shared 3D meshes; deterministic local RNG leaves gameplay random state untouched.
static var cache := {}
static var mats := {}
static func tube(st: SurfaceTool, a: Vector3, b: Vector3, r: float, tip: float) -> void:
    var c := CylinderMesh.new()
    c.top_radius = tip
    c.bottom_radius = r
    c.height = a.distance_to(b)
    c.radial_segments = 7
    c.rings = 0
    st.append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, (b-a).normalized())), (a+b)*0.5))
static func leaf(st: SurfaceTool, pos: Vector3, basis: Basis, size: float, color: Color) -> void:
    var pts := [Vector3(0,0,0),Vector3(-0.42,0.05,0.5),Vector3(0,0.1,1),Vector3(0.42,0.05,0.5)]
    for i in [0,1,2,0,2,3]:
        st.set_color(color)
        st.set_normal(basis * Vector3.UP)
        st.set_uv(Vector2(pts[i].x+0.5,pts[i].z))
        st.add_vertex(pos + basis * pts[i] * size)
static func tree(kind: int) -> Array:
    if cache.has(kind): return cache[kind]
    var rng := RandomNumberGenerator.new()
    rng.seed = 8901 + kind
    var bark := SurfaceTool.new()
    var leaves := SurfaceTool.new()
    bark.begin(Mesh.PRIMITIVE_TRIANGLES)
    leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
    var height := 4.8 if kind == 1 else 4.0
    var lean := Vector3(0.12,0,0.08)
    for i in 5:
        var a := Vector3(0,height*i/5.0,0)+lean*i/5.0
        var b := Vector3(0,height*(i+1)/5.0,0)+lean*(i+1)/5.0
        tube(bark,a,b,lerpf(0.24,0.025,i/5.0),lerpf(0.24,0.025,(i+1)/5.0))
    for i in 6:
        var ang := i*TAU/6.0
        tube(bark,Vector3(cos(ang)*0.65,0.03,sin(ang)*0.65),Vector3(0,0.35,0),0.035,0.14)
    var count := 18 if kind == 1 else 14
    for i in count:
        var ang := i*2.4 + rng.randf_range(-0.3,0.3)
        var y := lerpf(1.5,height-0.3,float(i)/count)
        var reach := (height-y)*0.48 if kind == 1 else rng.randf_range(0.85,1.5)
        var start := Vector3(0.1,y,0)
        var end := start+Vector3(cos(ang)*reach,0.15 if kind == 1 else 0.5,sin(ang)*reach)
        tube(bark,start,end,0.07*(1.0-float(i)/count)+0.02,0.012)
        for j in 3:
            var at := start.lerp(end,0.5+j*0.25)
            var fan := ang + (j-1)*0.75
            var dest := at + Vector3(cos(fan)*0.5,0.25,sin(fan)*0.5)
            tube(bark,at,dest,0.018,0.004)
            for k in 14:
                var p := at.lerp(dest,rng.randf())+Vector3(rng.randf_range(-0.3,0.3),rng.randf_range(-0.15,0.2),rng.randf_range(-0.3,0.3))
                var color := Color(0.18,0.31,0.095) if kind == 0 else (Color(0.11,0.25,0.14) if kind == 1 else Color(0.3,0.42,0.13))
                color = color.lightened(rng.randf_range(-0.12,0.15))
                leaf(leaves,p,Basis.from_euler(Vector3(rng.randf_range(-0.8,0.8),rng.randf()*TAU,rng.randf_range(-0.6,0.6))),0.46 if kind == 1 else 0.32,color)
    var result := [bark.commit(),leaves.commit()]
    cache[kind] = result
    return result
static func bark_material(kind: int) -> ShaderMaterial:
    var key := "bark%d" % kind
    if mats.has(key): return mats[key]
    var sh := Shader.new()
    sh.code = "shader_type spatial; varying vec3 p; uniform vec3 base:source_color; uniform bool birch=false; void vertex(){p=VERTEX;} void fragment(){float grain=sin(p.y*13.0+sin(p.x*29.0+p.z*37.0)*2.0); float fissure=pow(abs(sin(atan(p.z,p.x)*23.0+sin(p.y*4.0)*0.7)),12.0); vec3 c=base*(0.72+0.18*grain+0.35*fissure); if(birch){float scar=step(0.8,sin(p.y*39.0+sin(p.x*31.0)*2.0));c=mix(base*(0.87+0.08*grain),c*0.3,scar*0.4);} ALBEDO=c;ROUGHNESS=0.95;}"
    var m := ShaderMaterial.new()
    m.shader = sh
    m.set_shader_parameter("base",Color(0.62,0.6,0.53) if kind == 2 else Color(0.34,0.23,0.15))
    m.set_shader_parameter("birch",kind == 2)
    mats[key]=m
    return m
static func foliage_material() -> StandardMaterial3D:
    if mats.has("leaf"): return mats.leaf
    var m := StandardMaterial3D.new()
    m.vertex_color_use_as_albedo = true
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.roughness = 0.85
    mats.leaf=m
    return m
static func rock() -> ArrayMesh:
    if cache.has("rock"): return cache.rock
    var sphere := SphereMesh.new()
    sphere.radius=0.85
    sphere.height=1.3
    sphere.radial_segments=13
    sphere.rings=7
    var arrays := sphere.get_mesh_arrays()
    var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    for i in verts.size():
        var v := verts[i]
        var n := sin(v.x*12.0+v.z*8.0)*sin(v.y*10.0-v.z*5.0)
        verts[i] = v*(1.0+n*0.16)
    arrays[Mesh.ARRAY_VERTEX]=verts
    var st := SurfaceTool.new()
    st.create_from_arrays(arrays)
    st.generate_normals()
    cache.rock=st.commit()
    return cache.rock
static func ore_material(kind: String) -> ShaderMaterial:
    if mats.has(kind): return mats[kind]
    var sh := Shader.new()
    sh.code="shader_type spatial; varying vec3 p; uniform vec3 mineral:source_color;uniform float metal=0.0;uniform bool plain=false;void vertex(){p=VERTEX;}void fragment(){float grit=sin(p.x*47.0+p.y*29.0)*sin(p.z*53.0-p.y*19.0);float v=abs(sin(p.x*9.0+p.y*7.0+sin(p.z*8.0)+sin(p.y*14.0)*0.4));float vein=1.0-smoothstep(0.08,0.2,v);if(plain){vein=0.0;}ALBEDO=mix(vec3(0.23,0.24,0.25)*(0.85+0.16*grit),mineral,vein);ROUGHNESS=mix(0.92,0.35,vein);METALLIC=vein*metal;}"
    var colors := {"stone":Color(0.5,0.5,0.52),"iron":Color(0.5,0.25,0.13),"copper":Color(0.3,0.58,0.43),"silver":Color(0.8,0.82,0.85),"gold":Color(0.9,0.62,0.17),"diamond":Color(0.6,0.73,0.78)}
    var m := ShaderMaterial.new()
    m.shader=sh
    m.set_shader_parameter("mineral",colors.get(kind,colors.stone))
    m.set_shader_parameter("metal",0.7 if kind in ["silver","gold","iron"] else 0.3)
    m.set_shader_parameter("plain",kind=="stone")
    mats[kind]=m
    return m
