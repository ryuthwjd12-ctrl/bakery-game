extends Node
## 화면 전환을 맡아요. 홀은 한 번 만들면 계속 살아 있어서, 주방이나 마을에 가 있어도 손님이 오가요.

const Hall := preload("res://scripts/hall.gd")
const Kitchen := preload("res://scripts/kitchen.gd")
const Village := preload("res://scripts/village.gd")
const Title := preload("res://scripts/title.gd")
const Hud := preload("res://scripts/hud.gd")
const Field := preload("res://scripts/field.gd")

var hall: Node2D
var current: Node
var current_name := ""
var hud: CanvasLayer


func _ready() -> void:
	get_tree().root.theme = UI.make_theme()
	UI.install_button_juice(get_tree())
	RenderingServer.set_default_clear_color(UI.CREAM)
	hud = Hud.new()
	hud.main = self
	add_child(hud)
	GameState.place_provider = _where
	goto("title")


## 지금 있는 곳(저장할 때 같이 적어요)
func _where() -> Dictionary:
	var out := {"screen": current_name}
	if current_name == "field":
		out.area = current.area_id
	if current and "player" in current and current.player:
		out.x = current.player.position.x
		out.y = current.player.position.y
	return out


func start(h: String, load_save: bool) -> void:
	get_tree().paused = false
	if load_save:
		GameState.load_game()
	else:
		GameState.new_game(h)
	if hall:
		hall.free()
	hall = Hall.new()
	hall.main = self
	add_child(hall)
	move_child(hall, 0)
	GameState.clock_running = true
	# 이어하기: 저장했던 곳, 저장했던 자리로 돌아가요
	var pl: Dictionary = GameState.place if load_save else {}
	match pl.get("screen", "hall"):
		"field":
			goto_field(pl.get("area", "forest_east"))
		"village":
			goto("village")
		"kitchen":
			goto("kitchen")
		_:
			goto("hall")
	if pl.has("x") and current and "player" in current and current.player:
		current.player.position = Vector2(pl.x, pl.y)
		if current == hall:
			hall._set_cam_room(hall.in_annex(current.player.position))


## 하루가 끝나도 있던 곳에 그대로 있어요(숲에서 싸우던 중이면 숲에서 아침을 맞아요)
func new_day() -> void:
	GameState.next_day()
	hall.reset_day()
	hud.show_toast("%d일차 아침이에요. 오늘도 힘내요!" % GameState.day)


## 마을 밖 지역(숲길, 다른 마을)으로 가요.
func goto_field(area_id: String, from := "") -> void:
	if current and current != hall:
		current.queue_free()
	if hall:
		hall.set_active(false)
	current = Field.new()
	current.main = self
	current.area_id = area_id
	current.from = from
	add_child(current)
	current_name = "field"
	hud.set_screen("field")
	GameState.save_game()


func goto(name: String, from := "") -> void:
	if current and current != hall:
		current.queue_free()
	current = null
	if hall:
		hall.set_active(false)
	match name:
		"title":
			GameState.clock_running = false
			if hall:
				hall.queue_free()
				hall = null
			current = Title.new()
			current.main = self
			add_child(current)
		"hall":
			current = hall
			hall.set_active(true, from)
		"kitchen":
			current = Kitchen.new()
			current.main = self
			add_child(current)
		"village":
			current = Village.new()
			current.main = self
			current.from = from
			add_child(current)
	current_name = name
	hud.set_screen(name)
	if name != "title":
		GameState.save_game()
