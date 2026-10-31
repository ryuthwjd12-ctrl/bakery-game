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
const MENU_BOARD := Rect2(565, 232, 110, 170)  # 그림 속 칠판 메뉴판(누르면 오늘의 메뉴)
## 그림 속 의자: 앉는 자리, 탁자 위 음식 자리, 다가가서 설 자리, 왼쪽을 보는지
const SEATS := [
	{"seat": Vector2(728, 478), "food": Vector2(786, 462), "stand": Vector2(738, 600), "left": false},
	{"seat": Vector2(896, 482), "food": Vector2(840, 462), "stand": Vector2(968, 505), "left": true},
	{"seat": Vector2(505, 652), "food": Vector2(568, 642), "stand": Vector2(432, 690), "left": false},
	{"seat": Vector2(674, 640), "food": Vector2(622, 642), "stand": Vector2(762, 640), "left": true},
	{"seat": Vector2(1028, 392), "food": Vector2(1085, 382), "stand": Vector2(955, 430), "left": false},
]

## 별관: 가로로 긴 빈 방 그림(2579x686)을 홀 오른쪽(ANNEX_X)에 이어 붙여요.
## 카메라가 주인공을 따라 옆으로 움직여요. 가구점에서 산 탁자 세트가 SLOT 자리에 한 줄로 놓여요.
const ANNEX_X := 1600.0
const ANNEX_SIZE := Vector2i(2579, 686)
const ANNEX_FLOOR := [Vector2(644, 392), Vector2(1934, 392), Vector2(2579, 626), Vector2(2579, 686),
	Vector2(0, 686), Vector2(0, 626)]
const ANNEX_BACK := Vector2(358, 552)  # 별관 왼쪽 아치문 → 홀
const ANNEX_ENTRY := Vector2(430, 590)  # 홀에서 오면 서는 곳
const ANNEX_EXIT := Vector2(2405, 645)  # 오른쪽 문 → 마을
const ANNEX_SLOTS := [Vector2(700, 410), Vector2(1100, 410), Vector2(1500, 410), Vector2(1860, 440)]
const DECOR_SPOTS := [["furniture/plant_big", Vector2(2250, 470)], ["furniture/plant_small", Vector2(520, 430)]]
## 탁자 세트 그림(table_set.png) 왼쪽 위 기준 좌표
const SET_BLOCK := [Vector2(6, 100), Vector2(76, 195), Vector2(146, 210), Vector2(261, 178), Vector2(256, 30),
	Vector2(196, 2), Vector2(76, 2), Vector2(6, 30)]
const SET_SEATS := [
	{"seat": Vector2(44, 108), "food": Vector2(102, 92), "stand": Vector2(54, 232), "left": false},
	{"seat": Vector2(212, 112), "food": Vector2(156, 92), "stand": Vector2(286, 135), "left": true},
]
const HERO_SCALE := 0.7
const ANIMAL_SCALE := 0.84
const ZOOM := 1.0
const ZOOM_MAX := 1.8  # 휠로 당겨 볼 수 있는 만큼(밀면 1배까지)

var main: Node
var world := Node2D.new()
var player
var waiter
var tables: Array = []
var walk: WalkMap  # 홀
var annex_walk: WalkMap  # 별관 (별관 좌표 그대로, ANNEX_X를 빼서 써요)
var annex_layer := Node2D.new()
var furn_layer := Node2D.new()  # 놓은 탁자(손님·주인공 아래)
var furn_nodes: Array = []
var furn_tables: Array = []  # 놓은 탁자 세트의 손님 자리
## 꾸미기(B): 산 가구를 고르면 마우스를 따라다니고, 누르면 그 자리에 놓여요. 놓은 가구를 누르면 다시 들어요.
var edit_mode := false
var ghost_id := ""
var ghost: Sprite2D
var ghost_from := -1  # 놓여 있던 가구를 든 거면 그 번호(취소하면 제자리)
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
	add_child(annex_layer)
	add_child(furn_layer)  # 놓은 탁자는 배경 바로 위, 손님·주인공 아래
	world.y_sort_enabled = true
	add_child(world)
	for sd in SEATS:
		_add_table(sd, Vector2.ZERO)
	_migrate_furniture()
	rebuild_furniture()

	player = Player.new()
	player.setup(GameState.hero, HERO_SCALE)
	player.can_walk = can_walk
	player.position = Vector2(800, 640)
	world.add_child(player)
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.set_meta("zoom_key", "hall")
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


