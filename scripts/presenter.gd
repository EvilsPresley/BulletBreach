extends Node
class_name Presenter
## Plays the events produced by Rules with the existing animations, and keeps
## one view node per Board unit. Also applies run-level consequences (XP,
## lives, cooldowns) at the moment their animation plays.
## Events between "parallel_begin"/"parallel_end" start together.

var views: Dictionary = {}  # unit id -> MapObject
var busy: bool = false
var _introduced: Dictionary = {}

signal first_spawn(tuto: Enums.tuto)

func register(unit_id: int, node: MapObject) -> void:
	node.unit_id = unit_id
	views[unit_id] = node

func play(events: Array) -> void:
	busy = true
	await _play_range(events, 0, events.size())
	busy = false

func _play_range(events: Array, start: int, end: int) -> void:
	var i: int = start
	while i < end:
		var event: Dictionary = events[i]
		if event.type == "parallel_begin":
			var close: int = _matching_end(events, i)
			await _play_parallel(events, i + 1, close)
			i = close + 1
		else:
			await _play_event(event)
			i += 1

func _matching_end(events: Array, begin: int) -> int:
	var depth: int = 0
	for i: int in range(begin, events.size()):
		if events[i].type == "parallel_begin":
			depth += 1
		elif events[i].type == "parallel_end":
			depth -= 1
			if depth == 0:
				return i
	return events.size() - 1

## Splits a parallel block into groups (each starting at a top-level
## tile_effect) and plays the groups at the same time.
func _play_parallel(events: Array, start: int, end: int) -> void:
	var groups: Array = []
	var depth: int = 0
	for i: int in range(start, end):
		var type: String = events[i].type
		if depth == 0 and (groups.is_empty() or type == "tile_effect"):
			groups.append([i, i + 1])
		else:
			groups[-1][1] = i + 1
		if type == "parallel_begin":
			depth += 1
		elif type == "parallel_end":
			depth -= 1
	var pending: Array[int] = [groups.size()]
	for group: Array in groups:
		_play_group(events, group[0], group[1], pending)
	while pending[0] > 0:
		await get_tree().process_frame

func _play_group(events: Array, start: int, end: int, pending: Array[int]) -> void:
	await _play_range(events, start, end)
	pending[0] -= 1

func _view(id: int) -> MapObject:
	var node = views.get(id)
	if is_instance_valid(node):
		return node
	return null

func _play_event(event: Dictionary) -> void:
	var player: Player = Map.PLAYER
	match event.type:
		"move_start":
			Events.player_move_started.emit(event.ability, event.flying)
			Globals.selected_ability = null
			player.on_move_start()
		"move_end":
			player.on_move_end()
			player.turn_complete.emit()
		"player_move":
			match event.style:
				"walk", "fly":
					await player.anim_step(event.to)
				"teleport":
					await player.anim_teleport(event.to)
				"portal":
					await player.anim_portal(event.to)
				"time_travel":
					await player.anim_time_travel(event.to)
				"werewolf":
					await player.anim_werewolf_leap(event.to)
				"dash":
					await Globals.wait(Globals.get_anim_duration())
					await player.anim_dash(event.to)
		"take_off":
			await player.anim_take_off()
		"land":
			await player.anim_land()
		"werewolf_strike":
			await player.anim_claw(event.tile)
		"harvest", "harvest_enemy":
			await player.anim_drain(_view(event.id))
			player.blood_harvested.emit()
		"player_hit":
			if event.absorbed:
				await player.anim_blood_pool()
			else:
				RunState.lives -= 1
				if RunState.lives <= 0:
					player.died.emit()
		"cooldowns_reduced":
			Events.cooldowns_reduced.emit(event.turns)
		"nova":
			await player.anim_nova(event.directions)
		"lob":
			await player.anim_lob(event.tiles)
		"tile_effect":
			var targets: Array = event.targets.map(func(id: int): return _view(id)) \
				.filter(func(n): return n != null and n != player)
			await Map.play_tile_effect(event.tile, event.effect, targets)
		"projectiles":
			await _play_projectiles(event)
		"arrow_fired":
			Events.arrow_fired.emit()
		"poison_added":
			await Map.add_poison_marker(event.tile)
		"poison_removed":
			Map.remove_poison_marker(event.tile)
		"spawned":
			_spawn_view(event)
		"destroyed":
			var node: MapObject = _view(event.id)
			if node:
				if node is Ennemy:
					node.clear_plan()
				node.queue_free()
			views.erase(event.id)
		"unit_moved":
			var node: MapObject = _view(event.id)
			if node == null:
				return
			if event.get("style") == "flee":
				var tween := create_tween()
				tween.tween_property(node, "global_position", Map.get_global_position(event.to), 0.2)
				await tween.finished
			else:
				node.direction = event.direction
				await node.anim_move_to(event.to)
		"visibility":
			var node: MapObject = _view(event.id)
			if node:
				node.visible = event.visible
		"planned":
			var node: MapObject = _view(event.id)
			if node:
				node.enable_highlight()
				node.show_plan(event)
				node.disable_highlight()
		"plan_cleared":
			var node: MapObject = _view(event.id)
			if node:
				node.clear_plan()
		"confused":
			var node: MapObject = _view(event.id)
			if node:
				node.play_confusion()
		"enemy_phase":
			await _wait_for_modals()
			Globals.calculating_turn = true
			Globals.set_anim_duration(Map.ENNEMIES.get_child_count())
		"enemy_turn":
			var node: MapObject = _view(event.id)
			if node:
				node.enable_highlight()
		"enemy_turn_end":
			var node: MapObject = _view(event.id)
			if node:
				node.disable_highlight()
			await get_tree().process_frame
		"enemy_phase_end":
			Globals.set_anim_duration(1)
			Globals.calculating_turn = false
		"turn_end":
			pass
		"enter_coffin":
			player.enter_coffin.emit()
		_:
			push_error("Presenter: unknown event %s" % event.type)

