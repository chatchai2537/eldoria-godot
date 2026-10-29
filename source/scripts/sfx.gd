extends Node
## ระบบเสียง (0.32): เสียงเอฟเฟกต์ 2D/3D + เสียงบรรยากาศตามสถานที่/เวลา + เสียงเท้าตามพื้น
## ไฟล์เสียงสังเคราะห์ด้วย tools/make_sfx.py → assets/sfx/*.wav · ชื่อที่มีหลายแบบ (_0 _1 ...) จะสุ่มแบบ + เพี้ยนระดับเสียงเล็กน้อยทุกครั้ง
## เรียก: town.sfx.play("ui_click") · town.sfx.at("chop", ตำแหน่ง) · ปิด/เปิดเสียง: toggle_mute() (ปุ่มลำโพงมือถือ / คีย์ M)
const DIR := "res://assets/sfx/"
const POOL_2D := 6
const POOL_3D := 10
const AMB_DB := -9.0
const SAVE := "user://eldoria_audio.cfg"

var town
var muted := false
var _cache := {}       # ชื่อ -> Array[AudioStream] (แบบต่าง ๆ)
var _p2: Array = []
var _p3: Array = []
var _i2 := 0
var _i3 := 0
var _last := {}        # กันเสียงเดียวกันซ้อนถี่เกิน (ชื่อ -> msec)
var _amb: Array = []   # ผู้เล่นเสียงบรรยากาศ 2 ตัว สลับเฟดกัน
var _amb_cur := -1
var _amb_name := ""
var _amb_tick := 0.0
var _step_acc := 0.0
var rng := RandomNumberGenerator.new()   # สุ่มของเสียงแยกจากเกม (ไม่ไปเปลี่ยนผลสุ่มดรอป/มอน)

func setup(t) -> void:
    town = t
    name = "Sfx"
    for i in POOL_2D:
        var a := AudioStreamPlayer.new()
        a.bus = "Master"
        add_child(a)
        _p2.append(a)
    for i in POOL_3D:
        var b := AudioStreamPlayer3D.new()
        b.unit_size = 6.0
        b.max_distance = 40.0
        b.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        b.panning_strength = 0.8
        add_child(b)
        _p3.append(b)
    for i in 2:
        var c := AudioStreamPlayer.new()
        c.volume_db = -60.0
        add_child(c)
        _amb.append(c)
    var cf := ConfigFile.new()
    if cf.load(SAVE) == OK:
        muted = bool(cf.get_value("audio", "muted", false))
    AudioServer.set_bus_mute(0, muted)

func toggle_mute() -> bool:
    muted = not muted
    AudioServer.set_bus_mute(0, muted)
    var cf := ConfigFile.new()
    cf.set_value("audio", "muted", muted)
    cf.save(SAVE)
    return muted

## แบบเสียงทั้งหมดของชื่อนี้ (ชื่อ_0.. หรือชื่อเดี่ยว)
func streams(n: String) -> Array:
    if _cache.has(n):
        return _cache[n]
    var L := []
    if ResourceLoader.exists(DIR + n + ".wav"):
        L.append(load(DIR + n + ".wav"))
    var i := 0
    while ResourceLoader.exists(DIR + "%s_%d.wav" % [n, i]):
        L.append(load(DIR + "%s_%d.wav" % [n, i]))
        i += 1
    _cache[n] = L
    return L

func _pick(n: String, gap_ms: int) -> AudioStream:
    var L := streams(n)
    if L.is_empty():
        return null
    var now := Time.get_ticks_msec()
    if now - int(_last.get(n, -100000)) < gap_ms:
        return null
    _last[n] = now
    return L[rng.randi() % L.size()]

