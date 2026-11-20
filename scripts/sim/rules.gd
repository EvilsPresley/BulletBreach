extends RefCounted
class_name Rules
## Game rules. Every function mutates a Board immediately and appends events
## (plain Dictionaries with a "type") to `log`; nothing here waits or animates.
## The Presenter plays the log afterwards. Because rules are instant and work
## on a cloneable Board, a turn can be simulated ahead (previews) or undone.

# Scenes are loaded lazily (never preloaded): the simulation must not pull
# view scenes at compile time, or it creates script load cycles with MapObject.
const DEFAULT_RUINS_PATH: String = "res://scenes/map/ruins.tscn"
const CIVILIAN_PATH: String = "res://scenes/map/civilian.tscn"
const PORTAL_PATH: String = "res://scenes/map/portal.tscn"
const MAX_PREVIOUS_POSITIONS: int = 10

# --- Whole turns ------------------------------------------------------------------

## Player move + enemy phase + spawns + end of turn. `turn`/`night` are the
## values after this move (spawn schedule).
static func play_turn(board: Board, ability: MoveAbility, tile: Vector2i,
		turn: int, night: int, spawn_table: SpawnTable) -> Array:
	var log: Array = []
	player_move(board, ability, tile, log)
	enemy_phase(board, log)
	if night >= 2 or turn >= 20:
		spawn_wave(board, night, spawn_table, log)
	elif turn % 2 == 0 and turn > 2:
		spawn_wave(board, 1, spawn_table, log)
	end_of_turn(board, log)
	return log

static func player_move(board: Board, ability: MoveAbility, tile: Vector2i, log: Array) -> void:
	var player: Unit = board.player
	# Enemies close to the destination come out of the fog.
	for enemy: Unit in board.alive_enemies():
		if !enemy.visible and Vector2(enemy.tile).distance_to(Vector2(tile)) < Board.SIGHT:
			enemy.visible = true
			log.append({"type": "visibility", "id": enemy.id, "visible": true})
	log.append({"type": "move_start", "ability": ability, "flying": player.fly_duration > 0})
	harvest_at(board, tile, log)
	ability.simulate(board, tile, log)

## Shared end of every player move (portals, upgrade triggers).
static func move_end(board: Board, log: Array, is_special_move: bool) -> void:
	var player: Unit = board.player
	_remember_position(player)
	if !is_special_move:
		var portals: Array = board.units.filter(func(u: Unit) -> bool: return u.is_portal and u.alive)
		var entered: bool = portals.any(func(u: Unit) -> bool: return u.tile == player.tile)
		if entered:
			for portal: Unit in portals:
				if portal.tile != player.tile:
					log.append({"type": "player_move", "style": "portal", "from": player.tile, "to": portal.tile})
					board.move_unit(player, portal.tile)
					_remember_position(player)
					break
	var effects: Array[Dictionary] = PlayerRewards.get_effects()
	if player.was_special_move and !is_special_move:
		for entry: Dictionary in effects:
			entry.effect.on_walk_after_special(board, player.direction, entry.stacks, log)
	player.was_special_move = is_special_move
	for entry: Dictionary in effects:
		entry.effect.on_move_end(board, entry.stacks, log)
	player.sanguine_pool_use = 0
	log.append({"type": "move_end", "tile": player.tile})

static func _remember_position(player: Unit) -> void:
	if player.previous_positions.size() >= MAX_PREVIOUS_POSITIONS:
		player.previous_positions.remove_at(0)
	player.previous_positions.append(player.tile)

