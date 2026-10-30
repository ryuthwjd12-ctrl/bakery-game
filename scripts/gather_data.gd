class_name GatherData
extends RefCounted
## tools/gather_overlays.py가 만든 파일이에요. 직접 고치지 말아요.
## 지도 → {id: 덮개 왼쪽 위 위치}

const SPOTS := {
	"backgrounds/acorn_village": {
		"bush_left": Vector2(0, 250),
		"bush_right": Vector2(1345, 262),
		"bush_bottom_left": Vector2(290, 628),
		"bush_bottom_right": Vector2(795, 628),
	},
	"maps/forest_path": {
		"strawberry_patch": Vector2(255, 385),
		"berry_bush": Vector2(505, 615),
		"berry_bottom": Vector2(390, 755),
	},
	"maps/apple_orchard": {
		"apple_tree_a": Vector2(110, 175),
		"apple_tree_b": Vector2(285, 385),
		"apple_tree_c": Vector2(115, 785),
	},
}
