extends Node2D
## 도토리 숲 마을. 카메라가 주인공을 따라가며 크게 보여 줘요.
## 동물 주민이 길을 오가고, 가게로 들어가는 손님도 보여요. 좌표는 마을 그림(1408x768) 기준이에요.

const Player := preload("res://scripts/player.gd")
const Animal := preload("res://scripts/animal.gd")

const ZOOM := 1.7
## 건물이 있는 곳은 못 걸어요.
const BLOCKED := [
	Rect2(380, 40, 220, 160), Rect2(850, 20, 225, 205), Rect2(1060, 110, 225, 185),
	Rect2(590, 200, 245, 255), Rect2(140, 360, 215, 215), Rect2(1065, 380, 255, 225),
	Rect2(495, 585, 120, 80), Rect2(770, 585, 155, 80),
]
const BAKERY_DOOR := Vector2(652, 468)
const BUSHES := {
	"bush_left": Vector2(40, 300),
	"bush_right": Vector2(1375, 305),
	"bush_bottom_left": Vector2(445, 700),
	"bush_bottom_right": Vector2(955, 700),
}
## 주민이 걷는 길(점과 이어진 점)
const NODES := {
	"n": Vector2(705, 40), "a": Vector2(715, 180), "b": Vector2(470, 330), "c": Vector2(540, 520),
	"d": Vector2(700, 560), "e": Vector2(905, 480), "f": Vector2(880, 290),
	"w2": Vector2(260, 345), "w": Vector2(40, 380), "e2": Vector2(1060, 335), "e1": Vector2(1370, 360),
	"s": Vector2(690, 745), "sw1": Vector2(420, 590), "sw": Vector2(220, 720),
	"se1": Vector2(985, 600), "se": Vector2(1250, 740),
}
const EDGES := [["n", "a"], ["a", "b"], ["a", "f"], ["b", "c"], ["c", "d"], ["d", "e"], ["e", "f"],
	["b", "w2"], ["w2", "w"], ["f", "e2"], ["e2", "e1"], ["d", "s"], ["c", "sw1"], ["sw1", "sw"],
	["e", "se1"], ["se1", "se"]]
const OUTER := ["n", "w", "e1", "s", "sw", "se"]
const RESIDENTS := ["cat", "deer", "bear", "squirrel", "chick"]
const GREETINGS := ["안녕! 오늘도 빵 냄새가 좋다.", "도토리가 잔뜩 열렸어.", "산딸기는 아래쪽 덤불에 많아!",
	"이따가 가게에 들를게.", "날씨가 참 포근하네.", "새 메뉴는 언제 나와?"]

var main: Node
var world := Node2D.new()
var player
var cam := Camera2D.new()
var near = null
var residents: Array = []
var puppy: AnimatedSprite2D
var door_armed := false


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex("backgrounds/acorn_village")
	bg.centered = false
	add_child(bg)
	world.y_sort_enabled = true
	add_child(world)

	player = Player.new()
	player.setup(GameState.hero, 0.36)
	player.can_walk = can_walk
	player.position = BAKERY_DOOR + Vector2(0, 50)
	world.add_child(player)

	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1408
	cam.limit_bottom = 768
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	cam.make_current()

	if not GameState.has_waiter:
		puppy = AnimatedSprite2D.new()
		puppy.sprite_frames = Sprites.frames_for("puppy", ["front", "back", "right", "tray", "sweep"])
		puppy.animation = "front"
		puppy.offset = Vector2(0, -61)
		puppy.scale = Vector2(0.42, 0.42)
		var holder := Node2D.new()
		holder.position = Vector2(770, 520)
		holder.add_child(puppy)
		world.add_child(holder)

	for k in RESIDENTS:
		_spawn_resident(k)
	GameState.customer_spawned.connect(_on_customer)
	Audio.play_bgm("bgm_village")


func _spawn_resident(kind: String) -> void:
	var a := Animal.new()
	a.setup(kind, 0.42 if kind != "chick" else 0.45)
	var keys := NODES.keys()
	var start: String = keys.pick_random()
	a.position = NODES[start]
	a.set_meta("node", start)
	world.add_child(a)
	residents.append(a)
	_wander(a)


func _neighbors(n: String) -> Array:
	var out: Array = []
	for e in EDGES:
		if e[0] == n:
			out.append(e[1])
		elif e[1] == n:
			out.append(e[0])
	return out


