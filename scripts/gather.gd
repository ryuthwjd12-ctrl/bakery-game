class_name Gather
extends RefCounted
## 채집 공통 기능: 열매가 사라진 덮개 그림, 땅에 떨어진 재료, 주인공에게 날아오는 열매.


## 지도 그림 위에 "따고 난 모습" 덮개를 깔아요. 이미 딴 곳은 바로 보여요.
## 돌려주는 값: {id: Sprite2D}
static func add_overlays(parent: Node2D, map_key: String, prefix: String) -> Dictionary:
	var out := {}
	var spots: Dictionary = GatherData.SPOTS.get(map_key, {})
	for sid in spots:
		var sp := Sprite2D.new()
		sp.texture = load("res://assets/gather/%s_%s.png" % [map_key.get_file(), sid])
		sp.centered = false
		sp.position = spots[sid]
		sp.visible = GameState.picked_today.has(prefix + sid)
		parent.add_child(sp)
		out[sid] = sp
	return out


## 딴 순간: 덮개가 스르르 나타나고, 열매 아이콘이 톡톡 튀어 주인공에게 날아가요.
static func pick_fx(parent: Node2D, overlay: Sprite2D, item: String, n: int, to_node: Node2D, icon_scale := 0.35) -> void:
	if overlay:
		overlay.modulate.a = 0.0
		overlay.visible = true
		overlay.create_tween().tween_property(overlay, "modulate:a", 1.0, 0.35)
	var from: Vector2 = overlay.position + overlay.texture.get_size() / 2 if overlay else to_node.position
	for i in n:
		var s := Sprite2D.new()
		s.texture = Sprites.item(item)
		s.scale = Vector2(icon_scale, icon_scale)
		s.position = from + Vector2(randf_range(-30, 30), randf_range(-15, 15))
		s.z_index = 80
		parent.add_child(s)
		var tw := s.create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(s, "position:y", s.position.y - 26, 0.18).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "position", to_node.position + Vector2(0, -20), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(s, "scale", Vector2(icon_scale, icon_scale) * 0.4, 0.28)
		tw.tween_callback(s.queue_free)
	Audio.sfx("gather")


## 땅에 떨어진 재료(도토리, 호두 등). 주우면 톡 튀며 사라지고, 다음 날 다시 생겨요.
## items: [[id, item, pos], ...]  → {id: Sprite2D}
static func add_ground_items(parent: Node2D, items: Array, prefix: String, icon_scale: float) -> Dictionary:
	var out := {}
	for it in items:
		if GameState.picked_today.has(prefix + it[0]):
			continue
		var s := Sprite2D.new()
		s.texture = Sprites.item(it[1])
		s.scale = Vector2(icon_scale, icon_scale)
		s.offset = Vector2(0, -s.texture.get_height() * 0.4)
		s.position = it[2]
		s.set_meta("item", it[1])
		parent.add_child(s)
		# 반짝이며 살짝 흔들려서 주울 수 있다는 걸 알려 줘요
		var tw := s.create_tween().set_loops()
		tw.tween_property(s, "rotation", 0.12, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(s, "rotation", -0.12, 0.6).set_trans(Tween.TRANS_SINE)
		out[it[0]] = s
	return out


static func pick_ground(s: Sprite2D, to_node: Node2D) -> void:
	var tw := s.create_tween()
	tw.tween_property(s, "scale", s.scale * Vector2(1.4, 0.6), 0.06)
	tw.tween_property(s, "scale", s.scale * 1.2, 0.08)
	tw.tween_property(s, "position", to_node.position + Vector2(0, -20), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.25)
	tw.tween_callback(s.queue_free)
	Audio.sfx("gather")
