extends Node2D
## 도토리 마을 밖의 지역(숲길, 다른 마을). Areas의 설정대로 지도를 깔고,
## 위험 지역에서는 몬스터가 나와요. 공격은 장착한 무기가 정해요(근접: 휘두르기, 마법: 반짝이 쏘기).

const Player := preload("res://scripts/player.gd")
const Monster := preload("res://scripts/monster.gd")
const Animal := preload("res://scripts/animal.gd")

var main: Node
var area_id := ""
var from := ""
var area: Dictionary
var walk: WalkMap
var world := Node2D.new()
var player
var cam := Camera2D.new()
var monsters: Array = []
var respawn: Array = []  # 남은 시간 목록
var facing := Vector2.RIGHT
var attack_cd := 0.0
var attacking := false
var invuln := 0.0
var player_down := false
var near = null
var pending := ""  # 눌러서 걸어가는 중인 대상 이름(닿으면 E 없이 바로 해요)
var mp_regen := 0.0
var boss = null
var aim := Vector2.RIGHT  # 이번 공격이 향하는 방향(8방향이 아니라 마우스 쪽 그대로)
var use_mouse_aim := true  # 테스트에서는 꺼요
var snow_cd := 3.0
var overlays := {}
var occluders: Array = []  # [Polygon2D, 지도 기준 모양, base_y]
var residents: Array = []
const TOWN_TALK := ["어서 와! 도토리 마을에서 왔구나?", "빵 냄새가 여기까지 나는 것 같아.", "우리 마을 구경하고 가!",
	"다음에 빵집에 놀러 갈게.", "오늘 날씨 좋다~", "가게는 저쪽이야!"]
var ground := {}
## 채집할 수 있는 곳: 지도 그림 → {덮개 id: [재료, 개수 최소, 최대, 서는 곳]}
const GATHER := {
	"maps/forest_path": {"strawberry_patch": ["strawberry", 2, 3, Vector2(1060, 528)],
		"berry_bush": ["raspberry", 1, 2, Vector2(895, 410)], "berry_bottom": ["strawberry", 1, 2, Vector2(790, 562)],
		"berry_left": ["raspberry", 1, 2, Vector2(430, 548)]},
	"maps/apple_orchard": {"apple": ["apple", 1, 2, Vector2(716, 478)], "peach": ["peach", 1, 2, Vector2(440, 350)],
		"lemon": ["lemon", 1, 2, Vector2(1013, 400)], "grape": ["grape", 1, 2, Vector2(164, 380)],
		"blueberry": ["blueberry", 2, 3, Vector2(166, 455)], "strawberry": ["strawberry", 2, 3, Vector2(210, 330)]},
	"maps/petal_hill": {"beehive": ["honey_jar", 1, 1, Vector2(491, 590)]},
}
## 숲 바닥에 떨어진 재료
const GROUND := [["g1", "walnut", Vector2(160, 330)], ["g2", "acorn", Vector2(700, 300)],
	["g3", "acorn", Vector2(1000, 330)], ["g4", "walnut", Vector2(620, 470)]]


func _ready() -> void:
	area = Areas.get_area(area_id)
	var bg := Sprite2D.new()
	bg.texture = Sprites.tex(area.bg)
	bg.centered = false
	bg.modulate = area.get("tint", Color.WHITE)
	add_child(bg)
	var over_layer := Node2D.new()
	over_layer.modulate = area.get("tint", Color.WHITE)
	add_child(over_layer)
	overlays = Gather.add_overlays(over_layer, area.bg, area_id + "_")
	world.y_sort_enabled = true
	add_child(world)
	for oc in area.get("occluders", []):
		_add_occluder(oc)
	if area.has("monsters"):
		ground = Gather.add_ground_items(world, GROUND, area_id + "_", 0.26)
	walk = WalkMap.new(area.area, area.blocks, 12, Vector2i(area.size))

	player = Player.new()
	player.setup(GameState.hero, area.hero)
	player.speed = 260.0 * area.hero / 0.68 * 0.75
	player.can_walk = can_walk
	player.position = area.entries.get(from, area.entries.values()[0])
	world.add_child(player)
	_add_attack_anims()
	var z: float = GameState.zoom.get("field", area.zoom)
	cam.zoom = Vector2(z, z)
	cam.set_meta("zoom_key", "field")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(area.size.x)
	cam.limit_bottom = int(area.size.y)
	cam.position_smoothing_enabled = true
	player.add_child(cam)
	cam.make_current()

	if area.has("shop"):
		var npc := Animal.new()
		npc.setup(area.shop.npc, area.hero * 1.3 * Sprites.size_fix(area.shop.npc))
		npc.position = area.shop.pos
		world.add_child(npc)
		# 한 마을에는 한 동물만 살아요: 가게 주인과 같은 동물 주민이 돌아다녀요.
		GameState.visit(area_id)
		var kinds: Array = GameState.VILLAGE_ANIMAL.get(area_id, [area.shop.npc])
		for i in 3:
			_spawn_resident(kinds[(i + 1) % kinds.size()])
	for e in area.exits:
		_signpost(e)
	for i in area.get("count", 0):
		_spawn_monster()
	Audio.play_bgm("bgm_forest" if area.has("monsters") or area.has("boss") else "bgm_village")
	add_child(Weather.new())  # 시간 따라 하늘빛, 비 오는 날엔 비
	main.hud.show_toast(area.name + (" — 몬스터 조심!" if area.has("monsters") else ""))


