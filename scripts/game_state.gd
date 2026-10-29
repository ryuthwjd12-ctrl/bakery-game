extends Node
## 게임 전체 상태: 골드, 재료, 진열대, 레시피북, 시계, 오븐, 주문 줄, 가게 레벨. 자동 로드(GameState)예요.

signal changed
signal tick  # 매 프레임 (시계용)
signal toast(text: String)
signal day_ended(summary: Dictionary)
signal level_up(level: int)
signal customer_spawned(kind: String)
signal tutorial_changed

const SAVE_PATH := "user://save.json"

const ITEMS := {
	"flour": {"name": "밀가루", "kind": "ing", "price": 5},
	"sugar": {"name": "설탕", "kind": "ing", "price": 4},
	"butter": {"name": "버터", "kind": "ing", "price": 8},
	"egg": {"name": "달걀", "kind": "ing", "price": 6},
	"milk": {"name": "우유", "kind": "ing", "price": 5},
	"chocolate": {"name": "초콜릿", "kind": "ing", "price": 10},
	"cream": {"name": "생크림", "kind": "ing", "price": 9},
	"raspberry": {"name": "산딸기", "kind": "ing", "price": 0},
	"rolling_pin": {"name": "밀대", "kind": "tool"},
	"star_cutter": {"name": "별 틀", "kind": "tool"},
	"cake_tin": {"name": "케이크 틀", "kind": "tool"},
	"piping_bag": {"name": "짤주머니", "kind": "tool"},
	"bowl": {"name": "볼", "kind": "tool"},
	"cake_plate": {"name": "케이크 접시", "kind": "tool"},
	"mug": {"name": "머그잔", "kind": "tool"},
	"butter_cookie": {"name": "버터 쿠키", "kind": "food", "price": 30, "bake": 8.0},
	"choco_cookie": {"name": "초코칩 쿠키", "kind": "food", "price": 40, "bake": 8.0},
	"star_cookie": {"name": "별 쿠키", "kind": "food", "price": 50, "bake": 10.0},
	"jam_cookie": {"name": "산딸기 잼 쿠키", "kind": "food", "price": 45, "bake": 10.0},
	"milk_bread": {"name": "우유 식빵", "kind": "food", "price": 40, "bake": 12.0},
	"raspberry_cake": {"name": "산딸기 생크림 케이크", "kind": "food", "price": 95, "bake": 15.0},
	"warm_milk": {"name": "따뜻한 우유", "kind": "food", "price": 15, "bake": 0.0},
}

## 넣는 순서는 상관없어요. 도구는 닳지 않고, 재료는 성공해도 실패해도 사라져요.
const RECIPES := [
	{"id": "butter_cookie", "needs": ["bowl", "flour", "butter", "sugar"]},
	{"id": "warm_milk", "needs": ["mug", "milk"]},
	{"id": "milk_bread", "needs": ["bowl", "flour", "milk", "egg"]},
	{"id": "choco_cookie", "needs": ["bowl", "flour", "butter", "sugar", "chocolate"]},
	{"id": "jam_cookie", "needs": ["bowl", "flour", "butter", "raspberry"]},
	{"id": "star_cookie", "needs": ["flour", "butter", "sugar", "egg", "star_cutter"]},
	{"id": "raspberry_cake", "needs": ["cake_tin", "flour", "egg", "cream", "raspberry"]},
]
## 처음 레시피는 주방 조합 칸에 흐린 그림자로 알려 줘요.
const STARTER := ["butter_cookie", "warm_milk", "milk_bread"]
## 가게 레벨마다 손님이 주문하는 메뉴
const MENU_BY_LEVEL := [
	["butter_cookie", "warm_milk", "milk_bread"],
	["choco_cookie", "jam_cookie"],
	["star_cookie", "raspberry_cake"],
]
const LEVEL_REP := [0, 8, 20, 40, 70]

const STORAGE := {
	"cabinet": {"name": "그릇장", "items": ["bowl", "mug", "cake_plate", "cake_tin", "star_cutter", "rolling_pin", "piping_bag"]},
	"fridge": {"name": "냉장고", "items": ["butter", "egg", "milk", "cream"]},
	"freezer": {"name": "냉동고", "items": ["raspberry"]},
	"pantry": {"name": "찬장", "items": ["flour", "sugar", "chocolate"]},
}

const DAY_START := 9 * 60
const DAY_END := 21 * 60
const LAST_ORDER := 20 * 60
const SECONDS_PER_MINUTE := 1.0  # 게임 하루(12시간) = 실제 12분
const OVEN_SLOTS := 3
const WAITER_COST := 150

var hero := "female"
var gold := 100
var day := 1
var minutes := float(DAY_START)
var inv := {}
var stock := {}
var known: Array = []
var oven: Array = []  # [{id, left, total}]
var picked_today: Array = []
var rep := 0
var has_waiter := false
var tutorial := {}  # 첫날 안내: order, cook, serve, clean
var clock_running := false
var day_over := false
var cleanliness := 100
var orders: Array = []  # 주문 받은 순서대로의 손님 자리(실행 중에만)
var today := {}


func new_game(h: String) -> void:
	hero = h
	gold = 100
	day = 1
	minutes = DAY_START
	inv = {"flour": 8, "sugar": 6, "butter": 5, "egg": 4, "milk": 5}
	stock = {}
	known = []
	oven = []
	picked_today = []
	rep = 0
	has_waiter = false
	tutorial = {}
	_reset_day()
	changed.emit()


func _reset_day() -> void:
	minutes = DAY_START
	picked_today = []
	orders = []
	day_over = false
	today = {"served": 0, "earned": 0, "lost": 0, "new": 0}


