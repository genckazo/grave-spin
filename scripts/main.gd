extends Control

const TITLE_SCREEN := preload("res://scripts/screens/title_screen.gd")
const FIGHT_SCREEN := preload("res://scripts/screens/fight_screen.gd")
const DRAFT_SCREEN := preload("res://scripts/screens/draft_screen.gd")
const END_SCREEN := preload("res://scripts/screens/end_screen.gd")
const CREDITS_SCREEN := preload("res://scripts/screens/credits_screen.gd")

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


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/generated/background.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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


func on_fight_won() -> void:
	if state == null or state.run_over:
		return
	var outcome := state.on_enemy_defeated()
	if outcome == "victory":
		finish_run(true)
	elif state.draft_options().is_empty():
		state.begin_next_fight()
		show_fight()
	else:
		show_draft()


func on_relic_chosen(relic: Dictionary) -> void:
	if state == null or state.run_over:
		return
	state.choose_relic(relic)
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
