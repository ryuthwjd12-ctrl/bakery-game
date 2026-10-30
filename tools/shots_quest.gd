extends Node
# 개발용: 부탁 손님(스페셜 요리) 흐름을 찍고 확인해요.
var main
func _ready():
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	main.start("male", false)
	GameState.day = 2
	GameState.minutes = 10 * 60 + 30
	var t = null
	for i in 40:
		GameState.quest_seen_today = false
		main.hall.spawn_left = 0.0
		await _wait(0.6)
		for x in main.hall.tables:
			if x.quest_id != "":
				t = x
		if t:
			break
	await _wait(5.0)
	print("quest table: ", t != null, " state=", t.state if t else "")
	main.hall.player.position = t.stand
	await _wait(0.5); await _shot("q1_star_customer")
	main.hall._take_order(t); await _wait(0.4); await _shot("q2_quest_dialog")
	main.hud.close_panel()
	GameState.active_quest = t.quest_id
	t.take_order()
	main.goto("kitchen"); await _wait(0.5); await _shot("q3_kitchen_banner")
	main.goto("hall", "kitchen")
	var g = GameState.gold
	GameState.add_stock(t.order, 1)
	main.hall._serve(t)
	await _wait(7.5); await _shot("q4_reward")
	print("gold gained: ", GameState.gold - g, " done=", GameState.quests_done)
	get_tree().quit()
func _wait(s): await get_tree().create_timer(s, true).timeout
func _shot(n):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
	print("shot ", n)
