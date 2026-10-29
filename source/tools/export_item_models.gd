extends SceneTree
const Kit = preload("res://scripts/item_model_kit.gd")
func _initialize() -> void:
    DirAccess.make_dir_recursive_absolute("res://assets/item_models")
    for id in Kit.IDS:
        var n = Kit.instance(id)
        var packed = PackedScene.new()
        packed.pack(n)
        ResourceSaver.save(packed, "res://assets/item_models/%s.tscn" % id)
        print(id, " triangles=", n.mesh.get_faces().size()/3)
        n.free()
    quit()
