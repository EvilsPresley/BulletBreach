extends Ennemy
class_name LandMines

func plan() -> void:
	planned_action = Enums.plan.STAND

func _move() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy.get_map_position() == get_map_position() and ennemy != self:
			Map.destroy_tile(get_map_position())
	for civilian: Civilians in Map.CIVILIANS.get_children():
		if civilian.get_map_position() == get_map_position():
			Map.destroy_tile(get_map_position())
	if Map.PLAYER.get_map_position() == get_map_position():
		Map.destroy_tile(get_map_position())
