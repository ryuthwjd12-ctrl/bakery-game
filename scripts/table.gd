extends Node2D
## 손님 자리 하나. 손님은 탁자 뒤 의자에 앉아서 그림으로 주문해요.
## 상태: empty → coming → ordering(주문 받아 주길 기다림) → waiting(음식 기다림) → eating → empty

signal left_table(t, kind: String, happy: bool)

const Bubble := preload("res://scripts/bubble.gd")
const ORDER_PATIENCE := 45.0
const FOOD_PATIENCE := 150.0
const EAT_TIME := 6.0
## 앉은 그림이 오른쪽을 보고 있는 동물은 뒤집어서 탁자를 보게 해요.
const FLIP_SIT := []

var state := "empty"
var kind := ""
var order := ""
var patience := 0.0
var patience_max := 1.0
var dirty := false
var busy := false  # 누군가(주인공·알바생) 이 자리 일을 하는 중
var eat_left := 0.0

var chair := Sprite2D.new()
var animal := AnimatedSprite2D.new()
var table := Sprite2D.new()
var food := Sprite2D.new()
var dust := Node2D.new()
var bubble


func _ready() -> void:
	chair.texture = Sprites.tex("furniture/pink_chair")
	chair.scale = Vector2(1.25, 1.25)
	chair.offset = Vector2(0, -41)
	chair.position = Vector2(66, -36)
	add_child(chair)
	animal.position = Vector2(64, -40)
	animal.visible = false
	add_child(animal)
	table.texture = Sprites.tex("furniture/round_table")
	table.scale = Vector2(1.5, 1.5)
	table.offset = Vector2(0, -33)
	add_child(table)
	food.position = Vector2(-4, -84)
	food.scale = Vector2(0.45, 0.45)
	food.visible = false
	add_child(food)
	dust.draw.connect(_draw_dust)
	add_child(dust)
	bubble = Bubble.new()
	bubble.position = Vector2(70, -150)
	bubble.visible = false
	add_child(bubble)


func interact_point() -> Vector2:
	return position + Vector2(-70, 18)


func reserve() -> void:
	state = "coming"


func seat(k: String, o: String) -> void:
	kind = k
	order = o
	state = "ordering"
	patience_max = ORDER_PATIENCE
	patience = patience_max
	animal.sprite_frames = Sprites.animal_frames(k)
	var h := Sprites.frame_height(k + "_front")
	animal.offset = Vector2(0, -h / 2.0)
	var s := 0.86 if k != "chick" else 0.92
	animal.scale = Vector2(s, s)
	animal.play("wait")
	animal.flip_h = FLIP_SIT.has(k)
	animal.visible = true
	chair.visible = true
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
	food.visible = true
	animal.play("eat")
	GameState.mark_tutorial("serve")
	Audio.sfx("pop")


func _process(delta: float) -> void:
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
			if eat_left <= 0:
				var price: int = GameState.ITEMS[order].price
				var tip := 5 if GameState.cleanliness >= 80 else 0
				GameState.earn(price + tip)
				GameState.today.served += 1
				GameState.add_rep(2 if tip > 0 else 1)
				_float_text("+%d" % (price + tip))
				Audio.sfx("coin")
				_leave(true)


func _float_text(t: String) -> void:
	var l := UI.label(t, 30, Color("#C9862B"))
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 8)
	l.position = Vector2(-20, -170)
	l.z_index = 80
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", -230.0, 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)


func _leave(happy: bool) -> void:
	var k := kind
	GameState.orders.erase(self)
	state = "empty"
	bubble.visible = false
	food.visible = false
	if happy:
		animal.play("happy")
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
	var c := Color(0.55, 0.45, 0.38, 0.55)
	for p in [Vector2(-40, 6), Vector2(-22, 14), Vector2(30, 10), Vector2(48, 4), Vector2(8, 18)]:
		dust.draw_circle(p, 7, c)
	dust.draw_circle(Vector2(-30, 10), 4, Color(0.95, 0.85, 0.6, 0.9))
	dust.draw_circle(Vector2(38, 12), 3, Color(0.95, 0.85, 0.6, 0.9))
	# 빈 접시
	dust.draw_set_transform(Vector2(-4, -88), 0, Vector2(1, 0.45))
	dust.draw_circle(Vector2.ZERO, 16, Color("#FFFDF7"))
	dust.draw_arc(Vector2.ZERO, 16, 0, TAU, 24, UI.OUTLINE, 2)
	dust.draw_set_transform(Vector2.ZERO)