func _process(delta: float) -> void:
	if not clock_running or day_over:
		return
	minutes += delta / SECONDS_PER_MINUTE
	for o in oven:
		o.left -= delta
	var done := oven.filter(func(o): return o.left <= 0.0)
	for o in done:
		oven.erase(o)
		add_stock(o.id, 1)
		Audio.sfx("ding")
		toast.emit("%s 완성! 진열대에 놓았어요." % item_name(o.id))
	if minutes >= DAY_END:
		day_over = true
		day_ended.emit(today.duplicate())
	tick.emit()


func next_day() -> void:
	day += 1
	_reset_day()
	save_game()
	changed.emit()


func clock_text() -> String:
	var m := int(minutes)
	var h := m / 60
	var ampm := "오전" if h < 12 else "오후"
	var h12 := h if h <= 12 else h - 12
	return "%d일차  %s %d:%02d" % [day, ampm, h12, (m % 60) / 10 * 10]


func is_open() -> bool:
	return minutes < LAST_ORDER and not day_over


func item_name(id: String) -> String:
	return ITEMS[id].name


func count(id: String) -> int:
	return inv.get(id, 0)


func add_item(id: String, n: int) -> void:
	inv[id] = count(id) + n
	changed.emit()


func add_stock(id: String, n: int) -> void:
	stock[id] = stock.get(id, 0) + n
	changed.emit()


func take_stock(id: String) -> bool:
	if stock.get(id, 0) <= 0:
		return false
	stock[id] -= 1
	if stock[id] == 0:
		stock.erase(id)
	changed.emit()
	return true


func earn(n: int) -> void:
	gold += n
	today.earned += n
	changed.emit()


func buy(id: String, n: int) -> bool:
	var cost: int = ITEMS[id].price * n
	if n <= 0 or cost > gold:
		return false
	gold -= cost
	add_item(id, n)
	return true


func level() -> int:
	var lv := 1
	for i in LEVEL_REP.size():
		if rep >= LEVEL_REP[i]:
			lv = i + 1
	return lv


func level_progress() -> float:
	var lv := level()
	if lv >= LEVEL_REP.size():
		return 1.0
	var a: int = LEVEL_REP[lv - 1]
	var b: int = LEVEL_REP[lv]
	return float(rep - a) / float(b - a)


func add_rep(n: int) -> void:
	var before := level()
	rep = maxi(0, rep + n)
	if level() > before:
		level_up.emit(level())
		Audio.sfx("sparkle")
	changed.emit()


func menu_now() -> Array:
	var out: Array = []
	for i in mini(level(), MENU_BY_LEVEL.size()):
		out.append_array(MENU_BY_LEVEL[i])
	for k in known:
		if not out.has(k):
			out.append(k)
	return out


func recipe(id: String) -> Dictionary:
	for r in RECIPES:
		if r.id == id:
			return r
	return {}


func find_recipe(slots: Array) -> Dictionary:
	var a := slots.duplicate()
	a.sort()
	for r in RECIPES:
		var b: Array = r.needs.duplicate()
		b.sort()
		if a == b:
			return r
	return {}


## 주방 조합 칸에 흐리게 보여 줄 레시피(처음 레시피만)
func hint_recipe() -> Dictionary:
	for t in orders:
		if is_instance_valid(t) and STARTER.has(t.order):
			return recipe(t.order)
	if known.is_empty():
		return recipe("butter_cookie")
	return {}


## 조합 칸에 넣은 것으로 만들어요. 돌려주는 값: {"ok": bool, "msg": String, "bake": bool, "new": bool}
func cook(slots: Array) -> Dictionary:
	if slots.is_empty():
		return {"ok": false, "msg": "조합 칸이 비어 있어요.", "empty": true}
	var r := find_recipe(slots)
	if not r.is_empty() and ITEMS[r.id].bake > 0.0 and oven.size() >= OVEN_SLOTS:
		return {"ok": false, "msg": "오븐이 가득 찼어요. 조금만 기다려요.", "empty": true}
	for s in slots:
		if ITEMS[s].kind == "ing":
			inv[s] = count(s) - 1
	if r.is_empty():
		changed.emit()
		return {"ok": false, "msg": "실패… 재료를 잃었어요."}
	var first := not known.has(r.id)
	if first:
		known.append(r.id)
		today.new += 1
	var name := item_name(r.id)
	var bake: bool = ITEMS[r.id].bake > 0.0
	var msg := ""
	if bake:
		oven.append({"id": r.id, "left": ITEMS[r.id].bake, "total": ITEMS[r.id].bake})
		msg = "%s 반죽을 오븐에 넣었어요." % name
	else:
		add_stock(r.id, 1)
		msg = "%s 완성!" % name
	if first:
		msg = "새 레시피 발견! " + msg
	mark_tutorial("cook")
	changed.emit()
	return {"ok": true, "msg": msg, "bake": bake, "new": first, "id": r.id}


func mark_tutorial(step: String) -> void:
	if not tutorial.has(step):
		tutorial[step] = true
		tutorial_changed.emit()


func tutorial_done() -> bool:
	return tutorial.size() >= 4


func save_game() -> void:
	var data := {
		"hero": hero, "gold": gold, "day": day, "inv": inv, "stock": stock,
		"known": known, "oven": oven, "rep": rep, "has_waiter": has_waiter, "tutorial": tutorial,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	hero = data.get("hero", "female")
	gold = int(data.get("gold", 100))
	day = int(data.get("day", 1))
	inv = _ints(data.get("inv", {}))
	stock = _ints(data.get("stock", {}))
	known = data.get("known", [])
	oven = data.get("oven", [])
	rep = int(data.get("rep", 0))
	has_waiter = data.get("has_waiter", false)
	tutorial = data.get("tutorial", {})
	_reset_day()
	changed.emit()
	return true


func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out
