extends Node

#Orthogonal:
#const N: Vector2i = Vector2i.UP
#const E: Vector2i = Vector2i.RIGHT
#const S: Vector2i = Vector2i.DOWN
#const W: Vector2i = Vector2i.LEFT

#Isometric:
const N: Vector2i = Vector2i(-1, -1)
const E: Vector2i = Vector2i(1, -1)
const S: Vector2i = Vector2i(1, 1)
const W: Vector2i = Vector2i(-1, 1)

const NE: Vector2i = Vector2i(0, -1)
const SE: Vector2i = Vector2i(1, 0)
const SW: Vector2i = Vector2i(0, 1)
const NW: Vector2i = Vector2i(-1, 0)

const cardinals: Array[Vector2i] = [N, NE, E, SE, S, SW, W, NW]
const orthogonals: Array[Vector2i] = [N, S, E, W]

const dimensions: Vector2i = Vector2i(32, 32)

@onready var TILEMAP: TileMapLayer = null
@onready var BUILDINGS: Node = null
@onready var CIVILIANS: Node = null
@onready var ENNEMIES: Node = null
@onready var PROPS: Node = null
@onready var CROSSES: Node = null
@onready var PLAYER: Player = null
@onready var DEEP_FOG: Control = null

var poisonned_tiles: Array[TextureRect] = []

# --- Occupancy index -------------------------------------------------------
# Tile -> objects standing on it. Rebuilt lazily after anything moves
# (MapObject bumps board_version on transform/tree changes), so queries never
# loop over every entity of the map.
var _occupancy: Dictionary = {}
var _crosses: Dictionary = {}
var _indexed_version: int = -1
var _threats: Dictionary = {}
var _threats_version: int = -1
var _threats_dirty: bool = true

## Call when an enemy's planned action changes.
func invalidate_threats() -> void:
	_threats_dirty = true

func _ensure_occupancy() -> void:
	if _indexed_version == MapObject.board_version:
		return
	_indexed_version = MapObject.board_version
	_occupancy.clear()
	_crosses.clear()
	if TILEMAP == null:
		return
	for group: Node in [PROPS, BUILDINGS, CIVILIANS, ENNEMIES]:
		if group == null:
			continue
		for object: MapObject in group.get_children():
			var tile: Vector2i = object.get_map_position()
			if !_occupancy.has(tile):
				_occupancy[tile] = []
			_occupancy[tile].append(object)
	if PLAYER:
		var player_tile: Vector2i = PLAYER.get_map_position()
		if !_occupancy.has(player_tile):
			_occupancy[player_tile] = []
		_occupancy[player_tile].append(PLAYER)
	if CROSSES:
		for cross: MapObject in CROSSES.get_children():
			_crosses[cross.get_map_position()] = true

## Everything standing on a tile (props, buildings, civilians, enemies, player).
func get_objects_at(tile: Vector2i) -> Array:
	_ensure_occupancy()
	return _occupancy.get(tile, [])

func is_walkable_ground(tile: Vector2i) -> bool:
	return TILEMAP.get_cell_source_id(tile) == 0

func get_map_position(global_pos: Vector2) -> Vector2i:
	return TILEMAP.local_to_map(global_pos)

func get_global_position(map_position: Vector2i) -> Vector2:
	return TILEMAP.map_to_local(map_position) + TILEMAP.global_position

func get_global_mid_position(map_position1: Vector2i, map_position2: Vector2i) -> Vector2:
	return (TILEMAP.map_to_local(map_position1) + TILEMAP.map_to_local(map_position2)) * 0.5 \
	+ TILEMAP.global_position

func vector_to_cardinal(vector: Vector2) -> Vector2i:
	var result: Vector2i = Vector2.ZERO
	if abs(vector.x) > abs(vector.y) * .5:
		if vector.x > 0:
			result.x = 1
		elif vector.x < 0:
			result.x = -1
	if abs(vector.y) > abs(vector.x) * .5:
		if vector.y > 0:
			result.y = 1
		elif vector.y < 0:
			result.y = -1
	return result

