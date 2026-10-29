extends CanvasLayer
## 위쪽 시계·골드, 아래 진열장, 알림 문구, 레시피북과 재료 상점 창.

var main: Node
var top: PanelContainer
var clock_l: Label
var gold_l: Label
var score_l: Label
var stock_box: HBoxContainer
var stock_panel: PanelContainer
var toast_l: Label
var toast_tween: Tween
var prompt_l: Label
var book_btn: Button
var panel: Control  # 지금 열려 있는 창
var screen := ""
var root := Control.new()


func _ready() -> void:
	layer = 10
	root.size = Vector2(1408, 768)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.make_theme()
	add_child(root)
	top = PanelContainer.new()
	top.position = Vector2(16, 12)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 28)
	top.add_child(hb)
	clock_l = UI.label("")
	gold_l = UI.label("")
	score_l = UI.label("")
	hb.add_child(clock_l)
	hb.add_child(gold_l)
	hb.add_child(score_l)
	root.add_child(top)

	book_btn = UI.button("레시피북 (R)", toggle_book)
	book_btn.position = Vector2(1220, 12)
	root.add_child(book_btn)

	stock_panel = PanelContainer.new()
	stock_panel.position = Vector2(16, 690)
	stock_box = HBoxContainer.new()
	stock_box.add_theme_constant_override("separation", 10)
	stock_panel.add_child(stock_box)
	root.add_child(stock_panel)

	toast_l = UI.label("", 26)
	toast_l.add_theme_stylebox_override("normal", UI.box(Color("#FFF8E6"), UI.PINK))
	toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_l.position = Vector2(404, 70)
	toast_l.size = Vector2(600, 0)
	toast_l.modulate.a = 0.0
	root.add_child(toast_l)

	prompt_l = UI.label("", 22)
	prompt_l.add_theme_stylebox_override("normal", UI.box(UI.APRON, UI.OUTLINE, 12, 2))
	prompt_l.visible = false
	root.add_child(prompt_l)

	GameState.changed.connect(refresh)
	GameState.toast.connect(show_toast)
	GameState.day_ended.connect(_on_day_ended)
	refresh()


func set_screen(name: String) -> void:
	screen = name
	close_panel()
	var playing := name != "title"
	top.visible = playing
	book_btn.visible = playing
	stock_panel.visible = playing
	set_prompt("", Vector2.ZERO)
	refresh()


func refresh() -> void:
	clock_l.text = GameState.clock_text()
	gold_l.text = "골드 %d" % GameState.gold
	score_l.text = "가게 점수 %d" % (GameState.cleanliness + 20)
	for c in stock_box.get_children():
		stock_box.remove_child(c)
		c.queue_free()
	stock_box.add_child(UI.label("진열장"))
	if GameState.stock.is_empty():
		stock_box.add_child(UI.label("비어 있어요", 20, UI.CHESTNUT))
	for id in GameState.stock:
		stock_box.add_child(UI.icon(Sprites.item(id), 40))
		stock_box.add_child(UI.label("%d" % GameState.stock[id]))
	for o in GameState.oven:
		var l := UI.label("오븐: %s %d초" % [GameState.item_name(o.id), ceili(o.left)], 18, UI.CHESTNUT)
		stock_box.add_child(l)


func show_toast(text: String) -> void:
	toast_l.text = text
	toast_l.size = Vector2(600, 0)
	if toast_tween:
		toast_tween.kill()
	toast_l.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(2.2)
	toast_tween.tween_property(toast_l, "modulate:a", 0.0, 0.6)


func set_prompt(text: String, at: Vector2) -> void:
	prompt_l.visible = text != ""
	if text != "":
		prompt_l.text = text
		prompt_l.reset_size()
		prompt_l.position = at - Vector2(prompt_l.size.x / 2, 0)


func _on_day_ended(d: int, earned: int) -> void:
	show_toast("%d일차가 끝났어요. 오늘 번 돈 %d골드. 저장했어요!" % [d, earned])


func _unhandled_input(event: InputEvent) -> void:
	if screen == "title" or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_R:
		toggle_book()
	elif event.keycode == KEY_ESCAPE and panel:
		close_panel()


func close_panel() -> void:
	if panel:
		panel.queue_free()
		panel = null


func is_panel_open() -> bool:
	return panel != null


func _open(p: Control) -> void:
	close_panel()
	panel = p
	root.add_child(p)


func _window(title: String, w: float, h: float) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0.25, 0.15, 0.1, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pc := PanelContainer.new()
	pc.position = Vector2((1408 - w) / 2, (768 - h) / 2)
	pc.custom_minimum_size = Vector2(w, h)
	shade.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	var head := HBoxContainer.new()
	var t := UI.label(title, 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.button("닫기", close_panel))
	vb.add_child(head)
	_open(shade)
	return vb


func toggle_book() -> void:
	if panel and panel.has_meta("book"):
		close_panel()
		return
	var vb := _window("레시피북  %d / %d" % [GameState.known.size(), GameState.RECIPES.size()], 900, 560)
	panel.set_meta("book", true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)
	for r in GameState.RECIPES:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(420, 60)
		var known: bool = GameState.known.has(r.id)
		var ic := UI.icon(Sprites.item(r.id), 56)
		if not known:
			ic.modulate = Color(0.3, 0.2, 0.15, 0.35)
		row.add_child(ic)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.add_child(UI.label(GameState.item_name(r.id) if known else "???", 22))
		var ings := HBoxContainer.new()
		if known:
			for n in r.needs:
				ings.add_child(UI.icon(Sprites.item(n), 28))
		else:
			ings.add_child(UI.label("아직 몰라요. 손님 말을 잘 들어 봐요.", 16, UI.CHESTNUT))
		col.add_child(ings)
		row.add_child(col)
		grid.add_child(row)


func open_shop() -> void:
	var vb := _window("도토리 재료 가게", 760, 600)
	vb.add_child(UI.label("필요한 만큼 골라서 사요. 재료는 상하지 않아요.", 18, UI.CHESTNUT))
	for id in ["flour", "sugar", "butter", "egg", "milk", "chocolate", "cream"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UI.icon(Sprites.item(id), 44))
		var name := UI.label("%s  (%d골드)" % [GameState.item_name(id), GameState.ITEMS[id].price])
		name.custom_minimum_size.x = 260
		row.add_child(name)
		var have := UI.label("가진 것 %d" % GameState.count(id), 18, UI.CHESTNUT)
		have.custom_minimum_size.x = 110
		row.add_child(have)
		var n := SpinBox.new()
		n.min_value = 1
		n.max_value = 20
		n.value = 1
		row.add_child(n)
		var buy := func():
			if GameState.buy(id, int(n.value)):
				have.text = "가진 것 %d" % GameState.count(id)
				show_toast("%s %d개를 샀어요." % [GameState.item_name(id), int(n.value)])
			else:
				show_toast("골드가 모자라요.")
		row.add_child(UI.button("사기", buy, 20))
		vb.add_child(row)
