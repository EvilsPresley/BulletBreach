extends Building
class_name CivilianBuilding

func destroy() -> void:
	var civilian = preload("res://scenes/map/civilian.tscn").instantiate()
	var buidling_position = get_map_position()
	civilian.set_map_position(buidling_position)
	Map.CIVILIANS.add_child(civilian)
	var fleeing_directions: Array[Vector2i] = Map.cardinals.duplicate()
	fleeing_directions.shuffle()
	for dir: Vector2i in fleeing_directions:
		var target: Vector2i = buidling_position + dir
		if Map.is_tile_safe(buidling_position, target) \
		and Map.can_move(target, [Map.BUILDINGS, Map.ENNEMIES, Map.PLAYER, Map.CIVILIANS]):
			var move_tween := create_tween()
			move_tween.tween_property(
				civilian, 
				"global_position", 
				Map.get_global_position(target), 
				0.2)
			await move_tween.finished
			break
	super()

func instant_destroy() -> void:
	var civilian = preload("res://scenes/map/civilian.tscn").instantiate()
	civilian.set_map_position(get_map_position())
	Map.CIVILIANS.add_child(civilian)
	var ruins: Prop = destroyed_scene.instantiate()
	ruins.global_position = global_position
	Map.PROPS.add_child(ruins)
	queue_free()
