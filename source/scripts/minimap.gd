extends Control
## แผนที่เล็กมุมขวา (เกม 2D mkMini/MINIW): โลกภายนอก (ทุ่ง+เมือง) · เหมือง · ดันเจี้ยน
## ภาพแผนที่สร้างครั้งเดียวต่อพื้นที่ · จุดบอกตำแหน่งวาดใหม่ 5 ครั้ง/วิ (ไม่หนักมือถือ)

var town
var tex: ImageTexture
var o := Vector2.ZERO        # มุมซ้ายบนของแผนที่ในโลก (x, z)
var cell := 2.0              # หน่วยโลกต่อ 1 พิกเซล
var size_px := Vector2i.ONE
var key := ""
var _t := 0.0
const MAXW := 150.0

func setup(t) -> void:
    town = t
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    anchor_left = 1.0
    anchor_right = 1.0
    offset_top = 56

func _overworld() -> void:
    var W := 104
    var H := 44
    var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
    for y in H:
        for x in W:
            var wx: float = town.FX0 + x * 2.0 + 1.0
            var wz: float = town.FZ0 + y * 2.0 + 1.0
            var c := Color(0.08, 0.1, 0.08, 0.85)
            if x < town.FW:
                match town.ftile(x, y):
                    town.F_WATER:
                        c = Color(0.25, 0.5, 0.85)
                    town.F_SAND:
                        c = Color(0.85, 0.78, 0.5)
                    town.F_TREE:
                        c = Color(0.12, 0.38, 0.15)
                    _:
                        c = Color(0.35, 0.62, 0.3)
            elif abs(wz) <= 34.0:
                c = Color(0.3, 0.28, 0.26) if town.blocked(wx, wz) else Color(0.72, 0.68, 0.6)
            img.set_pixel(x, y, c)
    _use(img, Vector2(town.FX0, town.FZ0), 2.0)

func _grid(d: Dictionary, org: Vector3) -> void:
    var W: int = d.W
    var H: int = d.H
    var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
    for y in H:
        for x in W:
            img.set_pixel(x, y, Color(0.75, 0.7, 0.62) if d.m[y * W + x] == 0 else Color(0.1, 0.09, 0.12, 0.85))
    _use(img, Vector2(org.x, org.z), 2.0)

func _use(img: Image, org: Vector2, c: float) -> void:
    tex = ImageTexture.create_from_image(img)
    o = org
    cell = c
    size_px = img.get_size()
    var sc := MAXW / size_px.x
    var sz := Vector2(size_px) * sc
    offset_left = -sz.x - 12
    offset_right = -12
    offset_bottom = offset_top + sz.y
    queue_redraw()

func _to_px(w: Vector3) -> Vector2:
    var sc := (offset_right - offset_left) / size_px.x
    return Vector2((w.x - o.x) / cell, (w.z - o.y) / cell) * sc

func _process(delta: float) -> void:
    if town == null or town.player == null:
        return
    var k := "world"
    if town.room != "":
        k = "room"
    elif town.mine.cur >= 0:
        k = "mine%d" % town.mine.cur
    visible = k != "room"
    if k != key:
        key = k
        if k == "world":
            _overworld()
        elif k.begins_with("mine"):
            _grid(town.mine.data[town.mine.cur], town.mine.origin(town.mine.cur))
    _t += delta
    if _t >= 0.2:
        _t = 0.0
        queue_redraw()

func _draw() -> void:
    if tex == null:
        return
    var r := Rect2(Vector2.ZERO, Vector2(offset_right - offset_left, offset_bottom - offset_top))
    draw_rect(r.grow(2), Color(0, 0, 0, 0.55))
    draw_texture_rect(tex, r, false, Color(1, 1, 1, 0.9))
    var m = town.mine
    if m.cur >= 0:
        draw_circle(_to_px(m.exit_pos(m.cur)), 3.0, Color(0.75, 0.5, 1.0))
        if m.boss != null and is_instance_valid(m.boss):
            draw_circle(_to_px(m.boss.position), 4.0, Color(1.0, 0.25, 0.2))
        if not m.chest.is_empty():
            draw_circle(_to_px(m.chest.pos), 3.5, Color(1.0, 0.85, 0.3))
    else:
        draw_circle(_to_px(town.field.portal_pos), 3.0, Color(0.75, 0.5, 1.0))
        draw_circle(_to_px(town.field.dungeon_pos), 3.0, Color(0.55, 0.45, 0.6))
    if town.story != null:
        var g: Vector3 = town.story.guide_target()
        if g != Vector3.INF:
            draw_circle(_to_px(g), 3.0, Color(1.0, 0.85, 0.3))
    var pp := _to_px(town.player.position)
    draw_circle(pp, 4.0, Color(0, 0, 0))
    draw_circle(pp, 3.0, Color(1, 1, 1))
