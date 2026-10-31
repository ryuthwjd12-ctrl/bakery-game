extends Node2D
## 손님 머리 위 생각 풍선. 글자 없이 그림(또는 느낌표)만 보여 줘요.

var icon := Sprite2D.new()
var icon2 := Sprite2D.new()  # 메뉴를 두 개 시켰을 때 두 번째
var mark := Label.new()
var fill := 1.0  # 기다림 바 (0~1)
var show_bar := true
var two := false
const W := 86.0
const H := 74.0


func _ready() -> void:
	z_index = 60
	icon.position = Vector2(0, -H / 2 - 18)
	add_child(icon)
	add_child(icon2)
	mark.text = "!"
	mark.add_theme_font_size_override("font_size", 46)
	mark.add_theme_color_override("font_color", UI.PINK)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.size = Vector2(W, 60)
	mark.position = Vector2(-W / 2, -H - 14)
	add_child(mark)


func show_mark(special := false) -> void:
	mark.text = "★" if special else "!"
	mark.add_theme_color_override("font_color", Color("#E8A33D") if special else UI.PINK)
	icon.visible = false
	icon2.visible = false
	mark.visible = true
	visible = true
	queue_redraw()


func show_item(id: String) -> void:
	show_items([id])


## 아직 안 받은 메뉴를 그림으로(두 개면 나란히)
func show_items(ids: Array) -> void:
	two = ids.size() > 1
	for pair in [[icon, 0], [icon2, 1]]:
		var sp: Sprite2D = pair[0]
		if pair[1] >= ids.size():
			sp.visible = false
			continue
		sp.texture = Sprites.item(ids[pair[1]])
		var s := (44.0 if two else 54.0) / maxf(sp.texture.get_width(), sp.texture.get_height())
		sp.scale = Vector2(s, s)
		sp.position = Vector2((-22.0 if pair[1] == 0 else 22.0) if two else 0.0, -H / 2 - 18)
		sp.visible = true
	mark.visible = false
	visible = true
	queue_redraw()


func set_fill(f: float) -> void:
	fill = clampf(f, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var w := W + (40.0 if two and icon2.visible else 0.0)
	var r := Rect2(-w / 2, -H - 18, w, H)
	var sb := UI.box(Color.WHITE, UI.OUTLINE, 26, 3)
	draw_style_box(sb, r)
	draw_circle(Vector2(-6, -12), 7, UI.OUTLINE)
	draw_circle(Vector2(-6, -12), 5, Color.WHITE)
	draw_circle(Vector2(-12, -2), 4, UI.OUTLINE)
	draw_circle(Vector2(-12, -2), 2.5, Color.WHITE)
	if show_bar:
		var bar := Rect2(-w / 2 + 10, -26, w - 20, 6)
		draw_rect(bar, Color("#EADFCB"))
		var c := UI.PINK if fill > 0.3 else Color("#D9534F")
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), c)
		_draw_mood(Vector2(w / 2 - 2, -H - 14))


## 기분 얼굴: 기다릴수록 웃음 → 무표정 → 찡그림
func _draw_mood(c: Vector2) -> void:
	var col := Color("#8BC98A") if fill > 0.6 else (Color("#F2C14E") if fill > 0.3 else Color("#E0675A"))
	draw_circle(c, 13, UI.OUTLINE)
	draw_circle(c, 11, col)
	draw_circle(c + Vector2(-4, -3), 1.8, UI.OUTLINE)
	draw_circle(c + Vector2(4, -3), 1.8, UI.OUTLINE)
	if fill > 0.6:
		draw_arc(c + Vector2(0, 1), 5, 0.3, PI - 0.3, 10, UI.OUTLINE, 2)
	elif fill > 0.3:
		draw_line(c + Vector2(-4, 4), c + Vector2(4, 4), UI.OUTLINE, 2)
	else:
		draw_arc(c + Vector2(0, 8), 5, PI + 0.3, TAU - 0.3, 10, UI.OUTLINE, 2)

