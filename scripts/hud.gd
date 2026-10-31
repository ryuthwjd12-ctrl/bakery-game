extends CanvasLayer
## 화면 위에 늘 떠 있는 것들: 시계·골드·가게 레벨, 주문 줄, 진열대, 알림, 첫날 안내,
## 그리고 레시피북·재료 가게·일시정지·설정·하루 정산 창.

var main: Node
var root := Control.new()
var clock_l: Label
var gold_l: Label
var level_l: Label
var level_bar: ColorRect
var hp_bar: ColorRect
var mp_bar: ColorRect
var hpmp_l: Label
var orders_panel: PanelContainer
var orders_box: VBoxContainer
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
## 마을 가게 창: 가게 안 그림, 주인 다람쥐, 인사말, 테두리 색이 가게마다 달라요.
var shop_ctx := ""
var shop_bar: HBoxContainer
var go_btn: Button
var open_btn: Button
var decor_btn: Button
var decor_bar: PanelContainer  # 꾸미기(B): 가방에 있는 가구 줄
var hover_rows: Array = []  # 마우스를 올리면 색이 바뀌는 가게 줄
const SHOP_LOOK := {
	"ingredient": {"bg": "shops/ingredient", "keeper": "shops/keeper_ingredient", "color": "#7FA65A", "pitch": 1.0,
		"greet": ["어서 와! 오늘 들어온 밀가루가 아주 고와.", "달걀은 아침에 막 가져온 거야!", "숲에서 주운 호두도 받아 줄게."]},
	"interior": {"bg": "shops/interior", "keeper": "shops/keeper_interior", "color": "#A98BC9", "pitch": 1.15,
		"greet": ["가게를 예쁘게 꾸며 볼까요?", "화분 하나면 분위기가 확 달라져요~", "오늘은 어떤 느낌으로 꾸며 볼까요?"]},
	"furniture": {"bg": "shops/furniture", "keeper": "shops/keeper_furniture", "color": "#A0703F", "pitch": 0.85,
		"greet": ["튼튼하게 만들었지! 탁자 보러 왔나?", "망치질 소리 시끄럽지? 헤헤.", "손님이 많아지면 탁자가 더 필요할걸."]},
	"dish": {"bg": "shops/dish", "keeper": "shops/keeper_dish", "color": "#6FA8C9", "pitch": 1.25,
		"greet": ["예쁜 그릇에 담으면 맛도 두 배예요.", "조심조심, 깨지기 쉬워요!", "새 찻잔이 들어왔어요~"]},
	"weapon": {"bg": "shops/weapon", "keeper": "shops/keeper_weapon", "color": "#C0584A", "pitch": 0.75,
		"greet": ["숲길은 위험해. 든든한 걸로 골라!", "이 뒤집개, 보기보다 세다고!", "비싼 건 다 이유가 있지."]},
	"petal": {"bg": "shops/petal", "keeper": "shops/keeper_petal", "color": "#E8B04A", "pitch": 1.3,
		"greet": ["꽃잎 언덕에 온 걸 환영해!", "오늘 딴 꿀이야, 정말 달아~", "말차 차 한 잔 어때?"]},
	"orchard": {"bg": "shops/orchard", "keeper": "shops/keeper_orchard", "color": "#C0584A", "pitch": 1.2,
		"greet": ["오늘 딴 과일이야, 맛보고 가!", "복숭아가 제일 달 때야~", "과일은 상하지 않으니 넉넉히 사 가."]},
	"beach": {"bg": "shops/beach", "keeper": "shops/keeper_beach", "color": "#5FB5AE", "pitch": 1.1,
		"greet": ["냐옹~ 바닷바람 시원하지?", "초콜릿은 배로 들어온 거야!", "조개는 팔지 않아, 내 보물이거든."]},
	"snow": {"bg": "shops/snow", "keeper": "shops/keeper_snow", "color": "#8FA8D8", "pitch": 1.35,
		"greet": ["어서 와, 안은 따뜻하지?", "얼음 수정 옆에 둔 우유라 아주 시원해!", "눈사람 거인 조심해, 덩치만 커."]},
}

