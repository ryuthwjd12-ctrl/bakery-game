extends Node2D
## 손님 자리 하나. 비었을 때는 탁자와 의자, 손님이 앉으면 앉은 그림으로 바뀌어요.

signal left_table(t)

const PATIENCE := 100.0
const EAT_TIME := 6.0

var state := "empty"  # empty, reserved, waiting, eating
var animal := ""
var order := ""
var patience := 0.0
var assigned := false
var dirty := false
var eat_left := 0.0

var sprite := Sprite2D.new()
var chair := Sprite2D.new()
var dust := Node2D.new()
var bubble: PanelContainer
var bubble_l: Label
var bubble_ic: TextureRect
var bar: ColorRect


func _ready() -> void:
	chair.texture = Sprites.tex("furniture/pink_chair")
	chair.scale = Vector2(1.3, 1.3)
	chair.centered = false
	chair.offset = Vector2(-27, -82)
	chair.position = Vector2(-48, -14)
	add_child(chair)
	sprite.centered = false
	add_child(sprite)
	dust.z_index = 1
	dust.draw.connect(_draw_dust)
	add_child(dust)

	bubble = PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UI.box(Color.WHITE, UI.OUTLINE, 18, 3))
	bubble.z_index = 60
	bubble.position = Vector2(-140, -300)
	var vb := VBoxContainer.new()
	var hb := HBoxContainer.new()
	bubble_ic = UI.icon(null, 40)
	hb.add_child(bubble_ic)
	bubble_l = UI.label("", 18)
	bubble_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_l.custom_minimum_size = Vector2(220, 0)
	hb.add_child(bubble_l)
	vb.add_child(hb)
	bar = ColorRect.new()
	bar.color = UI.PINK
	bar.custom_minimum_size = Vector2(260, 6)
	vb.add_child(bar)
	bubble.add_child(vb)
	bubble.visible = false
	add_child(bubble)
	_show_empty()


func _show_empty() -> void:
	chair.visible = true
	_set_tex(Sprites.tex("furniture/round_table"), 1.5)


func _set_tex(t: Texture2D, s: float) -> void:
	sprite.texture = t
	sprite.scale = Vector2(s, s)
	sprite.offset = Vector2(-t.get_width() / 2.0, -t.get_height())


func seat(a: String, o: String) -> void:
	animal = a
	order = o
	state = "waiting"
	patience = PATIENCE
	assigned = false
	chair.visible = false
	_set_tex(Sprites.tex("customers/%s_wait" % a), 0.85)
	var known: bool = GameState.known.has(o)
	bubble_ic.texture = Sprites.item(o) if known else null
	bubble_ic.visible = known
	bubble_l.text = GameState.recipe(o).hint
	bubble.visible = true
	bubble.reset_size()
	bubble.position = Vector2(-bubble.size.x / 2, -sprite.texture.get_height() * 0.85 - bubble.size.y - 10)


func serve() -> void:
	state = "eating"
	eat_left = EAT_TIME
	bubble.visible = false
	_set_tex(Sprites.tex("customers/%s_eat" % animal), 0.85)


func _process(delta: float) -> void:
	match state:
		"waiting":
			patience -= delta
			bar.custom_minimum_size.x = 260.0 * clampf(patience / PATIENCE, 0, 1)
			bar.size.x = bar.custom_minimum_size.x
			if patience <= 0:
				GameState.toast.emit("손님이 기다리다 돌아갔어요…")
				_leave(false)
		"eating":
			eat_left -= delta
			if eat_left <= 0:
				var price: int = GameState.ITEMS[order].price
				var tip := 5 if GameState.cleanliness >= 80 else 0
				GameState.earn(price + tip)
				GameState.toast.emit("+%d골드! 맛있게 먹었어요." % (price + tip))
				_leave(true)


func _leave(ate: bool) -> void:
	var a := animal
	state = "empty"
	animal = ""
	order = ""
	assigned = false
	bubble.visible = false
	if ate:
		dirty = true
		dust.queue_redraw()
	_show_empty()
	left_table.emit(self, a)


func clean() -> void:
	dirty = false
	dust.queue_redraw()


func _draw_dust() -> void:
	if not dirty:
		return
	var c := Color(0.55, 0.45, 0.38, 0.55)
	for p in [Vector2(-40, 8), Vector2(-22, 14), Vector2(30, 10), Vector2(48, 4), Vector2(8, 18)]:
		dust.draw_circle(p, 7, c)
	dust.draw_circle(Vector2(-30, 10), 4, Color(0.95, 0.85, 0.6, 0.9))
	dust.draw_circle(Vector2(38, 12), 3, Color(0.95, 0.85, 0.6, 0.9))
