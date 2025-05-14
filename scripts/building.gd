extends MapObject
class_name Building

@export var civilians: bool = false
@export var skills: Array[Enums.building_skill] = []
@export var destroyed_scene: PackedScene = null

func destroy() -> void:
	if civilians:
		await escape()
	if destroyed_scene:
		var new_building = destroyed_scene.instantiate()
		new_building.global_position = global_position
		Map.BUILDINGS.add_child(new_building)
		queue_free()

func rescue() -> void:
	var new_building = preload("res://scenes/civilian_building_empty.tscn").instantiate()
	new_building.global_position = global_position
	Map.BUILDINGS.add_child(new_building)
	queue_free()

func escape() -> void:
	var civilians_scene = preload("res://scenes/civilians.tscn").instantiate()
	civilians_scene.global_position = global_position
	Map.CIVILIANS.add_child(civilians_scene)
	var escape_ways: Array[Vector2i] = Map.cardinals
	var eligible_ways: Array[Vector2i] = []
	for dir: Vector2i in escape_ways:
		if Map.can_ennemy_move(get_map_position() + dir):
			eligible_ways.append(dir)
	eligible_ways.shuffle()
	for dir: Vector2i in eligible_ways:
		if Map.is_tile_safe(get_map_position(), get_map_position() + dir):
			civilians_scene.direction = dir
			await civilians_scene.move_one_tile()
			return
	civilians_scene.direction = eligible_ways.pick_random()
	await civilians_scene.move_one_tile()
