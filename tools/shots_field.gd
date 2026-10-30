extends Node
# 개발용: 숲길 전투·다른 마을·보스·가방·지도·무기 상점을 찍어요.
var main
func _ready():
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	main.start("female", false)
	GameState.gold = 3000
	main.goto("village")
	await _wait(0.5)
	main.current._shop("weapon"); await _wait(0.4); await _shot("f1_weapon_shop")
	main.hud.close_panel()
	# 마을 동쪽 끝으로 걸어 나가기
	main.current.player.position = Vector2(1385, 378)
	main.current.player.walk_to(Vector2(1400, 378))
	await _wait(1.0)
	print("now: ", main.current_name, " ", main.current.get("area_id"))
	await _wait(1.5); await _shot("f2_forest")
	var f = main.current
	# 가장 가까운 몬스터 쪽으로 가서 때리기
	for i in 12:
		if f.monsters.is_empty():
			break
		var m = f.monsters[0]
		f.player.position = m.position + Vector2(-50, 0)
		f.facing = Vector2.RIGHT
		f.attack()
		await _wait(0.5)
		if i == 0:
			await _shot("f3_attack")
	await _wait(0.5); await _shot("f4_after_fight")
	print("hp=", GameState.hp, " gold=", GameState.gold, " inv=", GameState.inv)
	GameState.weapons.append("star_cutter"); GameState.weapon = "star_cutter"
	if not f.monsters.is_empty():
		var m2 = f.monsters[0]
		f.player.position = m2.position + Vector2(-220, 0)
		f.facing = Vector2.RIGHT
		f.attack()
		await _wait(0.15); await _shot("f5_magic")
	await _wait(0.6)
	main.hud.open_bag(); await _wait(0.3); await _shot("f6_bag")
	main.hud.close_panel()
	main.hud.open_world_map(); await _wait(0.3); await _shot("f7_world_map")
	main.hud.close_panel()
	main.goto_field("forest_north", "village"); await _wait(1.0)
	main.current.player.position = Vector2(895, 412); await _wait(0.3)
	main.current._gather("berry_bush"); await _wait(0.8); await _shot("f7b_forest_gather")
	main.goto_field("petal_hill", "forest_north"); await _wait(1.5); await _shot("f8_petal_hill")
	main.current.player.position = Vector2(880, 470); await _wait(1.0); await _shot("f8b_petal_shop")
	main.goto_field("seashell_beach", "forest_east"); await _wait(1.5); await _shot("f9_beach")
	main.goto_field("apple_orchard", "forest_south"); await _wait(1.5); await _shot("f10_orchard")
	main.goto_field("snowflake_village", "forest_west"); await _wait(1.0)
	main.current.player.position = Vector2(950, 690)
	await _wait(2.0); await _shot("f11_boss")
	var sv = main.current
	GameState.weapon = "walnut_hammer"; GameState.hp = 999
	for i in 40:
		if sv.boss == null or not is_instance_valid(sv.boss) or sv.boss.dead:
			break
		sv.player.position = sv.boss.position + Vector2(-60, 10)
		sv.facing = Vector2.RIGHT
		sv.attack()
		await _wait(0.5)
	await _wait(0.8); await _shot("f12_boss_down")
	print("boss_done=", GameState.boss_done, " snow known=", GameState.known.has("snow_cookie"))
	main.hud.close_panel()
	main.current.player.position = Vector2(30, 728)
	main.current.player.walk_to(Vector2(2, 728))
	await _wait(1.0)
	print("after exit: ", main.current_name, " ", main.current.get("area_id"))
	get_tree().quit()
func _wait(s): await get_tree().create_timer(s, true).timeout
func _shot(n):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
	print("shot ", n)
