extends Ennemy
class_name Tank

func _resolve_shoot() -> void:
	var bullet: Bullet = BULLET.instantiate()
	add_child(bullet)
	if sprite.flip_h:
		if !bullet.sprite.is_node_ready():
			await bullet.sprite.ready
		bullet.sprite.flip_h = true
	bullet.direction = Map.vector_to_cardinal(direction)
	await bullet._move()
	Events.arrow_fired.emit()

func get_threatened_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if planned_action != Enums.plan.SHOOT:
		return tiles
	for i: int in Globals.sight:
		var tile: Vector2i = get_map_position() + (i + 1) * direction
		if _can_attack(get_map_position(), tile):
			tiles.append(tile)
	return tiles

func _can_attack(from: Vector2i, to: Vector2i) -> bool:
	var pos_dif: Vector2i = to - from
	var target_is_aligned: bool = false
	if Map.is_under_fog(from):
		return false
	for i in Globals.sight:
		for cardinal: Vector2i in Map.cardinals:
			if pos_dif == (i + 1) * cardinal:
				target_is_aligned = true
	if !target_is_aligned:
		return false
	var target_direction: Vector2i = Map.vector_to_cardinal(pos_dif)
	for i in Globals.sight:
		if to == from + (i + 1) * target_direction:
			return true
		if !Map.can_arrow_move(from + (i + 1) * target_direction, false):
			return false
	return false

func plan() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	planned_action = Enums.plan.STAND
	planned_target = Vector2i.ZERO
	if reload_counter > 0:
		planned_action = Enums.plan.RELOAD
		planned_target = Map.PLAYER.get_map_position()
	elif _can_attack(get_map_position(), Map.PLAYER.get_map_position()):
		_turn(pos_dif)
		planned_action = Enums.plan.SHOOT
		planned_target = Map.PLAYER.get_map_position()
	else:
		planned_action = Enums.plan.STAND

func _display_shoot_plan() -> void:
	for i: int in Globals.sight:
		var target_tile: Vector2i = get_map_position() + (i + 1) * direction
		var bullet_path_icon1 := TextureRect.new()
		var bullet_path_icon2 := TextureRect.new()
		bullet_path_icon1.texture = preload("res://assets/ennemies/bullet_path.png")
		bullet_path_icon2.texture = preload("res://assets/ennemies/bullet_path.png")
		bullet_path_icon1.self_modulate = Colors.RED
		bullet_path_icon2.self_modulate = Colors.RED
		PLAN.add_child(bullet_path_icon1)
		PLAN.add_child(bullet_path_icon2)
		bullet_path_icon1.global_position = Map.get_global_mid_position(
			get_map_position() + i * direction,
			target_tile)
		bullet_path_icon1.global_position -= bullet_path_icon1.size / 2
		bullet_path_icon2.global_position = Map.get_global_position(
			target_tile)
		bullet_path_icon2.global_position -= bullet_path_icon2.size / 2
		if !Map.can_move(target_tile):
			return
