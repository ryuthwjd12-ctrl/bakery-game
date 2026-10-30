extends Node
# 개발용: 별관·가구점 화면을 찍어요.
var main
func _ready():
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	main.start("female", false)
	GameState.gold = 2000
	await _wait(0.5); await _shot("a1_hall_cam")
	main.goto("village")
	await _wait(0.5)
	main.current._shop("furniture"); await _wait(0.4); await _shot("a2_furniture_shop")
	for i in 4:
		GameState.annex_tables += 1
		main.hall.add_annex_set()
	GameState.decor = 2
	main.hall.add_decor(); main.hall.add_decor()
	main.hud.close_panel()
	main.goto("hall", "village")
	await _wait(0.3)
	main.hall.walk_player(Vector2(1600 + 600, 600))
	await _wait(6.0); await _shot("a3_walk_to_annex")
	print("in annex: ", main.hall.in_annex(main.hall.player.position))
	main.hall.spawn_left = 0.0
	await _wait(12.0); main.hall.spawn_left = 0.0
	await _wait(12.0); await _shot("a4_annex_customers")
	main.hall.walk_player(Vector2(500, 600))
	await _wait(6.0); await _shot("a5_back_hall")
	get_tree().quit()
func _wait(s): await get_tree().create_timer(s, true).timeout
func _shot(n):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
	print("shot ", n)