const GUIDE := [
	["order", "손님에게 가서 E(또는 클릭)로 주문 받기"],
	["cook", "주방에서 재료를 골라 만들기 (흐린 그림이 힌트)"],
	["serve", "만든 음식을 손님에게 내주기 (순서는 상관없어요)"],
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
	# 체력·마나
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 6)
	hp_bar = _mini_bar(row3, Color("#E0675A"))
	mp_bar = _mini_bar(row3, Color("#6FA8DC"))
	hpmp_l = UI.label("", 14, Color("#9A8B7A"))
	row3.add_child(hpmp_l)
	tl.add_child(row3)
	root.add_child(top_left)

	top_right = HBoxContainer.new()
	top_right.add_theme_constant_override("separation", 8)
	for b in [["equip", "가방과 장비 (I)", open_bag], ["map", "지도 (M)", open_world_map],
			["achieve", "목표와 친구 (G)", open_goals], ["book", "레시피북 (R)", toggle_book],
			["settings", "메뉴 (Esc)", open_pause]]:
		top_right.add_child(_icon_btn(b[0], b[1], b[2]))
	root.add_child(top_right)
	top_right.reset_size()
	top_right.position = Vector2(1408 - 16 - top_right.size.x, 12)

	# 가게 아래: 홀↔주방 오가기(K), 가게 열기/닫기
	shop_bar = HBoxContainer.new()
	shop_bar.add_theme_constant_override("separation", 10)
	go_btn = UI.button("주방으로 (K)", toggle_kitchen, 20)
	open_btn = UI.button("", toggle_open, 20)
	decor_btn = UI.button("꾸미기 (B)", toggle_decor, 20)
	shop_bar.add_child(go_btn)
	shop_bar.add_child(open_btn)
	shop_bar.add_child(decor_btn)
	root.add_child(shop_bar)
	decor_bar = PanelContainer.new()
	decor_bar.add_theme_stylebox_override("panel", UI.box(Color(1, 0.98, 0.93, 0.95), UI.OUTLINE, 14, 2))
	decor_bar.visible = false
	root.add_child(decor_bar)

	orders_panel = PanelContainer.new()
	orders_panel.add_theme_stylebox_override("panel", UI.box(Color(1, 0.98, 0.93, 0.92), UI.OUTLINE, 14, 2))
	orders_box = VBoxContainer.new()
	orders_box.add_theme_constant_override("separation", 6)
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
	_refresh_shop_bar()
	set_prompt("", Vector2.ZERO)
	refresh()


func _mini_bar(parent: Control, col: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color("#EADFCB")
	bg.custom_minimum_size = Vector2(90, 8)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bar := ColorRect.new()
	bar.color = col
	bar.size = Vector2(90, 8)
	bg.add_child(bar)
	parent.add_child(bg)
	return bar


func _refresh_shop_bar() -> void:
	shop_bar.visible = screen == "hall" or screen == "kitchen"
	decor_btn.visible = screen == "hall"
	if screen != "hall" and decor_bar.visible:
		_end_decor()
	go_btn.text = "홀로 (K)" if screen == "kitchen" else "주방으로 (K)"
	open_btn.text = "영업 중  ●" if GameState.shop_open else "준비 중  ○"
	open_btn.add_theme_color_override("font_color", Color("#4F9A55") if GameState.shop_open else Color("#9A8B7A"))
	open_btn.tooltip_text = "누르면 가게 문을 닫아요(손님이 더 오지 않아요)" if GameState.shop_open else "누르면 가게 문을 열어요"
	shop_bar.reset_size()
	# 주방에서는 조합 칸을 가리지 않게 조리대 위에 둬요
	shop_bar.position = Vector2((1408 - shop_bar.size.x) / 2, 470 if screen == "kitchen" else 768 - 16 - shop_bar.size.y)


## 꾸미기(B): 산 가구를 골라 가게에 직접 놓고, 놓은 가구를 눌러 옮겨요.
func toggle_decor() -> void:
	if screen != "hall":
		return
	if decor_bar.visible:
		_end_decor()
		return
	main.hall.set_edit(true)
	decor_bar.visible = true
	orders_panel.visible = false
	refresh_decor_bar()
	show_toast("가구를 골라 바닥을 누르면 놓여요. 놓은 가구를 누르면 다시 들어요. 오른쪽 클릭은 취소.")


func _end_decor() -> void:
	decor_bar.visible = false
	orders_panel.visible = true
	if main.hall:
		main.hall.set_edit(false)


func refresh_decor_bar() -> void:
	if not decor_bar.visible:
		return
	for c in decor_bar.get_children():
		c.queue_free()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.label("꾸미기", 20))
	var any := false
	for id in GameState.FURNITURE:
		var n := int(GameState.furn_inv.get(id, 0))
		if n <= 0:
			continue
		any = true
		var f: Dictionary = GameState.FURNITURE[id]
		var b := Button.new()
		b.icon = Sprites.tex(f.icon)
		b.expand_icon = true
		b.custom_minimum_size = Vector2(150, 64)
		b.text = "%s x%d" % [f.name, n]
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(func(): main.hall.hold(id))
		row.add_child(b)
	if not any:
		row.add_child(UI.label("가방에 가구가 없어요. 마을 가구점·인테리어점에서 사요.", 16, UI.CHESTNUT))
	row.add_child(UI.button("가방에 넣기", func(): main.hall.store_held(), 18))
	row.add_child(UI.button("다 했어요", _end_decor, 18))
	decor_bar.add_child(row)
	await get_tree().process_frame
	decor_bar.reset_size()
	decor_bar.position = Vector2((1408 - decor_bar.size.x) / 2, 768 - 80 - decor_bar.size.y)


