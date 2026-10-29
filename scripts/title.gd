extends Control
## 첫 화면: 주인공(여자/남자) 고르기와 이어하기.

var main: Node


func _ready() -> void:
	size = Vector2(1408, 768)
	theme = UI.make_theme()
	var bg := UI.bg(Sprites.tex("backgrounds/title"))
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(1, 0.97, 0.9, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var pc := PanelContainer.new()
	pc.position = Vector2(404, 150)
	pc.custom_minimum_size = Vector2(600, 0)
	add_child(pc)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	pc.add_child(vb)
	var t := UI.label("도토리 베이커리", 56, UI.CHESTNUT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := UI.label("누구로 가게를 열까요?", 24)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 40)
	vb.add_child(hb)
	for h in [["female", "여자 주인공"], ["male", "남자 주인공"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 300)
		b.pressed.connect(func(): main.start(h[0], false))
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sf := Sprites.frames_for(h[0], ["front", "back", "right"])
		var ic := UI.icon(sf.get_frame_texture("front", 0), 230)
		col.add_child(ic)
		var l := UI.label(h[1], 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		b.add_child(col)
		hb.add_child(b)

	if GameState.has_save():
		var c := UI.button("이어하기", func(): main.start("", true), 26)
		vb.add_child(c)
	var help := UI.label("이동: 방향키/WASD 또는 클릭 · 행동: E · 레시피북: R", 18, UI.CHESTNUT)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(help)