## ---- 가구: 가구점·인테리어점에서 산 가구를 "꾸미기"(B)로 홀이나 별관 바닥에 직접 놓아요.
## 놓은 가구는 걸을 수 없는 자리가 되고, 탁자 세트에는 손님 두 명이 앉아요.

## 예전 저장 파일(정해진 자리에 놓이던 탁자·화분)을 새 방식으로 옮겨요.
func _migrate_furniture() -> void:
	if not GameState.placed.is_empty():
		return
	for i in mini(GameState.annex_tables, ANNEX_SLOTS.size()):
		var o: Vector2 = ANNEX_SLOTS[i] + Vector2(ANNEX_X, 0)
		GameState.placed.append({"id": "table_set", "x": o.x, "y": o.y})
	var ids := ["plant_big", "plant_small"]
	for i in mini(GameState.decor, 2):
		var tex := Sprites.tex(GameState.FURNITURE[ids[i]].tex)
		var o2: Vector2 = DECOR_SPOTS[i][1] + Vector2(ANNEX_X - tex.get_width() / 2.0, 0)
		GameState.placed.append({"id": ids[i], "x": o2.x, "y": o2.y})


func _foot(id: String, o: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in GameState.FURNITURE[id].foot:
		out.append(q + o)
	return out


## 놓은 가구를 모두 다시 그리고, 걷기 지도와 손님 자리를 다시 만들어요.
func rebuild_furniture() -> void:
	for n in furn_nodes:
		n.queue_free()
	furn_nodes.clear()
	for t in furn_tables:
		tables.erase(t)
		GameState.orders.erase(t)
		t.queue_free()
	furn_tables.clear()
	var hall_blocks: Array = BLOCKS.duplicate()
	var annex_blocks: Array = []
	for i in GameState.placed.size():
		var p: Dictionary = GameState.placed[i]
		var f: Dictionary = GameState.FURNITURE[p.id]
		var o := Vector2(p.x, p.y)
		var sp := Sprite2D.new()
		sp.texture = Sprites.tex(f.tex)
		sp.centered = false
		sp.set_meta("placed", i)
		if f.kind == "table":
			sp.position = o
			furn_layer.add_child(sp)  # 탁자는 앉은 손님보다 아래
			for sd in SET_SEATS:
				furn_tables.append(_add_table(sd, o))
		else:
			# 화분은 발 위치로 앞뒤가 정해져요(주인공이 뒤로 가면 가려져요)
			sp.offset = Vector2(0, -sp.texture.get_height())
			sp.position = o + Vector2(0, sp.texture.get_height())
			world.add_child(sp)
		furn_nodes.append(sp)
		var foot := Array(_foot(p.id, o))
		if in_annex(o + Vector2(10, 10)):
			annex_blocks.append(foot.map(func(q): return q - Vector2(ANNEX_X, 0)))
		else:
			hall_blocks.append(foot)
	walk = WalkMap.new(FLOOR, hall_blocks)
	annex_walk = WalkMap.new(ANNEX_FLOOR, annex_blocks, 12, ANNEX_SIZE)
	GameState.annex_tables = GameState.placed_count("table")
	GameState.decor = GameState.placed_count("decor")


## 이 자리에 놓을 수 있는지(바닥 위, 다른 가구·문·길목과 안 겹치게). skip은 지금 옮기는 가구 번호.
func can_place(id: String, o: Vector2, skip := -1) -> bool:
	var foot := _foot(id, o)
	var c := Vector2.ZERO
	for q in foot:
		c += q
	c /= foot.size()
	var annex := in_annex(c)
	var floor_poly := PackedVector2Array(ANNEX_FLOOR.map(func(q): return q + Vector2(ANNEX_X, 0))) if annex else PackedVector2Array(FLOOR)
	for q in foot:
		if not Geometry2D.is_point_in_polygon(q, floor_poly) or in_annex(q) != annex:
			return false
	if not annex:
		for b in BLOCKS:
			if not Geometry2D.intersect_polygons(foot, PackedVector2Array(b)).is_empty():
				return false
	for i in GameState.placed.size():
		if i == skip:
			continue
		var p: Dictionary = GameState.placed[i]
		if not Geometry2D.intersect_polygons(foot, _foot(p.id, Vector2(p.x, p.y))).is_empty():
			return false
	for spot in [DOOR, KITCHEN_SPOT, ANNEX_DOOR, CASE_SPOT, HALL_ENTRY, ANNEX_BACK + Vector2(ANNEX_X, 0),
			ANNEX_ENTRY + Vector2(ANNEX_X, 0), ANNEX_EXIT + Vector2(ANNEX_X, 0)]:
		if Geometry2D.is_point_in_polygon(spot, foot) or c.distance_to(spot) < 90:
			return false
	# 탁자는 손님에게 다가갈 자리가 바닥 위여야 해요
	if GameState.FURNITURE[id].kind == "table":
		for sd in SET_SEATS:
			var st: Vector2 = sd.stand + o
			if not Geometry2D.is_point_in_polygon(st, floor_poly):
				return false
	return true


## 가구에 손님이 앉아 있으면 옮길 수 없어요.
func furniture_busy(i: int) -> bool:
	var p: Dictionary = GameState.placed[i]
	if GameState.FURNITURE[p.id].kind != "table":
		return false
	var o := Vector2(p.x, p.y)
	for t in furn_tables:
		if t.position.distance_to(o + SET_SEATS[0].seat) < 1.0 or t.position.distance_to(o + SET_SEATS[1].seat) < 1.0:
			if t.state != "empty":
				return true
	return false


func furniture_at(p: Vector2) -> int:
	for i in range(GameState.placed.size() - 1, -1, -1):
		var q: Dictionary = GameState.placed[i]
		var tex := Sprites.tex(GameState.FURNITURE[q.id].tex)
		if Rect2(Vector2(q.x, q.y), tex.get_size()).has_point(p):
			return i
	return -1


func in_annex(p: Vector2) -> bool:
	return p.x >= ANNEX_X - 50


func _set_cam_room(annex: bool) -> void:
	cam.limit_left = int(ANNEX_X) if annex else 0
	cam.limit_right = int(ANNEX_X) + ANNEX_SIZE.x if annex else 1408
	cam.limit_top = 0
	cam.limit_bottom = ANNEX_SIZE.y if annex else 768
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
	out.append({"pos": KITCHEN_SPOT, "r": 50.0, "text": "주방으로", "do": func(): main.goto("kitchen", "hall"), "door": true})
	out.append({"pos": DOOR, "r": 50.0, "text": "밖으로", "do": func(): main.goto("village", "hall"), "door": true})
	out.append({"pos": ANNEX_DOOR, "r": 50.0, "text": "별관으로", "do": _to_annex, "door": true})
	out.append({"pos": ANNEX_BACK + Vector2(ANNEX_X, 0), "r": 50.0, "text": "홀로", "do": _to_hall, "door": true})
	out.append({"pos": ANNEX_EXIT + Vector2(ANNEX_X, 0), "r": 50.0, "text": "밖으로", "do": func(): main.goto("village", "hall"), "door": true})
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
	if edit_mode:
		_ghost_follow()
		main.hud.set_prompt("", Vector2.ZERO)
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
	if not active or main.hud.is_panel_open():
		return
	if UI.wheel_zoom(cam, event, ZOOM, ZOOM_MAX):
		get_viewport().set_input_as_handled()
		return
	if edit_mode:
		_edit_input(event)
		return
	if player.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_E or event.keycode == KEY_SPACE) and near:
			near.do.call()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		pending = null
		if MENU_BOARD.has_point(p):
			main.hud.open_menu_board()
			get_viewport().set_input_as_handled()
			return
		for a in _actions():
			if a.pos.distance_to(p) < 90 or _table_hit(a, p):
				pending = a
				walk_player(a.pos)
				return
		walk_player(p)


