extends Node2D
## 주인공. 방향키/WASD로 걷고, 바닥을 클릭하면 그쪽으로 걸어가요.

var sprite: AnimatedSprite2D
var speed := 230.0
var active := true
var can_walk: Callable  # func(Vector2) -> bool
var target = null


func setup(hero: String, scale_f: float) -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.frames_for(hero, ["front", "back", "right"])
	sprite.centered = true
	sprite.offset = Vector2(0, -Sprites.frame_height(hero, "front") / 2.0)
	sprite.scale = Vector2(scale_f, scale_f)
	sprite.animation = "front"
	add_child(sprite)
	speed = 230.0 * scale_f / 0.68


func _process(delta: float) -> void:
	if not active:
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
	elif target != null:
		var d: Vector2 = target - position
		if d.length() < 6.0:
			target = null
		else:
			v = d
	if v == Vector2.ZERO:
		sprite.stop()
		sprite.frame = 0
		return
	v = v.normalized()
	var step := v * speed * delta
	step.y *= 0.8  # 비스듬한 바닥이라 위아래는 조금 느리게
	var np := position + step
	if can_walk.call(np):
		position = np
	elif can_walk.call(Vector2(np.x, position.y)):
		position.x = np.x
	elif can_walk.call(Vector2(position.x, np.y)):
		position.y = np.y
	else:
		target = null
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
	target = p
