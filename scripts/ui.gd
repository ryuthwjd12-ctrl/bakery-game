class_name UI
extends RefCounted
## 게임 화면 색과 상자 모양을 한곳에서 정해요.

const CREAM := Color("#FBF3E3")
const OUTLINE := Color("#7A4E3C")
const PINK := Color("#E07A86")
const LIGHT_PINK := Color("#F2A9B4")
const APRON := Color("#F7EDCB")
const CHESTNUT := Color("#8E5A3A")
const SKY := Color("#A9CFE8")


static func box(bg: Color = CREAM, border: Color = OUTLINE, radius := 16, width := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static var _theme: Theme


static func make_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	_theme = t
	t.default_font = load("res://assets/fonts/Jua-Regular.ttf")
	t.default_font_size = 22
	t.set_color("font_color", "Label", OUTLINE)
	t.set_stylebox("panel", "PanelContainer", box())
	t.set_stylebox("panel", "Panel", box())
	t.set_stylebox("normal", "Button", box(APRON))
	t.set_stylebox("hover", "Button", box(Color("#FFF8E6"), PINK))
	t.set_stylebox("pressed", "Button", box(LIGHT_PINK, PINK))
	t.set_stylebox("disabled", "Button", box(Color("#EDE3D0"), Color("#B8A493")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", OUTLINE)
	t.set_color("font_disabled_color", "Button", Color("#B8A493"))
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, UI.OUTLINE, 10, 2))
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, PINK, 10, 2))
	t.set_color("font_color", "LineEdit", OUTLINE)
	return t


static func label(text: String, size := 22, color: Color = OUTLINE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, cb: Callable, size := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	return b


## 그림 위에 겹치는 투명 버튼. 마우스를 올리면 분홍 테두리가 생겨요.
static func hotspot(rect: Rect2, cb: Callable) -> Button:
	var b := Button.new()
	b.position = rect.position
	b.size = rect.size
	b.flat = true
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.18), PINK, 18, 4))
	b.add_theme_stylebox_override("pressed", box(Color(1, 0.85, 0.88, 0.3), PINK, 18, 4))
	b.pressed.connect(cb)
	return b


static func icon(tex: Texture2D, size := 48) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func bg(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
