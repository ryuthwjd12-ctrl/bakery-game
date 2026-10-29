extends CanvasLayer
## 화면 위에 늘 떠 있는 것들: 시계·골드·가게 레벨, 주문 줄, 진열대, 알림, 첫날 안내,
## 그리고 레시피북·재료 가게·일시정지·설정·하루 정산 창.

var main: Node
var root := Control.new()
var clock_l: Label
var gold_l: Label
var level_l: Label
var level_bar: ColorRect
var orders_panel: PanelContainer
var orders_box: HBoxContainer
var order_bars: Array = []  # [table, ColorRect]
var stock_panel: PanelContainer
var stock_box: HBoxContainer
var guide_panel: PanelContainer
var guide_box: VBoxContainer
var toast_l: Label
var toast_tween: Tween
var prompt_l: Label
var top_left: PanelContainer
var top_right: HBoxContainer
var panel: Control  # 지금 열려 있는 창
var screen := ""

const GUIDE := [
	["order", "손님에게 가서 E(또는 클릭)로 주문 받기"],
	["cook", "주방에서 재료를 골라 만들기 (흐린 그림이 힌트)"],
	["serve", "받은 순서대로 손님에게 음식 내주기"],
	["clean", "손님이 떠난 자리 치우기"],
]


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.size = Vector2(1408, 768)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.make_theme()
	add_child(root)

	top_left = PanelContainer.new()
	top_left.position = Vector2(16, 12)
	var tl := VBoxContainer.new()
	tl.add_theme_constant_override("separation", 2)
	top_left.add_child(tl)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 22)
	clock_l = UI.label("", 22)
	gold_l = UI.label("", 22, Color("#B8741A"))
	row1.add_child(clock_l)
	row1.add_child(gold_l)
	tl.add_child(row1)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	level_l = UI.label("", 18)
	row2.add_child(level_l)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color("#EADFCB")
	bar_bg.custom_minimum_size = Vector2(140, 10)
	bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	level_bar = ColorRect.new()
	level_bar.color = UI.PINK
	level_bar.size = Vector2(0, 10)
	bar_bg.add_child(level_bar)
	row2.add_child(bar_bg)
	tl.add_child(row2)
	root.add_child(top_left)

	top_right = HBoxContainer.new()
	top_right.add_theme_constant_override("separation", 8)
	top_right.add_child(UI.button("레시피북 (R)", toggle_book, 20))
	top_right.add_child(UI.button("메뉴 (Esc)", open_pause, 20))
	root.add_child(top_right)
	top_right.reset_size()
	top_right.position = Vector2(1408 - 16 - top_right.size.x, 12)

	orders_panel = PanelContainer.new()
	orders_panel.add_theme_stylebox_override("panel", UI.box(Color(1, 0.98, 0.93, 0.92), UI.OUTLINE, 14, 2))
	orders_box = HBoxContainer.new()
	orders_box.add_theme_constant_override("separation", 8)
	orders_panel.add_child(orders_box)
	root.add_child(orders_panel)

	stock_panel = PanelContainer.new()
	stock_box = HBoxContainer.new()
	stock_box.add_theme_constant_override("separation", 8)
	stock_panel.add_child(stock_box)
	root.add_child(stock_panel)

	guide_panel = PanelContainer.new()
	guide_panel.add_theme_stylebox_override("panel", UI.box(Color(1, 0.98, 0.93, 0.95), UI.PINK, 14, 3))
	guide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_box = VBoxContainer.new()
	guide_panel.add_child(guide_box)
	root.add_child(guide_panel)

	toast_l = UI.label("", 24)
	toast_l.add_theme_stylebox_override("normal", UI.box(Color("#FFF8E6"), UI.PINK))
	toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_l.modulate.a = 0.0
	toast_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_l)

	prompt_l = UI.label("", 20)
	prompt_l.add_theme_stylebox_override("normal", UI.box(UI.APRON, UI.OUTLINE, 12, 2))
	prompt_l.visible = false
	prompt_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(prompt_l)

	GameState.changed.connect(refresh)
	GameState.tick.connect(_tick)
	GameState.toast.connect(show_toast)
	GameState.day_ended.connect(_on_day_ended)
	GameState.level_up.connect(func(lv): show_toast("가게 레벨 %d! 새로운 메뉴를 찾는 손님이 와요." % lv))
	GameState.tutorial_changed.connect(_refresh_guide)
	refresh()


