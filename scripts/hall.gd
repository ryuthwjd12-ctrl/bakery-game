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
const KITCHEN_SPOT := Vector2(650, 470)  # 계산대 옆(주방 들어가는 곳)
const ANNEX_DOOR := Vector2(945, 352)  # 안쪽 오른쪽 문 → 별관
const HALL_ENTRY := Vector2(962, 382)  # 별관에서 돌아오면 서는 곳
const CASE_SPOT := Vector2(420, 585)  # 진열장 앞
## 그림 속 의자: 앉는 자리, 탁자 위 음식 자리, 다가가서 설 자리, 왼쪽을 보는지
const SEATS := [
	{"seat": Vector2(728, 478), "food": Vector2(786, 462), "stand": Vector2(738, 600), "left": false},
	{"seat": Vector2(896, 482), "food": Vector2(840, 462), "stand": Vector2(968, 505), "left": true},
	{"seat": Vector2(505, 652), "food": Vector2(568, 642), "stand": Vector2(432, 690), "left": false},
	{"seat": Vector2(674, 640), "food": Vector2(622, 642), "stand": Vector2(762, 640), "left": true},
	{"seat": Vector2(1028, 392), "food": Vector2(1085, 382), "stand": Vector2(955, 430), "left": false},
]

## 별관: 빈 방 그림을 홀 오른쪽(ANNEX_X)에 이어 붙여요. 가구점에서 산 탁자 세트가 SLOT 자리에 놓여요.
const ANNEX_X := 1600.0
const ANNEX_FLOOR := [Vector2(688, 196), Vector2(1330, 522), Vector2(1135, 610), Vector2(1135, 768),
	Vector2(500, 768), Vector2(75, 522)]
const ANNEX_FRONT := [Vector2(950, 575), Vector2(1135, 490), Vector2(1135, 768), Vector2(950, 768)]
const ANNEX_BACK := Vector2(405, 362)  # 별관 왼쪽 문 → 홀
const ANNEX_ENTRY := Vector2(442, 384)  # 홀에서 오면 서는 곳
const ANNEX_SLOTS := [Vector2(470, 280), Vector2(210, 370), Vector2(760, 380), Vector2(480, 505)]
const DECOR_SPOTS := [["furniture/plant_big", Vector2(1230, 349)], ["furniture/plant_small", Vector2(92, 397)]]
## 탁자 세트 그림(table_set.png) 왼쪽 위 기준 좌표
const SET_BLOCK := [Vector2(6, 100), Vector2(76, 195), Vector2(146, 210), Vector2(261, 178), Vector2(256, 30),
	Vector2(196, 2), Vector2(76, 2), Vector2(6, 30)]
const SET_SEATS := [
	{"seat": Vector2(44, 108), "food": Vector2(102, 92), "stand": Vector2(54, 232), "left": false},
	{"seat": Vector2(212, 112), "food": Vector2(156, 92), "stand": Vector2(286, 135), "left": true},
]
const HERO_SCALE := 0.88
const ANIMAL_SCALE := 1.05
const ZOOM := 1.2

var main: Node
var world := Node2D.new()
var player
var waiter
var tables: Array = []
var walk: WalkMap  # 홀
var annex_walk: WalkMap  # 별관 (별관 좌표 그대로, ANNEX_X를 빼서 써요)
var annex_layer := Node2D.new()
var cam := Camera2D.new()
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
	var abg := Sprite2D.new()
	abg.texture = Sprites.tex("backgrounds/annex")
	abg.centered = false
	abg.position = Vector2(ANNEX_X, 0)
	add_child(abg)
	add_child(annex_layer)  # 별관 탁자는 배경 바로 위, 손님·주인공 아래
	world.y_sort_enabled = true
	add_child(world)
	walk = WalkMap.new(FLOOR, BLOCKS)
	var n_sets := GameState.annex_tables
	for i in n_sets:
		GameState.annex_tables = i + 1
		add_annex_set()
	for i in GameState.decor:
		_place_decor(i)
	_build_annex()

	for sd in SEATS:
		_add_table(sd, Vector2.ZERO)

	player = Player.new()
	player.setup(GameState.hero, HERO_SCALE)
	player.can_walk = can_walk
	player.position = Vector2(800, 640)
	world.add_child(player)
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	player.add_child(cam)
	_set_cam_room(false)
	if GameState.has_waiter:
		hire_waiter()


func _add_table(sd: Dictionary, off: Vector2):
	var t := Table.new()
	t.position = sd.seat + off
	t.food_at = sd.food - sd.seat
	t.stand = sd.stand + off
	t.face_left = sd.left
	t.left_table.connect(_on_left)
	world.add_child(t)
	tables.append(t)
	return t


