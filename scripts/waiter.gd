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
	sprite.offset = Vector2(0, -61)
	sprite.scale = Vector2(0.9, 0.9)
	sprite.animation = "front"
	add_child(sprite)


func _process(_delta: float) -> void:
	if busy:
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


func _idle() -> void:
	sprite.animation = "front"
	sprite.flip_h = false
	sprite.stop()
	sprite.frame = 0


func walk_to(p: Vector2, carrying := false) -> void:
	var d := p - position
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
	_idle()
	busy = false


func _take(t) -> void:
	busy = true
	t.busy = true
	await walk_to(t.interact_point())
	t.busy = false
	if t.state == "ordering":
		t.take_order()
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
	_idle()
	busy = false
