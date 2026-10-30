class_name Areas
extends RefCounted
## 도토리 마을 밖의 지역들. 좌표는 각 지도 그림 기준이에요.
## exits: 그 칸에 들어가면 to 지역으로 가요. entries: 어느 지역에서 왔는지에 따라 서는 곳.
## monsters가 있으면 위험 지역이에요(무기로 싸워요).

const FOREST_AREA := [Vector2(0, 215), Vector2(1408, 215), Vector2(1408, 560), Vector2(1260, 545), Vector2(1130, 600),
	Vector2(960, 600), Vector2(760, 578), Vector2(560, 578), Vector2(470, 612), Vector2(320, 615), Vector2(180, 540),
	Vector2(70, 560), Vector2(0, 560)]
const FOREST_BLOCKS := [
	# 가운데 큰 나무
	[Vector2(470, 250), Vector2(560, 205), Vector2(665, 255), Vector2(655, 380), Vector2(560, 400), Vector2(480, 370)],
	# 그루터기, 바위, 덤불, 표지판
	[Vector2(235, 290), Vector2(300, 272), Vector2(360, 300), Vector2(355, 355), Vector2(250, 350)],
	[Vector2(1090, 215), Vector2(1160, 200), Vector2(1215, 225), Vector2(1200, 270), Vector2(1100, 265)],
	[Vector2(1190, 320), Vector2(1240, 298), Vector2(1278, 340), Vector2(1260, 375), Vector2(1195, 372)],
	[Vector2(1068, 295), Vector2(1150, 285), Vector2(1150, 345), Vector2(1070, 345)],
	[Vector2(55, 225), Vector2(125, 225), Vector2(125, 318), Vector2(55, 318)],
	[Vector2(1285, 250), Vector2(1355, 250), Vector2(1355, 345), Vector2(1285, 345)],
	# 양쪽 소나무
	[Vector2(0, 400), Vector2(45, 400), Vector2(70, 560), Vector2(0, 560)],
	[Vector2(1360, 440), Vector2(1408, 400), Vector2(1408, 560), Vector2(1330, 560)],
	# 열매 덤불(채집하는 곳)
	[Vector2(835, 285), Vector2(950, 285), Vector2(955, 395), Vector2(840, 395)],
	[Vector2(700, 420), Vector2(780, 360), Vector2(880, 470), Vector2(870, 550), Vector2(705, 520)],
	[Vector2(1000, 430), Vector2(1085, 355), Vector2(1195, 380), Vector2(1190, 440), Vector2(1125, 510), Vector2(1000, 505)],
	[Vector2(350, 430), Vector2(455, 405), Vector2(520, 455), Vector2(515, 525), Vector2(405, 530), Vector2(350, 470)],
]

static func forest(name: String, to: String, monsters: Array, tint: Color, entry_side: String) -> Dictionary:
	return {
		"name": name, "bg": "maps/forest_path", "size": Vector2(1408, 768), "zoom": 1.8, "hero": 0.3,
		"area": FOREST_AREA, "blocks": FOREST_BLOCKS, "tint": tint, "monsters": monsters, "count": 6,
		"exits": [
			{"rect": Rect2(-40, 300, 52, 110), "to": "village", "label": "도토리 마을"},
			{"rect": Rect2(1396, 340, 60, 100), "to": to, "label": ""},
		],
		"entries": {"village": Vector2(40, 355), to: Vector2(1365, 392)},
		"village_side": entry_side,
	}


## 꽃잎 언덕·사과 과수원·눈꽃 마을은 같은 모양의 계단식 마을이에요:
## 가운데 광장(계단 둘), 왼쪽 아래와 오른쪽 아래로 내려가는 길. 위 언덕 집들은 절벽 위라 못 가요.
const TERRACE_AREA := [Vector2(0, 700), Vector2(150, 650), Vector2(330, 595), Vector2(470, 555), Vector2(525, 540),
	Vector2(550, 500), Vector2(590, 470), Vector2(600, 430), Vector2(640, 405), Vector2(700, 365), Vector2(760, 355),
	Vector2(830, 395), Vector2(905, 418), Vector2(990, 420), Vector2(1030, 445), Vector2(985, 485), Vector2(960, 500),
	Vector2(1000, 540), Vector2(1150, 590), Vector2(1300, 640), Vector2(1408, 680), Vector2(1408, 768), Vector2(1330, 768),
	Vector2(1150, 670), Vector2(1010, 600), Vector2(965, 565), Vector2(930, 545), Vector2(600, 545), Vector2(565, 565),
	Vector2(420, 640), Vector2(200, 710), Vector2(80, 768), Vector2(0, 768)]