## 나무 모양으로 지도 그림을 잘라 세워요. 밑동보다 위(뒤)에 선 주인공은 잎에 가려져요.
func _add_occluder(oc: Dictionary) -> void:
	var holder := Node2D.new()
	holder.position = Vector2(0, oc.base_y)
	var poly := Polygon2D.new()
	poly.texture = Sprites.tex(area.bg)
	var pts := PackedVector2Array(oc.poly)
	poly.uv = pts
	var moved := PackedVector2Array()
	for q in pts:
		moved.append(q - Vector2(0, oc.base_y))
	poly.polygon = moved
	if area.has("tint"):
		poly.color = area.tint
	holder.add_child(poly)
	world.add_child(holder)
	occluders.append([poly, pts, float(oc.base_y)])


## 주인공 그림에 공격 동작(휘두르기·마법)을 더해요.
func _add_attack_anims() -> void:
	var sf: SpriteFrames = player.sprite.sprite_frames.duplicate()
	for pair in [["attack", "_attack"], ["cast", "_cast"]]:
		var key: String = GameState.hero + pair[1]
		if Sprites.has_strip(key) and not sf.has_animation(pair[0]):
			Sprites._add(sf, pair[0], key, 12.0)
			sf.set_animation_loop(pair[0], false)
	player.sprite.sprite_frames = sf


func _signpost(e: Dictionary) -> void:
	if e.label == "":
		return
	var c0: Vector2 = e.rect.get_center()
	var arrow := "← " if c0.x < 60 else ("→ " if c0.x > area.size.x - 60 else ("↓ " if c0.y > area.size.y / 2 else "↑ "))
	var l := UI.label(arrow + e.label, 12)
	l.add_theme_stylebox_override("normal", UI.box(UI.APRON, UI.OUTLINE, 8, 1))
	l.z_index = 40
	var c: Vector2 = e.rect.get_center()
	l.position = Vector2(clampf(c.x, 20, area.size.x - 110), clampf(c.y, 20, area.size.y - 40)) - Vector2(30, 40)
	add_child(l)


func _spawn_resident(kind: String) -> void:
	var a := Animal.new()
	a.setup(kind, area.hero * 1.2 * Sprites.size_fix(kind))
	a.speed = 40.0
	a.position = walk.random_point()
	world.add_child(a)
	residents.append(a)
	_wander(a)


func _wander(a) -> void:
	while is_instance_valid(a) and a.is_inside_tree():
		var to := walk.random_point()
		if to.distance_to(a.position) > 500:
			await get_tree().process_frame
			continue
		await a.walk_path(walk.find_path(a.position, to))
		if not is_instance_valid(a):
			return
		a.idle()
		await get_tree().create_timer(randf_range(1.5, 4.0)).timeout


func can_walk(p: Vector2) -> bool:
	return walk.can_walk(p)


func _spawn_monster() -> void:
	var kinds: Array = area.get("monsters", [])
	if kinds.is_empty():
		return
	var p := walk.random_point()
	for i in 20:
		if p.distance_to(player.position) > 300:
			break
		p = walk.random_point()
	var m := Monster.new()
	m.setup(kinds.pick_random(), area.hero * 1.35)
	m.field = self
	m.position = p
	m.home = p
	m.died.connect(_on_monster_died)
	world.add_child(m)
	monsters.append(m)


