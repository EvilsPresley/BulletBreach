extends Ennemy
class_name LandMines

func is_walk_through() -> bool:
	return true

func get_threatened_tiles() -> Array[Vector2i]:
	return [get_map_position()]

## Mines are only known when the player stands next to them.
func is_threat_known_from(observer: Vector2i) -> bool:
	return Map.get_orthogonal_distance(observer, get_map_position()) <= 1

func plan() -> void:
	planned_action = Enums.plan.STAND

func _move() -> void:
	if Map.PLAYER.get_map_position() == get_map_position():
		Map.destroy_tile(get_map_position(), Enums.destruction_type.EXPLOSION)
