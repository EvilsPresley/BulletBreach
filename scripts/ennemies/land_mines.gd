extends Ennemy
class_name LandMines

func plan() -> void:
	planned_action = Enums.plan.STAND

func _move() -> void:
	if Map.PLAYER.get_map_position() == get_map_position():
		Map.destroy_tile(get_map_position(), Enums.destruction_type.EXPLOSION)
