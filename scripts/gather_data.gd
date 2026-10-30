class_name GatherData
extends RefCounted
## tools/gather_overlays.py가 만든 파일이에요. 직접 고치지 말아요.
## 지도 → {id: 덮개 왼쪽 위 위치}

const SPOTS := {
	"backgrounds/acorn_village": {
		"bush_left": Vector2(5, 232),
		"bed_west": Vector2(290, 408),
		"bed_plaza": Vector2(768, 503),
	},
	"maps/forest_path": {
		"strawberry_patch": Vector2(995, 345),
		"berry_bush": Vector2(828, 272),
		"berry_bottom": Vector2(692, 350),
		"berry_left": Vector2(342, 398),
	},
	"maps/apple_orchard": {
		"apple": Vector2(660, 490),
		"peach": Vector2(418, 210),
		"lemon": Vector2(979, 240),
		"grape": Vector2(0, 285),
		"blueberry": Vector2(0, 405),
		"strawberry": Vector2(52, 225),
	},
}
