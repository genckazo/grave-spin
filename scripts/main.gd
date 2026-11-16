extends Control

const TITLE_SCREEN := preload("res://scripts/screens/title_screen.gd")
const FIGHT_SCREEN := preload("res://scripts/screens/fight_screen.gd")
const DRAFT_SCREEN := preload("res://scripts/screens/draft_screen.gd")
const END_SCREEN := preload("res://scripts/screens/end_screen.gd")
const CREDITS_SCREEN := preload("res://scripts/screens/credits_screen.gd")
const SHOP_SCREEN := preload("res://scripts/screens/shop_screen.gd")

var state: GameState
var meta: Dictionary = {}
var current_screen: Control
var screen_root: Control
var fast := false
var autoplay := false
var shots := false
var _dust: CPUParticles2D


func _ready() -> void:
	GameData.ensure_loaded()
	meta = MetaSave.load_meta()
	_build_background()
	screen_root = Control.new()
	screen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_root)

	var args: Array = []
	for a in OS.get_cmdline_args():
		args.append(a)
	for a in OS.get_cmdline_user_args():
		args.append(a)
	fast = (args.has("--fast") or args.has("--autoplay") or args.has("--shots")) and not args.has("--slow")
	autoplay = args.has("--autoplay")
	shots = args.has("--shots")
	if autoplay or shots:
		MetaSave.enabled = false

	# Warm the font cache before the first screen measures text.
	UI.font("body")
	UI.font("header")
	UI.font("title")

	Sfx.play_music()
	show_title()
	if shots:
		_run_shots.call_deferred()
	elif autoplay:
		_run_autoplay.call_deferred()


var _bg_time := 0.0
var _bg_layers: Array = []


func _process(delta: float) -> void:
	# Slow independent drift per layer = parallax. Layers are 1280 wide (two
	# screens) and wrap, so the drift never shows an edge.
	_bg_time += delta
	for layer in _bg_layers:
		var sp: float = layer["speed"]
		layer["node"].position.x = -fmod(_bg_time * sp, 640.0)


func _build_background() -> void:
	# Dusk sky: stacked gradient bands, drawn in-engine (original art).
	var sky := [Color("150e2b"), Color("33183d"), Color("5c2547"), Color("93374a"), Color("cf7440")]
	for i in range(sky.size()):
		var band := ColorRect.new()
		band.color = sky[i]
		band.position = Vector2(0, i * 72.0)
		band.size = Vector2(640, 73)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(band)

	# Moon with a soft halo.
	var moon := Control.new()
	moon.position = Vector2(496, 26)
	moon.size = Vector2(64, 64)
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon.draw.connect(func() -> void:
		moon.draw_circle(Vector2(32, 32), 26, Color(0.95, 0.88, 0.66, 0.16))
		moon.draw_circle(Vector2(32, 32), 20, Color("f2e3b6"))
	)
	add_child(moon)

	# Far ridge — slow layer.
	add_child(_ridge_layer(Color("241536"), 210.0, 0.10, 26.0))
	# Near graveyard — faster layer with headstones and a dead tree.
	add_child(_graveyard_layer())

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.03, 0.18)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_dust = CPUParticles2D.new()
	_dust.position = Vector2(320, 352)
	_dust.amount = 26
	_dust.lifetime = 11.0
	_dust.preprocess = 11.0
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(320, 8)
	_dust.direction = Vector2(0, -1)
	_dust.spread = 30.0
	_dust.gravity = Vector2(0, -2)
	_dust.initial_velocity_min = 3.0
	_dust.initial_velocity_max = 12.0
	_dust.scale_amount_min = 0.4
	_dust.scale_amount_max = 1.4
	_dust.color = Color(0.86, 0.76, 0.6, 0.34)
	_dust.texture = load("res://assets/generated/dust.png")
	_dust.emitting = true
	add_child(_dust)


