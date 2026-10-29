extends Node2D
## 손님 자리 하나. 손님은 탁자 뒤 의자에 앉아서 그림으로 주문해요.
## 상태: empty → coming → ordering(주문 받아 주길 기다림) → waiting(음식 기다림) → eating → empty

signal left_table(t, kind: String, happy: bool)

const Bubble := preload("res://scripts/bubble.gd")
const ORDER_PATIENCE := 45.0
const FOOD_PATIENCE := 150.0
const EAT_TIME := 6.0
const SIT_SCALE := 0.95

var state := "empty"
var kind := ""
var order := ""
var patience := 0.0
var patience_max := 1.0
var dirty := false
var busy := false  # 누군가(주인공·알바생) 이 자리 일을 하는 중
var eat_left := 0.0
## 그림 속 의자 자리(이 노드의 위치), 탁자 위 음식 자리, 손님에게 다가갈 바닥 자리
var food_at := Vector2.ZERO
var stand := Vector2.ZERO
var face_left := false

var animal := AnimatedSprite2D.new()
var food := Sprite2D.new()
var steam := CPUParticles2D.new()
var dust := Node2D.new()
var bubble
var _t := randf() * 10.0


func _ready() -> void:
	# 탁자 위 음식과 부스러기는 손님보다 먼저 그려요
	dust.draw.connect(_draw_dust)
	add_child(dust)
	food.position = food_at
	food.visible = false
	add_child(food)
	animal.visible = false
	add_child(animal)
	steam.position = food_at + Vector2(0, -16)
	steam.emitting = false
	steam.amount = 6
	steam.lifetime = 1.4
	steam.direction = Vector2.UP
	steam.spread = 12.0
	steam.gravity = Vector2(0, -18)
	steam.initial_velocity_min = 8.0
	steam.initial_velocity_max = 14.0
	steam.scale_amount_min = 2.5
	steam.scale_amount_max = 4.0
	steam.color = Color(1, 1, 1, 0.55)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.6))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	steam.color_ramp = ramp
	add_child(steam)
	bubble = Bubble.new()
	bubble.position = Vector2(0, -132)
	bubble.visible = false
	add_child(bubble)


func interact_point() -> Vector2:
	return stand


func reserve() -> void:
	state = "coming"


func seat(k: String, o: String) -> void:
	kind = k
	order = o
	state = "ordering"
	patience_max = ORDER_PATIENCE
	patience = patience_max
	animal.sprite_frames = Sprites.animal_frames(k)
	var wk := k + "_wait" if Sprites.has_strip(k + "_wait") else k + "_front"
	var h := float(Sprites.frame_height(wk))
	animal.offset = Vector2(0, -h / 2.0 + 14)
	var s := SIT_SCALE * (0.9 if k == "chick" else 1.0)
	animal.scale = Vector2(s, s)
	animal.play("wait")
	animal.flip_h = face_left
	animal.visible = true
	bubble.show_mark()
	bubble.set_fill(1.0)


func take_order() -> void:
	state = "waiting"
	patience_max = FOOD_PATIENCE
	patience = patience_max
	bubble.show_item(order)
	GameState.orders.append(self)
	GameState.mark_tutorial("order")
	Audio.sfx("order")


func serve() -> void:
	state = "eating"
	eat_left = EAT_TIME
	GameState.orders.erase(self)
	bubble.visible = false
	food.texture = Sprites.item(order)
	var fs := 34.0 / maxf(food.texture.get_width(), food.texture.get_height())
	food.scale = Vector2(fs, fs)
	food.visible = true
	steam.emitting = true
	animal.play("eat")
	GameState.mark_tutorial("serve")
	Audio.sfx("pop")


func _process(delta: float) -> void:
	# 앉아 있을 때 숨쉬듯 살짝 움직여요
	_t += delta
	if animal.visible and state != "eating":
		animal.position.y = 0.0
		animal.scale.y = animal.scale.x * (1.0 + sin(_t * 2.4) * 0.015)
	match state:
		"ordering", "waiting":
			patience -= delta
			bubble.set_fill(patience / patience_max)
			if patience <= 0:
				GameState.toast.emit("손님이 기다리다 화가 나서 돌아갔어요…")
				GameState.today.lost += 1
				GameState.add_rep(-1)
				_leave(false)
		"eating":
			eat_left -= delta
			# 한 입씩 줄어들어요
			var fs := 34.0 / maxf(food.texture.get_width(), food.texture.get_height())
			var left := clampf(eat_left / EAT_TIME, 0.25, 1.0)
			food.scale = Vector2(fs, fs) * (0.5 + 0.5 * left)
			animal.position.y = -absf(sin(eat_left * 6.0)) * 3.0
			if eat_left <= 0:
				var price: int = GameState.ITEMS[order].price
				var tip := (5 if GameState.cleanliness >= 80 else 0) + GameState.decor * 2
				GameState.earn(price + tip)
				GameState.today.tips = GameState.today.get("tips", 0) + tip
				GameState.today.served += 1
				var sold: Dictionary = GameState.today.get("sold", {})
				sold[order] = sold.get(order, 0) + 1
				GameState.today.sold = sold
				GameState.add_rep(2 if tip > 0 else 1)
				_float_text("+%d" % (price + tip))
				Audio.sfx("coin")
				_leave(true)


func _float_text(t: String) -> void:
	var l := UI.label(t, 30, Color("#C9862B"))
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 8)
	l.position = Vector2(-20, -150)
	l.z_index = 80
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", -210.0, 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)


func _leave(happy: bool) -> void:
	var k := kind
	GameState.orders.erase(self)
	state = "empty"
	bubble.visible = false
	food.visible = false
	steam.emitting = false
	animal.position.y = 0.0
	if happy:
		animal.play("happy")
		_float_text("♥")
	else:
		animal.play("sad")
	await get_tree().create_timer(0.8).timeout
	animal.visible = false
	kind = ""
	order = ""
	busy = false
	if happy:
		dirty = true
		dust.queue_redraw()
	left_table.emit(self, k, happy)


func clean() -> void:
	dirty = false
	busy = false
	dust.queue_redraw()


func _draw_dust() -> void:
	if not dirty:
		return
	# 탁자 위 빈 접시와 부스러기
	dust.draw_set_transform(food_at, 0, Vector2(1, 0.5))
	dust.draw_circle(Vector2.ZERO, 15, Color("#FFFDF7"))
	dust.draw_arc(Vector2.ZERO, 15, 0, TAU, 24, UI.OUTLINE, 2)
	dust.draw_set_transform(Vector2.ZERO)
	var c := Color(0.85, 0.66, 0.4, 0.95)
	for p in [Vector2(-9, -2), Vector2(6, 3), Vector2(12, -4), Vector2(-3, 5)]:
		dust.draw_circle(food_at + p, 2.2, c)
	# 바닥에 떨어진 부스러기
	var fc := Color(0.5, 0.38, 0.28, 0.5)
	for p in [Vector2(-26, 10), Vector2(-8, 16), Vector2(18, 12), Vector2(34, 6)]:
		dust.draw_circle(p, 5, fc)
