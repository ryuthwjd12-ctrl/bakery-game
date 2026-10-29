extends Node
## 화면 전환을 맡아요. 홀은 한 번 만들면 계속 살아 있어서, 주방이나 마을에 가 있어도 알바생이 손님을 받아요.

const Hall := preload("res://scripts/hall.gd")
const Kitchen := preload("res://scripts/kitchen.gd")
const Village := preload("res://scripts/village.gd")
const Title := preload("res://scripts/title.gd")
const Hud := preload("res://scripts/hud.gd")

var hall: Node2D
var current: Node
var current_name := ""
var hud: CanvasLayer


func _ready() -> void:
	get_tree().root.theme = UI.make_theme()
	RenderingServer.set_default_clear_color(UI.CREAM)
	hud = Hud.new()
	hud.main = self
	add_child(hud)
	goto("title")


func start(h: String, load_save: bool) -> void:
	if load_save:
		GameState.load_game()
	else:
		GameState.new_game(h)
	if hall:
		hall.queue_free()
	hall = Hall.new()
	hall.main = self
	add_child(hall)
	move_child(hall, 0)
	GameState.clock_running = true
	goto("hall")


func goto(name: String, from := "") -> void:
	if current and current != hall:
		current.queue_free()
	current = null
	if hall:
		hall.set_active(false)
	match name:
		"title":
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
			add_child(current)
	current_name = name
	hud.set_screen(name)
	if name != "title":
		GameState.save_game()
