extends Control
## 주방 화면. 그릇장·냉장고·냉동고·찬장을 눌러 재료와 그릇을 고르면 아래 조합 칸으로 날아가요.
## "굽기"(음료는 "만들기")를 누르면 맞는 조합일 때 바로 완성돼서 진열대에 놓여요. 좌표는 주방 그림(1408x768) 기준이에요.

var main: Node

const FURNITURE := {
	"cabinet": {"tex": "kitchen/cabinet", "pos": Vector2(84, 58)},
	"fridge": {"tex": "kitchen/fridge", "pos": Vector2(470, 170)},
	"pantry": {"tex": "kitchen/pantry", "pos": Vector2(730, 120)},
}
## 누를 수 있는 곳(냉장고는 위 칸이 냉동고)
const HOTSPOTS := {
	"cabinet": Rect2(100, 64, 360, 386),
	"freezer": Rect2(476, 176, 224, 134),
	"fridge": Rect2(476, 312, 224, 140),
	"pantry": Rect2(736, 124, 234, 328),
}
const PANEL_STYLE := {
	"cabinet": ["#FBF3E3", "#8E5A3A"], "fridge": ["#F1F8FB", "#7FB2CF"],
	"freezer": ["#E8F3FA", "#A9CFE8"], "pantry": ["#F7EDCB", "#8E5A3A"],
}
const SLOT_X := [42, 242, 440, 638, 838, 1036]
const SLOT_Y := 562
const SLOT_SIZE := Vector2(170, 165)
const OK_RECT := Rect2(1245, 580, 120, 120)
const OVEN_MOUTH := Rect2(1145, 250, 170, 112)

var slots: Array = []
var slot_icons: Array = []
var ghost_icons: Array = []
var furn_sprites := {}
var popup: PanelContainer
var popup_kind := ""
var catcher: Control  # 창 바깥을 누르면 닫히게 깔아 두는 투명한 판
var ok_l: Label
var oven_glow: ColorRect
var msg_l: Label
var _t := 0.0
var _quiet := false


func _ready() -> void:
	size = Vector2(1408, 768)
	theme = UI.make_theme()
	add_child(UI.bg(Sprites.tex("backgrounds/kitchen")))

	for k in FURNITURE:
		var tr := TextureRect.new()
		tr.texture = Sprites.tex(FURNITURE[k].tex)
		tr.position = FURNITURE[k].pos
		tr.size = tr.texture.get_size()
		tr.pivot_offset = Vector2(tr.size.x / 2, tr.size.y)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		furn_sprites[k] = tr
	for k in HOTSPOTS:
		var b := UI.hotspot(HOTSPOTS[k], _open_storage.bind(k))
		b.mouse_entered.connect(_hover.bind(k, true))
		b.mouse_exited.connect(_hover.bind(k, false))
		b.tooltip_text = GameState.STORAGE[k].name
		add_child(b)
	# 냉장고는 위 칸(냉동고)과 아래 칸(냉장고)을 따로 눌러요: 문마다 이름표를 붙여 둬요
	for k in ["freezer", "fridge"]:
		var r: Rect2 = HOTSPOTS[k]
		var tag := UI.label(GameState.STORAGE[k].name, 16, Color("#4A7A99"))
		tag.add_theme_stylebox_override("normal", UI.box(Color(1, 1, 1, 0.85), Color(PANEL_STYLE[k][1]), 8, 2))
		tag.position = r.position + Vector2(r.size.x - 86, r.size.y - 34)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tag)

	oven_glow = ColorRect.new()
	oven_glow.position = OVEN_MOUTH.position
	oven_glow.size = OVEN_MOUTH.size
	oven_glow.color = Color(1.0, 0.6, 0.2, 0.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	oven_glow.material = mat
	oven_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(oven_glow)

	for i in SLOT_X.size():
		var r := Rect2(Vector2(SLOT_X[i], SLOT_Y), SLOT_SIZE)
		var g := UI.icon(null, 92)
		g.position = r.position + (r.size - Vector2(92, 92)) / 2
		g.modulate = Color(0.25, 0.15, 0.1, 0.32)
		add_child(g)
		ghost_icons.append(g)
		var ic := UI.icon(null, 92)
		ic.position = g.position
		ic.pivot_offset = Vector2(46, 46)
		add_child(ic)
		slot_icons.append(ic)
		add_child(UI.hotspot(r, _remove_slot.bind(i)))

	var ok := UI.label("굽기", 28)
	ok_l = ok
	ok.position = OK_RECT.position
	ok.size = OK_RECT.size
	ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ok.pivot_offset = OK_RECT.size / 2
	ok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ok)
	add_child(UI.hotspot(OK_RECT, _cook.bind(ok)))

	# 쓰레기통: 칸만 비우고 재료는 그대로 돌아가요
	var clear := Button.new()
	clear.icon = Sprites.tex("ui/trash")
	clear.expand_icon = true
	clear.custom_minimum_size = Vector2(52, 52)
	clear.tooltip_text = "칸 비우기 (재료는 그대로)"
	clear.position = Vector2(1352, 520)
	clear.pressed.connect(func():
		_bounce(clear, 0.15)
		_clear_slots())
	add_child(clear)


	msg_l = UI.label("", 24)
	msg_l.add_theme_stylebox_override("normal", UI.box(Color("#FFF8E6"), UI.PINK))
	msg_l.position = Vector2(300, 520)
	msg_l.modulate.a = 0.0
	msg_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(msg_l)


	# 받은 부탁이 있으면 위쪽에 스페셜 요리를 보여 줘요
	if GameState.active_quest != "":
		var q := GameState.quest(GameState.active_quest)
		var banner := PanelContainer.new()
		banner.add_theme_stylebox_override("panel", UI.box(Color(1, 0.97, 0.88, 0.95), Color("#E8A33D"), 14, 3))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		hb.add_child(UI.label("★ 스페셜 요리: %s  " % GameState.item_name(q.dish), 22, Color("#B8741A")))
		for n in GameState.recipe(q.dish).needs:
			hb.add_child(UI.icon(Sprites.item(n), 34))
		banner.add_child(hb)
		add_child(banner)
		banner.reset_size()
		banner.position = Vector2((1408 - banner.size.x) / 2, 12)
	GameState.changed.connect(_refresh)
	_refresh()
	Audio.play_bgm("bgm_shop")