## 눈꽃 마을은 아래 눈밭도 걸을 수 있어요(시냇물만 빼고).
const SNOW_AREA := [Vector2(0, 690), Vector2(150, 650), Vector2(330, 595), Vector2(470, 555), Vector2(525, 540),
	Vector2(550, 500), Vector2(590, 470), Vector2(600, 430), Vector2(640, 405), Vector2(700, 365), Vector2(760, 355),
	Vector2(830, 395), Vector2(905, 418), Vector2(990, 420), Vector2(1030, 445), Vector2(985, 485), Vector2(960, 500),
	Vector2(1000, 540), Vector2(1150, 590), Vector2(1300, 640), Vector2(1408, 680), Vector2(1408, 768), Vector2(0, 768)]
const STALLS := [
	[Vector2(645, 445), Vector2(700, 435), Vector2(708, 500), Vector2(650, 505)],
	[Vector2(710, 470), Vector2(775, 465), Vector2(775, 540), Vector2(712, 540)],
	[Vector2(740, 400), Vector2(800, 400), Vector2(802, 470), Vector2(742, 470)],
	[Vector2(800, 428), Vector2(865, 428), Vector2(865, 505), Vector2(802, 505)],
]
const TERRACE_EXIT := [{"rect": Rect2(-40, 690, 52, 90), "to": "", "label": "숲길"}]


static func terrace(name: String, bg: String, forest_id: String, area: Array, blocks: Array, shop: Dictionary) -> Dictionary:
	var exits := TERRACE_EXIT.duplicate(true)
	exits[0].to = forest_id
	return {
		"name": name, "bg": bg, "size": Vector2(1408, 768), "zoom": 1.7, "hero": 0.28,
		"area": area, "blocks": blocks, "exits": exits, "entries": {forest_id: Vector2(40, 728)}, "shop": shop,
	}


static func get_area(id: String) -> Dictionary:
	match id:
		"forest_north":
			return forest("북쪽 꽃길 숲", "petal_hill", ["bee", "sheep", "slime"], Color(1, 0.97, 1), "north")
		"forest_east":
			return forest("동쪽 바닷바람 숲", "seashell_beach", ["slime", "mushroom", "squirrel"], Color(1, 1, 1), "east")
		"forest_south":
			return forest("남쪽 과수원 숲", "apple_orchard", ["squirrel", "mushroom", "sheep"], Color(1, 0.98, 0.92), "south")
		"forest_west":
			return forest("서쪽 눈바람 숲", "snowflake_village", ["sheep", "dragon", "mushroom"], Color(0.9, 0.95, 1.06), "west")
		"petal_hill":
			return terrace("꽃잎 언덕", "maps/petal_hill", "forest_north", TERRACE_AREA, [
				[Vector2(700, 435), Vector2(770, 435), Vector2(770, 475), Vector2(700, 475)],
				[Vector2(655, 480), Vector2(725, 480), Vector2(725, 525), Vector2(655, 525)],
				[Vector2(755, 465), Vector2(840, 465), Vector2(840, 520), Vector2(755, 520)],
			], {"pos": Vector2(880, 432), "npc": "rabbit", "name": "꽃잎 언덕 꿀가게", "items": ["honey_jar", "matcha", "milk"]})
		"apple_orchard":
			return terrace("사과 과수원", "maps/apple_orchard", "forest_south", TERRACE_AREA, STALLS,
				{"pos": Vector2(880, 432), "npc": "bear", "name": "과수원 가게", "items": ["apple", "walnut", "acorn"]})
		"snowflake_village":
			var d := terrace("눈꽃 마을", "maps/snowflake_village", "forest_west", SNOW_AREA, STALLS + [
				# 시냇물(다리 아래)
				[Vector2(775, 650), Vector2(805, 650), Vector2(745, 705), Vector2(660, 768), Vector2(600, 768), Vector2(700, 690)],
			], {"pos": Vector2(880, 432), "npc": "deer", "name": "눈꽃 상점", "items": ["cream", "milk", "butter"]})
			d["boss"] = {"pos": Vector2(1120, 700), "trigger": 230.0}
			return d
		"seashell_beach":
			return {
				"name": "조개 해변", "bg": "maps/seashell_beach", "size": Vector2(1408, 768), "zoom": 1.7, "hero": 0.28,
				"area": [Vector2(0, 305), Vector2(170, 268), Vector2(420, 268), Vector2(640, 250), Vector2(760, 250),
					Vector2(1000, 240), Vector2(1180, 285), Vector2(1260, 330), Vector2(1300, 600), Vector2(1408, 630),
					Vector2(1408, 768), Vector2(1080, 768), Vector2(1000, 742), Vector2(800, 702), Vector2(600, 642),
					Vector2(400, 562), Vector2(200, 452), Vector2(0, 418)],
				"blocks": [
					[Vector2(545, 350), Vector2(640, 280), Vector2(725, 300), Vector2(722, 390), Vector2(640, 395), Vector2(600, 445), Vector2(548, 440)],
					[Vector2(460, 320), Vector2(560, 320), Vector2(560, 390), Vector2(460, 390)],
					[Vector2(752, 290), Vector2(815, 235), Vector2(880, 290), Vector2(870, 385), Vector2(752, 372)],
					[Vector2(865, 330), Vector2(930, 290), Vector2(1020, 360), Vector2(1010, 465), Vector2(880, 460)],
					[Vector2(1030, 410), Vector2(1060, 410), Vector2(1060, 480), Vector2(1030, 480)],
					[Vector2(995, 462), Vector2(1070, 462), Vector2(1070, 530), Vector2(995, 530)],
					[Vector2(1100, 480), Vector2(1190, 430), Vector2(1255, 460), Vector2(1280, 560), Vector2(1110, 555)],
					[Vector2(1050, 440), Vector2(1100, 440), Vector2(1100, 500), Vector2(1050, 500)],
					[Vector2(1015, 250), Vector2(1100, 200), Vector2(1170, 250), Vector2(1165, 330), Vector2(1020, 330)],
					[Vector2(1190, 270), Vector2(1255, 270), Vector2(1255, 312), Vector2(1190, 312)],
					[Vector2(680, 470), Vector2(800, 440), Vector2(845, 500), Vector2(800, 525), Vector2(680, 500)],
					[Vector2(775, 580), Vector2(850, 560), Vector2(915, 610), Vector2(900, 640), Vector2(800, 640)],
					[Vector2(195, 385), Vector2(290, 385), Vector2(290, 440), Vector2(195, 440)],
					[Vector2(1055, 660), Vector2(1165, 660), Vector2(1165, 720), Vector2(1055, 720)],
				],
				"exits": [{"rect": Rect2(-40, 300, 52, 110), "to": "forest_east", "label": "숲길"}],
				"entries": {"forest_east": Vector2(40, 345)},
				"shop": {"pos": Vector2(800, 405), "npc": "cat", "name": "바닷가 생선 가게", "items": ["chocolate", "cream", "matcha"]},
			}
	return {}