## 홀과 주방을 바로 오가요(K)
func toggle_kitchen() -> void:
	if screen == "hall":
		main.goto("kitchen", "hall")
	elif screen == "kitchen":
		main.goto("hall", "kitchen")


func toggle_open() -> void:
	GameState.shop_open = not GameState.shop_open
	Audio.sfx("door")
	show_toast("가게 문을 열었어요. 손님이 와요!" if GameState.shop_open else "가게 문을 닫았어요. 이미 온 손님은 끝까지 대접해요.")
	_refresh_shop_bar()
	GameState.save_game()


func refresh() -> void:
	_tick()
	_refresh_shop_bar()
	hp_bar.size.x = 90.0 * clampf(float(GameState.hp) / GameState.max_hp(), 0, 1)
	mp_bar.size.x = 90.0 * clampf(float(GameState.mp) / GameState.max_mp(), 0, 1)
	hpmp_l.text = "체력 %d  마나 %d" % [GameState.hp, GameState.mp]
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
			ob[1].size.x = 100.0 * f
			ob[1].color = UI.PINK if f > 0.3 else Color("#D9534F")


func _refresh_orders() -> void:
	for c in orders_box.get_children():
		orders_box.remove_child(c)
		c.queue_free()
	order_bars.clear()
	orders_panel.visible = _playing() and not GameState.orders.is_empty()
	if not orders_panel.visible:
		return
	orders_box.add_child(UI.label("받은 주문", 17, UI.CHESTNUT))
	for i in GameState.orders.size():
		var t = GameState.orders[i]
		if not is_instance_valid(t):
			continue
		var card := PanelContainer.new()
		var first := i == 0
		card.add_theme_stylebox_override("panel", UI.box(Color.WHITE if first else Color("#FFFBF2"), UI.PINK if first else Color("#D8C6A8"), 10, 3 if first else 2))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		hb.add_child(UI.label(str(i + 1), 18, UI.PINK if first else UI.OUTLINE))
		hb.add_child(UI.icon(Sprites.first_frame(t.kind + "_front"), 40))
		for id in t.wanted():
			var ic := UI.icon(Sprites.item(id), 42)
			if GameState.stock.get(id, 0) <= 0:
				ic.modulate = Color(1, 1, 1, 0.45)  # 아직 안 만든 메뉴는 흐리게
			hb.add_child(ic)
		vb.add_child(hb)
		var bg := ColorRect.new()
		bg.color = Color("#EADFCB")
		bg.custom_minimum_size = Vector2(100, 7)
		bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var bar := ColorRect.new()
		bar.color = UI.PINK
		bar.size = Vector2(100, 7)
		bg.add_child(bar)
		vb.add_child(bg)
		card.add_child(vb)
		orders_box.add_child(card)
		order_bars.append([t, bar])
	orders_panel.reset_size()
	orders_panel.position = Vector2(1408 - 16 - orders_panel.size.x, 88)


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
	guide_panel.visible = _playing() and screen != "field" and screen != "village" and not GameState.tutorial_done()
	if not guide_panel.visible:
		return
	guide_box.add_child(UI.label("첫 영업 안내", 20, UI.PINK))
	for g in GUIDE:
		var done: bool = GameState.tutorial.has(g[0])
		guide_box.add_child(UI.label(("✓ " if done else "○ ") + g[1], 17, Color("#9A8B7A") if done else UI.OUTLINE))
	guide_panel.reset_size()
	if screen == "kitchen":
		guide_panel.position = Vector2(16, 120)  # 주방은 오른쪽에 주문 순서와 오븐이 있어서 왼쪽에
	else:
		guide_panel.position = Vector2(1408 - 16 - guide_panel.size.x, 768 - 16 - guide_panel.size.y)


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
	elif (event.keycode == KEY_K or event.keycode == KEY_TAB) and not get_tree().paused and not panel and (screen == "hall" or screen == "kitchen"):
		toggle_kitchen()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_B and not get_tree().paused and not panel and screen == "hall":
		toggle_decor()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_I and not get_tree().paused:
		if panel:
			close_panel()
		else:
			open_bag()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_G and not get_tree().paused:
		if panel:
			close_panel()
		else:
			open_goals()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_M and not get_tree().paused:
		if panel:
			close_panel()
		else:
			open_world_map()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		if panel and not panel.has_meta("locked"):
			close_panel()
		elif panel and panel.has_meta("pause"):
			close_panel()
		elif not panel:
			open_pause()
		get_viewport().set_input_as_handled()


