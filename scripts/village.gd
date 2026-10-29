extends Node2D
## 도토리 숲 마을. 재료 가게에서 사고, 산딸기 덤불에서 채집하고, 가게로 돌아가요.
## 좌표는 마을 그림(1408x768) 위의 위치예요.

const Player := preload("res://scripts/player.gd")

## 건물이 있는 곳은 못 걸어요.
const BLOCKED := [
	Rect2(380, 40, 220, 165), Rect2(850, 20, 225, 205), Rect2(1060, 110, 225, 195),
	Rect2(590, 200, 245, 250), Rect2(140, 360, 215, 220), Rect2(1065, 380, 255, 230),
	Rect2(495, 585, 120, 80), Rect2(770, 585, 155, 80),
]
const BUSHES := {
	"bush_left": Vector2(40, 300),
	"bush_right": Vector2(1375, 305),
	"bush_bottom_left": Vector2(445, 700),
	"bush_bottom_right": Vector2(955, 700),
}

var main: Node
var world := Node2D.new()
var player
var hotspots: Array = []
var near = null


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex("backgrounds/acorn_village")
	bg.centered = false
	add_child(bg)
	world.y_sort_enabled = true
	add_child(world)

	player = Player.new()
	player.setup(GameState.hero, 0.5)
	player.can_walk = can_walk
	player.position = Vector2(655, 500)
	world.add_child(player)

	hotspots = [
		{"pos": Vector2(650, 470), "r": 70.0, "text": "E  우리 가게로 들어가기", "act": "bakery"},
		{"pos": Vector2(530, 225), "r": 70.0, "text": "E  재료 가게", "act": "shop"},
		{"pos": Vector2(960, 235), "r": 70.0, "text": "E  그릇 가게", "act": "soon"},
		{"pos": Vector2(1100, 315), "r": 60.0, "text": "E  가구점", "act": "soon"},
		{"pos": Vector2(290, 595), "r": 60.0, "text": "E  도구점", "act": "soon"},
		{"pos": Vector2(1120, 620), "r": 60.0, "text": "E  인테리어 상점", "act": "soon"},
	]
	for id in BUSHES:
		hotspots.append({"pos": BUSHES[id], "r": 90.0, "text": "E  산딸기 따기", "act": "bush", "id": id})


func can_walk(p: Vector2) -> bool:
	if p.x < 12 or p.x > 1396 or p.y < 30 or p.y > 760:
		return false
	for r in BLOCKED:
		if r.has_point(p):
			return false
	return true


func _process(_delta: float) -> void:
	near = null
	var best := 1e9
	for h in hotspots:
		var d: float = player.position.distance_to(h.pos)
		if d < h.r and d < best:
			near = h
			best = d
	player.active = not main.hud.is_panel_open()
	if near and player.active:
		main.hud.set_prompt(near.text, player.position + Vector2(0, 10))
	else:
		main.hud.set_prompt("", Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if main.hud.is_panel_open():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_E or event.keycode == KEY_SPACE) and near:
			_act(near)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player.walk_to(event.position)


func _act(h: Dictionary) -> void:
	match h.act:
		"bakery":
			main.goto("hall", "village")
		"shop":
			main.hud.open_shop()
		"soon":
			GameState.toast.emit("아직 문을 열지 않았어요. 다음 버전에서 만나요!")
		"bush":
			if GameState.picked_today.has(h.id):
				GameState.toast.emit("다 땄어요. 내일 다시 열려요.")
			else:
				var n := randi_range(2, 3)
				GameState.picked_today.append(h.id)
				GameState.add_item("raspberry", n)
				GameState.toast.emit("산딸기 %d개를 땄어요!" % n)
