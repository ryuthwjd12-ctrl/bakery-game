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
	main.hud.close_panel()
	GameState.furn_inv = {"table_set": 4, "plant_big": 1, "plant_small": 2}
	main.goto("hall", "village")
	await _wait(0.3)
	var h = main.hall
	h.player.position = Vector2(1600 + 900, 600)
	await _wait(1.0)
	main.hud.toggle_decor(); await _wait(0.3)
	h.hold("table_set"); h.ghost.position = Vector2(1600 + 1300, 120); h._ghost_follow()
	await _wait(0.2); await _shot("a2b_decor_mode")
	for i in 4:
		h.hold("table_set"); h.place_ghost(h.ANNEX_SLOTS[i] + Vector2(1600, 0))
	h.hold("plant_big"); print("plant: ", h.place_ghost(Vector2(1600 + 2150, 440)))
	h.hold("plant_small"); print("plant2: ", h.place_ghost(Vector2(1600 + 1000, 520)))
	h.hold("plant_small"); print("plant hall: ", h.place_ghost(Vector2(300, 560)))
	await _wait(0.3); await _shot("a2c_decor_placed")
	main.hud.toggle_decor()
	print("tables=", GameState.annex_tables, " decor=", GameState.decor, " inv=", GameState.furn_inv)
	h.player.position = Vector2(800, 640)
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
