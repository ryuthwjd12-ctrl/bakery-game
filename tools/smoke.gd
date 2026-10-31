extends Node
# 개발용 자동 점검: 손님 주문 → 요리 → 서빙 → 계산 → 청소, 저장·불러오기까지 돌려 봐요.
func _ready():
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start("female", false)
	var h = main.hall
	GameState.furn_inv["table_set"] = 4
	for i in 4:
		h.hold("table_set")
		print("placed: ", h.place_ghost(h.ANNEX_SLOTS[i] + Vector2(h.ANNEX_X, 0)))
	print("bad place: ", h.can_place("table_set", Vector2(100, 100)), " overlap: ", h.can_place("table_set", h.ANNEX_SLOTS[0] + Vector2(h.ANNEX_X + 20, 0)))
	print("walkable spots: ", h.can_walk(h.HALL_ENTRY), h.can_walk(h.ANNEX_ENTRY + Vector2(h.ANNEX_X, 0)),
		h.can_walk(h.KITCHEN_SPOT), h.can_walk(h.KITCHEN_SPOT + Vector2(30, 60)), h.can_walk(h.DOOR), h.can_walk(h.CASE_SPOT),
		h.can_walk(Vector2(h.ANNEX_X + 915, 705)), h.can_walk(h.ANNEX_DOOR), h.can_walk(h.ANNEX_BACK + Vector2(h.ANNEX_X, 0)))
	for t in h.tables:
		if not h.can_walk(t.stand):
			print("stand blocked: ", t.stand)
	print("cross path: ", h.find_path(Vector2(800, 640), Vector2(h.ANNEX_X + 600, 600)).size())
	print("cook ok: ", GameState.cook(["bowl", "flour", "butter", "sugar"]))
	print("cook fail: ", GameState.cook(["flour", "milk"]))
	GameState.add_stock("butter_cookie", 5); GameState.add_stock("warm_milk", 5); GameState.add_stock("milk_bread", 5)
	for i in 40:
		await get_tree().create_timer(1.0).timeout
		for t in main.hall.tables:
			if t.state == "ordering":
				t.take_order()
		# 순서와 상관없이 있는 메뉴부터 내줘요
		for t in GameState.orders.duplicate():
			main.hall._serve(t)
	print("gold=", GameState.gold, " rep=", GameState.rep, " stock=", GameState.stock, " served=", GameState.today)
	GameState.save_game()
	var g = GameState.gold
	GameState.gold = 0
	GameState.load_game()
	print("load ok: ", GameState.gold == g)
	get_tree().quit()
