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
	# 도토리 나무와 도토리 집(왼쪽 위)
	[Vector2(0, 0), Vector2(210, 0), Vector2(210, 185), Vector2(153, 212), Vector2(31, 215), Vector2(0, 200)],
	# 도토리 지붕 집
	[Vector2(225, 20), Vector2(348, 20), Vector2(348, 128), Vector2(227, 135)],
	# 벤치
	[Vector2(343, 85), Vector2(404, 80), Vector2(404, 132), Vector2(343, 134)],
	# 벤치
	[Vector2(97, 188), Vector2(162, 188), Vector2(162, 238), Vector2(97, 238)],
	# 연못 왼쪽
	[Vector2(118, 262), Vector2(164, 232), Vector2(230, 232), Vector2(261, 262), Vector2(297, 272), Vector2(292, 318), Vector2(174, 326), Vector2(118, 300)],
	# 연못 오른쪽
	[Vector2(268, 178), Vector2(327, 160), Vector2(404, 170), Vector2(414, 205), Vector2(373, 228), Vector2(353, 212), Vector2(307, 206), Vector2(268, 212)],
	# 산딸기 덤불(왼쪽)
	[Vector2(8, 240), Vector2(97, 235), Vector2(104, 320), Vector2(61, 335), Vector2(10, 322)],
	# 재료 가게 노점
	[Vector2(428, 110), Vector2(481, 48), Vector2(614, 48), Vector2(657, 150), Vector2(655, 238), Vector2(542, 250), Vector2(493, 272), Vector2(425, 242)],
	# 빵집
	[Vector2(573, 330), Vector2(706, 210), Vector2(845, 330), Vector2(841, 440), Vector2(573, 440)],
	# 인테리어점
	[Vector2(790, 150), Vector2(860, 60), Vector2(952, 0), Vector2(1023, 0), Vector2(1087, 110), Vector2(1087, 195), Vector2(1023, 228), Vector2(926, 212), Vector2(800, 228), Vector2(774, 198)],
	# 인테리어점 앞 화분
	[Vector2(916, 205), Vector2(1023, 200), Vector2(1028, 255), Vector2(921, 262)],
	# 화단(위)
	[Vector2(783, 50), Vector2(880, 40), Vector2(885, 90), Vector2(788, 96)],
	# 가구점
	[Vector2(1110, 180), Vector2(1207, 70), Vector2(1291, 90), Vector2(1363, 182), Vector2(1353, 300), Vector2(1269, 322), Vector2(1207, 300), Vector2(1115, 300)],
	# 가구점 장작
	[Vector2(1259, 282), Vector2(1330, 250), Vector2(1390, 300), Vector2(1373, 352), Vector2(1300, 352)],
	# 가구점 앞 탁자
	[Vector2(1039, 275), Vector2(1167, 265), Vector2(1169, 356), Vector2(1044, 358)],
	# 무기점
	[Vector2(1117, 470), Vector2(1228, 378), Vector2(1322, 400), Vector2(1353, 480), Vector2(1343, 620), Vector2(1228, 640), Vector2(1128, 580)],
	# 무기점 모루·통
	[Vector2(1059, 518), Vector2(1117, 518), Vector2(1117, 575), Vector2(1059, 575)],
	# 무기점 통
	[Vector2(1264, 575), Vector2(1322, 575), Vector2(1322, 668), Vector2(1264, 668)],
	# 무기점 모루
	[Vector2(1177, 612), Vector2(1233, 612), Vector2(1233, 665), Vector2(1177, 665)],
	# 화단(라벤더)
	[Vector2(931, 455), Vector2(1023, 405), Vector2(1060, 425), Vector2(1054, 452), Vector2(967, 490), Vector2(931, 476)],
	# 분수
	[Vector2(854, 600), Vector2(892, 555), Vector2(936, 600), Vector2(923, 652), Vector2(865, 652)],
	# 분수 벤치들
	[Vector2(819, 562), Vector2(882, 562), Vector2(882, 615), Vector2(819, 615)],
	# 분수 벤치들
	[Vector2(921, 550), Vector2(987, 550), Vector2(987, 615), Vector2(921, 615)],
	# 분수 벤치들
	[Vector2(825, 645), Vector2(886, 645), Vector2(886, 692), Vector2(825, 692)],
	# 분수 벤치들
	[Vector2(921, 640), Vector2(982, 640), Vector2(982, 692), Vector2(921, 692)],
	# 분수 옆 화단
	[Vector2(773, 540), Vector2(875, 510), Vector2(886, 545), Vector2(798, 585), Vector2(773, 575)],
	# 그릇 가게
	[Vector2(399, 535), Vector2(481, 458), Vector2(561, 522), Vector2(573, 592), Vector2(532, 652), Vector2(471, 656), Vector2(405, 620)],
	# 그릇 가게 진열대
	[Vector2(558, 555), Vector2(641, 550), Vector2(641, 652), Vector2(569, 652)],
	# 그릇 가게 화단
	[Vector2(353, 615), Vector2(420, 600), Vector2(467, 640), Vector2(466, 690), Vector2(358, 660)],
	# 나무 집들(왼쪽 아래)
	[Vector2(0, 410), Vector2(113, 412), Vector2(174, 440), Vector2(194, 400), Vector2(289, 402), Vector2(305, 550), Vector2(268, 580), Vector2(184, 582), Vector2(180, 700), Vector2(113, 708), Vector2(31, 702), Vector2(0, 690)],
	# 화단(왼쪽 아래)
	[Vector2(292, 445), Vector2(353, 415), Vector2(404, 445), Vector2(399, 478), Vector2(338, 492), Vector2(292, 470)],
	# 그루터기
	[Vector2(287, 488), Vector2(333, 488), Vector2(333, 530), Vector2(287, 530)],
	# 작은 벤치
	[Vector2(205, 602), Vector2(258, 602), Vector2(258, 650), Vector2(205, 650)],
]
const BAKERY_DOOR := Vector2(706, 452)
const BAKERY_BLOCK := 8  # BLOCKS에서 빵집 번호
const BUSHES := {
	"bush_left": Vector2(61, 342),
	"bed_west": Vector2(348, 502),
	"bed_plaza": Vector2(808, 503),
}
## 손님이 마을에 들어오는 길 끝(위, 왼쪽, 오른쪽, 아래)
const ENTRANCES := [Vector2(707, 8), Vector2(10, 382), Vector2(1398, 378), Vector2(642, 760)]
## 도토리 마을은 다람쥐 마을이에요. 목도리·꽃핀·안경·모자·나비넥타이·바구니 다람쥐 6마리.
const RESIDENTS := ["sq1", "sq2", "sq3", "sq4", "sq5", "sq6"]
const GREETINGS := ["안녕! 오늘도 빵 냄새가 좋다.", "도토리가 잔뜩 열렸어.", "산딸기는 연못 옆 덤불에 많아!",
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
const GROUND := [["acorn1", "acorn", Vector2(174, 245)], ["acorn2", "acorn", Vector2(123, 352)],
	["acorn3", "acorn", Vector2(246, 600)], ["walnut1", "walnut", Vector2(430, 330)],
	["acorn4", "acorn", Vector2(1003, 520)], ["walnut2", "walnut", Vector2(1381, 412)]]
## 가게: 문 앞(서는 곳)과 BLOCKS 번호(건물을 누르면 문으로 걸어가요)
const SHOP_DOORS := {
	"ingredient": [Vector2(561, 290), 7], "interior": [Vector2(892, 238), 9],
	"furniture": [Vector2(1213, 332), 12], "dish": [Vector2(524, 668), 26], "weapon": [Vector2(1154, 614), 15],
}


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
	var edge := {"forest_north": Vector2(707, 30), "forest_east": Vector2(1370, 378),
		"forest_south": Vector2(642, 735), "forest_west": Vector2(34, 382)}
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
		var ph := float(Sprites.frame_height("puppy_front"))
		puppy.offset = Vector2(0, -ph / 2.0)
		puppy.scale = Vector2.ONE * 0.14 * 122.0 / ph
		var holder := Node2D.new()
		holder.position = Vector2(778, 470)
		holder.add_child(puppy)
		world.add_child(holder)

	for k in RESIDENTS:
		_spawn_resident(k)
	GameState.customer_spawned.connect(_on_customer)
	GameState.customer_left.connect(_on_customer_left)
	Audio.play_bgm("bgm_village")
	add_child(Weather.new())  # 시간 따라 하늘빛, 비 오는 날엔 비


func _spawn_resident(kind: String) -> void:
	var a := Animal.new()
	# 주민 그림은 손님 그림보다 크게 그려져 있어서 키를 맞춰요
	a.setup(kind, ANIMAL_SCALE * 121.0 / Sprites.frame_height(kind + "_front"))
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
	a.setup(kind, ANIMAL_SCALE * (1.1 if kind == "chick" else 1.0) * Sprites.size_fix(kind))
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
	a.setup(kind, ANIMAL_SCALE * (1.1 if kind == "chick" else 1.0) * Sprites.size_fix(kind))
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
		{"pos": SHOP_DOORS.ingredient[0], "r": 40.0, "text": "재료 가게", "do": _shop.bind("ingredient")},
		{"pos": SHOP_DOORS.interior[0], "r": 36.0, "text": "인테리어점", "do": _shop.bind("interior")},
		{"pos": SHOP_DOORS.furniture[0], "r": 36.0, "text": "가구점", "do": _shop.bind("furniture")},
		{"pos": SHOP_DOORS.dish[0], "r": 36.0, "text": "그릇 가게", "do": _shop.bind("dish")},
		{"pos": SHOP_DOORS.weapon[0], "r": 36.0, "text": "무기점", "do": _shop.bind("weapon")},
	]
	for id in BUSHES:
		if not GameState.picked_today.has(id):
			out.append({"pos": BUSHES[id], "r": 40.0, "text": "산딸기 따기", "do": _pick.bind(id)})
	for gid in ground:
		if is_instance_valid(ground[gid]):
			out.append({"pos": ground[gid].position, "r": 18.0, "text": "줍기", "do": _pick_ground.bind(gid)})
	if puppy:
		out.append({"pos": Vector2(778, 488), "r": 30.0, "text": "강아지와 이야기", "do": _talk_puppy})
	for a in residents:
		out.append({"pos": a.position, "r": 24.0, "text": GameState.friend_action(a.kind), "do": _greet.bind(a)})
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
		if Geometry2D.is_point_in_polygon(to, PackedVector2Array(BLOCKS[BAKERY_BLOCK])):
			to = BAKERY_DOOR
		for id in SHOP_DOORS:
			if Geometry2D.is_point_in_polygon(to, PackedVector2Array(BLOCKS[SHOP_DOORS[id][1]])):
				to = SHOP_DOORS[id][0]
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
		{"icon": Sprites.tex("items/deco_plant_big"), "name": "큰 화분", "price": 150,
			"note": "가게가 예뻐져서 손님이 더 자주 오고 팁이 늘어요.",
			"block": func(): return "이미 놓았어요" if GameState.decor >= 1 else "",
			"buy": func():
				GameState.decor = 1
				hall.add_decor()},
		{"icon": Sprites.tex("items/deco_plant"), "name": "작은 화분", "price": 100,
			"note": "큰 화분을 놓은 다음에 놓을 수 있어요. 효과는 같아요.",
			"block": func(): return "이미 놓았어요" if GameState.decor >= 2 else ("큰 화분 먼저" if GameState.decor < 1 else ""),
			"buy": func():
				GameState.decor = 2
				hall.add_decor()},
	]
	main.hud.open_store("다람쥐 인테리어점", "가게가 예뻐지면 손님이 더 자주 오고 팁이 늘어요.", entries)