static func enemy_phase(board: Board, log: Array) -> void:
	log.append({"type": "enemy_phase"})
	for enemy: Unit in board.enemies():
		if !enemy.alive:
			continue
		log.append({"type": "enemy_turn", "id": enemy.id})
		if enemy.visible:
			log.append({"type": "plan_cleared", "id": enemy.id})
			enemy.behaviour.execute(board, enemy, log)
			if !enemy.alive:
				continue
		move_enemy(board, enemy, log)
		if enemy.visible:
			plan_enemy(board, enemy, log)
		else:
			enemy.planned_action = Enums.plan.STAND
		log.append({"type": "enemy_turn_end", "id": enemy.id})
	# Poison resolves after every enemy acted.
	var poisoned: Array[Vector2i] = board.poison_tiles.duplicate()
	board.poison_tiles.clear()
	for tile: Vector2i in poisoned:
		destroy_tile(board, tile, Enums.destruction_type.POISON, log)
		log.append({"type": "poison_removed", "tile": tile})
	# Dead enemies leave the board.
	for enemy: Unit in board.enemies():
		if !enemy.alive:
			board.remove_unit(enemy)
	log.append({"type": "enemy_phase_end"})

static func end_of_turn(board: Board, log: Array) -> void:
	var player: Unit = board.player
	if player.fly_duration > 0:
		player.fly_duration -= 1
		if player.fly_duration <= 0:
			log.append({"type": "land", "tile": player.tile})
			for enemy: Unit in board.find_at(player.tile, Unit.Kind.ENEMY):
				destroy_unit(board, enemy, log, false, false)
	log.append({"type": "turn_end"})
	for prop: Unit in board.find_at(player.tile, Unit.Kind.PROP):
		if prop.is_coffin:
			log.append({"type": "enter_coffin"})

# --- Enemies ------------------------------------------------------------------------

static func move_enemy(board: Board, enemy: Unit, log: Array) -> void:
	var under_fog: bool = board.is_under_fog(enemy.tile)
	if enemy.reload_counter <= 0:
		enemy.behaviour.move(board, enemy, log)
	if under_fog and board.is_under_fog(enemy.tile) and enemy.visible:
		enemy.visible = false
		log.append({"type": "visibility", "id": enemy.id, "visible": false})

static func step_enemy(board: Board, enemy: Unit, dir: Vector2i, log: Array) -> void:
	enemy.direction = Grid.vector_to_cardinal(dir)
	var from: Vector2i = enemy.tile
	board.move_unit(enemy, enemy.tile + dir)
	log.append({"type": "unit_moved", "id": enemy.id, "from": from, "to": enemy.tile,
		"direction": enemy.direction})

static func plan_enemy(board: Board, enemy: Unit, log: Array) -> void:
	enemy.behaviour.plan(board, enemy)
	board.invalidate()
	log.append(plan_event(board, enemy))

## What the view needs to draw an enemy's current plan.
static func plan_event(board: Board, enemy: Unit) -> Dictionary:
	return {"type": "planned", "id": enemy.id, "action": enemy.planned_action,
		"direction": enemy.direction, "reload_counter": enemy.reload_counter,
		"tiles": enemy.behaviour.plan_display_tiles(board, enemy), "from": enemy.tile}

static func spawn_enemy(board: Board, definition: EnemyDefinition, tile: Vector2i, log: Array) -> Unit:
	var enemy := Unit.new()
	enemy.kind = Unit.Kind.ENEMY
	enemy.tile = tile
	enemy.definition = definition
	enemy.behaviour = definition.behaviour
	enemy.reload_time = definition.reload_time
	enemy.scene = definition.scene
	board.add_unit(enemy)
	log.append({"type": "spawned", "id": enemy.id, "kind": enemy.kind, "tile": tile,
		"scene": enemy.scene, "definition": definition})
	return enemy

