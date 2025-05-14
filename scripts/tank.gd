extends Ennemy
class_name Tank

func _resolve_shoot() -> void:
	var bullet: Bullet = BULLET.instantiate()
	add_child(bullet)
	bullet.global_position = global_position
	bullet.direction = Map.vector_to_cardinal(direction)
	bullet.shoot_range = shoot_range
	await bullet._move()

func _can_shoot(from: Vector2i, to: Vector2i) -> bool:
	var pos_dif: Vector2i = to - from
	var target_is_aligned: bool = false
	for i in shoot_range:
		for cardinal: Vector2i in Map.cardinals:
			if pos_dif == (i + 1) * cardinal:
				target_is_aligned = true
	if !target_is_aligned:
		return false
	var target_direction: Vector2i = Map.vector_to_cardinal(pos_dif)
	for i in shoot_range:
		if to == from + (i + 1) * target_direction:
			return true
		for building: Building in Map.BUILDINGS.get_children():
			if building.get_map_position() == from + (i + 1) * target_direction:
				return false
		for ennemy: Ennemy in Map.ENNEMIES.get_children():
			if ennemy.get_map_position() == from + (i + 1) * target_direction:
				return false
	return false

func plan() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	planned_action = Enums.plan.STAND
	planned_target = Vector2i.ZERO
	if reload_counter > 0:
		planned_action = Enums.plan.RELOAD
		planned_target = Map.PLAYER.get_map_position()
	elif _can_shoot(get_map_position(), Map.PLAYER.get_map_position()):
		_turn(pos_dif)
		planned_action = Enums.plan.SHOOT
		planned_target = Map.PLAYER.get_map_position()
	else:
		planned_action = Enums.plan.STAND

func _display_shoot_plan() -> void:
	for i: int in shoot_range:
		var target_tile: Vector2i = get_map_position() + (i + 1) * direction
		var bullet_path_icon1 := TextureRect.new()
		var bullet_path_icon2 := TextureRect.new()
		bullet_path_icon1.texture = preload("res://assets/bullet_path.png")
		bullet_path_icon2.texture = preload("res://assets/bullet_path.png")
		PLAN.add_child(bullet_path_icon1)
		PLAN.add_child(bullet_path_icon2)
		bullet_path_icon1.global_position = Map.get_global_mid_position(
			get_map_position() + i * direction,
			target_tile)
		bullet_path_icon1.global_position -= bullet_path_icon1.size / 2
		bullet_path_icon2.global_position = Map.get_global_position(
			target_tile)
		bullet_path_icon2.global_position -= bullet_path_icon2.size / 2
		bullet_path_icon1.self_modulate = Color.ORANGE_RED
		bullet_path_icon2.self_modulate = Color.ORANGE_RED
		if !Map.can_move(target_tile):
			return

func _move() -> void:
	var cardinals: Array[Vector2i] = Map.cardinals.duplicate()
	cardinals.shuffle()
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	var player_dir: Vector2i = Map.vector_to_cardinal(pos_dif)
	var eligible_directions: Array[Vector2i] = [Vector2i.ZERO, player_dir]
	eligible_directions.append_array(cardinals)
	
	for dir: Vector2i in eligible_directions:
		if Map.can_ennemy_move(get_map_position() + dir) \
		and _can_shoot(get_map_position() + dir, Map.PLAYER.get_map_position()):
			if dir != Vector2i.ZERO:
				_turn(dir)
				await move_one_tile()
			return 
	for dir: Vector2i in Map.get_similar_directions(Map.vector_to_cardinal(pos_dif)):
		if Map.can_ennemy_move(get_map_position() + dir):
			_turn(dir)
			await move_one_tile()
			return
