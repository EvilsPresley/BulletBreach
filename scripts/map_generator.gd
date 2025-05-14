extends Node
class_name MapGenerator

const CIVILIAN_BUILDING = preload("res://scenes/civilian_building.tscn")
const SPAWNER = preload("res://scenes/ennemy_spawn_point.tscn")

const spawners_position: Array[Vector2i] = [
	Vector2i(3, 3),
	Map.dimensions - Vector2i(3, 3),
	Vector2i(3, Map.dimensions.y - 3),
	Vector2i(Map.dimensions.x - 3, 3),
]

func generate_map() -> void:
	# Create ground
	Map.TILEMAP.clear()
	for x: int in Map.dimensions.x:
		for y: int in Map.dimensions.y:
			var distance_to_center: Vector2 = Map.dimensions * .5 - Vector2(x, y)
			distance_to_center.length_squared()
			if distance_to_center.length_squared() < pow(Map.dimensions.x * .5, 2):
				Map.TILEMAP.set_cell(Vector2(x, y), 0, Vector2.ZERO)
	
	# Position player
	Map.PLAYER.set_map_position(Map.dimensions / 2)
	
	# Position ennemy spawners
	for spawner_position: Vector2i in spawners_position:
		var spawner = SPAWNER.instantiate()
		Map.BUILDINGS.add_child(spawner)
		spawner.set_map_position(spawner_position)
	
	# Position civil buildings
	for i: int in Globals.total_civilians:
		var building = CIVILIAN_BUILDING.instantiate()
		var random_position: Vector2i = get_random_map_position()
		while(!_tile_is_free(random_position)):
			random_position = get_random_map_position()
		Map.BUILDINGS.add_child(building)
		building.set_map_position(random_position)

func _tile_is_free(tile: Vector2i) -> bool:
	if Map.PLAYER.get_map_position() == tile:
		return false
	for building: Building in Map.BUILDINGS.get_children():
		if building.get_map_position() == tile:
			return false
	return true

func get_random_map_position() -> Vector2i:
	var position: Vector2i = Vector2i.ZERO
	var spawner_neighboor: bool = true
	while spawner_neighboor:
		position = Map.TILEMAP.get_used_cells().pick_random()
		spawner_neighboor = false
		for spawner_position: Vector2i in spawners_position:
			if Map.cardinals.find(position - spawner_position) >= 0:
				spawner_neighboor = true
	return position
