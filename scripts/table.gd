extends Node2D
## 손님 자리 하나. 손님은 탁자 뒤 의자에 앉아서 그림으로 주문해요(한 사람이 메뉴를 두 개까지 시켜요).
## 상태: empty → coming → ordering(주문 받아 주길 기다림) → waiting(음식 기다림) → eating → empty
## 음식은 받은 순서와 상관없이, 시킨 메뉴가 있으면 바로 내줄 수 있어요. 다 먹으면 접시는 저절로 치워져요.

signal left_table(t, kind: String, happy: bool)

const Bubble := preload("res://scripts/bubble.gd")
const EatShader := preload("res://scripts/eat.gdshader")
const ORDER_PATIENCE := 45.0
const FOOD_PATIENCE := 150.0
const SIT_SCALE := 0.78
## 메뉴 종류마다 먹는 모습이 달라요: 음료는 컵을 들어 마시고, 쿠키는 가장자리부터 한 입씩,
## 빵은 위에서부터 크게 베어 물고, 케이크·타르트는 포크로 한 조각씩 떠먹어요.
const KIND_OF := {
	"warm_milk": "drink",
	"milk_bread": "bread", "croissant": "bread", "cream_bun": "bread", "choco_brioche": "bread", "cinnamon_roll": "bread",
	"raspberry_cake": "cake", "peach_tart": "cake", "grape_roll": "cake", "blueberry_muffin": "cake", "macaron": "cake",
}
const EAT_TIME := {"drink": 4.5, "cookie": 5.0, "bread": 6.0, "cake": 6.5}

var state := "empty"
var kind := ""
var order := ""  # 첫 번째 메뉴(부탁 손님의 스페셜 요리)
var items: Array = []  # 시킨 메뉴들
var served: Array = []  # 받은 메뉴들
var patience := 0.0
var patience_max := 1.0
var dirty := false  # 예전 저장 호환용(이제 손님이 떠나면 저절로 치워져요)
var busy := false  # 누군가(주인공·알바생) 이 자리 일을 하는 중
var eat_i := 0  # 지금 먹고 있는 음식 번호
var eat_t := 0.0
var quest_id := ""  # 부탁 손님이면 부탁 id
## 그림 속 의자 자리(이 노드의 위치), 탁자 위 음식 자리, 손님에게 다가갈 바닥 자리
var food_at := Vector2.ZERO
var stand := Vector2.ZERO
var face_left := false

var animal := AnimatedSprite2D.new()
var plates := Node2D.new()
var foods: Array = []  # Sprite2D, served와 같은 순서
var steam := CPUParticles2D.new()
var crumbs := CPUParticles2D.new()
var bubble
var _t := randf() * 10.0
var _bites := 0


func _ready() -> void:
	# 접시와 음식은 손님보다 먼저 그려요
	plates.draw.connect(_draw_plates)
	add_child(plates)
	animal.visible = false
	add_child(animal)
	_particles(steam, Color(1, 1, 1, 0.55), Vector2(0, -18), 6, 1.4)
	steam.direction = Vector2.UP
	steam.gravity = Vector2(0, -18)
	steam.initial_velocity_min = 8.0
	steam.initial_velocity_max = 14.0
	steam.scale_amount_min = 2.5
	steam.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.6))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	steam.color_ramp = ramp
	# 한 입 먹을 때마다 부스러기가 톡톡 떨어져요
	_particles(crumbs, Color("#D9A86C"), Vector2.ZERO, 8, 0.6)
	crumbs.one_shot = true
	crumbs.explosiveness = 0.9
	crumbs.direction = Vector2.UP
	crumbs.spread = 70.0
	crumbs.gravity = Vector2(0, 260)
	crumbs.initial_velocity_min = 30.0
	crumbs.initial_velocity_max = 60.0
	crumbs.scale_amount_min = 1.5
	crumbs.scale_amount_max = 2.5
	bubble = Bubble.new()
	bubble.position = Vector2(0, -112)
	bubble.visible = false
	add_child(bubble)


func _particles(p: CPUParticles2D, col: Color, at: Vector2, amount: int, life: float) -> void:
	p.position = food_at + at
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.spread = 12.0
	p.color = col
	p.z_index = 1
	add_child(p)


