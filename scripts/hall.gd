extends Node2D
## 가게 홀. 손님이 와서 앉으면 주인공(나중엔 알바생)이 주문을 받고, 받은 순서대로 음식을 내주고, 자리를 치워요.

const Player := preload("res://scripts/player.gd")
const Table := preload("res://scripts/table.gd")
const Animal := preload("res://scripts/animal.gd")
const Waiter := preload("res://scripts/waiter.gd")

## 빈 방 그림(1408x768)의 바닥 모양. 발이 이 안에 있어야 걸을 수 있어요.
const FLOOR := [Vector2(688, 228), Vector2(1290, 515), Vector2(1010, 735),
	Vector2(590, 740), Vector2(125, 520)]
const DOOR := Vector2(1040, 600)
const KITCHEN_DOOR := Vector2(395, 380)
const CASE_SPOT := Vector2(430, 540)
const TABLE_SPOTS := [Vector2(600, 470), Vector2(850, 395), Vector2(770, 625), Vector2(1075, 505)]

var main: Node
var world := Node2D.new()
var player
var waiter
var tables: Array = []
var blockers: Array = []  # [center, radius-x, radius-y]
var spawn_left := 3.0
var active := false
var near = null
var pending = null  # 클릭해서 걸어가는 중인 대상
var case_icons := Node2D.new()
var door_cooldown := 0.0


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex("backgrounds/hall_empty")
	bg.centered = false
	add_child(bg)
	_deco("furniture/picture", Vector2(560, 175), 1.1)
	_deco("furniture/rug_icon", Vector2(790, 600), 2.0)

	world.y_sort_enabled = true
	add_child(world)
	var case_sp := _furniture("furniture/display_case", Vector2(330, 480), 1.9, 80, 30)
	case_sp.add_child(case_icons)
	_furniture("furniture/plant", Vector2(690, 268), 1.4, 30, 14)
	_furniture("furniture/plant", Vector2(1235, 520), 1.4, 30, 14)
	_furniture("furniture/lamp", Vector2(180, 540), 1.3, 18, 10)

	for p in TABLE_SPOTS:
		var t := Table.new()
		t.position = p
		t.left_table.connect(_on_left)
		world.add_child(t)
		tables.append(t)
		blockers.append([p + Vector2(10, -14), 72.0, 30.0])

	player = Player.new()
	player.setup(GameState.hero, 0.68)
	player.can_walk = can_walk
	player.position = Vector2(700, 560)
	world.add_child(player)
	if GameState.has_waiter:
		hire_waiter()
	GameState.changed.connect(_refresh_case)
	_refresh_case()


func hire_waiter() -> void:
	if waiter:
		return
	waiter = Waiter.new()
	waiter.hall = self
	waiter.home = Vector2(960, 330)
	waiter.position = DOOR
	world.add_child(waiter)


func _deco(path: String, at: Vector2, s: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = Sprites.tex(path)
	sp.position = at
	sp.scale = Vector2(s, s)
	add_child(sp)
	return sp


func _furniture(path: String, at: Vector2, s: float, rx: float, ry: float) -> Sprite2D:
	var sp := Sprite2D.new()
	var tex := Sprites.tex(path)
	sp.texture = tex
	sp.offset = Vector2(0, -tex.get_height() / 2.0)
	sp.scale = Vector2(s, s)
	sp.position = at
	world.add_child(sp)
	blockers.append([at + Vector2(0, -ry * 0.5), rx, ry])
	return sp


## 진열대 위에 만들어 둔 음식을 보여 줘요.
func _refresh_case() -> void:
	for c in case_icons.get_children():
		c.queue_free()
	var i := 0
	for id in GameState.stock:
		for n in mini(GameState.stock[id], 3):
			if i >= 8:
				return
			var s := Sprite2D.new()
			s.texture = Sprites.item(id)
			s.scale = Vector2(0.22, 0.22)
			s.position = Vector2(-26 + (i % 4) * 15, -60 + (i / 4) * 16)
			case_icons.add_child(s)
			i += 1


func can_walk(p: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(p, PackedVector2Array(FLOOR)):
		return false
	for b in blockers:
		var d: Vector2 = p - b[0]
		if (d.x * d.x) / (b[1] * b[1]) + (d.y * d.y) / (b[2] * b[2]) < 1.0:
			return false
	return true


func set_active(on: bool, from := "") -> void:
	active = on
	visible = on
	player.active = on
	pending = null
	if on:
		Audio.play_bgm("bgm_shop")
		door_cooldown = 0.6
		if from == "kitchen":
			player.position = KITCHEN_DOOR + Vector2(60, 60)
		elif from == "village":
			player.position = DOOR + Vector2(-80, -40)
	else:
		main.hud.set_prompt("", Vector2.ZERO)


## 지금 할 수 있는 일 목록
func _actions() -> Array:
	var out: Array = []
	for t in tables:
		if t.busy:
			continue
		if t.state == "ordering":
			out.append({"pos": t.interact_point(), "r": 70.0, "text": "주문 받기", "do": _take_order.bind(t)})
		elif t.state == "waiting":
			out.append({"pos": t.interact_point(), "r": 70.0, "text": "음식 내주기", "do": _serve.bind(t)})
		elif t.state == "empty" and t.dirty:
			out.append({"pos": t.interact_point(), "r": 70.0, "text": "치우기", "do": _clean.bind(t)})
	out.append({"pos": KITCHEN_DOOR, "r": 60.0, "text": "주방으로", "do": func(): main.goto("kitchen", "hall"), "door": true})
	out.append({"pos": DOOR, "r": 70.0, "text": "밖으로", "do": func(): main.goto("village", "hall"), "door": true})
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
				player.walk_to(a.pos)
				return
		player.walk_to(p)


func _table_hit(a: Dictionary, p: Vector2) -> bool:
	for t in tables:
		if a.pos == t.interact_point() and Rect2(t.position + Vector2(-70, -190), Vector2(190, 200)).has_point(p):
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
	_fly_item(t.order, player.position + Vector2(0, -120), t.position + Vector2(-4, -84))
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
	var a := Animal.new()
	a.setup(kind, 0.8 if kind != "chick" else 0.9)
	a.position = DOOR
	world.add_child(a)
	await a.walk_path([DOOR + Vector2(-60, -30), t.position + Vector2(80, -28)])
	a.queue_free()
	if t.state == "coming":
		t.seat(kind, order)


func _on_left(t, kind: String, _happy: bool) -> void:
	update_cleanliness()
	var a := Animal.new()
	a.setup(kind, 0.8 if kind != "chick" else 0.9)
	a.position = t.position + Vector2(80, -28)
	world.add_child(a)
	await a.walk_path([DOOR + Vector2(-60, -30), DOOR])
	Audio.sfx("door")
	var tw := a.create_tween()
	tw.tween_property(a, "modulate:a", 0.0, 0.3)
	tw.tween_callback(a.queue_free)


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
	player.position = Vector2(700, 560)


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
