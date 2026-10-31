extends Node
## 게임 전체 상태: 골드, 재료, 진열대, 레시피북, 시계, 오븐, 주문 줄, 가게 레벨. 자동 로드(GameState)예요.

signal changed
signal tick  # 매 프레임 (시계용)
signal toast(text: String)
signal day_ended(summary: Dictionary)
signal level_up(level: int)
signal customer_spawned(kind: String)
signal customer_left(kind: String)
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
	# 다른 마을·몬스터에게서 얻는 재료
	"walnut": {"name": "호두", "kind": "ing", "price": 12},
	"acorn": {"name": "도토리", "kind": "ing", "price": 10},
	"matcha": {"name": "말차 가루", "kind": "ing", "price": 14},
	"honey_jar": {"name": "꿀", "kind": "ing", "price": 15},
	"strawberry": {"name": "딸기", "kind": "ing", "price": 12},
	"apple": {"name": "사과", "kind": "ing", "price": 10},
	"blueberry": {"name": "블루베리", "kind": "ing", "price": 12},
	"lemon": {"name": "레몬", "kind": "ing", "price": 12},
	"almond": {"name": "아몬드", "kind": "ing", "price": 14},
	"peach": {"name": "복숭아", "kind": "ing", "price": 14},
	"grape": {"name": "포도", "kind": "ing", "price": 14},
	# 과수원 과일로 만드는 디저트
	"lemon_cookie": {"name": "상큼 레몬 쿠키", "kind": "food", "price": 65, "bake": 9.0},
	"blueberry_muffin": {"name": "블루베리 머핀", "kind": "food", "price": 70, "bake": 10.0},
	"peach_tart": {"name": "복숭아 타르트", "kind": "food", "price": 90, "bake": 12.0},
	"grape_roll": {"name": "포도 크림 롤", "kind": "food", "price": 110, "bake": 12.0},
	"nut_cookie": {"name": "호두 쿠키", "kind": "food", "price": 60, "bake": 10.0},
	"cream_bun": {"name": "꿀 크림빵", "kind": "food", "price": 70, "bake": 12.0},
	"macaron": {"name": "말차 마카롱", "kind": "food", "price": 85, "bake": 10.0},
	"bear_cookie": {"name": "곰돌이 꿀쿠키", "kind": "food", "price": 75, "bake": 10.0},
	"croissant": {"name": "사과 크루아상", "kind": "food", "price": 80, "bake": 12.0},
	"mushroom_cookie": {"name": "도토리 버섯 쿠키", "kind": "food", "price": 90, "bake": 10.0},
	"choco_brioche": {"name": "초코 브리오슈", "kind": "food", "price": 100, "bake": 14.0},
	"snow_cookie": {"name": "눈꽃 쿠키", "kind": "food", "price": 150, "bake": 10.0},
	# 스페셜 요리(부탁 손님만 주문해요)
	"heart_cookie": {"name": "산딸기 하트 쿠키", "kind": "food", "price": 80, "bake": 10.0},
	"acorn_cookie": {"name": "초코 도토리 쿠키", "kind": "food", "price": 90, "bake": 10.0},
	"flower_cookie": {"name": "생크림 꽃 쿠키", "kind": "food", "price": 100, "bake": 10.0},
	"cinnamon_roll": {"name": "폭신 시나몬롤", "kind": "food", "price": 110, "bake": 12.0},
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
	{"id": "heart_cookie", "needs": ["bowl", "flour", "butter", "sugar", "raspberry"]},
	{"id": "acorn_cookie", "needs": ["bowl", "flour", "butter", "chocolate", "egg"]},
	{"id": "flower_cookie", "needs": ["flour", "sugar", "egg", "cream", "star_cutter"]},
	{"id": "cinnamon_roll", "needs": ["cake_tin", "flour", "butter", "sugar", "cream"]},
	{"id": "nut_cookie", "needs": ["bowl", "flour", "butter", "sugar", "walnut"]},
	{"id": "cream_bun", "needs": ["bowl", "flour", "milk", "honey_jar", "cream"]},
	{"id": "macaron", "needs": ["bowl", "sugar", "egg", "matcha", "cream"]},
	{"id": "bear_cookie", "needs": ["bowl", "flour", "butter", "honey_jar", "egg"]},
	{"id": "croissant", "needs": ["rolling_pin", "flour", "butter", "egg", "apple"]},
	{"id": "mushroom_cookie", "needs": ["bowl", "flour", "butter", "sugar", "acorn"]},
	{"id": "choco_brioche", "needs": ["cake_tin", "flour", "butter", "chocolate", "milk"]},
	{"id": "snow_cookie", "needs": ["flour", "sugar", "butter", "cream", "star_cutter"]},
	{"id": "lemon_cookie", "needs": ["bowl", "flour", "butter", "sugar", "lemon"]},
	{"id": "blueberry_muffin", "needs": ["bowl", "flour", "egg", "milk", "blueberry"]},
	{"id": "peach_tart", "needs": ["rolling_pin", "flour", "butter", "sugar", "peach"]},
	{"id": "grape_roll", "needs": ["rolling_pin", "flour", "egg", "sugar", "cream", "grape"]},
]
## 가끔 오는 부탁 손님. 사연을 듣고 스페셜 요리를 만들어 주면 큰 보상을 받아요.
const QUESTS := [
	{"id": "heart", "kind": "rb2", "dish": "heart_cookie", "reward": 200, "rep": 4, "min_day": 2,
		"story": "저… 좋아하는 친구가 있는데요, 오늘 마음을 전하고 싶어요.\n산딸기가 들어간 하트 쿠키를 만들어 줄 수 있어요?"},
	{"id": "acorn", "kind": "sq4", "dish": "acorn_cookie", "reward": 220, "rep": 4, "min_day": 3,
		"story": "겨울 준비로 도토리를 모으다 너무 지쳤어요.\n달걀을 넣은 초코 도토리 쿠키라면 힘이 날 것 같아요!"},
	{"id": "flower", "kind": "dr3", "dish": "flower_cookie", "reward": 260, "rep": 5, "min_day": 4,
		"story": "내일이 할머니 생신이에요. 꽃을 좋아하시거든요.\n생크림을 올린 꽃 모양 쿠키를 선물하고 싶어요."},
	{"id": "cinnamon", "kind": "bear", "dish": "cinnamon_roll", "reward": 300, "rep": 6, "min_day": 5,
		"story": "겨울잠에서 막 깼더니 배가 너무 고파요…\n케이크 틀에 구운 폭신하고 달콤한 빵이 먹고 싶어요."},
]
## 처음 레시피는 주방 조합 칸에 흐린 그림자로 알려 줘요.
const STARTER := ["butter_cookie", "warm_milk", "milk_bread"]
## 가게 레벨마다 손님이 주문하는 메뉴
const MENU_BY_LEVEL := [
	["butter_cookie", "warm_milk", "milk_bread"],
	["choco_cookie", "jam_cookie"],
	["star_cookie", "raspberry_cake"],
	["nut_cookie", "cream_bun", "mushroom_cookie", "lemon_cookie", "blueberry_muffin"],
	["macaron", "bear_cookie", "croissant", "choco_brioche", "peach_tart", "grape_roll"],
]
const LEVEL_REP := [0, 8, 20, 40, 70]

