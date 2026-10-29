extends Node2D
## 위험 지역의 몬스터. 어슬렁거리다 주인공이 가까우면 쫓아오고, 부딪히면 아파요.

signal died(m)

var kind := "slime"
var data: Dictionary
var hp := 10
var field  # field.gd (걷기 지도, 주인공)
var sprite := Sprite2D.new()
var front: Texture2D
var side: Texture2D
var home := Vector2.ZERO
var wander_to := Vector2.ZERO
var knock := Vector2.ZERO
var hurt_t := 0.0
var dead := false
var _t := randf() * 10.0
var bar := Node2D.new()
var boss := false


func setup(k: String, scale_f: float) -> void:
	kind = k
	data = Areas.MONSTERS[k]
	hp = data.hp
	boss = k == "snowman"
	front = load("res://assets/monsters/%s.png" % ("snowman_idle" if boss else k + "_front"))
	side = load("res://assets/monsters/%s.png" % ("snowman_walk" if boss else k + "_side"))
	sprite.texture = front
	sprite.offset = Vector2(0, -front.get_height() / 2.0)
	sprite.scale = Vector2(scale_f, scale_f)
	add_child(sprite)
	bar.draw.connect(_draw_bar)
	bar.position = Vector2(0, -front.get_height() * scale_f - 10)
	bar.z_index = 50
	add_child(bar)


func _draw_bar() -> void:
	if hp >= data.hp or dead:
		return
	var w := 46.0 if not boss else 120.0
	bar.draw_rect(Rect2(-w / 2 - 1, -1, w + 2, 7), UI.OUTLINE)
	bar.draw_rect(Rect2(-w / 2, 0, w * float(hp) / data.hp, 5), Color("#E0675A"))


func _process(delta: float) -> void:
	if dead or get_tree().paused:
		return
	_t += delta
	hurt_t -= delta
	sprite.modulate = Color(1, 0.55, 0.55) if hurt_t > 0.15 else Color.WHITE
	# 통통 튀며 움직여요
	sprite.position.y = -absf(sin(_t * (9.0 if not boss else 4.0))) * (4.0 if not boss else 6.0)
	if knock.length() > 1.0:
		_try_move(knock * delta * 8.0)
		knock = knock.lerp(Vector2.ZERO, delta * 8.0)
		return
	var p: Vector2 = field.player.position
	var to_p := p - position
	var v := Vector2.ZERO
	if to_p.length() < (240.0 if not boss else 500.0) and not field.player_down:
		v = to_p.normalized() * data.speed
	else:
		if position.distance_to(wander_to) < 8.0 or wander_to == Vector2.ZERO:
			wander_to = home + Vector2(randf_range(-120, 120), randf_range(-70, 70))
			if not field.can_walk(wander_to):
				wander_to = home
		v = (wander_to - position).normalized() * data.speed * 0.4
	if v.length() > 0.1:
		_face(v)
		_try_move(v * delta)
	if to_p.length() < (30.0 if not boss else 70.0):
		field.hurt_player(data.dmg, to_p.normalized())


func _face(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		sprite.texture = side
		sprite.flip_h = v.x < 0
	else:
		sprite.texture = front
		sprite.flip_h = false


func _try_move(step: Vector2) -> void:
	var np := position + step
	if field.can_walk(np):
		position = np
	elif field.can_walk(Vector2(np.x, position.y)):
		position.x = np.x
	elif field.can_walk(Vector2(position.x, np.y)):
		position.y = np.y
	else:
		wander_to = home


func hit(dmg: int, from: Vector2) -> void:
	if dead:
		return
	hp -= dmg
	hurt_t = 0.3
	knock = (position - from).normalized() * (60.0 if not boss else 15.0)
	bar.queue_redraw()
	field.float_text(position + Vector2(0, -70), "-%d" % dmg, Color("#E0675A"))
	Audio.sfx("pop", 0.8 if boss else 1.2)
	if hp <= 0:
		dead = true
		died.emit(self)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.2, 0.3), 0.18)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(queue_free)