func _on_monster_died(m) -> void:
	monsters.erase(m)
	var d: Dictionary = m.data
	if m.boss:
		_boss_defeated()
		return
	GameState.gold += d.gold
	GameState.stats.monsters = GameState.stats.get("monsters", 0) + 1
	var msg := "+%d골드" % d.gold
	if d.drop != "" and randf() < 0.7:
		GameState.add_item(d.drop, 1)
		msg += "  %s +1" % GameState.item_name(d.drop)
		_fly_icon(Sprites.item(d.drop), m.position)
	GameState.changed.emit()
	float_text(m.position + Vector2(0, -40), msg, Color("#B8741A"))
	respawn.append(12.0)


func _fly_icon(tex: Texture2D, at: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(0.4, 0.4)
	s.position = at + Vector2(0, -30)
	s.z_index = 60
	add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "position:y", s.position.y - 30, 0.25)
	tw.tween_property(s, "position", player.position + Vector2(0, -60), 0.3)
	tw.tween_callback(s.queue_free)


func float_text(at: Vector2, text: String, col: Color, dur := 0.8) -> void:
	var l := UI.label(text, 16, col)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 6)
	l.position = at - Vector2(30, 0)
	l.z_index = 80
	add_child(l)
	var tw := l.create_tween()
	if dur > 1.0:
		tw.tween_interval(dur - 0.8)
	tw.tween_property(l, "position:y", at.y - 40, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)


func hurt_player(dmg: int, dir: Vector2) -> void:
	if invuln > 0 or player_down:
		return
	invuln = 1.0
	GameState.hp = maxi(0, GameState.hp - dmg)
	GameState.changed.emit()
	Audio.sfx("hurt")
	UI.pop(player.sprite, 0.18)
	float_text(player.position + Vector2(0, -90), "-%d" % dmg, Color("#E0675A"))
	var np: Vector2 = player.position + dir * 26
	if can_walk(np):
		player.position = np
	if GameState.hp <= 0:
		_faint()


## 쓰러지면 골드를 조금 잃고 가게에서 눈을 떠요.
func _faint() -> void:
	player_down = true
	player.active = false
	player.posing = true
	# 비틀비틀하다 옆으로 털썩 쓰러지고, 머리 위로 별이 빙글빙글 돌아요
	var sp: AnimatedSprite2D = player.sprite
	sp.stop()
	var tw := sp.create_tween()
	tw.tween_property(sp, "rotation", -0.25, 0.12)
	tw.tween_property(sp, "rotation", 0.25, 0.14)
	tw.tween_property(sp, "rotation", PI / 2 * (-1.0 if sp.flip_h else 1.0), 0.28).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sp, "position:y", 6.0, 0.28)
	tw.tween_property(sp, "scale", sp.scale * Vector2(1.05, 0.92), 0.08)
	tw.tween_property(sp, "scale", sp.scale, 0.1)
	var stars := Node2D.new()
	stars.position = Vector2(0, -30)
	stars.z_index = 80
	stars.draw.connect(func():
		var t := Time.get_ticks_msec() * 0.004
		for i in 3:
			var p := Vector2(cos(t + i * TAU / 3) * 22, sin(t + i * TAU / 3) * 7)
			stars.draw_circle(p, 4, Color("#FFD966"))
			stars.draw_line(p - Vector2(6, 0), p + Vector2(6, 0), Color("#FFD966"), 2)
			stars.draw_line(p - Vector2(0, 6), p + Vector2(0, 6), Color("#FFD966"), 2))
	player.add_child(stars)
	var spin := stars.create_tween().set_loops()
	spin.tween_callback(stars.queue_redraw).set_delay(0.03)
	Audio.sfx("hurt", 0.7)
	var lost := int(GameState.gold * 0.1)
	GameState.gold -= lost
	GameState.hp = GameState.max_hp() / 2
	main.hud.show_toast("쓰러졌어요… 숲속 친구들이 가게까지 데려다줬어요. (%d골드를 잃었어요)" % lost)
	await get_tree().create_timer(2.4).timeout
	main.goto("hall", "village")