func close_panel(keep_shop := false) -> void:
	if panel:
		panel.queue_free()
		panel = null
	if not keep_shop:
		shop_ctx = ""
	get_tree().paused = false


func is_panel_open() -> bool:
	return panel != null


## 가운데에 뜨는 창을 만들어요.
func window(title: String, w: float, closable := true) -> VBoxContainer:
	var reopen := panel != null
	close_panel(true)
	var shade := ColorRect.new()
	shade.color = Color(0.25, 0.15, 0.1, 0.4)
	shade.size = Vector2(1408, 768)
	if shop_ctx != "":
		_shop_scene(shade, reopen)
	var pc := PanelContainer.new()
	if shop_ctx != "":
		pc.set_meta("right", true)
		pc.add_theme_stylebox_override("panel", UI.box(Color(1, 0.98, 0.93, 0.97), Color(SHOP_LOOK[shop_ctx].color), 18, 4))
	pc.custom_minimum_size = Vector2(w, 0)
	shade.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	var head := HBoxContainer.new()
	var t := UI.label(title, 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if shop_ctx != "":
		# 가게 안에서는 가진 골드를 늘 보여 줘요
		var g := UI.label("가진 골드  %d" % GameState.gold, 22, Color("#B8741A"))
		g.add_theme_stylebox_override("normal", UI.box(Color("#FFF6DC"), Color("#E8B04A"), 10, 2))
		head.add_child(g)
	if closable:
		head.add_child(UI.button("닫기", close_panel, 18))
	else:
		shade.set_meta("locked", true)
	vb.add_child(head)
	panel = shade
	root.add_child(shade)
	_center.call_deferred(pc)
	return vb


## 마우스를 올린 줄을 다른 색으로 보여 줘요. 줄을 감싼 판을 돌려줘요.
func _hl(row: Control) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UI.box(Color(1, 1, 1, 0), Color(1, 1, 1, 0), 10, 0))
	pc.set_meta("hl", true)
	pc.add_child(row)
	hover_rows.append(pc)
	return pc


func _process(_delta: float) -> void:
	if hover_rows.is_empty():
		return
	var m := root.get_global_mouse_position()
	for pc in hover_rows.duplicate():
		if not is_instance_valid(pc):
			hover_rows.erase(pc)
			continue
		var on: bool = pc.get_global_rect().has_point(m)
		if on != pc.get_meta("on", false):
			pc.set_meta("on", on)
			var col: Color = Color(SHOP_LOOK[shop_ctx].color) if SHOP_LOOK.has(shop_ctx) else UI.PINK
			pc.add_theme_stylebox_override("panel", UI.box(Color(col, 0.16) if on else Color(1, 1, 1, 0), Color(col, 0.7) if on else Color(1, 1, 1, 0), 10, 2 if on else 0))


func _center(pc: Control) -> void:
	if is_instance_valid(pc):
		pc.reset_size()
		pc.position = (Vector2(1408, 768) - pc.size) / 2
		if pc.has_meta("right"):
			pc.position.x = 1408 - pc.size.x - 28


## 가게 창 뒤: 가게 안 그림과 주인. 처음 들어오면 인사하고, 사고팔면(창이 다시 그려지면) 웃으며 폴짝 뛰어요.
## 동그란 그림 버튼. 마우스를 올리면 살짝 커지고 이름이 떠요.
func _icon_btn(icon: String, tip: String, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = Sprites.tex("ui/btn_" + icon)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(68, 68)
	b.pivot_offset = Vector2(34, 34)
	b.tooltip_text = tip
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): b.scale = Vector2(1.08, 1.08))
	b.mouse_exited.connect(func(): b.scale = Vector2.ONE)
	return b