## --- 꾸미기 ---
func set_edit(on: bool) -> void:
	if not on:
		cancel_ghost()
	edit_mode = on
	player.walk_to(player.position)


func mouse_world() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()


## 가방의 가구 하나를 들어요(마우스를 따라와요).
func hold(id: String, from := -1) -> void:
	cancel_ghost()
	ghost_id = id
	ghost_from = from
	ghost = Sprite2D.new()
	ghost.texture = Sprites.tex(GameState.FURNITURE[id].tex)
	ghost.centered = false
	ghost.z_index = 50
	add_child(ghost)
	_ghost_follow()


func _ghost_origin() -> Vector2:
	var tex: Texture2D = ghost.texture
	return (mouse_world() - Vector2(tex.get_width() / 2.0, tex.get_height() * 0.75)).round()


func _ghost_follow() -> void:
	if ghost == null:
		return
	var o := _ghost_origin()
	ghost.position = o
	var ok := can_place(ghost_id, o, ghost_from)
	ghost.modulate = Color(0.75, 1.0, 0.75, 0.75) if ok else Color(1.0, 0.55, 0.55, 0.6)


func cancel_ghost() -> void:
	if ghost_from >= 0 and ghost_from < furn_nodes.size() and is_instance_valid(furn_nodes[ghost_from]):
		furn_nodes[ghost_from].modulate.a = 1.0
	if ghost:
		ghost.queue_free()
	ghost = null
	ghost_id = ""
	ghost_from = -1