## 마을 가장자리에서 나가는 곳 → 숲 이름
const VILLAGE_EXITS := {"north": "forest_north", "east": "forest_east", "south": "forest_south", "west": "forest_west"}

## 몬스터: 체력, 빠르기, 부딪히면 주는 피해, 떨어뜨리는 재료
const MONSTERS := {
	"slime": {"name": "새싹 슬라임", "hp": 20, "speed": 45.0, "dmg": 6, "drop": "matcha", "gold": 4},
	"mushroom": {"name": "빨간 버섯", "hp": 28, "speed": 38.0, "dmg": 8, "drop": "acorn", "gold": 5},
	"squirrel": {"name": "장난꾸러기 다람쥐", "hp": 24, "speed": 70.0, "dmg": 7, "drop": "walnut", "gold": 5},
	"bee": {"name": "솜털 꿀벌", "hp": 22, "speed": 75.0, "dmg": 8, "drop": "honey_jar", "gold": 6},
	"sheep": {"name": "구름 양", "hp": 40, "speed": 42.0, "dmg": 10, "drop": "milk", "gold": 7},
	"dragon": {"name": "아기 용", "hp": 60, "speed": 55.0, "dmg": 14, "drop": "chocolate", "gold": 12},
	"snowman": {"name": "눈사람 거인", "hp": 360, "speed": 34.0, "dmg": 16, "drop": "", "gold": 500},
}

## 세계 지도 위 지역 이름 위치(world_map.png 기준)
const WORLD := [
	["꽃잎 언덕", Vector2(430, 125), "petal_hill"],
	["눈꽃 마을", Vector2(140, 335), "snowflake_village"],
	["도토리 숲 마을", Vector2(430, 300), "village"],
	["조개 해변", Vector2(735, 325), "seashell_beach"],
	["사과 과수원", Vector2(440, 540), "apple_orchard"],
	["꿀벌 들판 (준비 중)", Vector2(110, 125), ""],
	["바다 동굴 (준비 중)", Vector2(760, 115), ""],
	["눈 덮인 산 (준비 중)", Vector2(130, 525), ""],
	["어둠의 헛간 숲 (준비 중)", Vector2(735, 515), ""],
]