## 별관 걷기 지도와 가구를 (다시) 만들어요. 탁자나 화분을 사면 불러요.
func _build_annex() -> void:
	var blocks: Array = [ANNEX_FRONT]
	for i in GameState.annex_tables:
		var o: Vector2 = ANNEX_SLOTS[i]
		var poly: Array = []
		for q in SET_BLOCK:
			poly.append(q + o)
		blocks.append(poly)
	for i in GameState.decor:
		var tex := Sprites.tex(DECOR_SPOTS[i][0])
		var o: Vector2 = DECOR_SPOTS[i][1]
		var w := float(tex.get_width())
		var h := float(tex.get_height())
		blocks.append([o + Vector2(w * 0.1, h * 0.7), o + Vector2(w * 0.9, h * 0.7), o + Vector2(w * 0.9, h), o + Vector2(w * 0.1, h)])
	annex_walk = WalkMap.new(ANNEX_FLOOR, blocks)


## 가구점에서 산 물건을 별관에 놓아요.
func add_annex_set() -> void:
	var i := GameState.annex_tables - 1
	var o: Vector2 = ANNEX_SLOTS[i] + Vector2(ANNEX_X, 0)
	var sp := Sprite2D.new()
	sp.texture = Sprites.tex("furniture/table_set")
	sp.centered = false
	sp.position = o
	annex_layer.add_child(sp)
	for sd in SET_SEATS:
		_add_table(sd, o)
	_build_annex()


## 가구를 되팔면 마지막에 놓은 탁자 세트를 치워요(손님이 앉아 있으면 못 팔아요).
func remove_annex_set() -> bool:
	var last2 := tables.slice(tables.size() - 2)
	for t in last2:
		if t.state != "empty" or t.dirty:
			return false
	for t in last2:
		tables.erase(t)
		t.queue_free()
	var sps := annex_layer.get_children()
	if not sps.is_empty():
		sps[-1].queue_free()
	GameState.annex_tables -= 1
	_build_annex()
	return true


func add_decor() -> void:
	var i := GameState.decor - 1
	_place_decor(i)
	_build_annex()


func _place_decor(i: int) -> void:
	var sp := Sprite2D.new()
	var tex := Sprites.tex(DECOR_SPOTS[i][0])
	sp.texture = tex
	sp.offset = Vector2(tex.get_width() / 2.0, 0)
	sp.centered = false
	sp.position = DECOR_SPOTS[i][1] + Vector2(ANNEX_X - tex.get_width() / 2.0, 0)
	world.add_child(sp)
	# y 정렬을 발 위치로 맞춰요
	sp.offset.y = -tex.get_height()
	sp.position.y += tex.get_height()


func in_annex(p: Vector2) -> bool:
	return p.x >= ANNEX_X - 50


func _set_cam_room(annex: bool) -> void:
	cam.limit_left = int(ANNEX_X) if annex else 0
	cam.limit_right = int(ANNEX_X) + 1408 if annex else 1408
	cam.limit_top = 0
	cam.limit_bottom = 768
	cam.reset_smoothing()


func hire_waiter() -> void:
	if waiter:
		return
	waiter = Waiter.new()
	waiter.hall = self
	waiter.home = Vector2(870, 612)
	waiter.position = DOOR
	world.add_child(waiter)


func can_walk(p: Vector2) -> bool:
	if in_annex(p):
		return annex_walk.can_walk(p - Vector2(ANNEX_X, 0))
	return walk.can_walk(p)


## from에서 to까지 걸어갈 점들. 방이 다르면 문을 지나가요(Dictionary {"tp": 위치}는 순간 이동).
func find_path(from: Vector2, to: Vector2) -> Array:
	var off := Vector2(ANNEX_X, 0)
	var fa := in_annex(from)
	var ta := in_annex(to)
	if fa == ta:
		if fa:
			return annex_walk.find_path(from - off, to - off).map(func(q): return q + off)
		return walk.find_path(from, to)
	if fa:
		var out: Array = annex_walk.find_path(from - off, ANNEX_BACK).map(func(q): return q + off)
		out.append({"tp": HALL_ENTRY})
		out.append_array(walk.find_path(HALL_ENTRY, to))
		return out
	var out2: Array = walk.find_path(from, ANNEX_DOOR)
	out2.append({"tp": ANNEX_ENTRY + off})
	out2.append_array(annex_walk.find_path(ANNEX_ENTRY, to - off).map(func(q): return q + off))
	return out2


func walk_player(p: Vector2) -> void:
	player.walk_path(find_path(player.position, p))


