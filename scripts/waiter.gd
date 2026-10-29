extends Node2D
## 알바생 강아지. 진열장에서 음식을 꺼내 손님에게 갖다주고, 손님이 떠난 자리를 쓸어요.

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
	t.assigned = true
	var order: String = t.order
	await walk_to(hall.CASE_SPOT)
	if t.state != "waiting" or t.order != order or not GameState.take_stock(order):
		t.assigned = false
		busy = false
		return
	await walk_to(t.position + Vector2(-80, 12), true)
	if t.state == "waiting" and t.order == order:
		t.serve()
	else:
		GameState.add_stock(order, 1)  # 손님이 가 버렸으면 다시 진열장으로
	_idle()
	busy = false


func _clean(t) -> void:
	busy = true
	t.set_meta("cleaning", true)
	await walk_to(t.position + Vector2(-70, 16))
	sprite.animation = "sweep"
	sprite.play()
	await get_tree().create_timer(2.0).timeout
	t.clean()
	t.remove_meta("cleaning")
	hall.update_cleanliness()
	_idle()
	busy = false