## เสียงไม่มีทิศทาง (UI · ตัวเราเอง)
func play(n: String, db: float = 0.0, jitter: float = 0.05, gap_ms: int = 40) -> void:
    var s := _pick(n, gap_ms)
    if s == null:
        return
    var a: AudioStreamPlayer = _p2[_i2]
    _i2 = (_i2 + 1) % _p2.size()
    a.stream = s
    a.volume_db = db
    a.pitch_scale = 1.0 + rng.randf_range(-jitter, jitter)
    a.play()

## เสียงมีตำแหน่งในโลก (ดังเบาตามระยะ · ซ้าย/ขวาตามกล้อง)
func at(n: String, pos: Vector3, db: float = 0.0, jitter: float = 0.08, gap_ms: int = 40) -> void:
    if town != null and town.cam != null and town.cam.global_position.distance_to(pos) > 48.0:
        return
    var s := _pick(n, gap_ms)
    if s == null:
        return
    var b: AudioStreamPlayer3D = _p3[_i3]
    _i3 = (_i3 + 1) % _p3.size()
    b.stream = s
    b.volume_db = db
    b.pitch_scale = 1.0 + rng.randf_range(-jitter, jitter)
    b.global_position = pos
    b.play()

## ---- บรรยากาศ ----
func ambient_name() -> String:
    if town == null or town.player == null:
        return ""
    if town.room != "":
        return ""
    if town.mine != null and town.mine.cur >= 0:
        return "amb_mine"
    var night: bool = town.time_of_day < 0.24 or town.time_of_day > 0.8
    if night:
        return "amb_night"
    var p: Vector3 = town.player.position
    if town.in_field_rect(p.x, p.z, 0.0):
        return "amb_field"
    return "amb_town"

func _set_amb(n: String) -> void:
    if n == _amb_name:
        return
    _amb_name = n
    _amb_cur = (_amb_cur + 1) % 2
    var a: AudioStreamPlayer = _amb[_amb_cur]
    var L := streams(n) if n != "" else []
    if not L.is_empty():
        var s: AudioStreamWAV = L[0]
        s.loop_mode = AudioStreamWAV.LOOP_FORWARD
        s.loop_begin = 0
        s.loop_end = int(s.get_length() * s.mix_rate)
        a.stream = s
        a.volume_db = -50.0
        a.play()

func _process(delta: float) -> void:
    if town == null:
        return
    _amb_tick -= delta
    if _amb_tick <= 0.0:
        _amb_tick = 1.0
        _set_amb(ambient_name())
    # เฟดเสียงบรรยากาศ: ตัวปัจจุบันขึ้น ตัวเก่าลง
    for i in _amb.size():
        var a: AudioStreamPlayer = _amb[i]
        var want := AMB_DB if (i == _amb_cur and _amb_name != "") else -60.0
        a.volume_db = move_toward(a.volume_db, want, delta * 25.0)
        if a.volume_db <= -59.0 and a.playing and i != _amb_cur:
            a.stop()
    _steps(delta)

## ---- เสียงเท้า: ทุกช่วงก้าวตามระยะที่เดินจริง · พื้นตามสถานที่ ----
func step_surface() -> String:
    if town.room != "":
        return "step_stone"
    if town.mine != null and town.mine.cur >= 0:
        return "step_dirt"
    var p: Vector3 = town.player.position
    return "step_grass" if town.in_field_rect(p.x, p.z, 0.0) else "step_stone"

var _last_pos := Vector3.INF
func _steps(delta: float) -> void:
    var p = town.player
    if p == null or p.dead:
        return
    if _last_pos == Vector3.INF:
        _last_pos = p.position
    var moved: float = Vector2(p.position.x - _last_pos.x, p.position.z - _last_pos.z).length()
    _last_pos = p.position
    if moved > 3.0 or (town.steed != null and town.steed.riding()) or p.dash_t > 0.0:
        _step_acc = 0.0
        return
    _step_acc += moved
    var stride: float = 1.25 if moved / max(delta, 0.001) < 4.5 else 1.7
    if _step_acc >= stride:
        _step_acc = 0.0
        play(step_surface(), -6.0, 0.08, 0)