func set_screen(name: String) -> void:
	screen = name
	close_panel()
	var playing := name != "title"
	top_left.visible = playing
	top_right.visible = playing
	set_prompt("", Vector2.ZERO)
	refresh()


func refresh() -> void:
	_tick()
	gold_l.text = "%d 골드" % GameState.gold
	level_l.text = "가게 Lv.%d" % GameState.level()
	level_bar.size.x = 140.0 * GameState.level_progress()
	_refresh_orders()
	_refresh_stock()
	_refresh_guide()


func _playing() -> bool:
	return screen != "" and screen != "title"


func _tick() -> void:
	clock_l.text = GameState.clock_text()
	if GameState.orders.size() != order_bars.size():
		_refresh_orders()
	for ob in order_bars:
		var t = ob[0]
		if is_instance_valid(t):
			var f: float = clampf(t.patience / t.patience_max, 0, 1)
			ob[1].size.x = 60.0 * f
			ob[1].color = UI.PINK if f > 0.3 else Color("#D9534F")


func _refresh_orders() -> void:
	for c in orders_box.get_children():
		orders_box.remove_child(c)
		c.queue_free()
	order_bars.clear()
	orders_panel.visible = _playing() and not GameState.orders.is_empty()
	for i in GameState.orders.size():
		var t = GameState.orders[i]
		if not is_instance_valid(t):
			continue
		var card := PanelContainer.new()
		var first := i == 0
		card.add_theme_stylebox_override("panel", UI.box(Color.WHITE if first else Color("#FFFBF2"), UI.PINK if first else Color("#D8C6A8"), 10, 3 if first else 2))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 2)
		hb.add_child(UI.icon(Sprites.first_frame(t.kind + "_front"), 34))
		hb.add_child(UI.icon(Sprites.item(t.order), 38))
		vb.add_child(hb)
		var bg := ColorRect.new()
		bg.color = Color("#EADFCB")
		bg.custom_minimum_size = Vector2(60, 6)
		bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var bar := ColorRect.new()
		bar.color = UI.PINK
		bar.size = Vector2(60, 6)
		bg.add_child(bar)
		vb.add_child(bg)
		card.add_child(vb)
		orders_box.add_child(card)
		order_bars.append([t, bar])
	orders_panel.reset_size()
	orders_panel.position = Vector2((1408 - orders_panel.size.x) / 2, 10)


func _refresh_stock() -> void:
	for c in stock_box.get_children():
		stock_box.remove_child(c)
		c.queue_free()
	stock_panel.visible = _playing() and not GameState.stock.is_empty()
	if GameState.stock.is_empty():
		return
	stock_box.add_child(UI.label("진열대", 20))
	for id in GameState.stock:
		stock_box.add_child(UI.icon(Sprites.item(id), 40))
		stock_box.add_child(UI.label("%d" % GameState.stock[id], 20))
	stock_panel.reset_size()
	stock_panel.position = Vector2(16, 768 - 16 - stock_panel.size.y)


func _refresh_guide() -> void:
	for c in guide_box.get_children():
		guide_box.remove_child(c)
		c.queue_free()
	guide_panel.visible = _playing() and not GameState.tutorial_done()
	if not guide_panel.visible:
		return
	guide_box.add_child(UI.label("첫 영업 안내", 20, UI.PINK))
	for g in GUIDE:
		var done: bool = GameState.tutorial.has(g[0])
		guide_box.add_child(UI.label(("✓ " if done else "○ ") + g[1], 17, Color("#9A8B7A") if done else UI.OUTLINE))
	guide_panel.reset_size()
	# 주방에서는 굽기 버튼을 가리지 않게 오븐 위쪽으로 올려요.
	var y := 330.0 if screen == "kitchen" else 768 - 16 - guide_panel.size.y
	guide_panel.position = Vector2(1408 - 16 - guide_panel.size.x, y)


