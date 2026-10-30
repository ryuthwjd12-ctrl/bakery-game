extends Node2D
## 도토리 숲 마을. 카메라가 주인공을 따라가며 크게 보여 줘요.
## 동물 주민이 길을 오가고, 가게로 들어가는 손님도 보여요. 좌표는 마을 그림(1408x768) 기준이에요.

const Player := preload("res://scripts/player.gd")
const Animal := preload("res://scripts/animal.gd")

## 마을 그림을 MAP_SCALE배로 키워 깔아요. 좌표·걷기 지도는 원래 그림(1408x768) 기준 그대로 쓰고,
## 주인공·주민은 작게 그려서 건물이 상대적으로 크게 보이게 해요.
const MAP_SCALE := 2.0
const ZOOM := 1.67
const HERO_SCALE := 0.15
const ANIMAL_SCALE := 0.17
const AREA := [Vector2(0, 0), Vector2(1408, 0), Vector2(1408, 768), Vector2(0, 768)]
## 건물·나무·덤불·화단 자리. 지붕 위나 건물 뒤로는 못 가요. 좌표는 마을 그림(1408x768) 기준.
const BLOCKS := [
	# 재료 가게와 앞 바구니
	[Vector2(370, 105), Vector2(470, 30), Vector2(560, 0), Vector2(615, 90), Vector2(615, 175),
		Vector2(560, 215), Vector2(470, 225), Vector2(380, 185)],
	[Vector2(460, 200), Vector2(535, 205), Vector2(535, 262), Vector2(460, 262)],
	# 왼쪽 위 과일 가판대와 도토리 나무
	[Vector2(290, 255), Vector2(330, 220), Vector2(425, 230), Vector2(430, 290), Vector2(350, 335), Vector2(295, 300)],
	[Vector2(130, 180), Vector2(180, 70), Vector2(300, 60), Vector2(380, 130), Vector2(380, 240),
		Vector2(300, 340), Vector2(220, 340), Vector2(150, 280)],
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 120), Vector2(130, 200), Vector2(100, 250), Vector2(0, 260)],
	[Vector2(0, 255), Vector2(80, 265), Vector2(85, 340), Vector2(0, 345)],
	# 위쪽 나무들
	[Vector2(190, 0), Vector2(660, 0), Vector2(650, 70), Vector2(560, 60), Vector2(440, 40), Vector2(260, 55), Vector2(190, 50)],
	[Vector2(750, 0), Vector2(870, 0), Vector2(860, 80), Vector2(790, 80)],
	# 위쪽 화단과 간판
	[Vector2(765, 95), Vector2(800, 75), Vector2(850, 90), Vector2(855, 205), Vector2(810, 205), Vector2(765, 150)],
	# 그릇 가게
	[Vector2(845, 60), Vector2(940, 0), Vector2(1080, 0), Vector2(1080, 200), Vector2(1050, 225),
		Vector2(990, 250), Vector2(960, 245), Vector2(850, 190)],
	# 가구점과 앞 탁자, 간판
	[Vector2(1045, 160), Vector2(1100, 70), Vector2(1200, 75), Vector2(1285, 180), Vector2(1290, 260),
		Vector2(1345, 265), Vector2(1345, 345), Vector2(1100, 345), Vector2(1050, 300)],
	[Vector2(1000, 235), Vector2(1050, 235), Vector2(1050, 295), Vector2(1000, 295)],
	# 오른쪽 위 나무, 덤불
	[Vector2(1170, 0), Vector2(1408, 0), Vector2(1408, 240), Vector2(1300, 230), Vector2(1250, 100), Vector2(1170, 50)],
	[Vector2(1350, 265), Vector2(1408, 265), Vector2(1408, 345), Vector2(1350, 345)],
	# 빵집 (문 앞 계단만 비워 둬요)
	[Vector2(575, 330), Vector2(640, 240), Vector2(640, 185), Vector2(770, 175), Vector2(840, 250),
		Vector2(905, 300), Vector2(905, 345), Vector2(885, 425), Vector2(810, 470), Vector2(760, 490),
		Vector2(660, 490), Vector2(610, 460), Vector2(575, 420)],
	[Vector2(515, 350), Vector2(590, 330), Vector2(590, 440), Vector2(515, 440)],
	# 도구점과 그루터기
	[Vector2(135, 450), Vector2(270, 345), Vector2(340, 390), Vector2(360, 430), Vector2(410, 470),
		Vector2(430, 545), Vector2(330, 575), Vector2(290, 610), Vector2(220, 640), Vector2(180, 590), Vector2(140, 540)],
	[Vector2(122, 610), Vector2(162, 610), Vector2(162, 650), Vector2(122, 650)],
	# 왼쪽 나무
	[Vector2(0, 390), Vector2(100, 390), Vector2(170, 450), Vector2(170, 560), Vector2(110, 600),
		Vector2(110, 700), Vector2(40, 700), Vector2(0, 640)],
	# 옷 가게와 간판
	[Vector2(1060, 450), Vector2(1120, 355), Vector2(1200, 360), Vector2(1320, 465), Vector2(1320, 560),
		Vector2(1215, 625), Vector2(1130, 590), Vector2(1065, 550)],
	[Vector2(1020, 495), Vector2(1070, 495), Vector2(1070, 565), Vector2(1020, 565)],
	# 오른쪽 나무, 화분
	[Vector2(1290, 430), Vector2(1408, 400), Vector2(1408, 700), Vector2(1330, 700), Vector2(1290, 560)],
	[Vector2(1255, 600), Vector2(1320, 600), Vector2(1320, 680), Vector2(1255, 680)],
	# 아래 화단 두 개
	[Vector2(488, 615), Vector2(540, 570), Vector2(645, 590), Vector2(645, 655), Vector2(600, 690), Vector2(488, 630)],
	[Vector2(765, 640), Vector2(800, 580), Vector2(925, 590), Vector2(925, 630), Vector2(830, 690), Vector2(765, 665)],
	# 아래 산딸기 덤불
	[Vector2(300, 700), Vector2(360, 640), Vector2(500, 650), Vector2(600, 710), Vector2(600, 768), Vector2(295, 768)],
	[Vector2(800, 768), Vector2(830, 690), Vector2(930, 630), Vector2(1060, 640), Vector2(1115, 700), Vector2(1115, 768)],
]
const BAKERY_DOOR := Vector2(630, 488)
const BUSHES := {
	"bush_left": Vector2(92, 300),
	"bush_right": Vector2(1338, 305),
	"bush_bottom_left": Vector2(450, 628),
	"bush_bottom_right": Vector2(960, 618),
}
## 손님이 마을에 들어오는 길 끝(위, 왼쪽, 오른쪽, 아래)
const ENTRANCES := [Vector2(712, 8), Vector2(10, 375), Vector2(1398, 362), Vector2(715, 760)]
## 도토리 마을은 다람쥐 마을이에요. 털색을 조금씩 달리해요.
const RESIDENTS := [Color(1, 1, 1), Color(1.08, 0.98, 0.9), Color(0.92, 0.9, 0.95), Color(1.05, 1.02, 1), Color(0.97, 0.93, 0.86)]
const GREETINGS := ["안녕! 오늘도 빵 냄새가 좋다.", "도토리가 잔뜩 열렸어.", "산딸기는 아래쪽 덤불에 많아!",
	"이따가 가게에 들를게.", "날씨가 참 포근하네.", "새 메뉴는 언제 나와?"]

