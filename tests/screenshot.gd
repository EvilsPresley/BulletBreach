extends Node
## Renders the main scene and saves screenshots (needs a real display / xvfb).
##   xvfb-run godot --path . res://tests/screenshot.tscn -- --out=/tmp/shots
var main: Main
func _ready() -> void:
	var out := "user://shots"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(3.0).timeout
	await _clear()
	await _shot(out + "/01_start.png")
	# grant a skill so the UI shows buttons, walk a few turns
	await main.activate_reward(load("res://data/rewards/teleport.tres"))
	await main.activate_reward(load("res://data/rewards/dash.tres"))
	var turns := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--turns="): turns = arg.trim_prefix("--turns=").to_int()
	Engine.time_scale = 8.0
	get_window().size = Vector2i(256, 144)
	for i in turns:
		await _clear()
		var p: Player = Map.PLAYER
		var tiles := []
		for d in Map.cardinals:
			if p.walk_ability.can_target(Map.board, Map.board.player.tile + d): tiles.append(Map.board.player.tile + d)
		var r := [null]
		(func(): r[0] = await p.try_act(tiles.pick_random())).call()
		for f in 900:
			for c in main.MODAL.get_children(): c.queue_free()
			await get_tree().process_frame
			if !main.TURN_MANAGER.is_busy() and !Globals.calculating_turn: break
	Engine.time_scale = 1.0
	get_window().size = Vector2i(1024, 576)
	# --light-at-end: play unlit (fast in software rendering), light the final frame.
	if OS.get_cmdline_user_args().has("--light-at-end"):
		main.add_child(Atmosphere.new())
		for i in 20: await get_tree().process_frame
	for i in 10: await get_tree().process_frame
	await _clear()
	await _shot(out + "/02_after_turns.png")
	get_tree().quit()
func _clear() -> void:
	for i in 30:
		for c in main.MODAL.get_children(): c.queue_free()
		await get_tree().process_frame
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", path)
