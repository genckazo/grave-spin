extends SceneTree
## Real balance sim — drives the same GameState the game uses (replaces the old
## Python approximation). Auto-player: bet 1, draft a random offered relic.
## Run:
##   Godot --headless --path . -s res://tools/balance_sim.gd
## PASS requires every seed's win rate inside the 40-60% band.

const RUNS := 1000
const SEEDS := [12345, 777, 2024, 99999, 31337]


func _init() -> void:
	GameData.ensure_loaded()
	var mode := "normal"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.trim_prefix("--mode=")
	var band_low := 0.40
	var band_high := 0.60
	if mode == "high_roller":
		band_low = 0.15
		band_high = 0.35
	var all_ok := true
	for seed_base in SEEDS:
		var wins := 0
		var spins_total := 0
		var fights_total := 0
		var depth_total := 0
		for i in range(RUNS):
			var s := GameState.new()
			s.start_run(seed_base + i, mode)
			var guard := 0
			while not s.run_over and guard < 900:
				guard += 1
				var roll: Dictionary = s.roll()
				var rep: Dictionary = s.resolve(roll["grid"])
				if bool(rep.get("enemy_dead", false)):
					var outcome := s.on_enemy_defeated()
					if outcome == "victory":
						break
					var opts := s.draft_options()
					if opts.size() > 0:
						s.choose_relic(opts[s.rng.randi_range(0, opts.size() - 1)])
					s.begin_next_fight()
			if s.victory:
				wins += 1
			depth_total += s.endless_depth
			spins_total += s.spin_count
			fights_total += s.fights_won
		var rate := float(wins) / float(RUNS)
		var ok := rate >= band_low and rate <= band_high
		all_ok = all_ok and ok
		print("seed %d: win rate %.1f%% (%d/%d)  avg spins %.1f  avg fights %.2f/%d  avg endless depth %.2f  band %.0f-%.0f%% (%s) -> %s" % [
			seed_base, rate * 100.0, wins, RUNS, float(spins_total) / RUNS, float(fights_total) / RUNS,
			GameData.fights.size(), float(depth_total) / RUNS, band_low * 100.0, band_high * 100.0, mode,
			"IN" if ok else "OUT"])
	print("SIM %s" % ("PASS" if all_ok else "FAIL"))
	quit(0 if all_ok else 1)