var main: Node
var from := ""  # 어디서 왔는지(숲에서 오면 그 가장자리에 서요)
var world := Node2D.new()
var player
var cam := Camera2D.new()
var near = null
var residents: Array = []
var puppy: AnimatedSprite2D
var door_armed := false
var walk := WalkMap.new(AREA, BLOCKS, 8)
var map := Node2D.new()  # 그림과 사람들을 함께 키우는 판
var overlays := {}  # 딴 덤불 덮개
var ground := {}  # 땅에 떨어진 재료
## 땅에 떨어진 재료: 도토리 나무 밑, 그루터기 옆, 화단 옆
const GROUND := [["acorn1", "acorn", Vector2(205, 345)], ["acorn2", "acorn", Vector2(262, 352)],
	["acorn3", "acorn", Vector2(95, 268)], ["walnut1", "walnut", Vector2(172, 655)],
	["acorn4", "acorn", Vector2(1290, 380)], ["walnut2", "walnut", Vector2(985, 560)]]


func _ready() -> void:
	map.scale = Vector2(MAP_SCALE, MAP_SCALE)
	add_child(map)
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex("backgrounds/acorn_village")
	bg.centered = false
	map.add_child(bg)
	var over_layer := Node2D.new()
	map.add_child(over_layer)
	overlays = Gather.add_overlays(over_layer, "backgrounds/acorn_village", "")
	world.y_sort_enabled = true
	map.add_child(world)
	ground = Gather.add_ground_items(world, GROUND, "v_", 0.11)

	player = Player.new()
	player.setup(GameState.hero, HERO_SCALE)
	player.speed = 70.0
	player.can_walk = can_walk
	player.position = BAKERY_DOOR + Vector2(0, 36)
	var edge := {"forest_north": Vector2(712, 30), "forest_east": Vector2(1370, 362),
		"forest_south": Vector2(715, 735), "forest_west": Vector2(34, 375)}
	if edge.has(from):
		player.position = edge[from]
		door_armed = true
	world.add_child(player)

	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(1408 * MAP_SCALE)
	cam.limit_bottom = int(768 * MAP_SCALE)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	cam.position = map.transform * player.position
	cam.make_current()
	cam.reset_smoothing.call_deferred()

	if not GameState.has_waiter:
		puppy = AnimatedSprite2D.new()
		puppy.sprite_frames = Sprites.frames_for("puppy", ["front", "back", "right", "tray", "sweep"])
		puppy.animation = "front"
		puppy.offset = Vector2(0, -61)
		puppy.scale = Vector2(0.14, 0.14)
		var holder := Node2D.new()
		holder.position = Vector2(770, 520)
		holder.add_child(puppy)
		world.add_child(holder)

	for tint in RESIDENTS:
		_spawn_resident("squirrel", tint)
	GameState.customer_spawned.connect(_on_customer)
	GameState.customer_left.connect(_on_customer_left)
	Audio.play_bgm("bgm_village")


