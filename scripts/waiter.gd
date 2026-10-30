extends Node2D
## 알바생 강아지(고용하면 와요). 주문 받기, 받은 순서대로 음식 내주기, 자리 치우기를 도와줘요.

var hall: Node2D
var sprite: AnimatedSprite2D
var busy := false
var speed := 170.0
var home := Vector2.ZERO


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.frames_for("puppy", ["front", "back", "right", "tray", "sweep"])
	var h := float(Sprites.frame_height("puppy_front"))
	sprite.offset = Vector2(0, -h / 2.0)
	sprite.scale = Vector2.ONE * 1.05 * 122.0 / h  # 예전 그림(키 122)과 같은 크기로
	sprite.animation = "front"
	add_child(sprite)


func _process(_delta: float) -> void:
	if busy:
		return
	# 일을 많이 하면 지쳐서 잠깐 쉬어요(쉬는 동안 머리 위에 Zz)
	if GameState.waiter_tired >= 100.0:
		_rest()
		return
	var t = hall.find_serve_job()
	if t:
		_serve(t)
		return
	t = hall.find_order_job()
	if t:
		_take(t)
		return
	t = hall.find_clean_job()
	if t:
		_clean(t)
		return
	if position.distance_to(home) > 8:
		busy = true
		await walk_to(home)
		_idle()
		busy = false


func _rest() -> void:
	busy = true
	GameState.toast.emit("강아지가 지쳐서 잠깐 쉬어요. 조금 뒤에 다시 일해요.")
	await walk_to(home)
	_idle()
	var z := UI.label("Zz", 22, UI.CHESTNUT)
	z.position = Vector2(14, -150)
	add_child(z)
	var tw := z.create_tween().set_loops(8)
	tw.tween_property(z, "position:y", -165.0, 0.9)
	tw.tween_property(z, "position:y", -150.0, 0.9)
	await get_tree().create_timer(14.0).timeout
	z.queue_free()
	GameState.waiter_tired = 0.0
	busy = false


## 일 하나를 마칠 때마다 피로가 쌓여요. 지칠수록 조금 느려져요.
func _work_done() -> void:
	GameState.waiter_tired += 9.0
	speed = 170.0 * (1.0 - GameState.waiter_tired / 300.0)


func _idle() -> void:
	sprite.animation = "front"
	sprite.flip_h = false
	sprite.stop()
	sprite.frame = 0


func walk_to(p: Vector2, carrying := false) -> void:
	for q in hall.find_path(position, p):
		await _step_to(q, carrying)


func _step_to(q, carrying: bool) -> void:
	if q is Dictionary:
		position = q.tp  # 문을 지나 다른 방으로
		return
	var p: Vector2 = q
	var d := p - position
	if d.length() < 1.0:
		return
	if carrying:
		sprite.animation = "tray"
		sprite.flip_h = d.x < 0
	elif absf(d.x) > absf(d.y) * 0.9:
		sprite.animation = "right"
		sprite.flip_h = d.x < 0
	else:
		sprite.animation = "back" if d.y < 0 else "front"
		sprite.flip_h = false
	sprite.play()
	var tw := create_tween()
	tw.tween_property(self, "position", p, d.length() / speed)
	await tw.finished


func _serve(t) -> void:
	busy = true
	t.busy = true
	var order: String = t.order
	await walk_to(hall.CASE_SPOT)
	if t.state != "waiting" or not GameState.take_stock(order):
		t.busy = false
		busy = false
		return
	await walk_to(t.interact_point(), true)
	t.busy = false
	if t.state == "waiting" and t.order == order:
		t.serve()
	else:
		GameState.add_stock(order, 1)  # 손님이 가 버렸으면 다시 진열대로
	_work_done()
	_idle()
	busy = false


func _take(t) -> void:
	busy = true
	t.busy = true
	await walk_to(t.interact_point())
	t.busy = false
	if t.state == "ordering":
		t.take_order()
	_work_done()
	_idle()
	busy = false


func _clean(t) -> void:
	busy = true
	t.busy = true
	await walk_to(t.interact_point())
	sprite.animation = "sweep"
	sprite.play()
	Audio.sfx("sweep")
	await get_tree().create_timer(2.0).timeout
	t.clean()
	hall.update_cleanliness()
	_work_done()
	_idle()
	busy = false