func _edit_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and ghost:
		cancel_ghost()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_ghost()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			if ghost:
				place_ghost(_ghost_origin())
			else:
				pick_up(furniture_at(mouse_world()))


## 든 가구를 o(그림 왼쪽 위)에 놓아요.
func place_ghost(o: Vector2) -> bool:
	if ghost == null:
		return false
	if not can_place(ghost_id, o, ghost_from):
		Audio.sfx("fail")
		GameState.toast.emit("여기에는 놓을 수 없어요. 바닥 위, 다른 가구와 문에서 떨어진 곳에 놓아요.")
		return false
	if ghost_from >= 0:
		GameState.placed[ghost_from] = {"id": ghost_id, "x": o.x, "y": o.y}
	else:
		GameState.furn_inv[ghost_id] = int(GameState.furn_inv.get(ghost_id, 0)) - 1
		if GameState.furn_inv[ghost_id] <= 0:
			GameState.furn_inv.erase(ghost_id)
		GameState.placed.append({"id": ghost_id, "x": o.x, "y": o.y})
	cancel_ghost()
	rebuild_furniture()
	Audio.sfx("coin")
	GameState.changed.emit()
	GameState.save_game()
	main.hud.refresh_decor_bar()
	return true


## 놓은 가구를 다시 들어요(옮기거나, 가방에 넣기).
func pick_up(i: int) -> void:
	if i < 0:
		return
	if furniture_busy(i):
		Audio.sfx("fail")
		GameState.toast.emit("손님이 앉아 있어서 옮길 수 없어요.")
		return
	hold(GameState.placed[i].id, i)
	furn_nodes[i].modulate.a = 0.3


## 들고 있던 놓인 가구를 가방에 넣어요.
func store_held() -> void:
	if ghost == null:
		return
	if ghost_from >= 0:
		GameState.placed.remove_at(ghost_from)
	GameState.furn_inv[ghost_id] = int(GameState.furn_inv.get(ghost_id, 0)) + (1 if ghost_from >= 0 else 0)
	cancel_ghost()
	rebuild_furniture()
	GameState.changed.emit()
	GameState.save_game()
	main.hud.refresh_decor_bar()


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