func _ridge_layer(color: Color, base_y: float, speed: float, amp: float) -> Control:
	var c := Control.new()
	c.position = Vector2(0, 0)
	c.size = Vector2(1280, 360)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pts := PackedVector2Array()
	for x in range(0, 1281, 40):
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(x * 0.011)) - amp * 0.5 * sin(x * 0.031 + 2.0)))
	pts.append(Vector2(1280, 360))
	pts.append(Vector2(0, 360))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	c.add_child(poly)
	_bg_layers.append({"node": c, "speed": speed})
	return c


func _graveyard_layer() -> Control:
	var c := Control.new()
	c.position = Vector2(0, 0)
	c.size = Vector2(1280, 360)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ground := ColorRect.new()
	ground.color = Color("120a1e")
	ground.position = Vector2(0, 268)
	ground.size = Vector2(1280, 92)
	c.add_child(ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777001
	for i in range(9):
		var x := 30.0 + i * 140.0 + rng.randf() * 40.0
		var h := 22.0 + rng.randf() * 16.0
		var stone := Polygon2D.new()
		var w := 12.0 + rng.randf() * 6.0
		stone.polygon = PackedVector2Array([
			Vector2(x, 268), Vector2(x, 268 - h + 6), Vector2(x + w * 0.5 - 3, 268 - h),
			Vector2(x + w * 0.5 + 3, 268 - h), Vector2(x + w, 268 - h + 6), Vector2(x + w, 268),
		])
		stone.color = Color("1d1030")
		c.add_child(stone)
	# A crooked dead tree silhouette.
	var tree := Polygon2D.new()
	tree.polygon = PackedVector2Array([
		Vector2(600, 268), Vector2(604, 200), Vector2(598, 200), Vector2(610, 168),
		Vector2(604, 170), Vector2(606, 150), Vector2(612, 152), Vector2(608, 172),
		Vector2(620, 158), Vector2(614, 176), Vector2(622, 210), Vector2(616, 210),
		Vector2(620, 268),
	])
	tree.color = Color("0c0714")
	c.add_child(tree)
	_bg_layers.append({"node": c, "speed": 0.22})
	return c


func set_screen(node: Control) -> void:
	if current_screen != null:
		current_screen.queue_free()
	current_screen = node
	screen_root.add_child(node)
	node.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 1.0, 0.16 if not fast else 0.01)


func show_title() -> void:
	meta = MetaSave.load_meta() if MetaSave.enabled else meta
	var s = TITLE_SCREEN.new()
	s.main = self
	s.meta = meta
	set_screen(s)


func start_run(seed_value: int = 0) -> void:
	state = GameState.new()
	state.start_run(seed_value)
	show_fight()


func show_fight() -> void:
	var s = FIGHT_SCREEN.new()
	s.main = self
	s.state = state
	set_screen(s)


func show_draft() -> void:
	var s = DRAFT_SCREEN.new()
	s.main = self
	s.state = state
	set_screen(s)


func show_shop() -> void:
	var s = SHOP_SCREEN.new()
	s.main = self
	s.state = state
	set_screen(s)


func on_shop_done() -> void:
	if state == null or state.run_over:
		return
	state.begin_next_fight()
	show_fight()


func on_fight_won() -> void:
	if state == null or state.run_over:
		return
	var outcome := state.on_enemy_defeated()
	if outcome == "victory":
		finish_run(true)
	elif state.draft_options().is_empty():
		if state.shop_pending:
			state.shop_pending = false
			show_shop()
		else:
			state.begin_next_fight()
			show_fight()
	else:
		show_draft()


func on_relic_chosen(relic: Dictionary) -> void:
	if state == null or state.run_over:
		return
	state.choose_relic(relic)
	if state.shop_pending:
		state.shop_pending = false
		show_shop()
	else:
		state.begin_next_fight()
		show_fight()


