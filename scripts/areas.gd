class_name Areas
extends RefCounted
## 도토리 마을 밖의 지역들. 좌표는 각 지도 그림 기준이에요.
## exits: 그 칸에 들어가면 to 지역으로 가요. entries: 어느 지역에서 왔는지에 따라 서는 곳.
## monsters가 있으면 위험 지역이에요(무기로 싸워요).

const FOREST_AREA := [Vector2(0, 555), Vector2(215, 545), Vector2(255, 430), Vector2(380, 385), Vector2(520, 368),
	Vector2(650, 372), Vector2(800, 385), Vector2(905, 325), Vector2(1000, 255), Vector2(1180, 185),
	Vector2(1374, 170), Vector2(1374, 250), Vector2(1110, 262), Vector2(1010, 320), Vector2(955, 420),
	Vector2(945, 560), Vector2(930, 640), Vector2(800, 690), Vector2(690, 715), Vector2(500, 725),
	Vector2(380, 705), Vector2(240, 692), Vector2(100, 705), Vector2(0, 715)]

static func forest(name: String, to: String, monsters: Array, tint: Color, entry_side: String) -> Dictionary:
	return {
		"name": name, "bg": "maps/forest_path", "size": Vector2(1374, 888), "zoom": 1.6, "hero": 0.42,
		"area": FOREST_AREA, "blocks": [], "tint": tint, "monsters": monsters, "count": 6,
		"exits": [
			{"rect": Rect2(-40, 540, 52, 200), "to": "village", "label": "도토리 마을"},
			{"rect": Rect2(1362, 160, 60, 100), "to": to, "label": ""},
		],
		"entries": {"village": Vector2(40, 640), to: Vector2(1330, 215)},
		"village_side": entry_side,
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
			return {
				"name": "꽃잎 언덕", "bg": "maps/petal_hill", "size": Vector2(1408, 768), "zoom": 1.7, "hero": 0.3,
				"area": [Vector2(0, 170), Vector2(640, 110), Vector2(700, 0), Vector2(1408, 0), Vector2(1408, 768), Vector2(0, 768)],
				"blocks": [
					[Vector2(290, 250), Vector2(330, 90), Vector2(500, 40), Vector2(500, 250), Vector2(460, 365), Vector2(300, 360)],
					[Vector2(1030, 150), Vector2(1130, 20), Vector2(1350, 20), Vector2(1360, 330), Vector2(1210, 345), Vector2(1100, 300), Vector2(1030, 280)],
					[Vector2(900, 560), Vector2(1080, 420), Vector2(1408, 420), Vector2(1408, 680), Vector2(1200, 680), Vector2(1000, 560)],
				],
				"exits": [{"rect": Rect2(360, 755, 360, 60), "to": "forest_north", "label": "숲길"}],
				"entries": {"forest_north": Vector2(560, 735)},
				"shop": {"pos": Vector2(1062, 365), "npc": "rabbit", "name": "꽃잎 언덕 꿀가게", "items": ["honey_jar", "matcha", "milk"]},
			}
		"seashell_beach":
			return {
				"name": "조개 해변", "bg": "maps/seashell_beach", "size": Vector2(1374, 1008), "zoom": 1.5, "hero": 0.4,
				"area": [Vector2(130, 430), Vector2(200, 330), Vector2(330, 240), Vector2(470, 160), Vector2(620, 90),
					Vector2(870, 40), Vector2(1374, 40), Vector2(1374, 1008), Vector2(1060, 1008), Vector2(860, 930),
					Vector2(660, 820), Vector2(560, 740), Vector2(400, 640), Vector2(250, 540), Vector2(130, 500)],
				"blocks": [
					[Vector2(170, 90), Vector2(380, 90), Vector2(380, 465), Vector2(170, 465)],
					[Vector2(880, 40), Vector2(1374, 40), Vector2(1374, 430), Vector2(1180, 440), Vector2(1090, 390), Vector2(880, 240)],
					[Vector2(455, 50), Vector2(780, 50), Vector2(780, 350), Vector2(455, 350)],
				],
				"exits": [{"rect": Rect2(1362, 450, 60, 400), "to": "forest_east", "label": "숲길"}],
				"entries": {"forest_east": Vector2(1320, 640)},
				"shop": {"pos": Vector2(1140, 470), "npc": "cat", "name": "바닷가 잡화점", "items": ["chocolate", "cream", "matcha"]},
			}
		"apple_orchard":
			return {
				"name": "사과 과수원", "bg": "maps/apple_orchard", "size": Vector2(1338, 1008), "zoom": 1.5, "hero": 0.4,
				"area": [Vector2(0, 590), Vector2(100, 615), Vector2(310, 720), Vector2(500, 820), Vector2(565, 700),
					Vector2(570, 610), Vector2(700, 470), Vector2(770, 410), Vector2(840, 330), Vector2(880, 330),
					Vector2(1050, 430), Vector2(1000, 520), Vector2(990, 740), Vector2(1140, 830), Vector2(1338, 840),
					Vector2(1338, 1008), Vector2(540, 1008), Vector2(500, 930), Vector2(280, 830), Vector2(0, 700)],
				"blocks": [],
				"exits": [{"rect": Rect2(-40, 580, 52, 130), "to": "forest_south", "label": "숲길"}],
				"entries": {"forest_south": Vector2(40, 650)},
				"shop": {"pos": Vector2(1050, 790), "npc": "bear", "name": "과수원 가게", "items": ["apple", "walnut", "acorn"]},
			}
		"snowflake_village":
			return {
				"name": "눈꽃 마을", "bg": "maps/snowflake_village", "size": Vector2(1408, 768), "zoom": 1.6, "hero": 0.32,
				"area": [Vector2(0, 0), Vector2(1408, 0), Vector2(1408, 768), Vector2(0, 768)],
				"blocks": [
					[Vector2(210, 170), Vector2(270, 90), Vector2(380, 110), Vector2(445, 190), Vector2(440, 300), Vector2(330, 320), Vector2(215, 270)],
					[Vector2(60, 420), Vector2(130, 340), Vector2(240, 345), Vector2(300, 430), Vector2(290, 520), Vector2(200, 570), Vector2(70, 530)],
					[Vector2(1105, 210), Vector2(1250, 95), Vector2(1340, 200), Vector2(1330, 330), Vector2(1220, 340), Vector2(1110, 280)],
					[Vector2(1050, 470), Vector2(1170, 400), Vector2(1340, 490), Vector2(1350, 640), Vector2(1240, 645), Vector2(1100, 580), Vector2(1050, 530)],
					[Vector2(0, 0), Vector2(200, 0), Vector2(190, 330), Vector2(90, 380), Vector2(80, 640), Vector2(0, 660)],
					[Vector2(760, 40), Vector2(900, 20), Vector2(970, 200), Vector2(880, 265), Vector2(770, 220)],
					[Vector2(1340, 280), Vector2(1408, 280), Vector2(1408, 768), Vector2(1340, 768)],
					[Vector2(500, 140), Vector2(620, 140), Vector2(630, 310), Vector2(500, 300)],
					[Vector2(300, 0), Vector2(500, 0), Vector2(480, 140), Vector2(330, 150)],
				],
				"exits": [{"rect": Rect2(380, 755, 460, 60), "to": "forest_west", "label": "숲길"}],
				"entries": {"forest_west": Vector2(620, 735)},
				"shop": {"pos": Vector2(1080, 600), "npc": "deer", "name": "눈꽃 상점", "items": ["cream", "milk", "butter"]},
				"boss": {"pos": Vector2(690, 150), "trigger": 230.0},
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