func _process(delta: float) -> void:
	if player_down:
		return
	attack_cd -= delta
	invuln -= delta
	player.sprite.modulate.a = 0.5 if invuln > 0 and int(invuln * 10) % 2 == 0 else 1.0
	mp_regen += delta
	if mp_regen > 2.0:
		mp_regen = 0.0
		if GameState.mp < GameState.max_mp():
			GameState.mp += 1
			GameState.changed.emit()
		if not area.has("monsters") and GameState.hp < GameState.max_hp():
			GameState.hp = mini(GameState.max_hp(), GameState.hp + 4)
			GameState.changed.emit()
	for i in range(respawn.size() - 1, -1, -1):
		respawn[i] -= delta
		if respawn[i] <= 0:
			respawn.remove_at(i)
			_spawn_monster()
	if player.target != null:
		facing = _dir4(player.target - player.position)
	var mv := Vector2(float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	if mv != Vector2.ZERO:
		facing = _dir4(mv)
	_check_boss(delta)
	for e in area.exits:
		if e.rect.has_point(player.position):
			_leave(e.to)
			return
	# 나무 뒤에 서면 잎을 반쯤 투명하게 해서 주인공이 보이게 해요
	for oc in occluders:
		var behind: bool = player.position.y < oc[2] and Geometry2D.is_point_in_polygon(player.position + Vector2(0, -30), oc[1])
		oc[0].modulate.a = move_toward(oc[0].modulate.a, 0.5 if behind else 1.0, delta * 4.0)
	near = _find_near()
	if pending != "" and near and near.text == pending and player.waypoints.is_empty() and not main.hud.is_panel_open():
		pending = ""
		near.do.call()
		return
	player.active = not main.hud.is_panel_open()
	if near and player.active:
		main.hud.set_prompt("E  " + near.text, get_viewport().get_canvas_transform() * (player.position + Vector2(0, 10)))
	else:
		main.hud.set_prompt("", Vector2.ZERO)


func _find_near():
	var p: Vector2 = player.position
	if area.has("shop") and p.distance_to(area.shop.pos) < 60:
		return {"text": area.shop.name, "do": func():
			main.hud.shop_ctx = area.shop.get("look", "")
			main.hud.open_trade(area.shop.name, area.shop.items)}
	for a in residents:
		if is_instance_valid(a) and p.distance_to(a.position) < 40:
			return {"text": GameState.friend_action(a.kind), "do": _greet.bind(a)}
	var spots: Dictionary = GATHER.get(area.bg, {})
	for sid in spots:
		if not GameState.picked_today.has(area_id + "_" + sid) and p.distance_to(spots[sid][3]) < 55:
			return {"text": GameState.item_name(spots[sid][0]) + " 따기", "do": _gather.bind(sid)}
	for gid in ground:
		if is_instance_valid(ground[gid]) and p.distance_to(ground[gid].position) < 40:
			return {"text": "줍기", "do": _pick_ground.bind(gid)}
	return null


func _greet(a) -> void:
	var k: String = a.kind
	var line: String = TOWN_TALK.pick_random()
	if not GameState.talked_today.has(k):
		GameState.talk(k)
	elif not GameState.gifted_today.has(k):
		var food := GameState.gift(k)
		if food != "":
			line = "와, %s! 정말 고마워!" % GameState.item_name(food)
			Audio.sfx("sparkle")
	float_text(a.position + Vector2(0, -60), line + "\n" + GameState.heart_text(k), Color("#C0566B"), 2.6)
	Audio.sfx("order")
	UI.pop(a.sprite, 0.15)


func _gather(sid: String) -> void:
	var g: Array = GATHER[area.bg][sid]
	var n := randi_range(g[1], g[2])
	GameState.picked_today.append(area_id + "_" + sid)
	GameState.add_item(g[0], n)
	player.work(0.5)
	Gather.pick_fx(world, overlays.get(sid), g[0], n, player, 0.3)
	main.hud.show_toast("%s %d개를 땄어요! 내일 다시 열려요." % [GameState.item_name(g[0]), n])


func _pick_ground(gid: String) -> void:
	var s: Sprite2D = ground[gid]
	ground.erase(gid)
	GameState.picked_today.append(area_id + "_" + gid)
	var item: String = s.get_meta("item")
	GameState.add_item(item, 1)
	Gather.pick_ground(s, player)
	main.hud.show_toast("%s 1개를 주웠어요." % GameState.item_name(item))


func _dir4(v: Vector2) -> Vector2:
	if absf(v.x) >= absf(v.y):
		return Vector2.RIGHT if v.x >= 0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0 else Vector2.UP


func _leave(to: String) -> void:
	set_process(false)
	Audio.sfx("door")
	if to == "village":
		main.goto("village", area_id)
	else:
		main.goto_field(to, area_id)


func _unhandled_input(event: InputEvent) -> void:
	if main.hud.is_panel_open() or player_down:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and near:
			near.do.call()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_J:
			attack()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1 or event.keycode == KEY_2:
			var id := "hp_potion" if event.keycode == KEY_1 else "mp_potion"
			if GameState.drink(id):
				Audio.sfx("sparkle")
				UI.pop(player.sprite, 0.15)
				main.hud.show_toast("%s을 마셨어요!" % GameState.item_name(id))
			get_viewport().set_input_as_handled()
	elif UI.wheel_zoom(cam, event, 1.0, 2.4):
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var to: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		if event.button_index == MOUSE_BUTTON_RIGHT:
			attack()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			UI.ripple(self, to, 14.0)
			pending = ""
			var t = _click_target(to)
			if t:
				pending = t[0]
				to = t[1]
			player.walk_path(walk.find_path(player.position, to))


## 누른 곳의 가게·주민·열매·떨어진 재료 [이름, 걸어갈 곳]
func _click_target(p: Vector2):
	if area.has("shop") and (p.distance_to(area.shop.pos) < 70 or Rect2(area.shop.pos + Vector2(-110, -230), Vector2(220, 230)).has_point(p)):
		return [area.shop.name, area.shop.pos]
	for a in residents:
		if is_instance_valid(a) and p.distance_to(a.position + Vector2(0, -20)) < 40:
			return [GameState.friend_action(a.kind), a.position]
	var spots: Dictionary = GATHER.get(area.bg, {})
	for sid in spots:
		if not GameState.picked_today.has(area_id + "_" + sid) and p.distance_to(spots[sid][3]) < 60:
			return [GameState.item_name(spots[sid][0]) + " 따기", spots[sid][3]]
	for gid in ground:
		if is_instance_valid(ground[gid]) and p.distance_to(ground[gid].position) < 30:
			return ["줍기", ground[gid].position]
	return null


## 장착한 무기로 공격해요. 근접 무기는 앞을 휘두르고, 마법 무기는 반짝이를 날려요.
func attack() -> void:
	if attack_cd > 0 or attacking:
		return
	var w: Dictionary = GameState.WEAPONS[GameState.weapon]
	if w.type == "magic":
		if GameState.mp < w.mp:
			main.hud.show_toast("마나가 모자라요. 잠깐 쉬면 조금씩 차요.")
			Audio.sfx("fail")
			attack_cd = 0.5
			return
		GameState.mp -= w.mp
		GameState.changed.emit()
	attack_cd = 0.45 if w.type == "melee" else 0.6
	# 마우스가 가리키는 쪽으로 공격해요(마법은 그 방향으로 곧게 날아가요). 마우스를 안 쓰면 보는 방향으로.
	aim = facing
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()) and use_mouse_aim:
		var to: Vector2 = get_global_mouse_position() - (player.position + Vector2(0, -50))
		if to.length() > 8.0:
			aim = to.normalized()
			facing = _dir4(aim)
	attacking = true
	player.posing = true
	player.target = null
	player.waypoints.clear()
	var anim := "attack" if w.type == "melee" else "cast"
	var sf: SpriteFrames = player.sprite.sprite_frames
	var key: String = GameState.hero + ("_attack" if w.type == "melee" else "_cast")
	var walk_off: Vector2 = player.sprite.offset
	if sf.has_animation(anim):
		player.sprite.offset = Vector2(0, -Sprites.frame_height(key) / 2.0)
		player.sprite.flip_h = facing.x < 0
		player.sprite.play(anim)
	if w.type == "melee":
		Audio.sfx("swing", randf_range(0.95, 1.1))
		_swing_fx(w)
		for m in monsters.duplicate():
			var d: Vector2 = m.position - player.position
			var reach := 62.0 if not m.boss else 110.0
			if d.length() < reach and (d.normalized().dot(aim) > 0.3 or d.length() < 24):
				m.hit(w.power, player.position)
	else:
		Audio.sfx("magic", randf_range(0.95, 1.1))
		_shoot(w)
	await get_tree().create_timer(0.32).timeout
	if is_instance_valid(player):
		player.sprite.offset = walk_off
		player.sprite.play("right" if facing.x != 0 else ("back" if facing.y < 0 else "front"))
		player.sprite.flip_h = facing.x < 0
		player.sprite.stop()
		player.posing = false
	attacking = false