func _wander(a) -> void:
	while is_instance_valid(a) and a.is_inside_tree():
		var nxt: String = _neighbors(a.get_meta("node")).pick_random()
		await a.walk_to(NODES[nxt] + Vector2(randf_range(-15, 15), randf_range(-8, 8)))
		if not is_instance_valid(a):
			return
		a.set_meta("node", nxt)
		if randf() < 0.3:
			await get_tree().create_timer(randf_range(1.0, 3.0)).timeout


## 가게로 가는 손님이 길을 따라 걸어와요.
func _on_customer(kind: String) -> void:
	var a := Animal.new()
	a.setup(kind, 0.42 if kind != "chick" else 0.45)
	var start: String = OUTER.pick_random()
	a.position = NODES[start]
	world.add_child(a)
	var path := _route(start, "d")
	path.append(BAKERY_DOOR + Vector2(0, 20))
	await a.walk_path(path)
	if is_instance_valid(a):
		var tw := a.create_tween()
		tw.tween_property(a, "modulate:a", 0.0, 0.3)
		tw.tween_callback(a.queue_free)


func _route(from: String, to: String) -> Array:
	# 너비 우선으로 가장 짧은 길
	var prev := {from: ""}
	var q := [from]
	while not q.is_empty():
		var n: String = q.pop_front()
		if n == to:
			break
		for m in _neighbors(n):
			if not prev.has(m):
				prev[m] = n
				q.append(m)
	var out: Array = []
	var cur := to
	while cur != "" and prev.has(cur):
		out.push_front(NODES[cur])
		cur = prev[cur]
	return out


func can_walk(p: Vector2) -> bool:
	if p.x < 12 or p.x > 1396 or p.y < 30 or p.y > 760:
		return false
	for r in BLOCKED:
		if r.has_point(p):
			return false
	return true


func _actions() -> Array:
	var out: Array = [
		{"pos": Vector2(525, 215), "r": 55.0, "text": "재료 가게", "do": func(): main.hud.open_shop()},
		{"pos": Vector2(960, 235), "r": 55.0, "text": "그릇 가게", "do": _soon},
		{"pos": Vector2(1100, 305), "r": 50.0, "text": "가구점", "do": _soon},
		{"pos": Vector2(290, 590), "r": 50.0, "text": "도구점", "do": _soon},
		{"pos": Vector2(1150, 615), "r": 50.0, "text": "인테리어 상점", "do": _soon},
	]
	for id in BUSHES:
		out.append({"pos": BUSHES[id], "r": 80.0, "text": "산딸기 따기", "do": _pick.bind(id)})
	if puppy:
		out.append({"pos": Vector2(770, 520), "r": 50.0, "text": "강아지와 이야기", "do": _talk_puppy})
	for a in residents:
		out.append({"pos": a.position, "r": 40.0, "text": "인사하기", "do": _greet.bind(a)})
	return out


func _process(_delta: float) -> void:
	var dd: float = player.position.distance_to(BAKERY_DOOR)
	if dd > 60:
		door_armed = true
	if door_armed and dd < 28:
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
	return get_viewport().get_canvas_transform() * p


func _unhandled_input(event: InputEvent) -> void:
	if main.hud.is_panel_open():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_E or event.keycode == KEY_SPACE) and near:
			near.do.call()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player.walk_to(get_viewport().get_canvas_transform().affine_inverse() * event.position)


func _soon() -> void:
	GameState.toast.emit("아직 문을 열지 않았어요. 곧 열 거예요!")


func _pick(id: String) -> void:
	if GameState.picked_today.has(id):
		GameState.toast.emit("다 땄어요. 내일 다시 열려요.")
		return
	var n := randi_range(2, 3)
	GameState.picked_today.append(id)
	GameState.add_item("raspberry", n)
	Audio.sfx("pick")
	GameState.toast.emit("산딸기 %d개를 땄어요! 냉동고에 넣어 둘게요." % n)


func _say_over(node: Node2D, text: String, height := 70.0) -> void:
	var l := UI.label(text, 11)
	l.add_theme_stylebox_override("normal", UI.box(Color.WHITE, UI.OUTLINE, 8, 1))
	l.z_index = 90
	node.add_child(l)
	l.reset_size()
	l.position = Vector2(-l.size.x / 2, -height - l.size.y)
	var tw := l.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func _greet(a) -> void:
	_say_over(a, GREETINGS.pick_random(), 58.0)
	Audio.sfx("order")


func _talk_puppy() -> void:
	if GameState.level() < 2:
		_say_over(puppy.get_parent(), "가게가 조금 더 유명해지면(레벨 2) 같이 일하고 싶어요!", 58.0)
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
