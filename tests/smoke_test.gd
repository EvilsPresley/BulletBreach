extends Node
## Headless smoke test: plays TURNS turns of the real main scene with every skill.
## Run from the project folder:
##   godot --headless --path . res://tests/smoke_test.tscn
## Look for "SCRIPT ERROR", "WARN" and the final "SMOKE TEST DONE errors=0".

const TURNS := 45
var main: Main
var player: Player
var turn_done := false
var errors := 0

func _ready() -> void:
	Engine.time_scale = 10.0
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	player = Map.PLAYER
	main.TURN_MANAGER.turn_completed.connect(func(): turn_done = true)
	await _settle()

	# 1. Real input path: click an adjacent walkable tile on screen.
	var start: Vector2i = player.get_map_position()
	var target := Vector2i(-999, -999)
	for d in Map.cardinals:
		if player.can_walk_to(start + d):
			target = start + d
			break
	var screen: Vector2 = player.get_canvas_transform() * Map.get_global_position(target)
	var motion := InputEventMouseMotion.new(); motion.position = screen
	get_viewport().push_input(motion, true)
	await get_tree().process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = screen
	get_viewport().push_input(click, true)
	await get_tree().process_frame
	await _wait_turn()
	print("CHECK input path: moved=%s (from %s to %s, expected %s)" % [player.get_map_position() == target, start, player.get_map_position(), target])

	# 2. Grant all skills and many upgrades.
	for r in ["teleport", "dash", "bat_form", "time_travel", "werewolf_form",
			"night_bolt1", "night_bolt2", "night_bolt3", "vengeance1", "vengeance2",
			"blood_nova1", "blood_dash", "portal", "soul_spores1", "soul_siphon1",
			"poison_shells1", "demon_wolf", "haste1", "teleport_range1", "fly_range1",
			"type_o_negative1", "versatile1"]:
		await _settle()
		await main.activate_reward(load("res://data/rewards/%s.tres" % r))
	print("CHECK rewards owned: %s, skill buttons: %d, effects: %s" % [PlayerRewards.owned_rewards.size(), main.MOVE_BUTTONS.get_child_count(), PlayerRewards.get_effects().map(func(e): return [e.effect.resource_path.get_file(), e.stacks])])

	# 3. Play turns.
	var modes_used := {}
	for i in TURNS:
		await _settle()
		Globals.lives = 99
		Globals.selected_ability = _pick_ability()
		var tiles := _candidate_tiles()
		if tiles.is_empty():
			Globals.selected_ability = null
			tiles = _candidate_tiles()
		if tiles.is_empty():
			print("TURN %d: no legal move" % i)
			break
		var safe := tiles.filter(func(t): return Map.is_tile_safe(player.get_map_position(), t))
		var pick: Vector2i = (safe if !safe.is_empty() else tiles).pick_random()
		var used: String = String(player.get_active_ability().id) if player.get_active_ability().id else player.get_active_ability().get_script().get_global_name()
		turn_done = false
		var ok: bool = await player.try_act(pick)
		if !ok:
			print("TURN %d: try_act refused %s on %s" % [i, used, pick]); errors += 1
			continue
		await _wait_turn()
		modes_used[used] = modes_used.get(used, 0) + 1
		print("TURN %2d %-11s enemies=%2d civilians=%d buildings=%d level=%d" % [Globals.turn, used,
			Map.ENNEMIES.get_child_count(), Map.CIVILIANS.get_child_count(),
			Map.BUILDINGS.get_child_count(), Globals.level])
	print("CHECK abilities used: %s" % modes_used)

	# 4. Death signal.
	await _settle()
	Globals.lives = 1
	await player.get_hit()
	await get_tree().create_timer(1.0).timeout
	print("CHECK death -> game_over=%s" % main.game_over)
	print("SMOKE TEST DONE errors=%d" % errors)
	get_tree().quit()

func _pick_ability() -> MoveAbility:
	if player.fly_duration > 0 or randf() < 0.5:
		return null
	var ready: Array = []
	for frame in main.MOVE_BUTTONS.get_children():
		for b in frame.get_children():
			if b is MoveButton and b.ability != null and b.get_reload() == 0:
				ready.append(b.ability)
	return ready.pick_random() if !ready.is_empty() else null

func _candidate_tiles() -> Array:
	var ability: MoveAbility = player.get_active_ability()
	var out: Array = []
	var p: Vector2i = player.get_map_position()
	for x in range(-4, 5):
		for y in range(-4, 5):
			if ability.can_target(player, p + Vector2i(x, y)):
				out.append(p + Vector2i(x, y))
	return out

func _settle() -> void:
	for i in 600:
		for c in main.MODAL.get_children():
			c.queue_free()
		await get_tree().process_frame
		if main.MODAL.get_child_count() == 0 and !Globals.calculating_turn and !player.moving:
			await get_tree().process_frame
			if main.MODAL.get_child_count() == 0:
				return
	print("WARN settle timeout"); errors += 1

func _wait_turn() -> void:
	for i in 3000:
		if turn_done:
			turn_done = false
			return
		for c in main.MODAL.get_children():
			c.queue_free()
		await get_tree().process_frame
	print("WARN turn timeout calc=%s moving=%s modal=%d" % [Globals.calculating_turn, player.moving, main.MODAL.get_child_count()]); errors += 1