func _swing_fx(w: Dictionary) -> void:
	var arc := Node2D.new()
	arc.position = player.position + Vector2(0, -40) + aim * 30
	arc.z_index = 70
	var ang := aim.angle()
	arc.draw.connect(func():
		arc.draw_arc(Vector2.ZERO, 34, ang - 1.0, ang + 1.0, 14, Color(1, 1, 1, 0.85), 6)
		arc.draw_arc(Vector2.ZERO, 26, ang - 0.8, ang + 0.8, 12, Color(1, 0.9, 0.6, 0.7), 3))
	add_child(arc)
	var tw := arc.create_tween()
	tw.tween_property(arc, "modulate:a", 0.0, 0.25)
	tw.tween_callback(arc.queue_free)


## 마법: 반짝이가 겨눈 방향으로 곧게 날아가다 처음 닿은 몬스터를 맞혀요(따라가지 않아요).
func _shoot(w: Dictionary) -> void:
	var dir := aim
	var s := Node2D.new()
	s.position = player.position + Vector2(0, -50) + dir * 20
	s.z_index = 70
	s.draw.connect(func():
		for i in 4:
			var a := i * PI / 2 + Time.get_ticks_msec() * 0.01
			s.draw_line(Vector2.ZERO, Vector2.from_angle(a) * 12, Color("#FFE08A"), 3)
		s.draw_circle(Vector2.ZERO, 6, Color(1, 1, 0.85)))
	add_child(s)
	var dist := 0.0
	while is_instance_valid(s) and dist < 420.0:
		await get_tree().process_frame
		if not is_instance_valid(s):
			return
		var step := 520.0 * get_process_delta_time()
		s.position += dir * step
		dist += step
		s.queue_redraw()
		for m in monsters.duplicate():
			if is_instance_valid(m) and (m.position + Vector2(0, -30)).distance_to(s.position) < (22.0 if not m.boss else 70.0):
				m.hit(w.power, s.position)
				s.queue_free()
				return
	if is_instance_valid(s):
		s.queue_free()