func _process(_delta: float) -> void:
	_t += _delta
	# 컵이 들어가면 음료라서 "만들기", 아니면 "굽기"
	ok_l.text = "만들기" if slots.has("mug") else "굽기"
	oven_glow.color.a = maxf(0.0, oven_glow.color.a - _delta * 0.6)


func _hover(k: String, on: bool) -> void:
	var key := "fridge" if k == "freezer" else k
	furn_sprites[key].modulate = Color(1.08, 1.06, 1.0) if on else Color.WHITE


func _bounce(c: Control, amount := 0.06) -> void:
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.0 + amount, 1.0 - amount), 0.07)
	tw.tween_property(c, "scale", Vector2(1.0 - amount * 0.5, 1.0 + amount * 0.5), 0.07)
	tw.tween_property(c, "scale", Vector2.ONE, 0.08)


## 가구는 배경 그림 위에 같은 그림을 얹은 거라, 줄어들지 않고 살짝 커졌다 돌아와요.
func _grow(c: Control) -> void:
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.04, 1.025), 0.07)
	tw.tween_property(c, "scale", Vector2(1.01, 1.035), 0.07)
	tw.tween_property(c, "scale", Vector2.ONE, 0.09)


func _open_storage(k: String) -> void:
	if not _quiet:
		Audio.sfx("click")
		_grow(furn_sprites["fridge" if k == "freezer" else k])
		if popup_kind == k:
			_close_popup()
			return
	_close_popup()
	popup_kind = k
	catcher = Control.new()
	catcher.size = Vector2(1408, 768)
	catcher.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_close_popup()
			accept_event())
	add_child(catcher)
	var st: Array = PANEL_STYLE[k]
	popup = PanelContainer.new()
	popup.add_theme_stylebox_override("panel", UI.box(Color(st[0]), Color(st[1]), 18, 4))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	popup.add_child(vb)
	var head := HBoxContainer.new()
	var title := UI.label(GameState.STORAGE[k].name, 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UI.button("닫기", _close_popup, 18))
	vb.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(grid)
	for id in GameState.STORAGE[k].items:
		grid.add_child(_item_card(id))
	if k == "freezer":
		vb.add_child(UI.label("마을 덤불에서 딴 산딸기는 여기 얼려 둬요.", 16, UI.CHESTNUT))
	add_child(popup)
	popup.reset_size()
	popup.position = Vector2((1408 - popup.size.x) / 2, 96)
	popup.pivot_offset = popup.size / 2
	if not _quiet:
		popup.scale = Vector2(0.9, 0.9)
		popup.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(popup, "scale", Vector2.ONE, 0.12)
		tw.parallel().tween_property(popup, "modulate:a", 1.0, 0.12)


