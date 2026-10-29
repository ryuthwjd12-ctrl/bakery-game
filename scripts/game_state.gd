extends Node
## 게임 전체 상태: 골드, 재료, 진열장, 레시피북, 시계, 오븐. 자동 로드(GameState)로 어디서나 써요.

signal changed
signal toast(text: String)
signal day_ended(day: int, earned: int)

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
	"star_cookie": {"name": "별 쿠키", "kind": "food", "price": 45, "bake": 10.0},
	"jam_cookie": {"name": "산딸기 잼 쿠키", "kind": "food", "price": 45, "bake": 10.0},
	"milk_bread": {"name": "우유 식빵", "kind": "food", "price": 40, "bake": 12.0},
	"raspberry_cake": {"name": "산딸기 생크림 케이크", "kind": "food", "price": 90, "bake": 15.0},
	"warm_milk": {"name": "따뜻한 우유", "kind": "food", "price": 15, "bake": 0.0},
}

## 넣는 순서는 상관없어요. 도구는 닳지 않고, 재료는 성공해도 실패해도 사라져요.
const RECIPES := [
	{"id": "butter_cookie", "needs": ["flour", "butter", "sugar"],
		"hint": "고소하고 바삭한 기본 쿠키 하나 주세요. 버터 향이 나면 좋겠어요."},
	{"id": "choco_cookie", "needs": ["flour", "butter", "sugar", "chocolate"],
		"hint": "쿠키 안에 달콤 쌉싸름한 조각이 콕콕 박혀 있으면 좋겠어요."},
	{"id": "star_cookie", "needs": ["flour", "butter", "sugar", "egg", "star_cutter"],
		"hint": "밤하늘에서 떨어진 것 같은 모양의 쿠키 있나요?"},
	{"id": "jam_cookie", "needs": ["flour", "butter", "sugar", "raspberry"],
		"hint": "숲에서 딴 빨간 열매가 들어간 쿠키가 먹고 싶어요."},
	{"id": "milk_bread", "needs": ["flour", "milk", "egg", "sugar"],
		"hint": "부드럽고 폭신한 빵이요. 우유 냄새가 솔솔 나는 걸로요."},
	{"id": "raspberry_cake", "needs": ["flour", "egg", "cream", "raspberry", "cake_tin"],
		"hint": "오늘 생일이에요! 하얀 크림 위에 빨간 열매가 올라간 거요."},
	{"id": "warm_milk", "needs": ["mug", "milk"],
		"hint": "몸이 으슬으슬해요. 따뜻하게 마실 거 있을까요?"},
]

const DAY_START := 9 * 60
const DAY_END := 21 * 60
const SECONDS_PER_MINUTE := 1.0  # 게임 하루(12시간) = 실제 12분
const OVEN_SLOTS := 3

var hero := "female"
var gold := 100
var day := 1
var minutes := float(DAY_START)
var inv := {}
var stock := {}
var known: Array = []
var oven: Array = []  # [{id, left}]
var picked_today: Array = []
var earned_today := 0
var clock_running := false
var cleanliness := 100


func new_game(h: String) -> void:
	hero = h
	gold = 100
	day = 1
	minutes = DAY_START
	inv = {"flour": 6, "sugar": 6, "butter": 4, "egg": 3, "milk": 3}
	stock = {}
	known = []
	oven = []
	picked_today = []
	earned_today = 0
	changed.emit()


func _process(delta: float) -> void:
	if not clock_running:
		return
	minutes += delta / SECONDS_PER_MINUTE
	for o in oven:
		o.left -= delta
	var done := oven.filter(func(o): return o.left <= 0.0)
	for o in done:
		oven.erase(o)
		add_stock(o.id, 1)
		toast.emit("%s 완성! 진열장에 놓았어요." % item_name(o.id))
	if minutes >= DAY_END:
		_end_day()
	changed.emit()


func _end_day() -> void:
	day_ended.emit(day, earned_today)
	day += 1
	minutes = DAY_START
	picked_today = []
	earned_today = 0
	save_game()


func clock_text() -> String:
	var m := int(minutes)
	var h := m / 60
	var ampm := "오전" if h < 12 else "오후"
	var h12 := h if h <= 12 else h - 12
	return "%d일차 · %s %d:%02d" % [day, ampm, h12, (m % 60) / 10 * 10]


func is_open() -> bool:
	return minutes < DAY_END - 60


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
	earned_today += n
	changed.emit()


func buy(id: String, n: int) -> bool:
	var cost: int = ITEMS[id].price * n
	if n <= 0 or cost > gold:
		return false
	gold -= cost
	add_item(id, n)
	return true


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


## 조합 칸에 넣은 것으로 만들어요. 돌려주는 값: {"ok": bool, "msg": String}
func cook(slots: Array) -> Dictionary:
	if slots.is_empty():
		return {"ok": false, "msg": "조합 칸이 비어 있어요."}
	var r := find_recipe(slots)
	if not r.is_empty():
		var food: Dictionary = ITEMS[r.id]
		if food.bake > 0.0 and oven.size() >= OVEN_SLOTS:
			return {"ok": false, "msg": "오븐이 가득 찼어요. 조금만 기다려요."}
	for s in slots:
		if ITEMS[s].kind == "ing":
			inv[s] = count(s) - 1
	if r.is_empty():
		changed.emit()
		return {"ok": false, "msg": "실패… 재료를 잃었어요."}
	var first := not known.has(r.id)
	if first:
		known.append(r.id)
	var name := item_name(r.id)
	var msg := ""
	if ITEMS[r.id].bake > 0.0:
		oven.append({"id": r.id, "left": ITEMS[r.id].bake})
		msg = "%s 반죽을 오븐에 넣었어요." % name
	else:
		add_stock(r.id, 1)
		msg = "%s 완성!" % name
	if first:
		msg = "새 레시피 발견! " + msg
	changed.emit()
	return {"ok": true, "msg": msg, "new": first}


func save_game() -> void:
	var data := {
		"hero": hero, "gold": gold, "day": day, "inv": inv, "stock": stock,
		"known": known, "oven": oven,
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
	minutes = DAY_START
	inv = _ints(data.get("inv", {}))
	stock = _ints(data.get("stock", {}))
	known = data.get("known", [])
	oven = data.get("oven", [])
	picked_today = []
	earned_today = 0
	changed.emit()
	return true


func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out