func _spawn_resident(kind: String, tint := Color.WHITE) -> void:
	var a := Animal.new()
	a.setup(kind, ANIMAL_SCALE * (1.1 if kind == "chick" else 1.0))
	a.modulate = tint
	a.speed = 28.0
	a.position = walk.random_point()
	world.add_child(a)
	residents.append(a)
	_wander(a)


## 주민은 마을 아무 곳이나 골라 길을 찾아 걸어가고, 잠깐 쉬었다가 또 걸어요.
func _wander(a) -> void:
	while is_instance_valid(a) and a.is_inside_tree():
		var to := walk.random_point()
		if to.distance_to(a.position) > 420:
			continue
		await a.walk_path(walk.find_path(a.position, to))
		if not is_instance_valid(a):
			return
		a.idle()
		await get_tree().create_timer(randf_range(1.0, 4.0)).timeout


## 가게로 가는 손님이 마을 입구에서 빵집 문까지 걸어와요.
func _on_customer(kind: String) -> void:
	var a := Animal.new()
	a.setup(kind, ANIMAL_SCALE * (1.1 if kind == "chick" else 1.0))
	a.speed = 34.0
	var start: Vector2 = ENTRANCES.pick_random()
	a.position = start
	world.add_child(a)
	await a.walk_path(walk.find_path(start, BAKERY_DOOR))
	if is_instance_valid(a):
		var tw := a.create_tween()
		tw.tween_property(a, "modulate:a", 0.0, 0.3)
		tw.tween_callback(a.queue_free)


## 가게에서 나온 손님이 마을 밖으로 걸어가요.
func _on_customer_left(kind: String) -> void:
	var a := Animal.new()
	a.setup(kind, ANIMAL_SCALE * (1.1 if kind == "chick" else 1.0))
	a.speed = 34.0
	a.position = BAKERY_DOOR
	world.add_child(a)
	var to: Vector2 = ENTRANCES.pick_random()
	await a.walk_path(walk.find_path(BAKERY_DOOR, to))
	if is_instance_valid(a):
		var tw := a.create_tween()
		tw.tween_property(a, "modulate:a", 0.0, 0.3)
		tw.tween_callback(a.queue_free)


func can_walk(p: Vector2) -> bool:
	return walk.can_walk(p)


func _actions() -> Array:
	var out: Array = [
		{"pos": Vector2(560, 240), "r": 40.0, "text": "재료 가게", "do": func(): main.hud.open_trade("도토리 재료 가게", ["flour", "sugar", "butter", "egg", "milk", "chocolate", "cream", "walnut", "acorn", "honey_jar", "matcha", "apple"])},
		{"pos": Vector2(930, 262), "r": 36.0, "text": "그릇 가게", "do": _dish_shop},
		{"pos": Vector2(1065, 335), "r": 36.0, "text": "가구점", "do": _furniture_shop},
		{"pos": Vector2(310, 615), "r": 36.0, "text": "무기 상점", "do": func(): main.hud.open_weapon_shop()},
		{"pos": Vector2(1110, 610), "r": 36.0, "text": "인테리어점", "do": _interior_shop},
	]
	for id in BUSHES:
		if not GameState.picked_today.has(id):
			out.append({"pos": BUSHES[id], "r": 40.0, "text": "산딸기 따기", "do": _pick.bind(id)})
	for gid in ground:
		if is_instance_valid(ground[gid]):
			out.append({"pos": ground[gid].position, "r": 18.0, "text": "줍기", "do": _pick_ground.bind(gid)})
	if puppy:
		out.append({"pos": Vector2(770, 540), "r": 30.0, "text": "강아지와 이야기", "do": _talk_puppy})
	for a in residents:
		out.append({"pos": a.position, "r": 24.0, "text": "인사하기", "do": _greet.bind(a)})
	return out


