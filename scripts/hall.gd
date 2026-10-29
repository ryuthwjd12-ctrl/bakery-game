extends Node2D
## 가게 홀. 손님이 들어와 앉아 힌트로 주문하고, 알바생이 진열장 음식을 갖다줘요.

const Player := preload("res://scripts/player.gd")
const Table := preload("res://scripts/table.gd")
const Walker := preload("res://scripts/walker.gd")
const Waiter := preload("res://scripts/waiter.gd")

## 빈 방 그림(1408x768)의 바닥 모양. 발이 이 안에 있어야 걸을 수 있어요.
const FLOOR := [Vector2(688, 228), Vector2(1290, 515), Vector2(1010, 735),
	Vector2(590, 740), Vector2(125, 520)]
const DOOR := Vector2(1040, 600)
const KITCHEN_DOOR := Vector2(400, 385)
const CASE_SPOT := Vector2(420, 530)
const TABLE_SPOTS := [Vector2(610, 470), Vector2(860, 400), Vector2(780, 620), Vector2(1080, 500)]
const ANIMALS := ["rabbit", "cat", "deer", "chick"]

var main: Node
var world := Node2D.new()
var player
var waiter
var tables: Array = []
var blockers: Array = []  # [center, radius-x, radius-y]
var spawn_left := 4.0
var active := false
var hotspots: Array = []
var near = null


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex("backgrounds/hall_empty")
	bg.centered = false
	add_child(bg)

	_deco("furniture/picture", Vector2(560, 175), 1.1)
	_deco("furniture/rug_icon", Vector2(800, 600), 2.0)

	world.y_sort_enabled = true
	add_child(world)
	_furniture("furniture/display_case", Vector2(330, 480), 1.9, 80, 30)
	_furniture("furniture/plant", Vector2(690, 268), 1.4, 30, 14)
	_furniture("furniture/plant", Vector2(1235, 520), 1.4, 30, 14)
	_furniture("furniture/lamp", Vector2(180, 540), 1.3, 18, 10)

	for p in TABLE_SPOTS:
		var t := Table.new()
		t.position = p
		t.left_table.connect(_on_left)
		world.add_child(t)
		tables.append(t)
		blockers.append([p + Vector2(0, -8), 70.0, 26.0])

	waiter = Waiter.new()
	waiter.hall = self
	waiter.home = Vector2(960, 330)
	waiter.position = waiter.home
	world.add_child(waiter)

	player = Player.new()
	player.setup(GameState.hero, 0.68)
	player.can_walk = can_walk
	player.position = Vector2(700, 560)
	world.add_child(player)

	hotspots = [
		{"pos": KITCHEN_DOOR, "r": 80.0, "text": "E  주방으로", "go": "kitchen"},
		{"pos": DOOR, "r": 90.0, "text": "E  밖으로 (도토리 숲 마을)", "go": "village"},
	]


func _deco(path: String, at: Vector2, s: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = Sprites.tex(path)
	sp.position = at
	sp.scale = Vector2(s, s)
	add_child(sp)
	return sp


func _furniture(path: String, at: Vector2, s: float, rx: float, ry: float) -> void:
	var sp := Sprite2D.new()
	var tex := Sprites.tex(path)
	sp.texture = tex
	sp.centered = false
	sp.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	sp.scale = Vector2(s, s)
	sp.position = at
	world.add_child(sp)
	blockers.append([at + Vector2(0, -ry * 0.5), rx, ry])


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
	if on:
		if from == "kitchen":
			player.position = KITCHEN_DOOR + Vector2(50, 50)
		elif from == "village":
			player.position = DOOR + Vector2(-60, -30)
	else:
		main.hud.set_prompt("", Vector2.ZERO)


func _process(delta: float) -> void:
	_spawn_tick(delta)
	if not active:
		return
	near = null
	for h in hotspots:
		if player.position.distance_to(h.pos) < h.r:
			near = h
	if near and not main.hud.is_panel_open():
		main.hud.set_prompt(near.text, player.position + Vector2(0, 14))
	else:
		main.hud.set_prompt("", Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if not active or main.hud.is_panel_open():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_E or event.keycode == KEY_SPACE) and near:
			main.goto(near.go, "hall")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player.walk_to(event.position)


func _spawn_tick(delta: float) -> void:
	if not GameState.is_open():
		return
	spawn_left -= delta
	if spawn_left > 0:
		return
	# 깨끗할수록 손님이 자주 와요.
	spawn_left = lerpf(32.0, 14.0, GameState.cleanliness / 100.0) + randf() * 6.0
	var free := tables.filter(func(t): return t.state == "empty" and not t.dirty)
	if free.is_empty():
		return
	var t = free.pick_random()
	t.state = "reserved"
	var animal: String = ANIMALS.pick_random()
	var order := _pick_order()
	var w := Walker.new()
	w.setup(animal)
	w.position = DOOR
	world.add_child(w)
	await w.walk(t.position + Vector2(70, 14))
	w.queue_free()
	t.seat(animal, order)


func _pick_order() -> String:
	if not GameState.known.is_empty() and randf() < 0.65:
		return GameState.known.pick_random()
	var pool := ["butter_cookie", "warm_milk", "milk_bread"]
	if GameState.day >= 2 or GameState.known.size() >= 2:
		pool = GameState.RECIPES.map(func(r): return r.id)
	return pool.pick_random()


func _on_left(t, animal: String) -> void:
	update_cleanliness()
	var w := Walker.new()
	w.setup(animal)
	w.position = t.position + Vector2(70, 14)
	world.add_child(w)
	await w.walk(DOOR)
	w.queue_free()


func update_cleanliness() -> void:
	var n := tables.filter(func(t): return t.dirty).size()
	GameState.cleanliness = clampi(100 - n * 15, 0, 100)
	GameState.changed.emit()


func find_serve_job():
	for t in tables:
		if t.state == "waiting" and not t.assigned and GameState.stock.get(t.order, 0) > 0:
			return t
	return null


func find_clean_job():
	for t in tables:
		if t.dirty and t.state == "empty" and not t.has_meta("cleaning"):
			return t
	return null
