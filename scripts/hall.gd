extends Node2D
## 가게 홀. 손님이 와서 앉으면 주인공(나중엔 알바생)이 주문을 받고, 받은 순서대로 음식을 내주고, 자리를 치워요.

const Player := preload("res://scripts/player.gd")
const Table := preload("res://scripts/table.gd")
const Animal := preload("res://scripts/animal.gd")
const Waiter := preload("res://scripts/waiter.gd")

## 가구가 그려진 가게 그림(1408x768) 기준 좌표예요. 발이 FLOOR 안, BLOCKS 밖에 있어야 걸을 수 있어요.
## BLOCKS는 가구 자리와 그 뒤쪽까지 막아서, 주인공이 가구 뒤로 가서 그림이 겹치는 일이 없게 해요.
const FLOOR := [Vector2(700, 240), Vector2(1335, 528), Vector2(1160, 612), Vector2(1160, 768),
	Vector2(440, 768), Vector2(75, 548)]
const BLOCKS := [
	# 진열장·계산대·메뉴판과 그 뒤 벽쪽
	[Vector2(75, 548), Vector2(205, 600), Vector2(300, 600), Vector2(480, 515), Vector2(600, 452),
		Vector2(690, 402), Vector2(700, 240)],
	# 안쪽 화분들
	[Vector2(690, 236), Vector2(880, 322), Vector2(870, 345), Vector2(800, 322), Vector2(740, 300), Vector2(690, 272)],
	# 가운데 탁자
	[Vector2(690, 470), Vector2(760, 565), Vector2(830, 580), Vector2(945, 548), Vector2(940, 400),
		Vector2(880, 372), Vector2(760, 372), Vector2(690, 400)],
	# 왼쪽 아래 탁자
	[Vector2(455, 640), Vector2(470, 730), Vector2(560, 755), Vector2(670, 745), Vector2(718, 690),
		Vector2(712, 555), Vector2(650, 535), Vector2(530, 535), Vector2(455, 560)],
	# 창가 탁자와 화분
	[Vector2(985, 330), Vector2(990, 475), Vector2(1080, 495), Vector2(1135, 550), Vector2(1245, 550),
		Vector2(1320, 540), Vector2(1335, 528), Vector2(1180, 345), Vector2(1060, 300), Vector2(1000, 300)],
	# 앞쪽 화분
	[Vector2(640, 680), Vector2(785, 680), Vector2(785, 768), Vector2(640, 768)],
	# 앞문 벽
	[Vector2(950, 575), Vector2(1160, 480), Vector2(1160, 768), Vector2(950, 768)],
]
const DOOR := Vector2(905, 705)  # 앞문 앞 발판
const KITCHEN_DOOR := Vector2(945, 352)  # 안쪽 오른쪽 문(주방)
const CASE_SPOT := Vector2(470, 560)  # 진열장 앞
## 그림 속 의자: 앉는 자리, 탁자 위 음식 자리, 다가가서 설 자리, 왼쪽을 보는지
const SEATS := [
	{"seat": Vector2(728, 478), "food": Vector2(786, 462), "stand": Vector2(738, 600), "left": false},
	{"seat": Vector2(896, 482), "food": Vector2(840, 462), "stand": Vector2(968, 505), "left": true},
	{"seat": Vector2(505, 652), "food": Vector2(568, 642), "stand": Vector2(432, 690), "left": false},
	{"seat": Vector2(674, 640), "food": Vector2(622, 642), "stand": Vector2(762, 640), "left": true},
	{"seat": Vector2(1028, 392), "food": Vector2(1085, 382), "stand": Vector2(955, 430), "left": false},
]
const HERO_SCALE := 0.88
const ANIMAL_SCALE := 1.05