func _shop_scene(shade: ColorRect, reopen: bool) -> void:
	var look: Dictionary = SHOP_LOOK[shop_ctx]
	shade.color = Color.BLACK
	var bg := TextureRect.new()
	bg.texture = Sprites.tex(look.bg)
	bg.size = Vector2(1408, 768)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.15, 0.1, 0.18)
	dim.size = Vector2(1408, 768)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(dim)
	var key: String = look.keeper
	if reopen and look.has("happy"):
		key = look.happy
	elif reopen and ResourceLoader.exists("res://assets/%s_happy.png" % key):
		key += "_happy"
	var tex := Sprites.tex(key)
	var k := TextureRect.new()
	k.texture = tex
	k.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	k.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var h := 420.0
	k.size = Vector2(h * tex.get_width() / tex.get_height(), h)
	k.position = Vector2(60, 768 - h - 10)
	k.pivot_offset = Vector2(k.size.x / 2, h)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(k)
	var tw := k.create_tween()
	if reopen:
		tw.tween_property(k, "position:y", k.position.y - 24, 0.12).set_ease(Tween.EASE_OUT)
		tw.tween_property(k, "position:y", k.position.y, 0.16).set_ease(Tween.EASE_IN)
	else:
		k.scale = Vector2(0.9, 0.9)
		tw.tween_property(k, "scale", Vector2(1.04, 0.97), 0.14)
		tw.tween_property(k, "scale", Vector2.ONE, 0.12)
		Audio.sfx("order", look.pitch)
		var say := UI.label(look.greet.pick_random(), 20)
		say.add_theme_stylebox_override("normal", UI.box(Color("#FFFDF6"), Color(look.color), 16, 3))
		say.custom_minimum_size = Vector2(0, 0)
		say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		say.size = Vector2(300, 0)
		say.position = Vector2(50, 768 - h - 110)
		say.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.add_child(say)
		say.modulate.a = 0.0
		var t2 := say.create_tween()
		t2.tween_property(say, "modulate:a", 1.0, 0.2)


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
	# 레시피가 많아서 창 안에서 굴려 봐요(휠 또는 끌기)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(grid)
	vb.add_child(sc)
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


## 가게 칠판 메뉴판: 오늘 손님이 시킬 수 있는 메뉴와 값, 진열대에 몇 개 있는지
func open_menu_board() -> void:
	Audio.sfx("click")
	var vb := window("오늘의 메뉴", 640)
	vb.add_child(UI.label("가게 레벨이 오르면 메뉴가 늘어요. 진열대에 없는 메뉴는 주방에서 만들어요.", 16, UI.CHESTNUT))
	for id in GameState.menu_now():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UI.icon(Sprites.item(id), 52))
		var nm := UI.label("%s  %d골드" % [GameState.item_name(id), GameState.ITEMS[id].price], 22)
		nm.custom_minimum_size.x = 300
		row.add_child(nm)
		var n: int = GameState.stock.get(id, 0)
		row.add_child(UI.label("진열대 %d개" % n, 18, Color("#4F9A55") if n > 0 else Color("#C0584A")))
		vb.add_child(_hl(row))


const SELL_RATE := 0.3  # 되팔 때는 산 값의 30%


static func sell_price(price: int) -> int:
	return maxi(1, int(price * SELL_RATE))


## 재료 가게: 사기와 팔기. 그 가게가 다루는 물건만 사고팔 수 있어요.
func open_trade(title: String, items: Array, selling := false) -> void:
	if not panel:
		Audio.sfx("door")
	var vb := window(title, 820)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	var buy_b := UI.button("사기", func(): open_trade(title, items, false), 20)
	var sell_b := UI.button("팔기", func(): open_trade(title, items, true), 20)
	(sell_b if selling else buy_b).add_theme_color_override("font_color", UI.PINK)
	tabs.add_child(buy_b)
	tabs.add_child(sell_b)
	var hint := UI.label("  되팔 때는 산 값의 30%만 받아요." if selling else "  재료는 상하지 않아요.", 16, UI.CHESTNUT)
	tabs.add_child(hint)
	vb.add_child(tabs)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	for id in items:
		list.add_child(_hl(_trade_row(id, selling, func(): open_trade(title, items, selling))))
	if items.size() > 7:
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(0, 470)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(list)
		vb.add_child(sc)
	else:
		vb.add_child(list)


