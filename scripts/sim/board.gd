extends RefCounted
class_name Board
## The whole state of the current night as plain data: ground, units, poison,
## and the random generator. Rules mutate a Board and log events; the Presenter
## plays those events. clone() gives an independent copy (undo, previews).

const SIGHT: int = 7

## Blocker flags for can_move().
const BLOCK_BUILDING: int = 1
const BLOCK_ENEMY: int = 2
const BLOCK_PLAYER: int = 4
const BLOCK_CIVILIAN: int = 8
const BLOCK_PROP: int = 16
const BLOCKS_PLAYER_MOVE: int = BLOCK_BUILDING | BLOCK_ENEMY | BLOCK_PLAYER
const BLOCKS_ENEMY_MOVE: int = BLOCK_BUILDING | BLOCK_ENEMY | BLOCK_PLAYER | BLOCK_CIVILIAN | BLOCK_PROP
const BLOCKS_FLEEING: int = BLOCK_BUILDING | BLOCK_ENEMY | BLOCK_PLAYER | BLOCK_CIVILIAN

## Read-only map data, shared between clones.
var walkable: Dictionary = {}
var crosses: Dictionary = {}

var units: Array[Unit] = []
var player: Unit
var poison_tiles: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()
var next_id: int = 1

var _index: Dictionary = {}
var _index_valid: bool = false
var _threats: Dictionary = {}
var _threats_valid: bool = false

func clone() -> Board:
	var copy := Board.new()
	copy.walkable = walkable
	copy.crosses = crosses
	for unit: Unit in units:
		var unit_copy: Unit = unit.clone()
		copy.units.append(unit_copy)
		if unit == player:
			copy.player = unit_copy
	copy.poison_tiles = poison_tiles.duplicate()
	copy.rng.seed = rng.seed
	copy.rng.state = rng.state
	copy.next_id = next_id
	return copy

## Short fingerprint of the state, used by tests (determinism, undo).
func fingerprint() -> int:
	var parts: Array = [rng.state, poison_tiles]
	for unit: Unit in units:
		parts.append([unit.id, unit.kind, unit.tile, unit.alive, unit.planned_action,
			unit.planned_target, unit.reload_counter, unit.visible, unit.fly_duration])
	return hash(parts)

# --- Units ------------------------------------------------------------------------

func add_unit(unit: Unit) -> Unit:
	unit.id = next_id
	next_id += 1
	units.append(unit)
	invalidate()
	return unit

func remove_unit(unit: Unit) -> void:
	units.erase(unit)
	invalidate()

func move_unit(unit: Unit, tile: Vector2i) -> void:
	unit.tile = tile
	invalidate()

func get_unit(id: int) -> Unit:
	for unit: Unit in units:
		if unit.id == id:
			return unit
	return null

func invalidate() -> void:
	_index_valid = false
	_threats_valid = false

## Alive units on a tile, in resolution order (props, buildings, civilians, enemies, player).
func units_at(tile: Vector2i) -> Array[Unit]:
	if !_index_valid:
		_index.clear()
		for unit: Unit in units:
			if unit.alive:
				if !_index.has(unit.tile):
					_index[unit.tile] = [] as Array[Unit]
				_index[unit.tile].append(unit)
		for list: Array[Unit] in _index.values():
			list.sort_custom(func(a: Unit, b: Unit) -> bool: return a.kind < b.kind)
		_index_valid = true
	return _index.get(tile, [] as Array[Unit])

func enemies() -> Array[Unit]:
	return units.filter(func(u: Unit) -> bool: return u.kind == Unit.Kind.ENEMY)

func alive_enemies() -> Array[Unit]:
	return units.filter(func(u: Unit) -> bool: return u.kind == Unit.Kind.ENEMY and u.alive)

func find_at(tile: Vector2i, kind: Unit.Kind) -> Array[Unit]:
	return units_at(tile).filter(func(u: Unit) -> bool: return u.kind == kind)

# --- Terrain & movement ------------------------------------------------------------

func is_ground(tile: Vector2i) -> bool:
	return walkable.has(tile)

func is_under_fog(tile: Vector2i) -> bool:
	return Vector2(player.tile).distance_to(Vector2(tile)) >= SIGHT

func is_tile_exhausted(tile: Vector2i) -> bool:
	return crosses.has(tile)

func can_move(tile: Vector2i, blockers: int = BLOCKS_PLAYER_MOVE) -> bool:
	if !is_ground(tile):
		return false
	for unit: Unit in units_at(tile):
		match unit.kind:
			Unit.Kind.BUILDING:
				if blockers & BLOCK_BUILDING: return false
			Unit.Kind.ENEMY:
				if blockers & BLOCK_ENEMY and !unit.is_walk_through(): return false
			Unit.Kind.PLAYER:
				if blockers & BLOCK_PLAYER: return false
			Unit.Kind.CIVILIAN:
				if blockers & BLOCK_CIVILIAN: return false
			Unit.Kind.PROP:
				if blockers & BLOCK_PROP: return false
	return true

func can_enemy_move(tile: Vector2i) -> bool:
	return can_move(tile, BLOCKS_ENEMY_MOVE)

## Arrows fly over flying players.
func can_arrow_move(tile: Vector2i, blocked_by_player: bool = player.fly_duration <= 0) -> bool:
	var blockers: int = BLOCK_BUILDING | BLOCK_ENEMY | BLOCK_CIVILIAN
	if blocked_by_player:
		blockers |= BLOCK_PLAYER
	return can_move(tile, blockers)

# --- Threats ---------------------------------------------------------------------------

## Enemies whose planned action will hit `tile`. Never consumes randomness.
func threats_at(tile: Vector2i) -> Array:
	if !_threats_valid:
		_threats.clear()
		for enemy: Unit in alive_enemies():
			for threatened: Vector2i in enemy.behaviour.threatened_tiles(self, enemy):
				if !_threats.has(threatened):
					_threats[threatened] = []
				_threats[threatened].append(enemy)
		_threats_valid = true
	return _threats.get(tile, [])

## True if no known enemy attack will hit `tile` for a player coming from `from`.
func is_tile_safe(from: Vector2i, tile: Vector2i) -> bool:
	for enemy: Unit in threats_at(tile):
		if enemy.behaviour.is_threat_known(self, enemy, from):
			return false
	return true

# --- Randomness (always through the board RNG, so clones stay independent) ----

func shuffled(array: Array) -> Array:
	var result: Array = array.duplicate()
	for i: int in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result

## [dir, side, other side] with the side order chosen at random.
func similar_directions(dir: Vector2i, orthogonal: bool) -> Array[Vector2i]:
	var sides: Array[Vector2i] = Grid.side_directions(dir, orthogonal)
	if rng.randi() % 2 != 0:
		sides.reverse()
	return [dir, sides[0], sides[1]]