## Spawn `count` enemies on the edge of the player's sight.
static func spawn_wave(board: Board, count: int, table: SpawnTable, log: Array) -> void:
	var player: Unit = board.player
	var origin: Vector2i = player.previous_positions[0] if !player.previous_positions.is_empty() else player.tile
	var candidates: Array = []
	for x: int in range(player.tile.x - Board.SIGHT, player.tile.x + Board.SIGHT + 1):
		for y: int in range(player.tile.y - Board.SIGHT, player.tile.y + Board.SIGHT + 1):
			var tile := Vector2i(x, y)
			var distance: float = Vector2(tile).distance_to(Vector2(player.tile))
			if distance >= Board.SIGHT and distance < Board.SIGHT + 1 \
			and board.can_enemy_move(tile) \
			and Vector2(tile).distance_to(Vector2(origin)) >= Board.SIGHT:
				candidates.append(tile)
	for tile: Vector2i in board.shuffled(candidates).slice(0, count):
		var alive: Dictionary = {}
		for other: Unit in board.alive_enemies():
			if other.definition:
				alive[other.definition] = alive.get(other.definition, 0) + 1
		var enemy: Unit = spawn_enemy(board, table.pick(alive), tile, log)
		move_enemy(board, enemy, log)
		plan_enemy(board, enemy, log)

# --- Damage --------------------------------------------------------------------------

static func destroy_tile(board: Board, tile: Vector2i, type: Enums.destruction_type, log: Array) -> void:
	if !board.is_ground(tile):
		return
	var victims: Array[Unit] = board.units_at(tile).duplicate()
	log.append({"type": "tile_effect", "tile": tile, "effect": type,
		"targets": victims.filter(func(u: Unit) -> bool: return u.kind != Unit.Kind.PROP).map(func(u: Unit) -> int: return u.id)})
	for unit: Unit in victims:
		if unit.alive and unit.tile == tile and unit.kind != Unit.Kind.PLAYER and unit.destructible:
			destroy_unit(board, unit, log)
	var player: Unit = board.player
	if player.tile == tile and (player.fly_duration == 0 or type == Enums.destruction_type.LIGHT):
		hit_player(board, log)

## `harvest`: Soul Spores may drain the enemy. `trigger`: on-death effects
## (Kamikaze explosion).
static func destroy_unit(board: Board, unit: Unit, log: Array,
		harvest: bool = true, trigger: bool = true) -> void:
	if !unit.alive:
		return
	match unit.kind:
		Unit.Kind.PROP, Unit.Kind.CIVILIAN:
			_remove(board, unit, log)
		Unit.Kind.BUILDING:
			if unit.shelters_civilian:
				_release_civilian(board, unit.tile, log)
			_remove(board, unit, log)
			var ruins := Unit.new()
			ruins.kind = Unit.Kind.PROP
			ruins.tile = unit.tile
			ruins.destructible = false
			ruins.scene = unit.ruins_scene if unit.ruins_scene else load(DEFAULT_RUINS_PATH)
			board.add_unit(ruins)
			log.append({"type": "spawned", "id": ruins.id, "kind": ruins.kind, "tile": ruins.tile, "scene": ruins.scene})
		Unit.Kind.ENEMY:
			if trigger and unit.behaviour.on_destroyed(board, unit, log):
				return
			kill_enemy(board, unit, log, harvest)

static func kill_enemy(board: Board, enemy: Unit, log: Array, harvest: bool) -> void:
	if !enemy.alive:
		return
	enemy.planned_action = Enums.plan.STAND
	log.append({"type": "plan_cleared", "id": enemy.id})
	if harvest and Grid.distance(board.player.tile, enemy.tile) <= PlayerRewards.stacks(&"soul_spores"):
		log.append({"type": "harvest_enemy", "id": enemy.id})
	enemy.alive = false
	board.invalidate()
	log.append({"type": "destroyed", "id": enemy.id})

static func _remove(board: Board, unit: Unit, log: Array) -> void:
	unit.alive = false
	board.remove_unit(unit)
	log.append({"type": "destroyed", "id": unit.id})