const STORAGE := {
	"cabinet": {"name": "그릇장", "items": ["bowl", "mug", "cake_plate", "cake_tin", "star_cutter", "rolling_pin", "piping_bag"]},
	"fridge": {"name": "냉장고", "items": ["butter", "egg", "milk", "cream", "apple", "peach", "lemon", "grape", "blueberry"]},
	"freezer": {"name": "냉동고", "items": ["raspberry", "strawberry"]},
	"pantry": {"name": "찬장", "items": ["flour", "sugar", "chocolate", "walnut", "acorn", "matcha", "honey_jar"]},
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
var oven: Array = []  # 예전 저장 파일 호환용(지금은 굽기가 바로 끝나요)
var made := {}  # 메뉴별로 만든 횟수(힌트는 3번까지)
const HINT_TIMES := 3
## 저장할 때 있던 곳: {"screen": "hall"/"kitchen"/"village"/"field", "area": 지역 id, "x", "y"}
var place := {}
var shop_open := true
## 저장 직전에 main이 지금 있는 곳을 place에 적어 줘요
var place_provider: Callable
var picked_today: Array = []
var rep := 0
var has_waiter := false
var tutorial := {}  # 첫날 안내: order, cook, serve, clean
var clock_running := false
var day_over := false
var cleanliness := 100
var orders: Array = []  # 주문 받은 순서대로의 손님 자리(실행 중에만)
var today := {}
## 가게 꾸미기: 별관 탁자 세트 수(0~4), 화분 수(0~2)
var annex_tables := 0
var decor := 0
## 모험: 체력·마나, 가진 무기와 장착한 무기
var hp := 100
var mp := 40
var weapons: Array = ["spatula"]
var weapon := "spatula"
var quests_done: Array = []
var boss_done := false
var active_quest := ""  # 받은 부탁(그날만)
var quest_seen_today := false
var dishes := 0  # 그릇 가게에서 산 예쁜 그릇 세트 수(팁이 늘어요)
var visited: Array = []
## 달력과 날씨: 계절마다 28일, 가끔 비가 와요(비 오는 날은 손님이 조금 적어요).
const SEASONS := ["봄", "여름", "가을", "겨울"]
const WEEK := ["월", "화", "수", "목", "금", "토", "일"]
var rain := false
## 주민과 친해지기: 하루 한 번 인사 +1, 음식 선물 +3. 5점마다 하트 하나(최대 5개).
var friends := {}  # 주민 그림 이름 → 점수
var talked_today: Array = []
var gifted_today: Array = []
## 목표: 해내면 보상을 받아요.
var goals_done: Array = []
var stats := {"served": 0, "monsters": 0}
## 알바생 피로: 일할수록 쌓이고, 다 차면 잠깐 쉬어요.
var waiter_tired := 0.0  # 가 본 다른 마을(그 마을 동물이 손님으로 놀러 와요)

const SAVE_KEYS := ["hero", "gold", "day", "inv", "stock", "known", "oven", "rep", "has_waiter", "tutorial",
	"annex_tables", "decor", "hp", "mp", "weapons", "weapon", "quests_done", "boss_done", "visited", "dishes", "friends", "goals_done", "stats", "made", "minutes", "place", "shop_open"]
## 무기: 근접(melee)은 앞으로 휘두르고, 마법(magic)은 반짝이를 쏘며 마나를 써요. 비쌀수록 세요.
const WEAPONS := {
	"spatula": {"name": "나무 뒤집개", "type": "melee", "power": 5, "price": 0, "icon": "items/w_spatula"},
	"rolling_pin": {"name": "밀대 몽둥이", "type": "melee", "power": 14, "price": 200, "icon": "items/w_rolling_pin"},
	"piping_bag": {"name": "크림 짤주머니", "type": "magic", "power": 12, "mp": 4, "price": 300, "icon": "items/w_piping_bag"},
	"cake_tin": {"name": "케이크 틀 망치", "type": "melee", "power": 22, "price": 550, "icon": "items/w_cake_tin"},
	"star_cutter": {"name": "별빛 쿠키 틀", "type": "magic", "power": 20, "mp": 5, "price": 700, "icon": "items/w_star_cutter"},
	"honey_staff": {"name": "꿀단지 지팡이", "type": "magic", "power": 30, "mp": 6, "price": 1200, "icon": "items/w_honey_staff"},
	"walnut_hammer": {"name": "호두 깨기 망치", "type": "melee", "power": 36, "price": 1500, "icon": "items/w_walnut_hammer"},
	"candy_cane": {"name": "사탕 지팡이", "type": "magic", "power": 44, "mp": 7, "price": 2400, "icon": "items/w_candy_cane"},
}
## 한 마을에는 한 동물만 살아요(주민 그림 이름들).
const VILLAGE_ANIMAL := {"village": ["sq1", "sq2", "sq3", "sq4", "sq5", "sq6"],
	"petal_hill": ["rb1", "rb2", "rb3", "rb4"], "seashell_beach": ["ct1", "ct2", "ct3", "ct4"],
	"apple_orchard": ["dr1", "dr2", "dr3", "dr4"], "snowflake_village": ["pg1", "pg2", "pg3", "pg4"]}
const ANNEX_MAX := 4
const DECOR_MAX := 2


func new_game(h: String) -> void:
	hero = h
	gold = 100
	day = 1
	minutes = DAY_START
	inv = {"flour": 8, "sugar": 6, "butter": 5, "egg": 4, "milk": 5}
	stock = {}
	known = []
	oven = []
	made = {}
	picked_today = []
	rep = 0
	has_waiter = false
	tutorial = {}
	annex_tables = 0
	decor = 0
	hp = max_hp()
	mp = max_mp()
	weapons = ["spatula"]
	weapon = "spatula"
	quests_done = []
	boss_done = false
	visited = []
	dishes = 0
	friends = {}
	goals_done = []
	stats = {"served": 0, "monsters": 0}
	_reset_day()
	changed.emit()


func max_hp() -> int:
	return 100 + (level() - 1) * 20


func max_mp() -> int:
	return 40 + (level() - 1) * 10


func _reset_day() -> void:
	minutes = DAY_START
	picked_today = []
	orders = []
	active_quest = ""
	quest_seen_today = false
	day_over = false
	today = {"served": 0, "earned": 0, "tips": 0, "spent": 0, "lost": 0, "new": 0, "sold": {}, "rep_start": rep}
	talked_today = []
	gifted_today = []
	waiter_tired = 0.0
	rain = day > 1 and (day * 7919 % 100) < 22  # 날마다 정해진 날씨(다시 불러와도 같아요)


var _goal_t := 0.0


func _process(delta: float) -> void:
	# 목표는 2초마다 확인해요(어디서 무엇을 하든)
	_goal_t += delta
	if _goal_t > 2.0 and clock_running:
		_goal_t = 0.0
		check_goals()
	if not clock_running or day_over:
		return
	minutes += delta / SECONDS_PER_MINUTE
	if minutes >= DAY_END:
		day_over = true
		day_ended.emit(today.duplicate())
	tick.emit()


func next_day() -> void:
	day += 1
	# 자고 나면 체력·마나가 다 차요
	hp = max_hp()
	mp = max_mp()
	_reset_day()
	save_game()
	changed.emit()


func clock_text() -> String:
	var m := int(minutes)
	var h := m / 60
	var ampm := "오전" if h < 12 else "오후"
	var h12 := h if h <= 12 else h - 12
	return "%s  %s %d:%02d%s" % [date_text(), ampm, h12, (m % 60) / 10 * 10, "  비" if rain else ""]


func date_text() -> String:
	var d := day - 1
	return "%s %d일 (%s)" % [SEASONS[(d / 28) % 4], d % 28 + 1, WEEK[d % 7]]


## 지금 시각의 하늘빛(마을·숲에 깔아요): 낮에는 그대로, 저녁엔 노을빛, 밤엔 푸르스름하게.
func sky_color() -> Color:
	var h := minutes / 60.0
	var c := Color.WHITE
	if h >= 16.5 and h < 18.5:
		c = Color.WHITE.lerp(Color(1.0, 0.86, 0.72), (h - 16.5) / 2.0)
	elif h >= 18.5:
		c = Color(1.0, 0.86, 0.72).lerp(Color(0.62, 0.66, 0.86), clampf((h - 18.5) / 2.0, 0.0, 1.0))
	if rain:
		c = c * Color(0.86, 0.88, 0.94)
	return c


func heart_text(kind: String) -> String:
	var h := hearts(kind)
	return "♥".repeat(h) + "♡".repeat(5 - h)


## 주민에게 다가가면 뜨는 말: 오늘 처음이면 인사, 인사했으면 선물(진열대에 음식이 있을 때), 아니면 이야기
func friend_action(kind: String) -> String:
	if not talked_today.has(kind):
		return "인사하기"
	if not gifted_today.has(kind) and not stock.is_empty():
		return "선물하기 (진열대 음식)"
	return "이야기하기"


func hearts(kind: String) -> int:
	return mini(5, friends.get(kind, 0) / 5)


## 인사하기: 하루 한 번 친밀도 +1. 하트가 늘면 true.
func talk(kind: String) -> bool:
	if talked_today.has(kind):
		return false
	talked_today.append(kind)
	return _add_friend(kind, 1)


## 음식 선물: 하루 한 번, 진열대의 음식을 하나 줘요. 친밀도 +3.
func gift(kind: String) -> String:
	if gifted_today.has(kind):
		return ""
	for id in stock:
		if take_stock(id):
			gifted_today.append(kind)
			_add_friend(kind, 3)
			return id
	return ""


func _add_friend(kind: String, n: int) -> bool:
	var before := hearts(kind)
	friends[kind] = friends.get(kind, 0) + n
	var up := hearts(kind) > before
	if up:
		# 하트가 늘면 그 주민이 고마움의 선물을 줘요
		gold += 20 * hearts(kind)
		toast.emit("♥ 친밀도 하트 %d개! 고맙다며 %d골드를 줬어요." % [hearts(kind), 20 * hearts(kind)])
	check_goals()
	changed.emit()
	return up


## 목표 목록: [id, 내용, 보상 골드, 달성했는지 확인]
func goal_list() -> Array:
	var max_heart := 0
	for k in friends:
		max_heart = maxi(max_heart, hearts(k))
	return [
		["serve10", "손님 10명에게 음식 내주기", 100, stats.get("served", 0) >= 10],
		["recipes5", "레시피 5개 알아내기", 120, known.size() >= 5],
		["heart1", "주민과 친해지기 (하트 1개)", 80, max_heart >= 1],
		["table1", "가구점에서 탁자 세트 사기", 100, annex_tables >= 1],
		["monster10", "몬스터 10마리 물리치기", 150, stats.get("monsters", 0) >= 10],
		["visit2", "다른 마을 2곳 가 보기", 150, visited.size() >= 2],
		["level3", "가게 레벨 3 되기", 200, level() >= 3],
		["serve100", "손님 100명에게 음식 내주기", 400, stats.get("served", 0) >= 100],
		["recipes15", "레시피 15개 알아내기", 400, known.size() >= 15],
		["heart5", "주민 한 명과 하트 5개", 500, max_heart >= 5],
		["boss", "눈사람 거인 물리치기", 300, boss_done],
		["visit4", "다른 마을 4곳 모두 가 보기", 300, visited.size() >= 4],
	]


func check_goals() -> void:
	for g in goal_list():
		if g[3] and not goals_done.has(g[0]):
			goals_done.append(g[0])
			gold += g[2]
			Audio.sfx("sparkle")
			toast.emit("★ 목표 달성: %s  (+%d골드)" % [g[1], g[2]])


## 가게 문을 열어 둔 동안만 손님이 와요(가게 아래 버튼으로 열고 닫아요).
func is_open() -> bool:
	return shop_open and minutes < LAST_ORDER and not day_over


func item_name(id: String) -> String:
	return ITEMS[id].name


func count_stock(id: String) -> int:
	return int(stock.get(id, 0))


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
	today.spent = today.get("spent", 0) + cost
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


func quest(id: String) -> Dictionary:
	for q in QUESTS:
		if q.id == id:
			return q
	return {}


## 오늘 올 수 있는 다음 부탁(차례대로)
func next_quest() -> Dictionary:
	for q in QUESTS:
		if not quests_done.has(q.id):
			return q if day >= q.min_day else {}
	return {}


## 주방 조합 칸에 흐리게 보여 줄 레시피(처음 레시피와 받은 스페셜 요리)
func hint_recipe() -> Dictionary:
	if active_quest != "":
		return recipe(quest(active_quest).dish)
	# 받은 주문 중 진열대에 아직 없는 메뉴를 먼저 알려 줘요. 세 번 만들어 본 메뉴는 더 안 알려 줘요.
	var need := {}
	for t in orders:
		if not is_instance_valid(t):
			continue
		for o in t.wanted():
			need[o] = need.get(o, 0) + 1
	for o in need:
		if count_stock(o) < need[o] and STARTER.has(o) and made.get(o, 0) < HINT_TIMES:
			return recipe(o)
	if known.is_empty():
		return recipe("butter_cookie")
	return {}


## 조합 칸에 넣은 것으로 만들어요. 돌려주는 값: {"ok": bool, "msg": String, "bake": bool, "new": bool}
func cook(slots: Array) -> Dictionary:
	if slots.is_empty():
		return {"ok": false, "msg": "조합 칸이 비어 있어요.", "empty": true}
	var r := find_recipe(slots)
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
	# 오븐에서 기다리지 않고 바로 완성돼서 진열대에 놓여요
	var bake: bool = ITEMS[r.id].bake > 0.0
	add_stock(r.id, 1)
	made[r.id] = made.get(r.id, 0) + 1
	var msg := "%s 완성!" % name
	if first:
		msg = "새 레시피 발견! " + msg
	mark_tutorial("cook")
	changed.emit()
	return {"ok": true, "msg": msg, "bake": bake, "new": first, "id": r.id}


func mark_tutorial(step: String) -> void:
	if not tutorial.has(step):
		tutorial[step] = true
		tutorial_changed.emit()


## 빵집 손님: 대부분 도토리 마을 다람쥐, 가 본 마을이 늘수록 그 마을 동물이 놀러 와요.
func customer_kind() -> String:
	var guests: Array = []
	for v in visited:
		if VILLAGE_ANIMAL.has(v):
			guests.append_array(VILLAGE_ANIMAL[v])
	if guests.is_empty() or randf() < 0.6:
		return VILLAGE_ANIMAL.village.pick_random()
	return guests.pick_random()


func visit(area_id: String) -> void:
	if VILLAGE_ANIMAL.has(area_id) and not visited.has(area_id):
		visited.append(area_id)


func tutorial_done() -> bool:
	return tutorial.size() >= 4


func save_game() -> void:
	if place_provider.is_valid():
		place = place_provider.call()
	var data := {}
	for k in SAVE_KEYS:
		data[k] = get(k)
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
	annex_tables = int(data.get("annex_tables", 0))
	decor = int(data.get("decor", 0))
	hp = int(data.get("hp", max_hp()))
	mp = int(data.get("mp", max_mp()))
	weapons = data.get("weapons", ["spatula"])
	weapon = data.get("weapon", "spatula")
	quests_done = data.get("quests_done", [])
	boss_done = data.get("boss_done", false)
	visited = data.get("visited", [])
	dishes = int(data.get("dishes", 0))
	friends = _ints(data.get("friends", {}))
	goals_done = data.get("goals_done", [])
	stats = _ints(data.get("stats", {"served": 0, "monsters": 0}))
	made = _ints(data.get("made", {}))
	place = data.get("place", {})
	shop_open = data.get("shop_open", true)
	_reset_day()
	minutes = float(data.get("minutes", DAY_START))
	# 예전 저장 파일에서 오븐에 있던 건 진열대로 옮겨요
	for o in oven:
		add_stock(o.id, 1)
	oven = []
	changed.emit()
	return true


func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out
