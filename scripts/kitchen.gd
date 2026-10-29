extends Control
## 주방 화면. 그릇장·냉장고·냉동고·찬장을 눌러 재료와 그릇을 고르면 아래 조합 칸으로 날아가요.
## "굽기"를 누르면 맞는 조합일 때 오븐에 들어가거나 바로 완성돼요. 좌표는 주방 그림(1408x768) 기준이에요.

var main: Node

const FURNITURE := {
	"cabinet": {"tex": "kitchen/cabinet", "pos": Vector2(140, 52)},
	"fridge": {"tex": "kitchen/fridge", "pos": Vector2(430, 32)},
	"pantry": {"tex": "kitchen/pantry", "pos": Vector2(690, 102)},
}
## 누를 수 있는 곳(냉장고는 위 칸이 냉동고)
const HOTSPOTS := {
	"cabinet": Rect2(150, 60, 262, 470),
	"freezer": Rect2(442, 40, 228, 162),
	"fridge": Rect2(442, 204, 228, 326),
	"pantry": Rect2(704, 170, 374, 370),
}
const PANEL_STYLE := {
	"cabinet": ["#FBF3E3", "#8E5A3A"], "fridge": ["#F1F8FB", "#7FB2CF"],
	"freezer": ["#E8F3FA", "#A9CFE8"], "pantry": ["#F7EDCB", "#8E5A3A"],
}
const SLOT_X := [135, 300, 463, 628, 793]
const SLOT_Y := 578
const SLOT_SIZE := Vector2(135, 124)
const OK_RECT := Rect2(956, 598, 146, 82)
const OVEN_MOUTH := Rect2(1222, 352, 118, 150)

var slots: Array = []
var slot_icons: Array = []
var ghost_icons: Array = []
var furn_sprites := {}
var popup: PanelContainer
var popup_kind := ""
var oven_box: VBoxContainer
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
		add_child(b)

	oven_glow = ColorRect.new()
	oven_glow.position = OVEN_MOUTH.position
	oven_glow.size = OVEN_MOUTH.size
	oven_glow.color = Color(1.0, 0.6, 0.2, 0.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	oven_glow.material = mat
	oven_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(oven_glow)

	for i in 5:
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

	var ok := UI.label("굽기", 30)
	ok.position = OK_RECT.position
	ok.size = OK_RECT.size
	ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ok.pivot_offset = OK_RECT.size / 2
	ok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ok)
	add_child(UI.hotspot(OK_RECT, _cook.bind(ok)))

	var clear := UI.button("비우기", _clear_slots, 18)
	clear.position = Vector2(990, 690)
	add_child(clear)

	var oven_panel := PanelContainer.new()
	oven_panel.add_theme_stylebox_override("panel", UI.box(Color(1, 0.97, 0.9, 0.92), UI.OUTLINE, 14, 2))
	oven_panel.position = Vector2(1170, 150)
	oven_panel.custom_minimum_size = Vector2(210, 0)
	oven_box = VBoxContainer.new()
	oven_panel.add_child(oven_box)
	add_child(oven_panel)

	msg_l = UI.label("", 24)
	msg_l.add_theme_stylebox_override("normal", UI.box(Color("#FFF8E6"), UI.PINK))
	msg_l.position = Vector2(300, 520)
	msg_l.modulate.a = 0.0
	msg_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(msg_l)

	var back := UI.button("← 홀로", func(): main.goto("hall", "kitchen"))
	back.position = Vector2(16, 70)
	add_child(back)

	GameState.changed.connect(_refresh)
	_refresh()
	Audio.play_bgm("bgm_shop")


func _process(_delta: float) -> void:
	_t += _delta
	var baking := not GameState.oven.is_empty()
	if int(_t * 4.0) != int((_t - _delta) * 4.0):
		_refresh_oven()
	oven_glow.color.a = (0.18 + 0.08 * sin(_t * 4.0)) if baking else 0.0


func _hover(k: String, on: bool) -> void:
	var key := "fridge" if k == "freezer" else k
	furn_sprites[key].modulate = Color(1.08, 1.06, 1.0) if on else Color.WHITE


func _bounce(c: Control, amount := 0.06) -> void:
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.0 + amount, 1.0 - amount), 0.07)
	tw.tween_property(c, "scale", Vector2(1.0 - amount * 0.5, 1.0 + amount * 0.5), 0.07)
	tw.tween_property(c, "scale", Vector2.ONE, 0.08)


func _open_storage(k: String) -> void:
	if not _quiet:
		Audio.sfx("click")
		_bounce(furn_sprites["fridge" if k == "freezer" else k], 0.03)
		if popup_kind == k:
			_close_popup()
			return
	_close_popup()
	popup_kind = k
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
	popup = null
	popup_kind = ""


func _available(id: String) -> int:
	if GameState.ITEMS[id].kind == "tool":
		return 0 if slots.has(id) else 1
	return GameState.count(id) - slots.count(id)


func _pick(id: String, card: Button) -> void:
	_bounce(card, 0.08)
	if slots.size() >= 5:
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
	for i in 5:
		slot_icons[i].texture = Sprites.item(slots[i]) if i < slots.size() else null
		var gi := i - slots.size()
		ghost_icons[i].texture = Sprites.item(ghosts[gi]) if gi >= 0 and gi < ghosts.size() else null
	_refresh_oven()


func _refresh_oven() -> void:
	for c in oven_box.get_children():
		oven_box.remove_child(c)
		c.queue_free()
	oven_box.add_child(UI.label("오븐 %d/%d" % [GameState.oven.size(), GameState.OVEN_SLOTS], 18))
	for o in GameState.oven:
		var row := HBoxContainer.new()
		row.add_child(UI.icon(Sprites.item(o.id), 36))
		var bar_bg := ColorRect.new()
		bar_bg.color = Color("#EADFCB")
		bar_bg.custom_minimum_size = Vector2(130, 10)
		bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bar := ColorRect.new()
		bar.color = Color("#E9A23B")
		bar.size = Vector2(130.0 * (1.0 - o.left / maxf(o.total, 0.1)), 10)
		bar_bg.add_child(bar)
		row.add_child(bar_bg)
		oven_box.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and popup:
		_close_popup()
		get_viewport().set_input_as_handled()
