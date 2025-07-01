extends Ennemy
class_name Artillery

var aiming: bool = false

func _can_attack(from: Vector2i, to: Vector2i) -> bool:
	var pos_dif: Vector2i = to - from
	return (pos_dif.x == 0 or pos_dif.y == 0 \
	or pos_dif.x == pos_dif.y or pos_dif.x == -pos_dif.y) \
	and !Map.is_under_fog(from)

func _display_shoot_plan() -> void:
	var shoot_direction: Vector2i = _get_artillery_direction()

	var launch_icon := TextureRect.new()
	var land_icon_texture: Texture2D
	match shoot_direction:
		Map.N, Map.S:
			launch_icon.texture = preload("res://assets/arrows/arrow_N.png")
			land_icon_texture = preload("res://assets/arrows/arrow_S.png")
		Map.E, Map.SE, Map.NE:
			launch_icon.texture = preload("res://assets/arrows/arrow_NE.png")
			land_icon_texture = preload("res://assets/arrows/arrow_SE.png")
		Map.W, Map.SW, Map.NW:
			launch_icon.texture = preload("res://assets/arrows/arrow_NE.png")
			land_icon_texture = preload("res://assets/arrows/arrow_SW.png")
			launch_icon.flip_h = true
		_:
			push_error("Shoort direction %s is not handled in artillery class" % shoot_direction)
	PLAN.add_child(launch_icon)
	launch_icon.global_position = Map.get_global_mid_position(get_map_position(), get_map_position() + Map.N)
	launch_icon.position -= launch_icon.size * .5
	
	for target: Vector2i in _get_artillery_targets():
		var land_icon := TextureRect.new()
		land_icon.texture = land_icon_texture
		PLAN.add_child(land_icon)
		land_icon.global_position = Map.get_global_mid_position(target, target + Map.N)
		land_icon.position -= land_icon.size * .5
		land_icon.z_index = 1
	aiming = true
	queue_redraw()

func plan() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	planned_action = Enums.plan.STAND
	planned_target = Vector2i.ZERO
	if reload_counter > 0:
		planned_action = Enums.plan.RELOAD
		planned_target = Map.PLAYER.get_map_position()
	elif _can_attack(get_map_position(), Map.PLAYER.get_map_position()):
		# shoot
		_turn(pos_dif)
		planned_action = Enums.plan.SHOOT
		planned_target = Map.PLAYER.get_map_position()
	else:
		planned_action = Enums.plan.STAND

func _get_artillery_targets() -> Array[Vector2i]:
	var targets: Array[Vector2i] = [planned_target]
	var shoot_directions: Array[Vector2i] = Map.get_similar_directions(
		_get_artillery_direction(),
		true
	)
	targets.append(planned_target + shoot_directions[1])
	targets.append(planned_target + shoot_directions[2])
	return targets

func _get_artillery_direction() -> Vector2i:
	return Map.vector_to_cardinal(planned_target - get_map_position())

func _resolve_shoot() -> void:
	for target: Vector2i in _get_artillery_targets():
		await Map.destroy_tile(target, Enums.destruction_type.LIGHT)
	aiming = false
	queue_redraw()

func _draw() -> void:
	if aiming:
		var origin: Vector2 = Map.get_global_mid_position(
			get_map_position(),
			get_map_position() + Map.N) - global_position
		for target: Vector2i in _get_artillery_targets():
			draw_line(
				origin,
				Map.get_global_mid_position(target, target + Map.N) - global_position,
				Color.RED,
				2)

func clear_plan() -> void:
	super()
	aiming = false
	queue_redraw()