## 주문 순서와 상관없이, 이 손님이 시킨 메뉴 중 진열대에 있는 걸 모두 내줘요.
func _serve(t) -> void:
	var gave := 0
	for id in t.wanted():
		if t.state == "waiting" and GameState.take_stock(id):
			_fly_item(id, player.position + Vector2(0, -90), t.position + t.food_at)
			t.serve(id)
			gave += 1
	if gave == 0:
		var names := ", ".join(t.wanted().map(func(i): return GameState.item_name(i)))
		GameState.toast.emit("%s이(가) 아직 없어요. 주방에서 만들어요." % names)
		_point_at(t)
		Audio.sfx("fail")


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
		- GameState.annex_tables * 2.0 - GameState.decor * 2.0 + (6.0 if GameState.rain else 0.0)
	spawn_left = maxf(10.0, base) + randf() * 6.0
	var free := tables.filter(func(t): return t.state == "empty" and t.foods.is_empty())
	if free.is_empty():
		return
	# 혼자 오기도 하고, 둘이 같이 오기도 하고, 가끔은 네 명이 우르르 와요(한 탁자에 둘씩)
	var roll := randf()
	var size := 1 if roll < 0.5 else (2 if roll < 0.88 else 4)
	var group: Array = _pick_seats(free, size)
	if group.is_empty():
		group = [free.pick_random()]
	if group.size() > 1:
		GameState.toast.emit("손님 %d명이 같이 왔어요!" % group.size())
	for i in group.size():
		_send_customer(group[i], i * 0.5, i == 0)


## 같은 탁자에 붙은 빈자리를 size개 골라요(둘씩 짝지어).
func _pick_seats(free: Array, size: int) -> Array:
	if size == 1:
		return [free.pick_random()]
	var pairs: Array = []
	for a in free:
		for b in free:
			# 두 자리의 음식 자리가 가까우면 같은 탁자예요
			if a.get_instance_id() < b.get_instance_id() and (a.position + a.food_at).distance_to(b.position + b.food_at) < 90.0:
				pairs.append([a, b])
	pairs.shuffle()
	var out: Array = []
	for p in pairs:
		if out.size() >= size:
			break
		if not out.has(p[0]) and not out.has(p[1]):
			out.append_array(p)
	return out if out.size() >= 2 else []


func _send_customer(t, delay: float, can_quest: bool) -> void:
	t.reserve()
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var kind: String = GameState.customer_kind()
	# 메뉴는 하나, 가끔 둘(음료 + 빵처럼)
	var menu: Array = GameState.menu_now()
	var order: Array = [menu.pick_random()]
	if randf() < 0.35 and menu.size() > 1:
		order.append(menu.pick_random())
	# 가끔 부탁 손님이 와요 (하루 한 번, 오전 10시 이후)
	var qid := ""
	var q := GameState.next_quest()
	if can_quest and not q.is_empty() and not GameState.quest_seen_today and GameState.active_quest == "" \
			and GameState.minutes > GameState.DAY_START + 60 and randf() < 0.5:
		GameState.quest_seen_today = true
		qid = q.id
		kind = q.kind
		order = [q.dish]
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
	return ANNEX_EXIT + Vector2(ANNEX_X, 0) if in_annex(t.position) else DOOR


func _new_customer(kind: String) -> Node2D:
	var a := Animal.new()
	a.setup(kind, ANIMAL_SCALE * (0.9 if kind == "chick" else 1.0) * Sprites.size_fix(kind))
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
		t.clear_plates()
		t.busy = false
		t.dirty = false
		t.dust.queue_redraw()
	update_cleanliness()
	spawn_left = 3.0


# 알바생이 쓰는 함수들
func find_serve_job():
	for t in GameState.orders:
		if not is_instance_valid(t) or t.busy:
			continue
		for id in t.wanted():
			if GameState.stock.get(id, 0) > 0:
				return t
	return null


func find_order_job():
	for t in tables:
		if t.state == "ordering" and not t.busy and t.quest_id == "":  # 부탁 손님은 주인공이 직접 들어요
			return t
	return null


## 손님이 떠나면 접시가 저절로 치워져서 알바생이 치울 일은 없어요.
func find_clean_job():
	return null