func _process(_delta: float) -> void:
	cam.position = map.transform * player.position
	# 마을 가장자리로 나가면 숲길이에요
	var pp: Vector2 = player.position
	var side := ""
	if pp.y < 14:
		side = "north"
	elif pp.x > 1394:
		side = "east"
	elif pp.y > 754:
		side = "south"
	elif pp.x < 14:
		side = "west"
	if side != "":
		set_process(false)
		main.goto_field(Areas.VILLAGE_EXITS[side], "village")
		return
	var dd: float = player.position.distance_to(BAKERY_DOOR)
	if dd > 26:
		door_armed = true
	if door_armed and dd < 16:
		Audio.sfx("door")
		main.goto("hall", "village")
		return
	near = null
	var best := 1e9
	for a in _actions():
		var d: float = player.position.distance_to(a.pos)
		if d < a.r and d < best:
			near = a
			best = d
	player.active = not main.hud.is_panel_open()
	if near and player.active:
		main.hud.set_prompt("E  " + near.text, _to_screen(player.position) + Vector2(0, 14))
	else:
		main.hud.set_prompt("", Vector2.ZERO)


func _to_screen(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * (map.transform * p)


func _to_map(screen: Vector2) -> Vector2:
	return map.transform.affine_inverse() * (get_viewport().get_canvas_transform().affine_inverse() * screen)


func _unhandled_input(event: InputEvent) -> void:
	if main.hud.is_panel_open():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_E or event.keycode == KEY_SPACE) and near:
			near.do.call()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var to: Vector2 = _to_map(event.position)
		# 빵집을 누르면 문으로 걸어가요
		if Geometry2D.is_point_in_polygon(to, PackedVector2Array(BLOCKS[14])):
			to = BAKERY_DOOR
		player.walk_path(walk.find_path(player.position, to))


func _furniture_shop() -> void:
	var hall = main.hall
	var set_price := 300 + GameState.annex_tables * 100
	var entries := [
		{"icon": Sprites.tex("furniture/table_set"), "name": "둥근 탁자 세트", "price": set_price,
			"note": "가게 별관에 놓여요. 손님 두 명이 더 앉을 수 있어요. (%d/%d)" % [GameState.annex_tables, GameState.ANNEX_MAX],
			"block": func(): return "자리가 꽉 찼어요" if GameState.annex_tables >= GameState.ANNEX_MAX else "",
			"buy": func():
				GameState.annex_tables += 1
				hall.add_annex_set()
				GameState.toast.emit("별관에 탁자를 놓았어요! 가게 안쪽 오른쪽 문으로 가 봐요.")},
	]
	if GameState.annex_tables > 0:
		var back := (300 + (GameState.annex_tables - 1) * 100)
		entries.append({"icon": Sprites.tex("furniture/table_set"), "name": "탁자 세트 되팔기", "price": 0,
			"note": "별관의 마지막 탁자를 %d골드에 팔아요. (산 값의 30%%)" % main.hud.sell_price(back),
			"block": func(): return "",
			"buy": func():
				if hall.remove_annex_set():
					GameState.earn(main.hud.sell_price(back))
					GameState.toast.emit("탁자 세트를 팔았어요.")
				else:
					GameState.toast.emit("손님이 앉아 있거나 지저분한 탁자는 팔 수 없어요.")})
	main.hud.open_store("다람쥐 가구점", "산 가구는 가게 별관에 바로 놓여요. 되팔면 산 값의 30%를 받아요.", entries)


