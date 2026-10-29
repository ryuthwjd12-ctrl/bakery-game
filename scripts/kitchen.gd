extends Control
## 주방 화면. 선반의 재료와 도구를 눌러 아래 조합 칸에 넣고 굽기 버튼을 눌러요.
## 좌표는 주방 그림(1408x768) 위의 위치예요.

var main: Node

const SHELF := {
	"flour": Rect2(160, 85, 160, 160),
	"sugar": Rect2(348, 78, 116, 166),
	"butter": Rect2(480, 122, 204, 124),
	"egg": Rect2(688, 108, 172, 136),
	"milk": Rect2(884, 70, 78, 174),
	"chocolate": Rect2(978, 106, 132, 136),
}
## 그림에 없는 재료는 아이콘으로 선반 아래 벽에 걸어 둬요.
const EXTRA := {
	"raspberry": Rect2(430, 282, 64, 64),
	"cream": Rect2(520, 282, 64, 64),
}
const TOOLS := {
	"rolling_pin": Rect2(106, 344, 158, 156),
	"star_cutter": Rect2(248, 382, 108, 98),
	"cake_tin": Rect2(368, 384, 146, 92),
	"piping_bag": Rect2(518, 344, 120, 156),
	"bowl": Rect2(644, 386, 148, 100),
	"cake_plate": Rect2(804, 388, 170, 98),
	"mug": Rect2(988, 380, 124, 110),
}
const SLOT_X := [135, 300, 463, 628, 793]
const SLOT_Y := 578
const SLOT_SIZE := Vector2(135, 124)
const OK_RECT := Rect2(956, 598, 146, 82)
const OVEN_RECT := Rect2(1132, 300, 276, 260)

var slots: Array = []
var slot_icons: Array = []
var count_labels := {}
var oven_l: Label
var msg_l: Label


func _ready() -> void:
	size = Vector2(1408, 768)
	theme = UI.make_theme()
	add_child(UI.bg(Sprites.tex("backgrounds/kitchen")))

	for id in SHELF:
		_add_source(id, SHELF[id], false)
	for id in EXTRA:
		var r: Rect2 = EXTRA[id]
		var ic := UI.icon(Sprites.item(id), int(r.size.x))
		ic.position = r.position
		add_child(ic)
		_add_source(id, r, false)
	for id in TOOLS:
		_add_source(id, TOOLS[id], true)

	for i in 5:
		var r := Rect2(Vector2(SLOT_X[i], SLOT_Y), SLOT_SIZE)
		var ic := UI.icon(null, 96)
		ic.position = r.position + (r.size - Vector2(96, 96)) / 2
		add_child(ic)
		slot_icons.append(ic)
		add_child(UI.hotspot(r, _remove_slot.bind(i)))

	var ok := UI.label("굽기", 30)
	ok.position = OK_RECT.position
	ok.size = OK_RECT.size
	ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(ok)
	add_child(UI.hotspot(OK_RECT, _cook))

	oven_l = UI.label("", 18)
	oven_l.add_theme_stylebox_override("normal", UI.box(Color(1, 0.97, 0.9, 0.92), UI.OUTLINE, 12, 2))
	oven_l.position = Vector2(1150, 200)
	add_child(oven_l)

	msg_l = UI.label("", 24)
	msg_l.add_theme_stylebox_override("normal", UI.box(Color("#FFF8E6"), UI.PINK))
	msg_l.position = Vector2(300, 530)
	msg_l.visible = false
	add_child(msg_l)

	var back := UI.button("← 홀로 (Esc)", func(): main.goto("hall", "kitchen"))
	back.position = Vector2(16, 64)
	add_child(back)

	GameState.changed.connect(_refresh)
	_refresh()


func _add_source(id: String, r: Rect2, is_tool: bool) -> void:
	add_child(UI.hotspot(r, _add_slot.bind(id)))
	var l := UI.label("", 18)
	l.add_theme_stylebox_override("normal", UI.box(Color(1, 0.98, 0.92, 0.95), UI.OUTLINE, 10, 2))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = Vector2(r.position.x + r.size.x / 2 - 40, r.end.y - 6)
	add_child(l)
	count_labels[id] = l
	l.set_meta("tool", is_tool)


func _available(id: String) -> int:
	if GameState.ITEMS[id].kind == "tool":
		return 0 if slots.has(id) else 1
	return GameState.count(id) - slots.count(id)


func _add_slot(id: String) -> void:
	if slots.size() >= 5:
		_say("조합 칸이 가득 찼어요.")
		return
	if _available(id) <= 0:
		_say("%s이(가) 없어요." % GameState.item_name(id) if GameState.ITEMS[id].kind == "ing" else "도구는 한 번만 넣어요.")
		return
	slots.append(id)
	_refresh()


func _remove_slot(i: int) -> void:
	if i < slots.size():
		slots.remove_at(i)
		_refresh()


func _cook() -> void:
	var res := GameState.cook(slots)
	if res.ok or res.msg.begins_with("실패"):
		slots.clear()
	_say(res.msg)
	_refresh()


func _say(text: String) -> void:
	msg_l.text = text
	msg_l.visible = true
	msg_l.reset_size()
	msg_l.position.x = 530 - msg_l.size.x / 2
	var tw := create_tween()
	msg_l.modulate.a = 1.0
	tw.tween_interval(2.0)
	tw.tween_property(msg_l, "modulate:a", 0.0, 0.5)


func _refresh() -> void:
	for i in 5:
		slot_icons[i].texture = Sprites.item(slots[i]) if i < slots.size() else null
	for id in count_labels:
		var l: Label = count_labels[id]
		if l.get_meta("tool"):
			l.text = GameState.item_name(id)
		else:
			l.text = "%s %d" % [GameState.item_name(id), maxi(_available(id), 0)]
		l.reset_size()
	var lines := ["오븐 %d/%d" % [GameState.oven.size(), GameState.OVEN_SLOTS]]
	for o in GameState.oven:
		lines.append("%s %d초" % [GameState.item_name(o.id), ceili(o.left)])
	oven_l.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not main.hud.is_panel_open():
		main.goto("hall", "kitchen")
