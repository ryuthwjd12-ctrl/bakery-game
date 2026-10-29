extends Node
# 개발용 자동 점검: 손님이 와서 주문하고, 알바생이 갖다주고, 돈을 내고, 청소까지 되는지 봐요.
func _ready():
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start("female", false)
	GameState.known = ["butter_cookie", "warm_milk", "milk_bread"]
	GameState.stock = {"butter_cookie": 5, "warm_milk": 5, "milk_bread": 5}
	var r = GameState.cook(["sugar", "flour", "butter"])
	print("cook: ", r)
	print("fail: ", GameState.cook(["flour", "milk"]))
	await get_tree().create_timer(60.0).timeout
	var dirty = main.hall.tables.filter(func(t): return t.dirty).size()
	print("gold=", GameState.gold, " stock=", GameState.stock, " oven=", GameState.oven, " dirty=", dirty)
	get_tree().quit()