var main: Node
var world := Node2D.new()
var player
var waiter
var tables: Array = []
var walk: WalkMap
var spawn_left := 3.0
var active := false
var near = null
var pending = null  # 클릭해서 걸어가는 중인 대상
var door_cooldown := 0.0


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex("backgrounds/hall")
	bg.centered = false
	add_child(bg)
	world.y_sort_enabled = true
	add_child(world)
	walk = WalkMap.new(FLOOR, BLOCKS)

	for sd in SEATS:
		var t := Table.new()
		t.position = sd.seat
		t.food_at = sd.food - sd.seat
		t.stand = sd.stand
		t.face_left = sd.left
		t.left_table.connect(_on_left)
		world.add_child(t)
		tables.append(t)

	player = Player.new()
	player.setup(GameState.hero, HERO_SCALE)
	player.can_walk = can_walk
	player.position = Vector2(800, 640)
	world.add_child(player)
	if GameState.has_waiter:
		hire_waiter()


func hire_waiter() -> void:
	if waiter:
		return
	waiter = Waiter.new()
	waiter.hall = self
	waiter.home = Vector2(870, 612)
	waiter.position = DOOR
	world.add_child(waiter)


func can_walk(p: Vector2) -> bool:
	return walk.can_walk(p)


func find_path(from: Vector2, to: Vector2) -> Array:
	return walk.find_path(from, to)


func walk_player(p: Vector2) -> void:
	player.walk_path(find_path(player.position, p))


func set_active(on: bool, from := "") -> void:
	active = on
	visible = on
	player.active = on
	pending = null
	if on:
		Audio.play_bgm("bgm_shop")
		door_cooldown = 0.6
		if from == "kitchen":
			player.position = KITCHEN_DOOR + Vector2(-10, 70)
		elif from == "village":
			player.position = DOOR + Vector2(-50, -40)
	else:
		main.hud.set_prompt("", Vector2.ZERO)


## 지금 할 수 있는 일 목록
func _actions() -> Array:
	var out: Array = []
	for t in tables:
		if t.busy:
			continue
		if t.state == "ordering":
			out.append({"pos": t.interact_point(), "r": 60.0, "text": "주문 받기", "do": _take_order.bind(t)})
		elif t.state == "waiting":
			out.append({"pos": t.interact_point(), "r": 60.0, "text": "음식 내주기", "do": _serve.bind(t)})
		elif t.state == "empty" and t.dirty:
			out.append({"pos": t.interact_point(), "r": 60.0, "text": "치우기", "do": _clean.bind(t)})
	out.append({"pos": KITCHEN_DOOR, "r": 50.0, "text": "주방으로", "do": func(): main.goto("kitchen", "hall"), "door": true})
	out.append({"pos": DOOR, "r": 50.0, "text": "밖으로", "do": func(): main.goto("village", "hall"), "door": true})
	return out


func _process(delta: float) -> void:
	_spawn_tick(delta)
	if not active:
		return
	door_cooldown -= delta
	near = null
	var best := 1e9
	for a in _actions():
		var d: float = player.position.distance_to(a.pos)
		if d < a.r and d < best:
			near = a
			best = d
	if pending and near and near.text == pending.text and near.pos == pending.pos:
		pending = null
		near.do.call()
		return
	# 문은 닿기만 해도 들어가요
	if near and near.get("door", false) and door_cooldown <= 0 and best < 40 and not player.busy:
		near.do.call()
		return
	if near and not main.hud.is_panel_open() and not player.busy:
		main.hud.set_prompt("E  " + near.text, player.position + Vector2(0, 14))
	else:
		main.hud.set_prompt("", Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if not active or main.hud.is_panel_open() or player.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_E or event.keycode == KEY_SPACE) and near:
			near.do.call()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		pending = null
		for a in _actions():
			if a.pos.distance_to(p) < 90 or _table_hit(a, p):
				pending = a
				walk_player(a.pos)
				return
		walk_player(p)


func _table_hit(a: Dictionary, p: Vector2) -> bool:
	for t in tables:
		if a.pos == t.interact_point() and Rect2(t.position + Vector2(-50, -150), Vector2(100, 170)).has_point(p):
			return true
	return false


func _take_order(t) -> void:
	t.take_order()