func show_toast(text: String) -> void:
	toast_l.text = text
	toast_l.reset_size()
	toast_l.position = Vector2((1408 - toast_l.size.x) / 2, 100)
	if toast_tween:
		toast_tween.kill()
	toast_l.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(2.4)
	toast_tween.tween_property(toast_l, "modulate:a", 0.0, 0.6)


func set_prompt(text: String, at: Vector2) -> void:
	prompt_l.visible = text != ""
	if text != "":
		prompt_l.text = text
		prompt_l.reset_size()
		prompt_l.position = at - Vector2(prompt_l.size.x / 2, 0)


func _unhandled_input(event: InputEvent) -> void:
	if screen == "title" or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_R and not get_tree().paused:
		toggle_book()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		if panel and not panel.has_meta("locked"):
			close_panel()
		elif panel and panel.has_meta("pause"):
			close_panel()
		elif not panel:
			open_pause()
		get_viewport().set_input_as_handled()


func close_panel() -> void:
	if panel:
		panel.queue_free()
		panel = null
	get_tree().paused = false


func is_panel_open() -> bool:
	return panel != null


## 가운데에 뜨는 창을 만들어요.
func window(title: String, w: float, closable := true) -> VBoxContainer:
	close_panel()
	var shade := ColorRect.new()
	shade.color = Color(0.25, 0.15, 0.1, 0.4)
	shade.size = Vector2(1408, 768)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(w, 0)
	shade.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	var head := HBoxContainer.new()
	var t := UI.label(title, 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if closable:
		head.add_child(UI.button("닫기", close_panel, 18))
	else:
		shade.set_meta("locked", true)
	vb.add_child(head)
	panel = shade
	root.add_child(shade)
	_center.call_deferred(pc)
	return vb


func _center(pc: Control) -> void:
	if is_instance_valid(pc):
		pc.reset_size()
		pc.position = (Vector2(1408, 768) - pc.size) / 2


func toggle_book() -> void:
	if panel and panel.has_meta("book"):
		close_panel()
		return
	Audio.sfx("click")
	var vb := window("레시피북   %d / %d" % [GameState.known.size(), GameState.RECIPES.size()], 900)
	panel.set_meta("book", true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)
	for r in GameState.RECIPES:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(420, 64)
		var known: bool = GameState.known.has(r.id)
		var ic := UI.icon(Sprites.item(r.id), 60)
		if not known:
			ic.modulate = Color(0.2, 0.12, 0.08, 0.5)
		row.add_child(ic)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.add_child(UI.label(GameState.item_name(r.id) if known else "???", 22))
		var ings := HBoxContainer.new()
		if known:
			for n in r.needs:
				ings.add_child(UI.icon(Sprites.item(n), 30))
		else:
			ings.add_child(UI.label("직접 만들어 보면 알 수 있어요.", 16, UI.CHESTNUT))
		col.add_child(ings)
		row.add_child(col)
		grid.add_child(row)


func open_shop() -> void:
	Audio.sfx("door")
	var vb := window("도토리 재료 가게", 800)
	vb.add_child(UI.label("필요한 만큼 골라서 사요. 재료는 상하지 않아요.", 18, UI.CHESTNUT))
	for id in ["flour", "sugar", "butter", "egg", "milk", "chocolate", "cream"]:
		vb.add_child(_shop_row(id))


func _shop_row(id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.icon(Sprites.item(id), 46))
	var name := UI.label("%s  (%d골드)" % [GameState.item_name(id), GameState.ITEMS[id].price])
	name.custom_minimum_size.x = 250
	row.add_child(name)
	var have := UI.label("가진 것 %d" % GameState.count(id), 18, UI.CHESTNUT)
	have.custom_minimum_size.x = 110
	row.add_child(have)
	var n := {"v": 1}
	var n_l := UI.label("1", 22)
	n_l.custom_minimum_size.x = 36
	n_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var minus := func():
		n.v = maxi(1, n.v - 1)
		n_l.text = str(n.v)
	var plus := func():
		n.v = mini(20, n.v + 1)
		n_l.text = str(n.v)
	var buy := func():
		if GameState.buy(id, n.v):
			have.text = "가진 것 %d" % GameState.count(id)
			Audio.sfx("coin")
			show_toast("%s %d개를 샀어요." % [GameState.item_name(id), n.v])
		else:
			Audio.sfx("fail")
			show_toast("골드가 모자라요.")
	row.add_child(UI.button("-", minus, 20))
	row.add_child(n_l)
	row.add_child(UI.button("+", plus, 20))
	row.add_child(UI.button("사기", buy, 20))
	return row


func confirm(text: String, yes: Callable) -> void:
	var vb := window("확인", 560)
	var l := UI.label(text, 20)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 520
	vb.add_child(l)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	var ok := func():
		close_panel()
		yes.call()
	hb.add_child(UI.button("좋아요", ok, 22))
	hb.add_child(UI.button("아니요", close_panel, 22))
	vb.add_child(hb)


func open_pause() -> void:
	if screen == "title":
		return
	Audio.sfx("click")
	var vb := window("일시정지", 420, false)
	panel.set_meta("pause", true)
	get_tree().paused = true
	var save := func():
		GameState.save_game()
		close_panel()
		show_toast("저장했어요.")
	var load := func():
		if not GameState.has_save():
			show_toast("저장된 게임이 없어요.")
			return
		close_panel()
		main.start("", true)
		show_toast("마지막 저장을 불러왔어요.")
	var to_title := func():
		close_panel()
		main.goto("title")
	for b in [["계속하기", close_panel], ["저장하기", save], ["불러오기 (마지막 저장)", load],
			["설정", open_options.bind(true)], ["처음 화면으로", to_title]]:
		var btn := UI.button(b[0], b[1], 24)
		btn.custom_minimum_size = Vector2(380, 52)
		vb.add_child(btn)


func open_options(from_pause := false) -> void:
	var vb := window("설정", 540, not from_pause)
	if from_pause:
		get_tree().paused = true
	for s in [["배경음악", "bgm_volume"], ["효과음", "sfx_volume"]]:
		var row := HBoxContainer.new()
		var l := UI.label(s[0], 22)
		l.custom_minimum_size.x = 130
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = Audio.get(s[1])
		sl.custom_minimum_size = Vector2(340, 32)
		var prop: String = s[1]
		sl.value_changed.connect(func(v):
			Audio.set(prop, v)
			Audio.apply()
			if prop == "sfx_volume":
				Audio.sfx("click"))
		row.add_child(sl)
		vb.add_child(row)
	var fs := CheckBox.new()
	fs.text = "전체 화면"
	fs.button_pressed = Audio.fullscreen
	fs.toggled.connect(func(on):
		Audio.fullscreen = on
		Audio.apply())
	vb.add_child(fs)
	vb.add_child(UI.label("조작: 방향키/WASD·클릭 이동, E 행동, R 레시피북, Esc 메뉴", 16, UI.CHESTNUT))
	var done := func():
		Audio.save_settings()
		if from_pause:
			open_pause()
		else:
			close_panel()
	vb.add_child(UI.button("확인", done, 22))


func _on_day_ended(s: Dictionary) -> void:
	Audio.sfx("sparkle")
	var vb := window("%d일차 영업 끝!" % GameState.day, 520, false)
	get_tree().paused = true
	for line in [
		"맛있게 먹고 간 손님  %d명" % s.served,
		"화나서 돌아간 손님  %d명" % s.lost,
		"오늘 번 돈  %d골드" % s.earned,
		"새로 찾은 레시피  %d개" % s.new,
		"가게 레벨  %d" % GameState.level(),
	]:
		vb.add_child(UI.label(line, 22))
	var next := func():
		close_panel()
		main.new_day()
	vb.add_child(UI.button("다음 날 (저장)", next, 24))