func finish_run(victory: bool) -> void:
	if state == null:
		return
	state.victory = victory
	state.run_over = true
	var earned := state.bone_coins_earned()
	if MetaSave.enabled:
		meta["bone_coins"] = int(meta.get("bone_coins", 0)) + earned
		meta["best_fights"] = max(int(meta.get("best_fights", 0)), state.fights_won)
		meta["runs"] = int(meta.get("runs", 0)) + 1
		meta["best_victory"] = bool(meta.get("best_victory", false)) or victory
		MetaSave.save_meta(meta)
	var s = END_SCREEN.new()
	s.main = self
	s.state = state
	s.earned = earned
	s.total_bones = int(meta.get("bone_coins", 0))
	set_screen(s)


func show_credits() -> void:
	var s = CREDITS_SCREEN.new()
	s.main = self
	set_screen(s)


func _run_autoplay() -> void:
	await get_tree().process_frame
	start_run(1234567)
	await get_tree().process_frame
	var guard := 0
	var reached_end := false
	var last_spins := -1
	while guard < 600:
		guard += 1
		await get_tree().process_frame
		if current_screen == null:
			continue
		if current_screen is FightScreen:
			var fight := current_screen as FightScreen
			if fight.busy:
				await get_tree().create_timer(0.02).timeout
				continue
			if fight.state == null:
				continue
			last_spins = fight.state.spin_count
			await fight.debug_pull()
		elif current_screen is DraftScreen:
			var draft := current_screen as DraftScreen
			draft.debug_pick(0)
			await get_tree().create_timer(0.02).timeout
		elif current_screen is ShopScreen:
			var shop := current_screen as ShopScreen
			shop.debug_leave()
			await get_tree().create_timer(0.02).timeout
		elif current_screen is EndScreen:
			reached_end = true
			break
	if state != null:
		print("AUTOPLAY result=%s fights=%d spins=%d coins=%d relics=%d bones=%d" % [
			"WIN" if state.victory else "LOSS",
			state.fights_won, state.spin_count, state.coins, state.relics.size(),
			state.bone_coins_earned(),
		])
	print("AUTOPLAY reached_end=%s last_spins=%d guard=%d" % [reached_end, last_spins, guard])
	get_tree().quit(0 if reached_end else 1)


func _run_shots() -> void:
	await get_tree().create_timer(0.5).timeout
	await _shot("01_title")
	start_run(424242)
	await get_tree().create_timer(0.4).timeout
	await _shot("02_fight")
	if current_screen is FightScreen:
		var fight := current_screen as FightScreen
		await fight.debug_pull()
		await get_tree().create_timer(0.25).timeout
		await _shot("03_fight_after_spin")
		fight.debug_pause()
		await get_tree().create_timer(0.2).timeout
		await _shot("04_pause")
		fight.debug_resume()
	state.fights_won = 2
	state.fight_index = 2
	state.coins = 23
	state.hp = 34
	show_draft()
	await get_tree().create_timer(0.3).timeout
	await _shot("05_draft")
	state.fights_won = 5
	state.coins = 47
	state.spin_count = 24
	state.stats = {"spins": 24, "damage_dealt": 143, "damage_taken": 58, "healed": 41, "blocked": 37}
	state.relics = GameData.relics.slice(0, 4)
	state.victory = true
	var s = END_SCREEN.new()
	s.main = self
	s.state = state
	s.earned = 14
	s.total_bones = 32
	set_screen(s)
	await get_tree().create_timer(1.1).timeout
	await _shot("06_victory")
	state.fights_won = 3
	state.coins = 31
	state.spin_count = 17
	state.stats = {"spins": 17, "damage_dealt": 86, "damage_taken": 54, "healed": 25, "blocked": 21}
	state.relics = GameData.relics.slice(0, 2)
	state.victory = false
	var s2 = END_SCREEN.new()
	s2.main = self
	s2.state = state
	s2.earned = 5
	s2.total_bones = 23
	set_screen(s2)
	await get_tree().create_timer(0.9).timeout
	await _shot("07_death")
	show_credits()
	await get_tree().create_timer(0.3).timeout
	await _shot("08_credits")
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://build/shots")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join(name + ".png"))
	print("SHOT " + name)
