extends Node
## 배경음악, 효과음, 설정(소리 크기·전체 화면). 자동 로드(Audio)예요.

const SETTINGS_PATH := "user://settings.cfg"

var bgm_volume := 0.6
var sfx_volume := 0.8
var fullscreen := false

var _bgm := AudioStreamPlayer.new()
var _bgm_name := ""
var _pool: Array = []
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	load_settings()
	apply()


func play_bgm(name: String) -> void:
	if name == _bgm_name:
		return
	_bgm_name = name
	var s: AudioStreamOggVorbis = load("res://assets/audio/%s.ogg" % name)
	s.loop = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _bgm.playing:
		_tween.tween_property(_bgm, "volume_db", -40.0, 0.5)
	_tween.tween_callback(func():
		_bgm.stream = s
		_bgm.volume_db = -40.0
		_bgm.play())
	_tween.tween_property(_bgm, "volume_db", _db(bgm_volume), 0.8)


func sfx(name: String, pitch := 1.0) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = load("res://assets/audio/%s.ogg" % name)
			p.volume_db = _db(sfx_volume)
			p.pitch_scale = pitch
			p.play()
			return


func _db(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))


func apply() -> void:
	if not (_tween and _tween.is_running()):
		_bgm.volume_db = _db(bgm_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save_settings() -> void:
	var c := ConfigFile.new()
	c.set_value("sound", "bgm", bgm_volume)
	c.set_value("sound", "sfx", sfx_volume)
	c.set_value("display", "fullscreen", fullscreen)
	c.save(SETTINGS_PATH)


func load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS_PATH) == OK:
		bgm_volume = c.get_value("sound", "bgm", bgm_volume)
		sfx_volume = c.get_value("sound", "sfx", sfx_volume)
		fullscreen = c.get_value("display", "fullscreen", fullscreen)
