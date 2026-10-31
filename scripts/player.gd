extends Node2D
## 주인공. 방향키/WASD로 걷고(Shift를 누르면 달려요), 바닥이나 손님을 클릭하면 그쪽으로 걸어가요.

signal arrived

var sprite: AnimatedSprite2D
var speed := 230.0
var active := true
var busy := false  # 청소처럼 잠깐 멈춰서 하는 일
var posing := false  # 공격처럼 다른 그림을 보여 주는 중
var can_walk: Callable  # func(Vector2) -> bool
var target = null
var waypoints: Array = []
var base_scale := 1.0
var _work_t := 0.0
var _idle_t := 0.0
var _step_t := 0.0
var running := false
const RUN := 1.7
var shadow := Node2D.new()


func setup(hero: String, scale_f: float) -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.frames_for(hero, ["front", "back", "right"])
	sprite.offset = Vector2(0, -Sprites.frame_height(hero + "_front") / 2.0)
	sprite.scale = Vector2(scale_f, scale_f)
	base_scale = scale_f
	sprite.animation = "front"
	# 발밑 그림자: 바닥에 붙어 있는 느낌이 나요
	var sw := Sprites.frame_height(hero + "_front") * scale_f * 0.22
	shadow.draw.connect(func(): shadow.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36)); shadow.draw_circle(Vector2.ZERO, sw, Color(0.25, 0.15, 0.08, 0.22)))
	add_child(shadow)
	add_child(sprite)
	speed = 200.0 + 60.0 * scale_f


func _process(delta: float) -> void:
	if posing:
		return
	if busy:
		_work_t += delta
		sprite.rotation = sin(_work_t * 18.0) * 0.06
		return
	sprite.rotation = 0.0
	if not active:
		sprite.stop()
		return
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1
	if v != Vector2.ZERO:
		target = null
		waypoints.clear()
	elif target != null:
		var d: Vector2 = target - position
		if d.length() < 6.0:
			if waypoints.is_empty():
				target = null
				arrived.emit()
			else:
				target = _next_point()
				d = target - position
		if target != null:
			v = d
	if v == Vector2.ZERO:
		sprite.stop()
		sprite.frame = 0
		sprite.position = Vector2.ZERO
		sprite.skew = 0.0
		# 서 있을 때 숨쉬듯 살짝
		_idle_t += delta
		sprite.scale = Vector2(base_scale, base_scale * (1.0 + sin(_idle_t * 2.2) * 0.012))
		return
	running = Input.is_key_pressed(KEY_SHIFT)
	sprite.speed_scale = 1.6 if running else 1.0
	# 걸을 때 통통 튀고 살짝 기울어요(달리면 더 크게)
	_step_t += delta * (16.0 if running else 11.0)
	var bob := absf(sin(_step_t)) * base_scale * Sprites.frame_height("%s_front" % GameState.hero) * (0.035 if running else 0.022)
	sprite.position = Vector2(0, -bob)
	sprite.scale = Vector2(base_scale * (1.0 + bob * 0.002), base_scale * (1.0 - bob * 0.002))
	v = v.normalized()
	sprite.skew = -v.x * (0.08 if running else 0.04)
	var step := v * speed * (RUN if running else 1.0) * delta
	step.y *= 0.8  # 비스듬한 바닥이라 위아래는 조금 느리게
	if target != null and step.length() > (target - position).length():
		step = target - position
	var np := position + step
	if can_walk.call(np):
		position = np
	elif can_walk.call(Vector2(np.x, position.y)):
		position.x = np.x
	elif can_walk.call(Vector2(position.x, np.y)):
		position.y = np.y
	else:
		if target != null:
			arrived.emit()
		target = null
		waypoints.clear()
	face(v)
	sprite.play()


func face(v: Vector2) -> void:
	var anim := "front"
	if absf(v.x) > absf(v.y) * 0.9:
		anim = "right"
		sprite.flip_h = v.x < 0
	else:
		anim = "back" if v.y < 0 else "front"
		sprite.flip_h = false
	if sprite.animation != anim:
		sprite.animation = anim


func walk_to(p: Vector2) -> void:
	waypoints.clear()
	target = p


func walk_path(points: Array) -> void:
	if points.is_empty():
		return
	waypoints = points.duplicate()
	target = _next_point()


## 다음 걸어갈 점. {"tp": 위치}는 문을 지나 순간 이동해요.
func _next_point() -> Vector2:
	var q = waypoints.pop_front()
	while q is Dictionary:
		position = q.tp
		Audio.sfx("door")
		q = waypoints.pop_front() if not waypoints.is_empty() else position
	return q


## 잠깐 일하는 동작(청소 등)
func work(seconds: float) -> void:
	busy = true
	target = null
	waypoints.clear()
	sprite.stop()
	await get_tree().create_timer(seconds).timeout
	busy = false
