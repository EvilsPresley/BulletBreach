extends Ennemy
class_name MineLayer

func plan() -> void:
	if reload_counter > 0:
		planned_action = Enums.plan.RELOAD
		planned_target = Map.PLAYER.get_map_position()

func _move() -> void:
	var cardinals: Array[Vector2i] = Map.cardinals.duplicate()
	cardinals.shuffle()
	for dir: Vector2i in cardinals:
		if Map.can_ennemy_move(get_map_position() + dir):
			_turn(dir)
			_create_mine()
			await move_one_tile()
			reload_counter = reload_time + 1 #Because plan is coming after and will already reload once
			return

func _create_mine() -> void:
	var mine: LandMines = preload("res://scenes/land_mines.tscn").instantiate()
	mine.set_map_position(get_map_position())
	Map.ENNEMIES.add_child(mine)