## 인테리어점: 화분처럼 가게를 꾸미는 물건(벽지·바닥은 새 그림이 오면 더해요).
func _interior_shop() -> void:
	var hall = main.hall
	var entries := [
		{"icon": Sprites.tex("furniture/plant_big"), "name": "큰 화분", "price": 150,
			"note": "가게가 예뻐져서 손님이 더 자주 오고 팁이 늘어요.",
			"block": func(): return "이미 놓았어요" if GameState.decor >= 1 else "",
			"buy": func():
				GameState.decor = 1
				hall.add_decor()},
		{"icon": Sprites.tex("furniture/plant_small"), "name": "작은 화분", "price": 100,
			"note": "큰 화분을 놓은 다음에 놓을 수 있어요. 효과는 같아요.",
			"block": func(): return "이미 놓았어요" if GameState.decor >= 2 else ("큰 화분 먼저" if GameState.decor < 1 else ""),
			"buy": func():
				GameState.decor = 2
				hall.add_decor()},
	]
	main.hud.open_store("다람쥐 인테리어점", "가게가 예뻐지면 손님이 더 자주 오고 팁이 늘어요.", entries)


## 그릇 가게: 예쁜 그릇 세트를 사면 음식이 더 맛있어 보여서 팁이 늘어요.
const DISH_SETS := [["꽃무늬 접시 세트", 180, "items/heart_cookie"], ["도토리 찻잔 세트", 320, "items/acorn_cookie"],
	["금테 디저트 접시", 520, "items/macaron"]]


func _dish_shop() -> void:
	var entries := []
	for i in DISH_SETS.size():
		var d: Array = DISH_SETS[i]
		entries.append({"icon": Sprites.tex(d[2]), "name": d[0], "price": d[1],
			"note": "손님 팁이 3골드씩 늘어요. (%d/%d)" % [GameState.dishes, DISH_SETS.size()],
			"block": func(): return "이미 샀어요" if GameState.dishes > i else ("앞의 그릇 먼저" if GameState.dishes < i else ""),
			"buy": func():
				GameState.dishes = i + 1
				GameState.toast.emit("%s를 들였어요! 손님 팁이 늘어요." % d[0])})
	main.hud.open_store("다람쥐 그릇 가게", "예쁜 그릇에 담으면 음식이 더 맛있어 보여요.", entries)


func _soon() -> void:
	GameState.toast.emit("아직 문을 열지 않았어요. 곧 열 거예요!")


func _pick(id: String) -> void:
	if GameState.picked_today.has(id):
		GameState.toast.emit("다 땄어요. 내일 다시 열려요.")
		return
	var n := randi_range(2, 3)
	GameState.picked_today.append(id)
	GameState.add_item("raspberry", n)
	player.work(0.5)
	Gather.pick_fx(world, overlays.get(id), "raspberry", n, player, 0.12)
	GameState.toast.emit("산딸기 %d개를 땄어요! 냉동고에 넣어 둘게요." % n)


func _pick_ground(gid: String) -> void:
	var s: Sprite2D = ground[gid]
	ground.erase(gid)
	GameState.picked_today.append("v_" + gid)
	var item: String = s.get_meta("item")
	GameState.add_item(item, 1)
	Gather.pick_ground(s, player)
	GameState.toast.emit("%s 1개를 주웠어요." % GameState.item_name(item))


func _say_over(node: Node2D, text: String, height := 70.0) -> void:
	var l := UI.label(text, 18)
	l.add_theme_stylebox_override("normal", UI.box(Color.WHITE, UI.OUTLINE, 10, 2))
	l.z_index = 90
	l.scale = Vector2.ONE / (MAP_SCALE * ZOOM) * 1.2  # 지도를 키운 만큼 줄여서 글자 크기를 맞춰요
	node.add_child(l)
	l.reset_size()
	l.position = Vector2(-l.size.x * l.scale.x / 2, -height - l.size.y * l.scale.y)
	var tw := l.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func _greet(a) -> void:
	_say_over(a, GREETINGS.pick_random(), 26.0)
	Audio.sfx("order")


func _talk_puppy() -> void:
	if GameState.level() < 2:
		_say_over(puppy.get_parent(), "가게가 조금 더 유명해지면(레벨 2) 같이 일하고 싶어요!", 24.0)
		return
	main.hud.confirm("알바생 강아지를 고용할까요?\n주문 받기, 음식 내주기, 청소를 도와줘요. (%d골드)" % GameState.WAITER_COST, func():
		if GameState.gold < GameState.WAITER_COST:
			GameState.toast.emit("골드가 모자라요.")
			return
		GameState.gold -= GameState.WAITER_COST
		GameState.has_waiter = true
		GameState.changed.emit()
		main.hall.hire_waiter()
		puppy.get_parent().queue_free()
		puppy = null
		Audio.sfx("sparkle")
		GameState.toast.emit("알바생 강아지가 가게에서 기다리고 있어요!"))