func _trade_row(id: String, selling: bool, reopen: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.icon(Sprites.item(id), 46))
	var price: int = GameState.ITEMS[id].price
	var unit := sell_price(price) if selling else price
	var name := UI.label("%s  (%d골드)" % [GameState.item_name(id), unit])
	name.custom_minimum_size.x = 260
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
	var act := func():
		if selling:
			if GameState.count(id) < n.v:
				Audio.sfx("fail")
				show_toast("가진 것이 모자라요.")
				return
			GameState.inv[id] = GameState.count(id) - n.v
			GameState.earn(unit * n.v)
			Audio.sfx("coin")
			show_toast("%s %d개를 팔았어요. (+%d골드)" % [GameState.item_name(id), n.v, unit * n.v])
		elif GameState.buy(id, n.v):
			Audio.sfx("coin")
			show_toast("%s %d개를 샀어요." % [GameState.item_name(id), n.v])
		else:
			Audio.sfx("fail")
			show_toast("골드가 모자라요.")
			return
		GameState.changed.emit()
		reopen.call()
	row.add_child(UI.button("-", minus, 20))
	row.add_child(n_l)
	row.add_child(UI.button("+", plus, 20))
	row.add_child(UI.button("팔기" if selling else "사기", act, 20))
	return row


## 무기 상점: 비쌀수록 센 무기. 산 무기는 바로 장착하고, 안 쓰는 무기는 되팔 수 있어요.
func open_weapon_shop() -> void:
	if not panel:
		Audio.sfx("door")
	var vb := window("다람쥐 무기점", 860)
	vb.add_child(UI.label("근접 무기는 앞으로 휘두르고, 마법 무기는 반짝이를 멀리 쏴요(마나 사용). 되팔면 30%.", 16, UI.CHESTNUT))
	for id in GameState.WEAPONS:
		var w: Dictionary = GameState.WEAPONS[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UI.icon(Sprites.tex(w.icon), 50))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.label("%s  (%s)" % [w.name, "%d골드" % w.price if w.price > 0 else "기본"], 20))
		var info := "근접 · 공격력 %d" % w.power if w.type == "melee" else "마법 · 공격력 %d · 마나 %d" % [w.power, w.mp]
		col.add_child(UI.label(info, 15, Color("#9A8B7A")))
		row.add_child(col)
		var owned: bool = GameState.weapons.has(id)
		if GameState.weapon == id:
			row.add_child(UI.label("장착 중", 18, UI.PINK))
		elif owned:
			row.add_child(UI.button("장착", func():
				GameState.weapon = id
				Audio.sfx("pick")
				GameState.changed.emit()
				open_weapon_shop(), 18))
			if w.price > 0:
				row.add_child(UI.button("팔기 %d" % sell_price(w.price), func():
					GameState.weapons.erase(id)
					GameState.earn(sell_price(w.price))
					Audio.sfx("coin")
					open_weapon_shop(), 18))
		else:
			row.add_child(UI.button("사기", func():
				if GameState.gold < w.price:
					Audio.sfx("fail")
					show_toast("골드가 모자라요.")
					return
				GameState.gold -= w.price
				GameState.today.spent = GameState.today.get("spent", 0) + w.price
				GameState.weapons.append(id)
				GameState.weapon = id
				GameState.changed.emit()
				GameState.save_game()
				Audio.sfx("coin")
				show_toast("%s을(를) 샀어요! 바로 장착했어요." % w.name)
				open_weapon_shop(), 18))
		vb.add_child(_hl(row))


## 목표: 해낸 것은 ★, 남은 것은 ☆. 해내면 바로 골드를 받아요. 친한 주민 하트도 여기서 봐요.
func open_goals() -> void:
	var vb := window("목표와 친구", 860)
	var done := 0
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	for g in GameState.goal_list():
		var ok: bool = GameState.goals_done.has(g[0])
		done += 1 if ok else 0
		var l := UI.label("%s %s  (+%d골드)" % ["★" if ok else "☆", g[1], g[2]], 17, UI.PINK if ok else UI.OUTLINE)
		grid.add_child(l)
	vb.add_child(UI.label("해낸 목표 %d / %d" % [done, GameState.goal_list().size()], 18, UI.CHESTNUT))
	vb.add_child(grid)
	vb.add_child(UI.label("친한 주민 (하루 한 번 인사 +1, 음식 선물 +3, 하트가 늘면 선물과 팁이 늘어요)", 17, UI.CHESTNUT))
	var keys: Array = GameState.friends.keys()
	keys.sort_custom(func(a, b): return GameState.friends[a] > GameState.friends[b])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	if keys.is_empty():
		row.add_child(UI.label("아직 인사한 주민이 없어요. 마을 주민에게 다가가 E를 눌러 봐요!", 16, Color("#9A8B7A")))
	for k in keys.slice(0, 6):
		var col := VBoxContainer.new()
		col.add_child(UI.icon(Sprites.first_frame(k + "_front"), 56))
		col.add_child(UI.label(GameState.heart_text(k), 14, UI.PINK))
		row.add_child(col)
	vb.add_child(row)