func vector_to_orthogonal(vector: Vector2) -> Vector2i:
	if abs(vector.x) > abs(vector.y):
		if vector.x > 0:
			return E
		else:
			return W
	else:
		if vector.y > 0:
			return N
		else:
			return S
	
func can_ennemy_move(tile: Vector2i) -> bool:
	return can_move(tile, [BUILDINGS, ENNEMIES, PLAYER, CIVILIANS, PROPS])

func can_arrow_move(tile: Vector2i, blocked_by_player: bool = Map.PLAYER.fly_duration <= 0) -> bool:
	if blocked_by_player:
		return can_move(tile, [BUILDINGS, ENNEMIES, PLAYER, CIVILIANS])
	else:
		return can_move(tile, [BUILDINGS, ENNEMIES, CIVILIANS])

func can_move(tile: Vector2i, obstacles: Array[Node] = [BUILDINGS, ENNEMIES, PLAYER]) -> bool:
	if !is_walkable_ground(tile):
		return false
	for object: MapObject in get_objects_at(tile):
		if object == PLAYER:
			if obstacles.has(PLAYER):
				return false
		elif obstacles.has(object.get_parent()) and !object.is_walk_through():
			return false
	return true

func get_similar_directions(dir: Vector2i, orthogonal_move: bool) -> Array[Vector2i]:
	var similar_directions: Array[Vector2i] = [dir]
	var clockwise: bool = randi() % 2 == 0
	var offset: int = 2
	if !orthogonal_move:
		offset = 1
	var index: int = cardinals.find(dir)
	var cw: Vector2i = cardinals[posmod(index + offset, cardinals.size())]
	var ccw: Vector2i = cardinals[posmod(index - offset, cardinals.size())]
	if clockwise:
		similar_directions.append_array([cw, ccw])
	else:
		similar_directions.append_array([ccw, cw])
	return similar_directions

func destroy_tile(tile: Vector2i, type: Enums.destruction_type) -> void:
	if Map.TILEMAP.get_cell_source_id(tile) == 0:
		var anim_duration: float = Globals.get_anim_duration()
		match type:
			Enums.destruction_type.FLAMES:
				var flames: Array[TextureRect] = []
				for i: int in 3:
					var flame: TextureRect = preload("res://scenes/ennemies/flame.tscn").instantiate()
					flames.append(flame)
					TILEMAP.add_child(flame)
					flame.z_index = 1
					flame.position = get_global_position(tile) + Vector2(-6 - 6 * ((i + 1) % 3), -10 - 6 * i)
					await Globals.wait(anim_duration * 0.3333)
				for flame in flames:
					flame.queue_free()
			Enums.destruction_type.EXPLOSION:
				var explosion: TextureRect = TextureRect.new()
				explosion.z_index = 2
				TILEMAP.add_child(explosion)
				for i: int in 5:
					explosion.texture = load("res://assets/ennemies/explosion%s.png" % (i + 1))
					explosion.global_position = get_global_position(tile) - explosion.size * .5
					await Globals.wait(anim_duration * 0.2)
				explosion.queue_free()
			Enums.destruction_type.LIGHT:
				var rain: TextureRect = TextureRect.new()
				rain.texture = preload("res://assets/ennemies/priest_air.png")
				rain.z_index = 1
				TILEMAP.add_child(rain)
				rain.global_position = get_global_position(tile + N + N) - rain.size * .5
				var tween = create_tween()
				tween.tween_property(
					rain,
					"global_position",
					get_global_position(tile) - rain.size * .5,
					anim_duration * 0.25
				)
				await tween.finished
				rain.queue_free()
				var explosion: TextureRect = TextureRect.new()
				explosion.z_index = 1
				TILEMAP.add_child(explosion)
				for i: int in 5:
					explosion.texture = load("res://assets/ennemies/priest_land%s.png" % (i + 1))
					explosion.global_position = get_global_position(tile) - explosion.size * .5
					await Globals.wait(anim_duration * 0.15)
				explosion.queue_free()
			Enums.destruction_type.SHADOW:
				var targets: Array[MapObject] = []
				for object: MapObject in get_objects_at(tile):
					if !(object is Prop):
						targets.append(object)
				if targets.size() > 0:
					var tween = create_tween().set_parallel(true)
					for target: MapObject in targets:
						tween.tween_property(
							target,
							"modulate",
							Color.BLACK,
							anim_duration * .5
						)
						tween.tween_property(
							target,
							"modulate:a",
							0,
							anim_duration * .5
						).set_delay(anim_duration * .5)
					await tween.finished
			Enums.destruction_type.POISON:
				var poison: TextureRect = TextureRect.new()
				poison.z_index = 1
				TILEMAP.add_child(poison)
				for i: int in 4:
					poison.texture = load("res://assets/map/poison%s.png" % (i + 1))
					poison.global_position = get_global_position(tile) - poison.size * .5
					await Globals.wait(anim_duration * 0.2)
				poison.queue_free()
		
		var entities: Array = get_objects_at(tile).duplicate()
		for entity in entities:
			# Entities can be freed while we await other destructions (e.g. a
			# burning house spawning/removing neighbours), so re-check validity.
			if is_instance_valid(entity) and !entity.is_queued_for_deletion():
				if entity != PLAYER and entity.get_map_position() == tile and entity.destructible:
					await entity.destroy()
		if PLAYER.get_map_position() == tile:
			if PLAYER.fly_duration == 0 or type == Enums.destruction_type.LIGHT:
				await PLAYER.get_hit()

