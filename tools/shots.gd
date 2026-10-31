extends Node
# 개발용: 화면별 스크린샷을 찍어요. godot res://tools/shots.tscn
var main
func _ready():
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.0); await _shot("01_title")
	main.current._hero_select(); await _wait(0.6); await _shot("02_hero")
	main.start("female", false)
	await _wait(4.2); await _shot("03a_walk_in")
	await _wait(7.8); await _shot("03_hall_customers")
	for t in main.hall.tables:
		if t.state == "ordering":
			t.take_order()
	await _wait(1.0); await _shot("04_hall_ordered")
	main.goto("kitchen")
	await _wait(0.6); await _shot("05_kitchen")
	main.current._open_storage("cabinet"); await _wait(0.5); await _shot("06_cabinet")
	main.current._open_storage("fridge"); await _wait(0.5); await _shot("07_fridge")
	main.current._close_popup()
	for id in ["bowl", "flour", "butter", "sugar"]:
		main.current.slots.append(id)
	main.current._refresh(); await _wait(0.3); await _shot("08_slots")
	main.current._cook(Label.new()); await _wait(1.0); await _shot("09_baking")
	main.goto("village")
	await _wait(1.5); await _shot("10_village")
	await _wait(4.0); await _shot("10b_village_later")
	main.current.player.position = Vector2(561, 300); await _wait(1.5); await _shot("11_village_shop")
	for id in ["ingredient", "interior", "furniture", "dish", "weapon"]:
		main.current._shop(id); await _wait(0.5); await _shot("12_shop_" + id)
		main.hud.close_panel()
	main.current.player.position = Vector2(1000, 420); await _wait(1.5); await _shot("10c_village_east")
	main.current.player.position = Vector2(300, 380); await _wait(1.5); await _shot("10d_village_west")
	# 문으로 걸어가서 다시 들어가지는지
	var v = main.current
	v.player.position = Vector2(700, 540)
	await _wait(0.3)
	v.player.walk_path(v.walk.find_path(v.player.position, v.BAKERY_DOOR))
	await _wait(4.0)
	print("re-entered hall: ", main.current_name)
	if main.current_name != "hall":
		main.goto("hall", "village")
	GameState.add_stock("butter_cookie", 3)
	await _wait(8.0); await _shot("13_hall_later")
	for t in main.hall.tables:
		if t.state == "ordering":
			t.take_order()
	await _wait(0.3); await _shot("13a_orders")
	for t0 in GameState.orders.duplicate():
		for id in t0.wanted():
			GameState.add_stock(id, 1)
		main.hall._serve(t0)
	await _wait(2.5); await _shot("13b_eating")
	main.hud.open_pause(); await _wait(0.4); await _shot("14_pause")
	main.hud.close_panel(); get_tree().paused = false
	main.hud.open_options(false); await _wait(0.4); await _shot("15_options")
	main.hud.close_panel()
	main.hud.toggle_book(); await _wait(0.4); await _shot("16_book")
	main.hud.close_panel()
	GameState.minutes = GameState.DAY_END - 1
	await _wait(3.0); await _shot("17_day_end")
	get_tree().quit()
func _wait(s): await get_tree().create_timer(s, true).timeout
func _shot(n):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
	print("shot ", n)
