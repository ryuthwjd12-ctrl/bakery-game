extends Control
## 첫 화면: 새 게임(주인공 고르기), 이어하기, 설정, 끝내기.

var main: Node
var menu: VBoxContainer
var card: PanelContainer


func _ready() -> void:
	size = Vector2(1408, 768)
	theme = UI.make_theme()
	add_child(UI.bg(Sprites.tex("backgrounds/title")))
	var shade := ColorRect.new()
	shade.color = Color(1, 0.97, 0.9, 0.25)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	Audio.play_bgm("bgm_shop")
	_main_menu()


func _clear() -> void:
	if card:
		card.queue_free()
	card = PanelContainer.new()
	add_child(card)
	menu = VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 14)
	card.add_child(menu)


func _center() -> void:
	card.reset_size()
	card.position = (size - card.size) / 2 + Vector2(0, 40)


func _title_label() -> void:
	var t := UI.label("도토리 베이커리", 60, UI.CHESTNUT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(t)


func _main_menu() -> void:
	_clear()
	_title_label()
	var new_game := func():
		if GameState.has_save():
			_confirm_new()
		else:
			_hero_select()
	var items := [["새 게임", new_game]]
	if GameState.has_save():
		items.push_front(["이어하기", func(): main.start("", true)])
	items.append(["설정", func(): main.hud.open_options(false)])
	items.append(["끝내기", func(): get_tree().quit()])
	for it in items:
		var b := UI.button(it[0], it[1], 26)
		b.custom_minimum_size = Vector2(360, 56)
		menu.add_child(b)
	_center.call_deferred()


func _confirm_new() -> void:
	_clear()
	var l := UI.label("새로 시작하면 지금 저장된 게임이 지워져요.\n그래도 새로 시작할까요?", 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(l)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	hb.add_child(UI.button("새로 시작", _hero_select, 22))
	hb.add_child(UI.button("돌아가기", _main_menu, 22))
	menu.add_child(hb)
	_center.call_deferred()


func _hero_select() -> void:
	_clear()
	var s := UI.label("누구로 가게를 열까요?", 30)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(s)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 40)
	menu.add_child(hb)
	for h in [["female", "여자 주인공"], ["male", "남자 주인공"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 320)
		var hero: String = h[0]
		b.pressed.connect(func():
			Audio.sfx("sparkle")
			main.start(hero, false))
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sf := Sprites.frames_for(hero, ["front", "back", "right"])
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = sf
		spr.animation = "front"
		spr.play()
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(220, 250)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.position = Vector2(110, 125)
		holder.add_child(spr)
		col.add_child(holder)
		var l := UI.label(h[1], 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		b.add_child(col)
		hb.add_child(b)
	menu.add_child(UI.button("돌아가기", _main_menu, 20))
	_center.call_deferred()
