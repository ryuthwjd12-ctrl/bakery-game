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
	main.current.player.position = Vector2(525, 260); await _wait(1.5); await _shot("11_village_shop")
	main.hud.open_shop(); await _wait(0.4); await _shot("12_shop")
	main.hud.close_panel()
	main.goto("hall", "village")
	GameState.add_stock("butter_cookie", 3)
	await _wait(8.0); await _shot("13_hall_later")
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
