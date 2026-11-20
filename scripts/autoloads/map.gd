extends Node
## Map *view* helpers: coordinates, node containers and visual effects.
## Game rules and state live in the Board (Map.board) and Rules.

const N: Vector2i = Grid.N
const E: Vector2i = Grid.E
const S: Vector2i = Grid.S
const W: Vector2i = Grid.W
const NE: Vector2i = Grid.NE
const SE: Vector2i = Grid.SE
const SW: Vector2i = Grid.SW
const NW: Vector2i = Grid.NW

const cardinals: Array[Vector2i] = Grid.cardinals
const orthogonals: Array[Vector2i] = [N, S, E, W]

const dimensions: Vector2i = Vector2i(32, 32)

var TILEMAP: TileMapLayer = null
var BUILDINGS: Node = null
var CIVILIANS: Node = null
var ENNEMIES: Node = null
var PROPS: Node = null
var CROSSES: Node = null
var PLAYER: Player = null
var DEEP_FOG: Control = null

## Authoritative state of the current night.
var board: Board

var _poison_markers: Dictionary = {}  # Vector2i -> Array[TextureRect]

func get_map_position(global_pos: Vector2) -> Vector2i:
	return TILEMAP.local_to_map(global_pos)

func get_global_position(map_position: Vector2i) -> Vector2:
	return TILEMAP.map_to_local(map_position) + TILEMAP.global_position

func get_global_mid_position(map_position1: Vector2i, map_position2: Vector2i) -> Vector2:
	return (TILEMAP.map_to_local(map_position1) + TILEMAP.map_to_local(map_position2)) * 0.5 \
	+ TILEMAP.global_position

func vector_to_cardinal(vector: Vector2) -> Vector2i:
	return Grid.vector_to_cardinal(vector)

func get_opposite_vector(vector: Vector2i) -> Vector2i:
	return Grid.opposite(vector)

func get_orthogonal_distance(from: Vector2i, to: Vector2i) -> int:
	return Grid.distance(from, to)

func is_under_fog(tile: Vector2i) -> bool:
	return board.is_under_fog(tile)

func update_fog() -> void:
	for deep_fog: MapObject in DEEP_FOG.get_children():
		if Vector2(deep_fog.get_map_position()).distance_to(Vector2(PLAYER.get_map_position())) < Globals.sight:
			deep_fog.queue_free()

# --- Visual effects -----------------------------------------------------------------

## Plays the visual of an attack on a tile. `targets` are the nodes hit
## (faded out by shadow attacks). Purely cosmetic: damage is already resolved.
func play_tile_effect(tile: Vector2i, type: Enums.destruction_type, targets: Array = []) -> void:
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
			await _play_frames(tile, "res://assets/ennemies/explosion%s.png", 5, anim_duration * 0.2, 2)
		Enums.destruction_type.LIGHT:
			var rain: TextureRect = TextureRect.new()
			rain.texture = preload("res://assets/ennemies/priest_air.png")
			rain.z_index = 1
			TILEMAP.add_child(rain)
			rain.global_position = get_global_position(tile + N + N) - rain.size * .5
			var tween = create_tween()
			tween.tween_property(rain, "global_position",
				get_global_position(tile) - rain.size * .5, anim_duration * 0.25)
			await tween.finished
			rain.queue_free()
			await _play_frames(tile, "res://assets/ennemies/priest_land%s.png", 5, anim_duration * 0.15, 1)
		Enums.destruction_type.SHADOW:
			var live_targets: Array = targets.filter(func(t): return is_instance_valid(t))
			if live_targets.size() > 0:
				var tween = create_tween().set_parallel(true)
				for target: CanvasItem in live_targets:
					tween.tween_property(target, "modulate", Color.BLACK, anim_duration * .5)
					tween.tween_property(target, "modulate:a", 0, anim_duration * .5).set_delay(anim_duration * .5)
				await tween.finished
		Enums.destruction_type.POISON:
			await _play_frames(tile, "res://assets/map/poison%s.png", 4, anim_duration * 0.2, 1)

func _play_frames(tile: Vector2i, path_pattern: String, count: int, frame_time: float, z: int) -> void:
	var frame := TextureRect.new()
	frame.z_index = z
	TILEMAP.add_child(frame)
	for i: int in count:
		frame.texture = load(path_pattern % (i + 1))
		frame.global_position = get_global_position(tile) - frame.size * .5
		await Globals.wait(frame_time)
	frame.queue_free()

func add_poison_marker(tile: Vector2i) -> void:
	var poison: TextureRect = TextureRect.new()
	poison.texture = preload("res://assets/map/poisonned.png")
	TILEMAP.add_child(poison)
	poison.modulate.a = 0.0
	poison.z_index = 1
	poison.position = get_global_position(tile) - poison.size * .5
	if !_poison_markers.has(tile):
		_poison_markers[tile] = []
	_poison_markers[tile].append(poison)
	var tween := create_tween()
	tween.tween_property(poison, "modulate:a", 1.0, Globals.get_anim_duration() * .25)
	await tween.finished

func remove_poison_marker(tile: Vector2i) -> void:
	if _poison_markers.has(tile) and !_poison_markers[tile].is_empty():
		var marker: TextureRect = _poison_markers[tile].pop_back()
		if is_instance_valid(marker):
			marker.queue_free()

func clear_poison_markers() -> void:
	for markers: Array in _poison_markers.values():
		for marker in markers:
			if is_instance_valid(marker):
				marker.queue_free()
	_poison_markers.clear()
