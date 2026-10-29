extends Node
# 개발용: 화면별 스크린샷을 찍어요. godot res://tools/shots.tscn
var main
func _ready():
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.0); await _shot("1_title")
	main.start("female", false)
	GameState.add_stock("butter_cookie", 2)
	GameState.known.append("butter_cookie")
	await _wait(9.0); await _shot("2_hall")
	main.goto("kitchen")
	await _wait(0.5)
	main.current._add_slot("flour"); main.current._add_slot("butter"); main.current._add_slot("sugar")
	await _wait(0.5); await _shot("3_kitchen")
	main.current._cook()
	await _wait(0.5); await _shot("4_kitchen_cooked")
	main.goto("village")
	await _wait(0.5); main.hud.open_shop(); await _wait(0.3); await _shot("5_shop")
	main.hud.close_panel(); await _wait(0.3); await _shot("6_village")
	main.hud.toggle_book(); await _wait(0.3); await _shot("7_book")
	main.hud.close_panel()
	GameState.minutes = 9*60
	main.start("male", false)
	await _wait(20.0); await _shot("8_hall_male")
	get_tree().quit()
func _wait(s): await get_tree().create_timer(s).timeout
func _shot(n):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
	print("shot ", n)