func set_active(on: bool, from := "") -> void:
	active = on
	visible = on
	player.active = on
	pending = null
	cam.enabled = on  # 주방은 카메라 없이 그려야 해서 꺼 둬요
	if on:
		cam.make_current()
		Audio.play_bgm("bgm_shop")
		door_cooldown = 0.6
		if from == "kitchen":
			player.position = KITCHEN_SPOT + Vector2(30, 60)
		elif from == "village":
			player.position = DOOR + Vector2(-50, -40)
		_set_cam_room(in_annex(player.position))
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
	out.append({"pos": KITCHEN_SPOT, "r": 50.0, "text": "주방으로", "do": func(): main.goto("kitchen", "hall"), "door": true})
	out.append({"pos": DOOR, "r": 50.0, "text": "밖으로", "do": func(): main.goto("village", "hall"), "door": true})
	out.append({"pos": ANNEX_DOOR, "r": 50.0, "text": "별관으로", "do": _to_annex, "door": true})
	out.append({"pos": ANNEX_BACK + Vector2(ANNEX_X, 0), "r": 50.0, "text": "홀로", "do": _to_hall, "door": true})
	out.append({"pos": Vector2(915, 705) + Vector2(ANNEX_X, 0), "r": 50.0, "text": "밖으로", "do": func(): main.goto("village", "hall"), "door": true})
	return out


func _to_annex() -> void:
	if GameState.annex_tables == 0:
		GameState.toast.emit("별관은 비어 있어요. 마을 가구점에서 탁자를 사면 손님을 받을 수 있어요.")
	player.position = ANNEX_ENTRY + Vector2(ANNEX_X, 0)
	player.walk_to(player.position)
	door_cooldown = 0.6
	Audio.sfx("door")
	_set_cam_room(true)


func _to_hall() -> void:
	player.position = HALL_ENTRY
	player.walk_to(player.position)
	door_cooldown = 0.6
	Audio.sfx("door")
	_set_cam_room(false)


func _process(delta: float) -> void:
	_spawn_tick(delta)
	if not active:
		return
	door_cooldown -= delta
	var annex_now := in_annex(player.position)
	if annex_now != (cam.limit_left > 0):
		_set_cam_room(annex_now)
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
	if near and near.get("door", false) and door_cooldown <= 0 and best < 40 and not player.busy \
			and player.waypoints.is_empty():
		near.do.call()
		return
	if near and not main.hud.is_panel_open() and not player.busy:
		main.hud.set_prompt("E  " + near.text, get_viewport().get_canvas_transform() * (player.position + Vector2(0, 14)))
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
		var p: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
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
	if t.quest_id != "":
		var q := GameState.quest(t.quest_id)
		main.hud.open_quest(q, func():
			GameState.active_quest = q.id
			t.take_order(), func(): t.decline())
		return
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
	var base := lerpf(34.0, 16.0, GameState.cleanliness / 100.0) - GameState.level() * 1.5 \
		- GameState.annex_tables * 2.0 - GameState.decor * 2.0
	spawn_left = maxf(10.0, base) + randf() * 6.0
	var free := tables.filter(func(t): return t.state == "empty" and not t.dirty)
	if free.is_empty():
		return
	var t = free.pick_random()
	t.reserve()
	var kind: String = GameState.customer_kind()
	var order: String = GameState.menu_now().pick_random()
	# 가끔 부탁 손님이 와요 (하루 한 번, 오전 10시 이후)
	var qid := ""
	var q := GameState.next_quest()
	if not q.is_empty() and not GameState.quest_seen_today and GameState.active_quest == "" \
			and GameState.minutes > GameState.DAY_START + 60 and randf() < 0.5:
		GameState.quest_seen_today = true
		qid = q.id
		kind = q.kind
		order = q.dish
	GameState.customer_spawned.emit(kind)
	var a := _new_customer(kind)
	a.position = _door_for(t)
	a.modulate.a = 0.0
	world.add_child(a)
	Audio.sfx("door")
	a.create_tween().tween_property(a, "modulate:a", 1.0, 0.3)
	await a.walk_path(find_path(a.position, t.stand) + [t.position + Vector2(0, 6)])
	a.queue_free()
	if t.state == "coming":
		t.seat(kind, order, qid)


func _on_left(t, kind: String, _happy: bool) -> void:
	update_cleanliness()
	var a := _new_customer(kind)
	a.position = t.position + Vector2(0, 6)
	world.add_child(a)
	await a.walk_path([t.stand] + find_path(t.stand, _door_for(t)))
	GameState.customer_left.emit(kind)
	if active:
		Audio.sfx("door")
	var tw := a.create_tween()
	tw.tween_property(a, "modulate:a", 0.0, 0.3)
	tw.tween_callback(a.queue_free)


func _door_for(t) -> Vector2:
	return Vector2(ANNEX_X + 915, 705) if in_annex(t.position) else DOOR


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
		if t.state == "ordering" and not t.busy and t.quest_id == "":  # 부탁 손님은 주인공이 직접 들어요
			return t
	return null


func find_clean_job():
	for t in tables:
		if t.dirty and t.state == "empty" and not t.busy:
			return t
	return null