func _serve(t) -> void:
	if GameState.orders.is_empty() or GameState.orders[0] != t:
		GameState.toast.emit("먼저 주문한 손님부터 드려요!")
		_point_at(GameState.orders[0] if not GameState.orders.is_empty() else null)
		Audio.sfx("fail")
		return
	if not GameState.take_stock(t.order):
		GameState.toast.emit("아직 만든 음식이 없어요. 주방에서 만들어요.")
		Audio.sfx("fail")
		return
	_fly_item(t.order, player.position + Vector2(0, -110), t.position + t.food_at)
	t.serve()


func _point_at(t) -> void:
	if t == null:
		return
	var tw := create_tween()
	tw.tween_property(t.bubble, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(t.bubble, "scale", Vector2.ONE, 0.12)
	tw.tween_property(t.bubble, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(t.bubble, "scale", Vector2.ONE, 0.12)


func _clean(t) -> void:
	t.busy = true
	Audio.sfx("sweep")
	await player.work(1.4)
	t.clean()
	GameState.mark_tutorial("clean")
	update_cleanliness()


func _fly_item(id: String, from: Vector2, to: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = Sprites.item(id)
	s.scale = Vector2(0.5, 0.5)
	s.position = from
	s.z_index = 90
	add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "position", to, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(s.queue_free)


func _spawn_tick(delta: float) -> void:
	if not GameState.is_open() or not GameState.clock_running:
		return
	spawn_left -= delta
	if spawn_left > 0:
		return
	# 깨끗하고 유명한 가게일수록 손님이 자주 와요.
	var base := lerpf(34.0, 16.0, GameState.cleanliness / 100.0) - GameState.level() * 1.5
	spawn_left = maxf(10.0, base) + randf() * 6.0
	var free := tables.filter(func(t): return t.state == "empty" and not t.dirty)
	if free.is_empty():
		return
	var t = free.pick_random()
	t.reserve()
	var kind: String = Sprites.ANIMALS.pick_random()
	var order: String = GameState.menu_now().pick_random()
	GameState.customer_spawned.emit(kind)
	var a := _new_customer(kind)
	a.position = DOOR
	a.modulate.a = 0.0
	world.add_child(a)
	Audio.sfx("door")
	a.create_tween().tween_property(a, "modulate:a", 1.0, 0.3)
	await a.walk_path(find_path(DOOR, t.stand) + [t.position + Vector2(0, 6)])
	a.queue_free()
	if t.state == "coming":
		t.seat(kind, order)


func _on_left(t, kind: String, _happy: bool) -> void:
	update_cleanliness()
	var a := _new_customer(kind)
	a.position = t.position + Vector2(0, 6)
	world.add_child(a)
	await a.walk_path([t.stand] + find_path(t.stand, DOOR))
	Audio.sfx("door")
	var tw := a.create_tween()
	tw.tween_property(a, "modulate:a", 0.0, 0.3)
	tw.tween_callback(a.queue_free)


func _new_customer(kind: String) -> Node2D:
	var a := Animal.new()
	a.setup(kind, ANIMAL_SCALE * (0.9 if kind == "chick" else 1.0))
	return a


func update_cleanliness() -> void:
	var n := tables.filter(func(t): return t.dirty).size()
	GameState.cleanliness = clampi(100 - n * 15, 0, 100)
	GameState.changed.emit()


## 하루가 끝나면 손님과 먼지를 정리해요.
func reset_day() -> void:
	for t in tables:
		t.state = "empty"
		t.animal.visible = false
		t.bubble.visible = false
		t.food.visible = false
		t.busy = false
		t.dirty = false
		t.dust.queue_redraw()
	update_cleanliness()
	spawn_left = 3.0
	player.position = Vector2(800, 640)


# 알바생이 쓰는 함수들
func find_serve_job():
	if GameState.orders.is_empty():
		return null
	var t = GameState.orders[0]
	if not t.busy and GameState.stock.get(t.order, 0) > 0:
		return t
	return null


func find_order_job():
	for t in tables:
		if t.state == "ordering" and not t.busy:
			return t
	return null


func find_clean_job():
	for t in tables:
		if t.dirty and t.state == "empty" and not t.busy:
			return t
	return null