## The civilian runs to a random safe neighbouring tile, if any.
static func _release_civilian(board: Board, tile: Vector2i, log: Array) -> Unit:
	var civilian := Unit.new()
	civilian.kind = Unit.Kind.CIVILIAN
	civilian.tile = tile
	civilian.scene = load(CIVILIAN_PATH)
	board.add_unit(civilian)
	log.append({"type": "spawned", "id": civilian.id, "kind": civilian.kind, "tile": tile, "scene": civilian.scene})
	for dir: Vector2i in board.shuffled(Grid.cardinals):
		var target: Vector2i = tile + dir
		if board.is_tile_safe(tile, target) and board.can_move(target, Board.BLOCKS_FLEEING):
			board.move_unit(civilian, target)
			log.append({"type": "unit_moved", "id": civilian.id, "from": tile, "to": target, "style": "flee"})
			break
	return civilian

static func hit_player(board: Board, log: Array) -> void:
	var player: Unit = board.player
	if PlayerRewards.stacks(&"sanguine_pool") > player.sanguine_pool_use:
		player.sanguine_pool_use += 1
		if board.rng.randi() % 3 <= PlayerRewards.stacks(&"sixth_sense"):
			log.append({"type": "player_hit", "absorbed": true})
			return
	log.append({"type": "player_hit", "absorbed": false})

## Blood drain of every civilian on `tile`.
static func harvest_at(board: Board, tile: Vector2i, log: Array) -> void:
	for civilian: Unit in board.find_at(tile, Unit.Kind.CIVILIAN):
		log.append({"type": "harvest", "id": civilian.id})
		_remove(board, civilian, log)

# --- Shared effects ---------------------------------------------------------------------

## Projectiles fired together from `origin`. Paths are computed on the current
## board first, then impacts resolve (they fly at the same time).
static func fire_projectiles(board: Board, origin: Vector2i, directions: Array[Vector2i],
		type: Enums.destruction_type, visual: String, log: Array, owner_id: int = 0) -> void:
	var impacts: Array[Vector2i] = []
	var paths: Array = []
	for dir: Vector2i in directions:
		var tile: Vector2i = origin
		var impact: bool = false
		for i: int in Board.SIGHT * 2:
			var next: Vector2i = tile + dir
			var continues: bool = board.can_arrow_move(next)
			tile = next
			if !continues:
				impact = true
				break
		paths.append({"direction": dir, "end": tile, "impact": impact})
		if impact and !impacts.has(tile):
			impacts.append(tile)
	log.append({"type": "projectiles", "origin": origin, "paths": paths, "visual": visual, "owner": owner_id})
	log.append({"type": "parallel_begin"})
	for tile: Vector2i in impacts:
		destroy_tile(board, tile, type, log)
	log.append({"type": "parallel_end"})

static func add_poison(board: Board, tile: Vector2i, log: Array) -> void:
	board.poison_tiles.append(tile)
	log.append({"type": "poison_added", "tile": tile})

static func blood_nova(board: Board, level: int, log: Array) -> void:
	var directions: Array[Vector2i] = []
	match level:
		0:
			return
		1:
			directions = [Grid.NE, Grid.SE, Grid.SW, Grid.NW]
		2:
			directions = Grid.cardinals.duplicate()
		_:
			directions = Grid.cardinals.duplicate()
			directions.append_array([Grid.NE * 2, Grid.SE * 2, Grid.SW * 2, Grid.NW * 2])
	var origin: Vector2i = board.player.tile
	log.append({"type": "nova", "origin": origin, "directions": directions})
	log.append({"type": "parallel_begin"})
	for dir: Vector2i in directions:
		destroy_tile(board, origin + dir, Enums.destruction_type.SHADOW, log)
	log.append({"type": "parallel_end"})

## Move the player and log it (abilities call this).
static func move_player(board: Board, to: Vector2i, style: String, log: Array, extra: Dictionary = {}) -> void:
	var event: Dictionary = {"type": "player_move", "style": style, "from": board.player.tile, "to": to}
	event.merge(extra)
	board.move_unit(board.player, to)
	log.append(event)