# ---- 눈사람 거인
func _check_boss(delta: float) -> void:
	if not area.has("boss") or GameState.boss_done:
		return
	if boss == null:
		if player.position.distance_to(area.boss.pos) < area.boss.trigger:
			boss = Monster.new()
			boss.setup("snowman", area.hero * 1.4)
			boss.field = self
			boss.position = area.boss.pos + Vector2(0, -40)
			boss.home = boss.position
			boss.died.connect(_on_monster_died)
			world.add_child(boss)
			monsters.append(boss)
			main.hud.show_toast("눈사람 거인이 나타났어요! 눈덩이를 피하며 싸워요.")
			Audio.sfx("fail", 0.6)
		return
	if not is_instance_valid(boss) or boss.dead:
		return
	snow_cd -= delta
	if snow_cd <= 0:
		snow_cd = 2.6
		boss.show_pose(load("res://assets/monsters/snowman_throw.png"), 0.45)
		_snowball(boss.position + Vector2(0, -60), (player.position + Vector2(0, -30) - boss.position - Vector2(0, -60)).normalized())


func _snowball(from_p: Vector2, dir: Vector2) -> void:
	var s := Node2D.new()
	s.position = from_p
	s.z_index = 70
	s.draw.connect(func():
		s.draw_circle(Vector2.ZERO, 11, UI.OUTLINE)
		s.draw_circle(Vector2.ZERO, 9, Color.WHITE))
	add_child(s)
	var dist := 0.0
	while is_instance_valid(s) and dist < 600.0:
		await get_tree().process_frame
		if not is_instance_valid(s) or player_down:
			break
		var step := 300.0 * get_process_delta_time()
		s.position += dir * step
		dist += step
		if s.position.distance_to(player.position + Vector2(0, -30)) < 26:
			hurt_player(12, dir)
			break
	if is_instance_valid(s):
		s.queue_free()


func _boss_defeated() -> void:
	GameState.boss_done = true
	GameState.gold += 500
	if not GameState.known.has("snow_cookie"):
		GameState.known.append("snow_cookie")
	GameState.add_rep(5)
	GameState.changed.emit()
	GameState.save_game()
	Audio.sfx("sparkle")
	var down := Sprite2D.new()
	down.texture = load("res://assets/monsters/snowman_down.png")
	var ds: float = area.hero * 1.4 * 200.0 / boss.front.get_height()
	down.offset = Vector2(0, -down.texture.get_height() / 2.0)
	down.scale = Vector2(ds, ds)
	down.position = boss.position
	world.add_child(down)
	main.hud.notice("눈사람 거인을 이겼어요!", "\"헤헤, 졌다! 너무 신나게 놀았어.\n고마움의 선물로 눈꽃 쿠키 만드는 법을 알려 줄게.\"\n\n500골드와 눈꽃 쿠키 레시피를 얻었어요!\n(밀가루 + 설탕 + 버터 + 생크림 + 별 틀)")