func _wait_for_modals() -> void:
	var modals: Control = Map.PLAYER.MAIN.MODAL
	if modals.get_child_count() > 0:
		await modals.get_child(0).tree_exited
		await Globals.wait(Globals.anim_duration * .25)
	await get_tree().process_frame

func _container_for(kind: Unit.Kind) -> Node:
	match kind:
		Unit.Kind.BUILDING: return Map.BUILDINGS
		Unit.Kind.CIVILIAN: return Map.CIVILIANS
		Unit.Kind.ENEMY: return Map.ENNEMIES
	return Map.PROPS

func _spawn_view(event: Dictionary) -> MapObject:
	var node: MapObject = event.scene.instantiate()
	node.set_map_position(event.tile)
	_container_for(event.kind).add_child(node)
	register(event.id, node)
	var definition: EnemyDefinition = event.get("definition")
	if definition and definition.intro_tuto != Enums.tuto.NONE and !_introduced.has(definition.intro_tuto):
		_introduced[definition.intro_tuto] = true
		first_spawn.emit(definition.intro_tuto)
	return node

func _play_projectiles(event: Dictionary) -> void:
	var shooter: MapObject = _view(event.owner)
	var parent: Node = Map.TILEMAP
	if shooter:
		parent = shooter
	var bullets: Array[Bullet] = []
	for path: Dictionary in event.paths:
		var bullet: Bullet = preload("res://scenes/ennemies/bullet.tscn").instantiate()
		parent.add_child(bullet)
		bullet.set_map_position(event.origin)
		if event.visual == "night_bolt":
			bullet.sprite.texture = preload("res://assets/player/bolt.png")
		bullet.direction = path.direction
		bullet.fly(path.end, Grid.distance(event.origin, path.end))
		bullets.append(bullet)
	for bullet: Bullet in bullets:
		if is_instance_valid(bullet):
			await bullet.tree_exited

## Recreates/repositions every view from the board (after an undo).
func sync_all(board: Board) -> void:
	var seen: Dictionary = {}
	for unit: Unit in board.units:
		seen[unit.id] = true
		if unit.kind == Unit.Kind.PLAYER:
			continue
		var node: MapObject = _view(unit.id)
		if node == null:
			node = _spawn_view({"id": unit.id, "kind": unit.kind, "tile": unit.tile, "scene": unit.scene})
		node.set_map_position(unit.tile)
		node.modulate = Color.WHITE
		if unit.kind == Unit.Kind.ENEMY:
			node.visible = unit.visible
			node.direction = unit.direction
			node.show_plan(Rules.plan_event(board, unit))
	for id: int in views.keys():
		if !seen.has(id):
			var node: MapObject = _view(id)
			if node:
				node.queue_free()
			views.erase(id)
	Map.PLAYER.set_map_position(board.player.tile)
	Map.PLAYER.sync_form(board.player.fly_duration > 0)
	Map.PLAYER.reveal_land_mines()
	Map.clear_poison_markers()
	for tile: Vector2i in board.poison_tiles:
		Map.add_poison_marker(tile)