func interact_point() -> Vector2:
	return stand


func reserve() -> void:
	state = "coming"


## 아직 안 받은 메뉴들
func wanted() -> Array:
	var left := items.duplicate()
	for s in served:
		left.erase(s)
	return left


func seat(k: String, o, q := "") -> void:
	kind = k
	items = o.duplicate() if o is Array else [o]
	order = items[0]
	served = []
	quest_id = q
	state = "ordering"
	patience_max = ORDER_PATIENCE
	patience = patience_max
	animal.sprite_frames = Sprites.animal_frames(k)
	var wk := k + "_wait" if Sprites.has_strip(k + "_wait") else k + "_front"
	var h := float(Sprites.frame_height(wk))
	animal.offset = Vector2(0, -h / 2.0 + 14)
	var s := SIT_SCALE * (0.9 if k == "chick" else 1.0)
	s *= Sprites.size_fix(k)  # 새 주민 그림은 크게 그려져 있어서 선 키를 맞춰요
	animal.scale = Vector2(s, s)
	animal.position = Vector2.ZERO
	animal.play("wait")
	animal.flip_h = face_left
	animal.visible = true
	bubble.show_mark(q != "")
	bubble.set_fill(1.0)


func take_order() -> void:
	state = "waiting"
	patience_max = FOOD_PATIENCE * (2.0 if quest_id != "" else 1.0)
	patience = patience_max
	bubble.show_items(wanted())
	GameState.orders.append(self)
	GameState.mark_tutorial("order")
	Audio.sfx("order")


## 시킨 메뉴 하나를 내줘요. 다 받으면 먹기 시작해요.
func serve(id := "") -> void:
	if id == "":
		id = wanted()[0]
	served.append(id)
	var sp := Sprite2D.new()
	sp.texture = Sprites.item(id)
	var fs := 34.0 / maxf(sp.texture.get_width(), sp.texture.get_height())
	sp.scale = Vector2(fs, fs)
	sp.position = _food_pos(served.size() - 1)
	var mat := ShaderMaterial.new()
	mat.shader = EatShader
	mat.set_shader_parameter("mode", {"cookie": 0, "bread": 1, "cake": 2}.get(_kind(id), 0))
	sp.material = mat
	add_child(sp)
	move_child(sp, plates.get_index() + 1)
	foods.append(sp)
	plates.queue_redraw()
	UI.pop(sp, 0.2)
	GameState.mark_tutorial("serve")
	Audio.sfx("pop")
	var left := wanted()
	if left.is_empty():
		GameState.orders.erase(self)
		bubble.visible = false
		state = "eating"
		eat_i = 0
		eat_t = 0.0
		_bites = 0
		animal.play("eat")
	else:
		bubble.show_items(left)


func _kind(id: String) -> String:
	return KIND_OF.get(id, "cookie")


## 음식이 여러 개면 탁자 위에 나란히 놓아요(손님 쪽이 첫 번째)
func _food_pos(i: int) -> Vector2:
	var side := -1.0 if face_left else 1.0
	return food_at + Vector2(side * 22.0 * i, 8.0 * i)


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
				if quest_id != "" and GameState.active_quest == quest_id:
					GameState.active_quest = ""
				quest_id = ""
				GameState.today.lost += 1
				GameState.add_rep(-1)
				_leave(false)
		"eating":
			_eat(delta)


func _eat(delta: float) -> void:
	var id: String = served[eat_i]
	var sp: Sprite2D = foods[eat_i]
	var k := _kind(id)
	var total: float = EAT_TIME[k]
	eat_t += delta
	var prog := clampf(eat_t / total, 0.0, 1.0)
	var home := _food_pos(eat_i)
	if k == "drink":
		# 컵을 들어 입가로 가져가 홀짝, 다시 내려놓아요
		var sip := maxf(0.0, sin(eat_t * 2.2))
		var mouth := Vector2(-10.0 if face_left else 10.0, -40.0)
		sp.position = home.lerp(mouth, sip * 0.75)
		sp.rotation = sip * (0.5 if face_left else -0.5)
		steam.position = sp.position + Vector2(0, -16)
		steam.emitting = prog < 0.8
		animal.position.y = -sip * 2.0
		(sp.material as ShaderMaterial).set_shader_parameter("progress", 0.0 if prog < 0.95 else (prog - 0.95) * 20.0)
	else:
		steam.emitting = false
		sp.position = home
		# 한 입마다 손님이 앞으로 살짝 숙였다 오물오물해요
		var bites := int(prog * 6.0)
		if bites > _bites:
			_bites = bites
			crumbs.position = home
			crumbs.color = Color("#F3E3C3") if k == "cake" else Color("#D9A86C")
			crumbs.restart()

			if k == "cake":
				_fork(home)
		animal.position.y = -absf(sin(eat_t * (9.0 if k == "cookie" else 6.0))) * 3.0
		(sp.material as ShaderMaterial).set_shader_parameter("progress", prog)
	if prog >= 1.0:
		sp.visible = false
		eat_i += 1
		eat_t = 0.0
		_bites = 0
		if eat_i >= served.size():
			_pay()