func _item_card(id: String) -> Button:
	var b := Button.new()
	b.set_meta("no_juice", true)  # 카드는 자기 튀는 동작과 소리가 있어요
	b.custom_minimum_size = Vector2(130, 130)
	b.add_theme_stylebox_override("normal", UI.box(Color(1, 1, 1, 0.7), Color("#D8C6A8"), 14, 2))
	b.add_theme_stylebox_override("hover", UI.box(Color.WHITE, UI.PINK, 14, 3))
	b.add_theme_stylebox_override("pressed", UI.box(Color("#FFE9EC"), UI.PINK, 14, 3))
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := UI.icon(Sprites.item(id), 70)
	col.add_child(ic)
	var is_tool: bool = GameState.ITEMS[id].kind == "tool"
	var n := _available(id)
	var l := UI.label(GameState.item_name(id) if is_tool else "%s %d" % [GameState.item_name(id), maxi(n, 0)], 17)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	b.add_child(col)
	if n <= 0:
		ic.modulate = Color(1, 1, 1, 0.35)
	b.pivot_offset = Vector2(65, 65)
	b.pressed.connect(func(): _pick(id, b))
	return b


func _close_popup() -> void:
	if popup:
		popup.queue_free()
	if catcher:
		catcher.queue_free()
	popup = null
	catcher = null
	popup_kind = ""


func _available(id: String) -> int:
	if GameState.ITEMS[id].kind == "tool":
		return 0 if slots.has(id) else 1
	return GameState.count(id) - slots.count(id)


func _pick(id: String, card: Button) -> void:
	_bounce(card, 0.08)
	if slots.size() >= SLOT_X.size():
		_say("조합 칸이 가득 찼어요.")
		Audio.sfx("fail")
		return
	if _available(id) <= 0:
		_say("도구는 한 번만 넣어요." if GameState.ITEMS[id].kind == "tool" else "%s이(가) 없어요. 마을에서 사 와요." % GameState.item_name(id))
		Audio.sfx("fail")
		return
	slots.append(id)
	var target: TextureRect = slot_icons[slots.size() - 1]
	var fly := UI.icon(Sprites.item(id), 70)
	fly.position = card.global_position + Vector2(30, 20)
	add_child(fly)
	var tw := create_tween()
	tw.tween_property(fly, "position", target.position + Vector2(11, 11), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		fly.queue_free()
		Audio.sfx("pop")
		_refresh()
		_bounce(target, 0.12))
	_refresh_popup()


func _refresh_popup() -> void:
	if popup_kind == "":
		return
	var k := popup_kind
	var pos := popup.position
	_quiet = true
	_open_storage(k)
	_quiet = false
	popup.position = pos


func _remove_slot(i: int) -> void:
	if i < slots.size():
		slots.remove_at(i)
		Audio.sfx("click", 0.8)
		_refresh()
		_refresh_popup()


func _clear_slots() -> void:
	slots.clear()
	_refresh()
	_refresh_popup()


func _cook(label: Label) -> void:
	_bounce(label, 0.1)
	var res := GameState.cook(slots)
	if res.get("empty", false):
		_say(res.msg)
		Audio.sfx("fail")
		return
	var icons := slot_icons.slice(0, slots.size())
	if res.ok:
		Audio.sfx("sparkle" if res.new else "pick")
		var dest: Vector2 = OVEN_MOUTH.get_center() if res.bake else Vector2(1300, 700)
		if res.bake:
			oven_glow.color.a = 0.45  # 오븐이 확 밝아졌다가 바로 완성돼요
		for ic in icons:
			var fly := UI.icon(ic.texture, 70)
			fly.position = ic.position + Vector2(11, 11)
			add_child(fly)
			var tw := create_tween()
			tw.tween_property(fly, "position", dest - Vector2(35, 35), 0.4).set_trans(Tween.TRANS_QUAD)
			tw.parallel().tween_property(fly, "scale", Vector2(0.3, 0.3), 0.4)
			tw.tween_callback(fly.queue_free)
	else:
		Audio.sfx("fail")
		for ic in icons:
			var tw := create_tween()
			var x: float = ic.position.x
			tw.tween_property(ic, "position:x", x - 8, 0.05)
			tw.tween_property(ic, "position:x", x + 8, 0.05)
			tw.tween_property(ic, "position:x", x, 0.05)
	slots.clear()
	_say(res.msg)
	await get_tree().create_timer(0.3).timeout
	if is_inside_tree():
		_refresh()
		_refresh_popup()


func _say(text: String) -> void:
	msg_l.text = text
	msg_l.reset_size()
	msg_l.position.x = 530 - msg_l.size.x / 2
	var tw := create_tween()
	msg_l.modulate.a = 1.0
	tw.tween_interval(2.0)
	tw.tween_property(msg_l, "modulate:a", 0.0, 0.5)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var hint := GameState.hint_recipe()
	var ghosts: Array = []
	if not hint.is_empty():
		for n in hint.needs:
			if not slots.has(n):
				ghosts.append(n)
	for i in SLOT_X.size():
		slot_icons[i].texture = Sprites.item(slots[i]) if i < slots.size() else null
		var gi := i - slots.size()
		ghost_icons[i].texture = Sprites.item(ghosts[gi]) if gi >= 0 and gi < ghosts.size() else null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and popup:
		_close_popup()
		get_viewport().set_input_as_handled()