## Enemies whose planned action will hit `tile` (cached until something changes).
func get_threats_at(tile: Vector2i) -> Array:
	if _threats_dirty or _threats_version != MapObject.board_version:
		_threats_dirty = false
		_threats_version = MapObject.board_version
		_threats.clear()
		if ENNEMIES:
			for ennemy: Ennemy in ENNEMIES.get_children():
				if ennemy.is_queued_for_destroy():
					continue
				for threatened: Vector2i in ennemy.get_threatened_tiles():
					if !_threats.has(threatened):
						_threats[threatened] = []
					_threats[threatened].append(ennemy)
	return _threats.get(tile, [])

## True if no known enemy attack will hit `tile` for a player coming from `from`.
func is_tile_safe(from: Vector2i, tile: Vector2i) -> bool:
	for ennemy: Ennemy in get_threats_at(tile):
		if ennemy.is_threat_known_from(from):
			return false
	return true

func get_opposite_vector(vector: Vector2i) -> Vector2i:
	return Vector2i(-vector.x, -vector.y)

func get_orthogonal_distance(from: Vector2i, to: Vector2i) -> int:
	var pos_dif: Vector2i = from - to
	return max(abs(pos_dif.x), abs(pos_dif.y))

func update_fog() -> void:
	for deep_fog: MapObject in DEEP_FOG.get_children():
		if deep_fog.get_map_position().distance_to(PLAYER.get_map_position()) < Globals.sight:
			deep_fog.queue_free()

func is_under_fog(tile: Vector2i) -> bool:
	return PLAYER.get_map_position().distance_to(tile) >= Globals.sight

func re_activate_visible_ennemies(tile: Vector2i) -> void:
	for ennemy: Ennemy in ENNEMIES.get_children():
		if !ennemy.visible and ennemy.get_map_position().distance_to(tile) < Globals.sight:
			ennemy.visible = true

func add_poison(tile: Vector2i) -> void:
	var poison: TextureRect = TextureRect.new()
	poison.texture = preload("res://assets/map/poisonned.png")
	TILEMAP.add_child(poison)
	poison.modulate.a = 0.0
	poison.z_index = 1
	poison.position = get_global_position(tile) - poison.size * .5
	poisonned_tiles.append(poison)
	var tween := create_tween()
	tween.tween_property(
		poison,
		"modulate:a",
		1.0,
		Globals.get_anim_duration() * .25
	)
	await tween.finished

func apply_poison() -> void:
	for tile: TextureRect in poisonned_tiles:
		await destroy_tile(TILEMAP.local_to_map(tile.position + tile.size * .5), Enums.destruction_type.POISON)
		tile.queue_free()
	poisonned_tiles = []

func is_tile_exhausted(tile: Vector2i) -> bool:
	_ensure_occupancy()
	return _crosses.has(tile)
