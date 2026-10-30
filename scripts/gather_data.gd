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
		"apple_tree_a": Vector2(415, 580),
		"apple_tree_b": Vector2(990, 585),
		"apple_tree_c": Vector2(555, 515),
	},
}