## 가방: 체력·마나, 무기 바꾸기, 모은 재료
func open_bag() -> void:
	var vb := window("가방", 760)
	vb.add_child(UI.label("체력 %d / %d    마나 %d / %d    (자고 나면 다 차요)" % [GameState.hp, GameState.max_hp(), GameState.mp, GameState.max_mp()], 18))
	vb.add_child(UI.label("무기  (숲에서 스페이스 또는 오른쪽 클릭으로 공격)", 20, UI.PINK))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	for id in GameState.weapons:
		var w: Dictionary = GameState.WEAPONS[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 110)
		b.icon = Sprites.tex(w.icon)
		b.expand_icon = true
		b.tooltip_text = w.name
		if GameState.weapon == id:
			b.add_theme_stylebox_override("normal", UI.box(Color("#FFE9EC"), UI.PINK, 14, 4))
		b.pressed.connect(func():
			GameState.weapon = id
			Audio.sfx("pick")
			GameState.changed.emit()
			open_bag())
		grid.add_child(b)
	vb.add_child(grid)
	var w0: Dictionary = GameState.WEAPONS[GameState.weapon]
	vb.add_child(UI.label("장착: %s (%s, 공격력 %d)" % [w0.name, "근접" if w0.type == "melee" else "마법", w0.power], 18))
	vb.add_child(UI.label("모은 재료", 20, UI.PINK))
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 10)
	for id in ["walnut", "acorn", "matcha", "honey_jar", "apple", "milk", "chocolate", "raspberry"]:
		if GameState.count(id) > 0:
			var cell := HBoxContainer.new()
			cell.add_child(UI.icon(Sprites.item(id), 36))
			cell.add_child(UI.label("×%d" % GameState.count(id), 18))
			items.add_child(cell)
	if items.get_child_count() == 0:
		items.add_child(UI.label("아직 없어요. 숲의 몬스터가 재료를 떨어뜨려요.", 16, Color("#9A8B7A")))
	vb.add_child(items)


## 세계 지도(M)
func open_world_map() -> void:
	var vb := window("세계 지도", 900)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(860, 606)
	var tr := TextureRect.new()
	tr.texture = Sprites.tex("maps/world_map")
	tr.size = Vector2(860, 606)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	holder.add_child(tr)
	var here: String = main.current_name if main.current_name != "field" else main.current.area_id
	if here == "hall" or here == "kitchen":
		here = "village"
	for w in Areas.WORLD:
		var l := UI.label(w[0], 16 if w[2] != "" else 13, UI.OUTLINE if w[2] != "" else Color("#9A8B7A"))
		l.add_theme_stylebox_override("normal", UI.box(Color(1, 0.98, 0.9, 0.9), UI.PINK if w[2] == here else Color("#D8C6A8"), 8, 3 if w[2] == here else 1))
		holder.add_child(l)
		l.reset_size()
		l.position = w[1] - Vector2(l.size.x / 2, 0)
	vb.add_child(holder)
	vb.add_child(UI.label("마을 가장자리 길로 나가면 숲길이에요. 숲에는 몬스터가 있어요. 북: 꽃잎 언덕 · 동: 조개 해변 · 남: 사과 과수원 · 서: 눈꽃 마을", 15, UI.CHESTNUT))


## 한 개씩 사는 가게(가구점, 도구점). entries: {icon, name, price, note, block: Callable -> String, buy: Callable}
func open_store(title: String, desc: String, entries: Array) -> void:
	if not panel:
		Audio.sfx("door")
	var vb := window(title, 820)
	vb.add_child(UI.label(desc, 18, UI.CHESTNUT))
	for e in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(UI.icon(e.icon, 64))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.label(e.name if e.price == 0 else "%s  (%d골드)" % [e.name, e.price], 22))
		col.add_child(UI.label(e.note, 16, Color("#9A8B7A")))
		row.add_child(col)
		var why: String = e.block.call()
		if why != "":
			row.add_child(UI.label(why, 18, Color("#9A8B7A")))
		else:
			var buy := func():
				if GameState.gold < e.price:
					Audio.sfx("fail")
					show_toast("골드가 모자라요.")
					return
				GameState.gold -= e.price
				GameState.today.spent = GameState.today.get("spent", 0) + e.price
				e.buy.call()
				GameState.changed.emit()
				GameState.save_game()
				Audio.sfx("coin")
				open_store(title, desc, entries)
			row.add_child(UI.button("팔기" if e.price == 0 else "사기", buy, 20))
		vb.add_child(_hl(row))


