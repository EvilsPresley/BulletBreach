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
var hits_taken := 0

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
		if player.walk_ability.can_target(Map.board, start + d):
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

	# 3. Play turns, rest in a coffin, play a second night.
	await _play_turns(TURNS)
	await _settle()
	var night_before: int = RunState.night
	main._rest_in_coffin()
	for i in 2000:
		for c in main.MODAL.get_children():
			c.queue_free()
		await get_tree().process_frame
		if RunState.night > night_before and !Globals.calculating_turn and !main.TURN_MANAGER.is_busy():
			break
	await _settle()
	print("CHECK coffin rest: night=%d turn=%d enemies=%d" % [RunState.night, RunState.turn, Map.ENNEMIES.get_child_count()])
	await _play_turns(8)
	await _test_undo()

	# 4. Death signal.
	await _settle()
	RunState.lives = 1
	await main.TURN_MANAGER.presenter.play([{"type": "player_hit", "absorbed": false}])
	await get_tree().create_timer(1.0).timeout
	print("CHECK run state: level=%d xp=%.2f/%d cooldowns=%s" % [RunState.level, RunState.xp, RunState.xp_to_next, RunState.cooldowns.keys().map(func(a): return "%s:%d" % [a.id, RunState.cooldowns[a]])])
	print("CHECK death -> game_over=%s" % main.game_over)
	print("SMOKE TEST DONE errors=%d" % errors)
	get_tree().quit()

func _play_turns(count: int) -> void:
	var modes_used := {}
	RunState.lives = 99
	for i in count:
		await _settle()
		hits_taken += 99 - RunState.lives
		RunState.lives = 99
		Globals.selected_ability = _pick_ability()
		var tiles := _candidate_tiles()
		if tiles.is_empty():
			Globals.selected_ability = null
			tiles = _candidate_tiles()
		if tiles.is_empty():
			print("TURN %d: no legal move" % i)
			break
		var board: Board = Map.board
		var from: Vector2i = board.player.tile
		var safe := tiles.filter(func(t): return board.is_tile_safe(from, t))
		var pick: Vector2i = (safe if !safe.is_empty() else tiles).pick_random()
		var ability: MoveAbility = player.get_active_ability()
		var used: String = String(ability.id) if ability.id else ability.get_script().get_global_name()
		var used_ability: MoveAbility = Globals.selected_ability

		# Preview isolation: simulating another move on a clone leaves the board untouched.
		var before: int = board.fingerprint()
		var preview: Board = board.clone()
		Rules.play_turn(preview, ability, tiles.pick_random(), RunState.turn + 1, RunState.night, main.TURN_MANAGER.spawn_table)
		if board.fingerprint() != before:
			print("WARN preview changed the real board"); errors += 1
		# Determinism: same move on a clone == what the real turn produces.
		var replay: Board = board.clone()
		Rules.play_turn(replay, ability, pick, RunState.turn + 1, RunState.night, main.TURN_MANAGER.spawn_table)

		var ok: bool = await _act(pick)
		if !ok:
			print("TURN %d: try_act refused %s on %s" % [i, used, pick]); errors += 1
			continue
		if replay.fingerprint() != Map.board.fingerprint():
			print("WARN turn %d not deterministic (%s)" % [RunState.turn, used]); errors += 1
		_check_views()
		if used_ability:
			var expected_min: int = used_ability.cooldown - PlayerRewards.stacks(&"haste")
			if RunState.get_cooldown(used_ability) < expected_min - 1 or Globals.selected_ability != null:
				print("WARN cooldown not applied for %s: %d" % [used_ability.id, RunState.get_cooldown(used_ability)]); errors += 1
		modes_used[used] = modes_used.get(used, 0) + 1
		print("TURN %2d %-17s enemies=%2d civilians=%d buildings=%d level=%d" % [RunState.turn, used,
			Map.board.alive_enemies().size(), Map.board.units.filter(func(u): return u.kind == Unit.Kind.CIVILIAN).size(),
			Map.board.units.filter(func(u): return u.kind == Unit.Kind.BUILDING).size(), RunState.level])
	print("CHECK abilities used: %s (player hits taken so far: %d)" % [modes_used, hits_taken])

## Every board unit has a live view on the same tile, and vice versa.
func _check_views() -> void:
	var views: Dictionary = main.TURN_MANAGER.presenter.views
	var problems: Array = []
	for unit: Unit in Map.board.units:
		if unit.kind == Unit.Kind.PLAYER:
			if player.get_map_position() != unit.tile:
				problems.append("player view %s vs board %s" % [player.get_map_position(), unit.tile])
			continue
		var node = views.get(unit.id)
		if !is_instance_valid(node) or node.is_queued_for_deletion():
			problems.append("no view for %s #%d" % [Unit.Kind.keys()[unit.kind], unit.id])
		elif node.get_map_position() != unit.tile:
			problems.append("%s #%d view at %s, board at %s" % [Unit.Kind.keys()[unit.kind], unit.id, node.get_map_position(), unit.tile])
	for container: Node in [Map.PROPS, Map.BUILDINGS, Map.CIVILIANS, Map.ENNEMIES]:
		for node: MapObject in container.get_children():
			if !node.is_queued_for_deletion() and Map.board.get_unit(node.unit_id) == null:
				problems.append("orphan view %s" % node.name)
	if !problems.is_empty():
		errors += 1
		print("WARN view/board mismatch: %s" % [problems.slice(0, 4)])

func _test_undo() -> void:
	await _settle()
	RunState.lives = 99
	var before: int = Map.board.fingerprint()
	var turn_before: int = RunState.turn
	var tiles := _candidate_tiles()
	Globals.selected_ability = null
	tiles = _candidate_tiles()
	await _act(tiles.pick_random())
	await _settle()
	var level_changed: bool = !main.TURN_MANAGER.can_undo()
	var undone: bool = main.TURN_MANAGER.undo_last_turn()
	await get_tree().process_frame
	await get_tree().process_frame
	if undone:
		_check_views()
	print("CHECK undo: undone=%s restored=%s turn %d->%d (blocked by level-up: %s)" % [undone,
		Map.board.fingerprint() == before, turn_before, RunState.turn, level_changed])
	if undone and (Map.board.fingerprint() != before or RunState.turn != turn_before):
		errors += 1

func _pick_ability() -> MoveAbility:
	if Map.board.player.fly_duration > 0 or randf() < 0.5:
		return null
	var ready_abilities: Array = []
	for frame in main.MOVE_BUTTONS.get_children():
		for b in frame.get_children():
			if b is MoveButton and b.ability != null and b.get_reload() == 0:
				ready_abilities.append(b.ability)
	return ready_abilities.pick_random() if !ready_abilities.is_empty() else null

func _candidate_tiles() -> Array:
	var ability: MoveAbility = player.get_active_ability()
	var out: Array = []
	var p: Vector2i = Map.board.player.tile
	for x in range(-4, 5):
		for y in range(-4, 5):
			if ability.can_target(Map.board, p + Vector2i(x, y)):
				out.append(p + Vector2i(x, y))
	return out

## Plays a turn like a player would, closing tutorial banners while it runs.
func _act(tile: Vector2i) -> bool:
	turn_done = false
	var result: Array = [null]
	(func(): result[0] = await player.try_act(tile)).call()
	await get_tree().process_frame
	if result[0] == false:
		return false
	await _wait_turn()
	return true

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