## 포크가 접시에서 손님 입으로 오가요
func _fork(at: Vector2) -> void:
	var f := Line2D.new()
	f.width = 2.5
	f.default_color = Color("#B9B2A6")
	f.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -14), Vector2(-3, -18), Vector2(0, -14), Vector2(3, -18)])
	f.position = at + Vector2(0, -4)
	f.z_index = 2
	add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "position", Vector2((-8.0 if face_left else 8.0), -34), 0.25)
	tw.tween_property(f, "position", at + Vector2(0, -4), 0.2)
	tw.tween_callback(f.queue_free)


func _pay() -> void:
	steam.emitting = false
	var price := 0
	for id in served:
		price += int(GameState.ITEMS[id].price)
	# 친한 주민일수록 팁을 더 줘요(하트 하나에 2골드)
	var tip := 5 + GameState.decor * 2 + GameState.dishes * 3 + GameState.hearts(kind) * 2
	if quest_id != "":
		_finish_quest()
	GameState.earn(price + tip)
	GameState.today.tips = GameState.today.get("tips", 0) + tip
	GameState.today.served += 1
	GameState.stats.served = GameState.stats.get("served", 0) + 1
	var sold: Dictionary = GameState.today.get("sold", {})
	for id in served:
		sold[id] = sold.get(id, 0) + 1
	GameState.today.sold = sold
	GameState.add_rep(2)
	_float_text("+%d" % (price + tip))
	Audio.sfx("coin")
	_leave(true)


func _finish_quest() -> void:
	var q := GameState.quest(quest_id)
	GameState.quests_done.append(quest_id)
	GameState.active_quest = ""
	GameState.earn(q.reward)
	GameState.add_rep(q.rep)
	GameState.today["quest"] = q.dish
	Audio.sfx("sparkle")
	GameState.toast.emit("스페셜 요리 대성공! 고마움의 선물로 %d골드를 받았어요." % q.reward)
	quest_id = ""


## 부탁을 거절하면 손님이 아쉬워하며 돌아가요(평판은 그대로).
func decline() -> void:
	if GameState.active_quest == quest_id:
		GameState.active_quest = ""
	quest_id = ""
	_leave(false)


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
	items = []
	busy = false
	left_table.emit(self, k, happy)
	# 빈 접시는 잠깐 뒤 저절로 치워져요
	await get_tree().create_timer(1.2).timeout
	if state == "empty":
		clear_plates()


func clear_plates() -> void:
	for f in foods:
		f.queue_free()
	foods.clear()
	served = []
	plates.queue_redraw()


func clean() -> void:
	dirty = false
	busy = false
	clear_plates()


func _draw_plates() -> void:
	for i in foods.size():
		var at := _food_pos(i)
		var drink := _kind(served[i]) == "drink" if i < served.size() else false
		var r := 13.0 if drink else 19.0
		plates.draw_set_transform(at + Vector2(0, 8), 0, Vector2(1, 0.45))
		plates.draw_circle(Vector2(0, 2), r + 2, Color(0.3, 0.2, 0.1, 0.15))
		plates.draw_circle(Vector2.ZERO, r, Color("#FFFDF7"))
		plates.draw_arc(Vector2.ZERO, r, 0, TAU, 28, UI.OUTLINE, 2)
		plates.draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 24, Color("#E8DCC8"), 1.5)
	plates.draw_set_transform(Vector2.ZERO)
