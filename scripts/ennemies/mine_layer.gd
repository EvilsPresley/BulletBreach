extends Ennemy
class_name MineLayer

func plan() -> void:
	if reload_counter > 0:
		planned_action = Enums.plan.RELOAD
		planned_target = Map.PLAYER.get_map_position()
	else:
		planned_action = Enums.plan.SHOOT

func _resolve_shoot() -> void:
	_create_mine()

func _display_shoot_plan() -> void:
	var exclamation_icon := TextureRect.new()
	exclamation_icon.texture = preload("res://assets/ennemies/exclamation_red.png")
	PLAN.add_child(exclamation_icon)
	exclamation_icon.scale = Vector2.ONE * 2
	exclamation_icon.position = -exclamation_icon.size + Vector2(0, -8)

func _create_mine() -> void:
	var mine: LandMines = preload("res://scenes/ennemies/land_mines.tscn").instantiate()
	mine.set_map_position(get_map_position())
	Map.ENNEMIES.add_child(mine)