## 부탁 손님 이야기 창: 얼굴, 사연, 스페셜 요리와 레시피
func open_quest(q: Dictionary, accept: Callable, decline: Callable) -> void:
	Audio.sfx("sparkle")
	var vb := window("부탁 손님", 760, false)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	hb.add_child(UI.icon(Sprites.first_frame(q.kind + "_front"), 120))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var story := UI.label(q.story, 20)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.custom_minimum_size.x = 580
	col.add_child(story)
	col.add_child(UI.label("스페셜 요리: %s" % GameState.item_name(q.dish), 22, UI.PINK))
	var rec := HBoxContainer.new()
	rec.add_theme_constant_override("separation", 4)
	var needs: Array = GameState.recipe(q.dish).needs
	for i in needs.size():
		rec.add_child(UI.icon(Sprites.item(needs[i]), 44))
		if i < needs.size() - 1:
			rec.add_child(UI.label("+", 22, UI.CHESTNUT))
	rec.add_child(UI.label("  →  ", 22, UI.CHESTNUT))
	rec.add_child(UI.icon(Sprites.item(q.dish), 52))
	col.add_child(rec)
	col.add_child(UI.label("사례: %d골드, 평판 +%d" % [q.reward, q.rep], 18, Color("#B8741A")))
	hb.add_child(col)
	vb.add_child(hb)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 24)
	btns.add_child(UI.button("만들어 줄게요", func():
		close_panel()
		accept.call(), 22))
	btns.add_child(UI.button("오늘은 어려워요", func():
		close_panel()
		decline.call(), 22))
	vb.add_child(btns)


## 확인 버튼 하나뿐인 알림 창
func notice(title: String, text: String) -> void:
	var vb := window(title, 600)
	var l := UI.label(text, 20)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 560
	vb.add_child(l)
	var b := UI.button("확인", close_panel, 22)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(b)


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


func _ledger_row(name: String, n: int, bold := false) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var l := UI.label(name, 22 if bold else 19)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	var col := Color("#5E9E5A") if n > 0 else (Color("#C9514A") if n < 0 else UI.OUTLINE)
	hb.add_child(UI.label("%s%d골드" % ["+" if n > 0 else "", n], 22 if bold else 19, col))
	return hb


func _on_day_ended(s: Dictionary) -> void:
	Audio.sfx("sparkle")
	var vb := window("%d일차 경영 일지" % GameState.day, 760, false)
	get_tree().paused = true
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	vb.add_child(cols)
	# 왼쪽: 돈
	var money := VBoxContainer.new()
	money.custom_minimum_size = Vector2(330, 0)
	money.add_child(UI.label("오늘의 장부", 22, UI.PINK))
	var tips: int = s.get("tips", 0)
	var spent: int = s.get("spent", 0)
	var sales: int = s.earned - tips
	var net: int = s.earned - spent
	for row in [["판매 수입", sales], ["팁", tips], ["재료비", -spent]]:
		money.add_child(_ledger_row(row[0], row[1]))
	money.add_child(HSeparator.new())
	money.add_child(_ledger_row("하루 순수익", net, true))
	money.add_child(UI.label("가진 돈  %d골드" % GameState.gold, 18, Color("#9A8B7A")))
	cols.add_child(money)
	# 오른쪽: 손님과 가게
	var shop := VBoxContainer.new()
	shop.custom_minimum_size = Vector2(330, 0)
	shop.add_child(UI.label("가게 상태", 22, UI.PINK))
	shop.add_child(UI.label("만족한 손님  %d명   화난 손님  %d명" % [s.served, s.lost], 18))
	var rep_d: int = GameState.rep - int(s.get("rep_start", GameState.rep))
	shop.add_child(UI.label("평판  %s%d   (가게 Lv.%d)" % ["+" if rep_d >= 0 else "", rep_d, GameState.level()], 18))
	shop.add_child(UI.label("새로 찾은 레시피  %d개" % s.new, 18))
	if s.has("quest"):
		shop.add_child(UI.label("스페셜 요리 성공: %s" % GameState.item_name(s.quest), 18, UI.PINK))
	var sold: Dictionary = s.get("sold", {})
	if not sold.is_empty():
		shop.add_child(UI.label("팔린 메뉴", 18, UI.CHESTNUT))
		var grid := HBoxContainer.new()
		grid.add_theme_constant_override("separation", 10)
		for id in sold:
			var cell := HBoxContainer.new()
			cell.add_child(UI.icon(Sprites.item(id), 34))
			cell.add_child(UI.label("×%d" % sold[id], 18))
			grid.add_child(cell)
		shop.add_child(grid)
	cols.add_child(shop)
	var next := func():
		close_panel()
		main.new_day()
	vb.add_child(UI.button("다음 날 (저장)", next, 24))