## 그릇 가게: 예쁜 그릇 세트를 사면 음식이 더 맛있어 보여서 팁이 늘어요.
const DISH_SETS := [["꽃무늬 접시 세트", 180, "items/dish_flower"], ["도토리 찻잔 세트", 320, "items/dish_acorn"],
	["금테 디저트 접시", 520, "items/dish_gold"]]


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


## 가게에 들어가요: 가게 안 그림과 주인 다람쥐가 보여요.
func _shop(id: String) -> void:
	main.hud.shop_ctx = id
	match id:
		"ingredient":
			main.hud.open_trade("다람쥐 재료 가게", ["flour", "sugar", "butter", "egg", "milk", "chocolate", "cream",
				"walnut", "acorn", "honey_jar", "matcha", "apple"])
		"interior":
			_interior_shop()
		"furniture":
			_furniture_shop()
		"dish":
			_dish_shop()
		"weapon":
			main.hud.open_weapon_shop()


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


## 인사(하루 한 번 친밀도 +1) → 선물(진열대 음식 하나, +3) → 그 뒤엔 이야기만. 말풍선에 하트가 보여요.
func _greet(a) -> void:
	var k: String = a.kind
	var line: String = GREETINGS.pick_random()
	if not GameState.talked_today.has(k):
		GameState.talk(k)
	elif not GameState.gifted_today.has(k):
		var food := GameState.gift(k)
		if food != "":
			line = "와, %s! 정말 고마워!" % GameState.item_name(food)
			Audio.sfx("sparkle")
	_say_over(a, line + "\n" + GameState.heart_text(k), 26.0)
	Audio.sfx("order")
	UI.pop(a.sprite, 0.15)


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
