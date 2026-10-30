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


## 다른 마을: 마을마다 모양이 달라요. 숲으로 이어지는 길 하나로 들어오고 나가요.
static func town(name: String, bg: String, forest_id: String, area: Array, blocks: Array, exit: Rect2, entry: Vector2, shop: Dictionary) -> Dictionary:
	return {
		"name": name, "bg": bg, "size": Vector2(1408, 768), "zoom": 1.7, "hero": 0.28,
		"area": area, "blocks": blocks, "exits": [{"rect": exit, "to": forest_id, "label": "숲길"}],
		"entries": {forest_id: entry}, "shop": shop,
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
			return town("꽃잎 언덕", "maps/petal_hill", "forest_north", [Vector2(0, 0), Vector2(1408, 0), Vector2(1408, 768), Vector2(0, 768)], [
					[Vector2(138, 170), Vector2(205, 95), Vector2(307, 70), Vector2(379, 95), Vector2(379, 190), Vector2(307, 215), Vector2(164, 240)],
					[Vector2(1090, 120), Vector2(1177, 105), Vector2(1269, 110), Vector2(1335, 215), Vector2(1310, 285), Vector2(1136, 260), Vector2(1090, 220)],
					[Vector2(72, 610), Vector2(143, 530), Vector2(246, 520), Vector2(297, 560), Vector2(297, 630), Vector2(205, 680), Vector2(82, 690)],
					[Vector2(1131, 480), Vector2(1218, 465), Vector2(1330, 580), Vector2(1330, 640), Vector2(1207, 625), Vector2(1136, 580)],
					[Vector2(0, 190), Vector2(153, 200), Vector2(205, 330), Vector2(246, 400), Vector2(327, 450), Vector2(481, 490), Vector2(460, 580), Vector2(379, 575), Vector2(256, 470), Vector2(153, 420), Vector2(0, 430)],
					[Vector2(379, 10), Vector2(553, 10), Vector2(553, 140), Vector2(430, 150), Vector2(379, 60)],
					[Vector2(936, 30), Vector2(1085, 30), Vector2(1074, 150), Vector2(941, 150)],
					[Vector2(404, 250), Vector2(532, 200), Vector2(686, 230), Vector2(686, 330), Vector2(573, 400), Vector2(409, 355)],
					[Vector2(706, 190), Vector2(952, 270), Vector2(987, 450), Vector2(911, 500), Vector2(716, 410), Vector2(696, 380)],
					[Vector2(532, 500), Vector2(614, 480), Vector2(737, 540), Vector2(737, 640), Vector2(634, 670), Vector2(537, 610)],
					[Vector2(952, 485), Vector2(1054, 490), Vector2(1054, 580), Vector2(957, 545)],
					[Vector2(1013, 420), Vector2(1085, 420), Vector2(1131, 535), Vector2(1131, 600), Vector2(1059, 600), Vector2(1013, 490)],
					[Vector2(798, 700), Vector2(900, 650), Vector2(1115, 665), Vector2(1115, 768), Vector2(778, 768)],
					[Vector2(0, 640), Vector2(72, 640), Vector2(235, 700), Vector2(235, 768), Vector2(0, 768)],
					[Vector2(1279, 300), Vector2(1408, 300), Vector2(1408, 360), Vector2(1279, 360)],
					[Vector2(1289, 650), Vector2(1408, 650), Vector2(1408, 740), Vector2(1289, 740)],
					[Vector2(307, 535), Vector2(343, 535), Vector2(343, 630), Vector2(307, 630)],
				], Rect2(532, 756, 133, 60), Vector2(604, 735),
				{"npc": "rb1", "look": "petal", "name": "꽃잎 언덕 꿀가게", "items": ["honey_jar", "matcha", "milk"], "pos": Vector2(721, 440)})
		"seashell_beach":
			return town("조개 해변", "maps/seashell_beach", "forest_east", [Vector2(0, 0), Vector2(1408, 0), Vector2(1408, 285), Vector2(1279, 330), Vector2(1126, 430), Vector2(1003, 520), Vector2(890, 560), Vector2(778, 620), Vector2(665, 690), Vector2(573, 768), Vector2(0, 768)], [
					[Vector2(128, 90), Vector2(184, 55), Vector2(287, 60), Vector2(348, 110), Vector2(338, 200), Vector2(266, 225), Vector2(153, 215), Vector2(128, 170)],
					[Vector2(20, 260), Vector2(72, 200), Vector2(153, 230), Vector2(205, 300), Vector2(200, 395), Vector2(113, 410), Vector2(31, 395)],
					[Vector2(0, 0), Vector2(123, 0), Vector2(113, 90), Vector2(51, 180), Vector2(0, 200)],
					[Vector2(409, 30), Vector2(471, 0), Vector2(542, 40), Vector2(537, 130), Vector2(481, 150), Vector2(414, 120)],
					[Vector2(358, 0), Vector2(420, 0), Vector2(409, 150), Vector2(373, 150)],
					[Vector2(947, 40), Vector2(1013, 0), Vector2(1095, 40), Vector2(1090, 140), Vector2(1013, 175), Vector2(952, 140)],
					[Vector2(1085, 0), Vector2(1408, 0), Vector2(1408, 130), Vector2(1187, 140), Vector2(1105, 110)],
					[Vector2(1161, 110), Vector2(1228, 50), Vector2(1320, 90), Vector2(1371, 190), Vector2(1310, 250), Vector2(1177, 250), Vector2(1161, 200)],
					[Vector2(711, 270), Vector2(778, 215), Vector2(947, 280), Vector2(993, 410), Vector2(911, 465), Vector2(798, 455), Vector2(721, 385)],
					[Vector2(655, 300), Vector2(686, 300), Vector2(686, 380), Vector2(655, 380)],
					[Vector2(762, 150), Vector2(798, 150), Vector2(798, 230), Vector2(762, 230)],
					[Vector2(952, 330), Vector2(982, 330), Vector2(982, 400), Vector2(952, 400)],
					[Vector2(256, 510), Vector2(327, 415), Vector2(409, 450), Vector2(440, 560), Vector2(409, 600), Vector2(266, 580)],
					[Vector2(51, 560), Vector2(133, 495), Vector2(225, 560), Vector2(251, 650), Vector2(205, 700), Vector2(72, 680)],
					[Vector2(0, 400), Vector2(113, 410), Vector2(113, 520), Vector2(41, 560), Vector2(0, 560)],
					[Vector2(0, 600), Vector2(102, 620), Vector2(82, 768), Vector2(0, 768)],
					[Vector2(205, 480), Vector2(235, 480), Vector2(235, 590), Vector2(205, 590)],
					[Vector2(532, 590), Vector2(614, 580), Vector2(655, 640), Vector2(573, 665), Vector2(532, 640)],
					[Vector2(1064, 345), Vector2(1167, 345), Vector2(1167, 440), Vector2(1064, 440)],
					[Vector2(1243, 270), Vector2(1300, 270), Vector2(1300, 312), Vector2(1243, 312)],
					[Vector2(327, 695), Vector2(450, 695), Vector2(450, 768), Vector2(327, 768)],
				], Rect2(655, -40, 215, 52), Vector2(762, 30),
				{"npc": "ct1", "look": "beach", "name": "바닷가 생선 가게", "items": ["chocolate", "cream", "matcha"], "pos": Vector2(737, 445)})
		"apple_orchard":
			return town("과일 과수원", "maps/apple_orchard", "forest_south", [Vector2(0, 0), Vector2(1408, 0), Vector2(1408, 768), Vector2(0, 768)], [
					[Vector2(0, 0), Vector2(604, 0), Vector2(583, 95), Vector2(481, 145), Vector2(389, 190), Vector2(338, 150), Vector2(133, 100), Vector2(61, 150), Vector2(0, 150)],
					[Vector2(819, 0), Vector2(1408, 0), Vector2(1408, 300), Vector2(1320, 300), Vector2(1146, 240), Vector2(1136, 185), Vector2(1023, 185), Vector2(952, 140), Vector2(900, 110), Vector2(839, 95)],
					[Vector2(138, 120), Vector2(225, 65), Vector2(338, 130), Vector2(338, 240), Vector2(235, 260), Vector2(143, 215)],
					[Vector2(409, 250), Vector2(532, 160), Vector2(655, 115), Vector2(778, 95), Vector2(875, 140), Vector2(880, 200), Vector2(778, 230), Vector2(716, 250), Vector2(675, 355), Vector2(573, 400), Vector2(481, 355), Vector2(409, 310)],
					[Vector2(716, 260), Vector2(778, 205), Vector2(947, 280), Vector2(993, 420), Vector2(941, 470), Vector2(829, 480), Vector2(665, 385)],
					[Vector2(880, 230), Vector2(952, 190), Vector2(1054, 250), Vector2(1054, 385), Vector2(972, 385), Vector2(900, 330)],
					[Vector2(1161, 470), Vector2(1300, 355), Vector2(1408, 370), Vector2(1408, 640), Vector2(1320, 640), Vector2(1167, 600)],
					[Vector2(1330, 580), Vector2(1408, 580), Vector2(1408, 660), Vector2(1330, 660)],
					[Vector2(1253, 650), Vector2(1320, 650), Vector2(1320, 700), Vector2(1253, 700)],
					[Vector2(527, 768), Vector2(624, 768), Vector2(860, 628), Vector2(827, 598)],
					[Vector2(962, 545), Vector2(993, 575), Vector2(1408, 380), Vector2(1408, 300)],
					[Vector2(1064, 345), Vector2(1161, 345), Vector2(1161, 440), Vector2(1064, 440)],
					[Vector2(1187, 315), Vector2(1243, 315), Vector2(1243, 355), Vector2(1187, 355)],
					[Vector2(1090, 180), Vector2(1151, 180), Vector2(1151, 230), Vector2(1090, 230)],
					[Vector2(51, 225), Vector2(189, 225), Vector2(189, 300), Vector2(51, 300)],
					[Vector2(179, 265), Vector2(240, 265), Vector2(240, 310), Vector2(179, 310)],
					[Vector2(0, 285), Vector2(151, 285), Vector2(151, 500), Vector2(0, 500)],
					[Vector2(189, 440), Vector2(240, 440), Vector2(240, 515), Vector2(189, 515)],
					[Vector2(41, 110), Vector2(128, 110), Vector2(128, 230), Vector2(41, 230)],
					[Vector2(256, 470), Vector2(338, 410), Vector2(445, 490), Vector2(440, 580), Vector2(338, 600), Vector2(261, 560)],
					[Vector2(256, 580), Vector2(327, 580), Vector2(327, 630), Vector2(256, 630)],
					[Vector2(46, 550), Vector2(133, 480), Vector2(246, 560), Vector2(240, 660), Vector2(164, 680), Vector2(51, 640)],
					[Vector2(0, 620), Vector2(82, 620), Vector2(174, 700), Vector2(215, 768), Vector2(0, 768)],
					[Vector2(307, 768), Vector2(389, 660), Vector2(512, 600), Vector2(573, 520), Vector2(665, 495), Vector2(747, 520), Vector2(737, 640), Vector2(634, 700), Vector2(573, 768)],
					[Vector2(578, 470), Vector2(634, 470), Vector2(634, 530), Vector2(578, 530)],
					[Vector2(655, 768), Vector2(778, 690), Vector2(921, 640), Vector2(1115, 700), Vector2(1126, 768)],
					[Vector2(1330, 660), Vector2(1408, 640), Vector2(1408, 768), Vector2(1330, 768)],
				], Rect2(614, -40, 205, 52), Vector2(716, 30),
				{"npc": "dr1", "look": "orchard", "name": "과일 가판대", "items": ["apple", "peach", "lemon", "grape", "blueberry", "strawberry"], "pos": Vector2(706, 432)})
		"snowflake_village":
			var d := town("눈꽃 마을", "maps/snowflake_village", "forest_west", [Vector2(0, 0), Vector2(1408, 0), Vector2(1408, 768), Vector2(0, 768)], [
					[Vector2(67, 100), Vector2(123, 75), Vector2(338, 75), Vector2(394, 130), Vector2(379, 215), Vector2(307, 245), Vector2(153, 250), Vector2(72, 210)],
					[Vector2(0, 0), Vector2(573, 0), Vector2(573, 60), Vector2(481, 90), Vector2(307, 40), Vector2(205, 50), Vector2(102, 100), Vector2(0, 150)],
					[Vector2(0, 150), Vector2(82, 180), Vector2(82, 300), Vector2(0, 300)],
					[Vector2(0, 300), Vector2(153, 340), Vector2(153, 450), Vector2(61, 500), Vector2(0, 500)],
					[Vector2(169, 410), Vector2(261, 410), Vector2(261, 510), Vector2(169, 510)],
					[Vector2(51, 540), Vector2(143, 485), Vector2(235, 520), Vector2(246, 640), Vector2(164, 670), Vector2(61, 640)],
					[Vector2(261, 450), Vector2(338, 415), Vector2(430, 450), Vector2(440, 560), Vector2(379, 590), Vector2(266, 560)],
					[Vector2(0, 580), Vector2(51, 600), Vector2(153, 660), Vector2(266, 700), Vector2(409, 700), Vector2(460, 768), Vector2(0, 768)],
					[Vector2(414, 240), Vector2(481, 200), Vector2(573, 150), Vector2(665, 110), Vector2(778, 90), Vector2(870, 130), Vector2(890, 210), Vector2(819, 230), Vector2(757, 220), Vector2(706, 260), Vector2(655, 330), Vector2(573, 400), Vector2(481, 380), Vector2(420, 330)],
					[Vector2(716, 260), Vector2(762, 205), Vector2(911, 240), Vector2(957, 300), Vector2(957, 430), Vector2(849, 465), Vector2(778, 440), Vector2(706, 390)],
					[Vector2(962, 270), Vector2(1023, 230), Vector2(1059, 300), Vector2(1023, 390), Vector2(972, 380)],
					[Vector2(967, 70), Vector2(1033, 30), Vector2(1126, 60), Vector2(1131, 160), Vector2(1064, 175), Vector2(982, 160)],
					[Vector2(1167, 140), Vector2(1248, 95), Vector2(1335, 120), Vector2(1351, 240), Vector2(1289, 265), Vector2(1177, 250)],
					[Vector2(1105, 0), Vector2(1408, 0), Vector2(1408, 240), Vector2(1351, 100), Vector2(1279, 60), Vector2(1136, 60)],
					[Vector2(849, 0), Vector2(982, 0), Vector2(972, 100), Vector2(860, 100)],
					[Vector2(1269, 240), Vector2(1408, 230), Vector2(1408, 300), Vector2(1274, 335)],
					[Vector2(1187, 310), Vector2(1243, 310), Vector2(1243, 355), Vector2(1187, 355)],
					[Vector2(1182, 500), Vector2(1269, 435), Vector2(1361, 460), Vector2(1371, 590), Vector2(1279, 615), Vector2(1187, 600)],
					[Vector2(1141, 520), Vector2(1187, 520), Vector2(1187, 560), Vector2(1141, 560)],
					[Vector2(1351, 350), Vector2(1408, 330), Vector2(1408, 768), Vector2(1330, 768), Vector2(1361, 600)],
					[Vector2(696, 768), Vector2(716, 700), Vector2(778, 650), Vector2(880, 620), Vector2(1003, 650), Vector2(1054, 700), Vector2(1126, 768)],
					[Vector2(1248, 650), Vector2(1320, 650), Vector2(1320, 700), Vector2(1248, 700)],
					[Vector2(752, 570), Vector2(849, 575), Vector2(849, 630), Vector2(757, 625)],
				], Rect2(675, -40, 164, 52), Vector2(757, 30),
				{"npc": "pg1", "name": "얼음 수정 상점", "items": ["cream", "milk", "butter"], "pos": Vector2(747, 452)})
			d["boss"] = {"pos": Vector2(614, 600), "trigger": 230.0}
			return d
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
	["과일 과수원", Vector2(440, 540), "apple_orchard"],
	["꿀벌 들판 (준비 중)", Vector2(110, 125), ""],
	["바다 동굴 (준비 중)", Vector2(760, 115), ""],
	["눈 덮인 산 (준비 중)", Vector2(130, 525), ""],
	["어둠의 헛간 숲 (준비 중)", Vector2(735, 515), ""],
]
