class_name WalkMap
extends RefCounted
## 그림 위에 칠한 "걸을 수 있는 곳" 지도. 발 위치가 area 안, blocks 밖이면 걸을 수 있어요.
## 칸 지도(A*)로 가구·건물을 돌아가는 길을 찾아요.

var area: PackedVector2Array
var blocks: Array = []  # PackedVector2Array 목록
var astar := AStarGrid2D.new()
var cell := 12


func _init(area_pts: Array, block_polys: Array, cell_size := 12, size := Vector2i(1408, 768)) -> void:
	area = PackedVector2Array(area_pts)
	for b in block_polys:
		blocks.append(PackedVector2Array(b))
	cell = cell_size
	astar.region = Rect2i(0, 0, size.x / cell + 1, size.y / cell + 1)
	astar.cell_size = Vector2(cell, cell)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in range(astar.region.size.x):
		for y in range(astar.region.size.y):
			astar.set_point_solid(Vector2i(x, y), not can_walk(Vector2(x, y) * cell))


func can_walk(p: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(p, area):
		return false
	for b in blocks:
		if Geometry2D.is_point_in_polygon(p, b):
			return false
	return true


func _cell(p: Vector2) -> Vector2i:
	var c := Vector2i(roundi(p.x / cell), roundi(p.y / cell))
	if astar.is_in_boundsv(c) and not astar.is_point_solid(c):
		return c
	for r in range(1, 14):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if astar.is_in_boundsv(n) and not astar.is_point_solid(n):
					return n
	return c


## from에서 to까지 걸어갈 점들. 곧게 갈 수 있는 곳은 건너뛰어 부드럽게 만들어요.
func find_path(from: Vector2, to: Vector2) -> Array:
	var cells := astar.get_id_path(_cell(from), _cell(to))
	var pts: Array = []
	for c in cells:
		pts.append(Vector2(c) * cell)
	if pts.is_empty():
		return [to]
	if can_walk(to):
		pts[pts.size() - 1] = to
	var out: Array = []
	var cur := from
	var i := 0
	while i < pts.size():
		var j := pts.size() - 1
		while j > i and not clear_line(cur, pts[j]):
			j -= 1
		cur = pts[j]
		out.append(cur)
		i = j + 1
	return out


func clear_line(a: Vector2, b: Vector2) -> bool:
	var n := int(a.distance_to(b) / 6.0) + 1
	for k in n + 1:
		if not can_walk(a.lerp(b, float(k) / n)):
			return false
	return true


## 아무 데나 걸을 수 있는 점 하나
func random_point() -> Vector2:
	for i in 200:
		var c := Vector2i(randi() % astar.region.size.x, randi() % astar.region.size.y)
		if not astar.is_point_solid(c):
			return Vector2(c) * cell
	return area[0]
