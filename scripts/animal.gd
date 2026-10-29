extends Node2D
## 동물 손님·주민 한 마리. 걸을 때는 방향에 맞는 걷기 그림, 그림이 한두 장뿐이면 통통 튀며 걸어요.

var kind := "rabbit"
var sprite := AnimatedSprite2D.new()
var speed := 110.0
var moving := false
var _t := 0.0
var _bouncy := false
var _base := 1.0


func setup(k: String, s: float) -> void:
	kind = k
	sprite.sprite_frames = Sprites.animal_frames(k)
	var h := Sprites.frame_height(_key("front"))
	sprite.offset = Vector2(0, -h / 2.0)
	sprite.scale = Vector2(s, s)
	_base = s
	sprite.animation = "front"
	if sprite.get_parent() == null:
		add_child(sprite)
	speed = 110.0 * s / 0.85


func _key(anim: String) -> String:
	var k := kind + "_" + anim
	return k if Sprites.has_strip(k) else kind + "_front"


func _process(delta: float) -> void:
	if moving and _bouncy:
		_t += delta
		sprite.position.y = -absf(sin(_t * 10.0)) * 5.0
		sprite.rotation = sin(_t * 10.0) * 0.05
	else:
		sprite.position.y = 0.0
		sprite.rotation = 0.0
		if not moving:
			_t += delta
			sprite.scale.y = _base * (1.0 + sin(_t * 2.4) * 0.015)


func face(d: Vector2) -> void:
	var anim := "front"
	if absf(d.x) > absf(d.y) * 0.9:
		anim = "right"
		sprite.flip_h = d.x < 0
	else:
		anim = "back" if d.y < 0 else "front"
		sprite.flip_h = false
	sprite.animation = anim
	_bouncy = Sprites.strip_count(kind + "_" + anim) < 3


func walk_to(p: Vector2) -> void:
	var d := p - position
	if d.length() < 1.0:
		return
	face(d)
	sprite.play()
	moving = true
	var tw := create_tween()
	tw.tween_property(self, "position", p, d.length() / speed)
	await tw.finished
	moving = false
	idle()


func walk_path(points: Array) -> void:
	for p in points:
		await walk_to(p)


func idle() -> void:
	sprite.animation = "front"
	sprite.flip_h = false
	sprite.stop()
	sprite.frame = 0


func pose(anim: String) -> void:
	sprite.flip_h = false
	sprite.play(anim)
