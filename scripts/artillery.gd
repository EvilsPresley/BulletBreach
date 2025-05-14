extends Ennemy
class_name Artillery

var aiming: bool = false

func _can_shoot(pos_dif: Vector2i) -> bool:
	return (pos_dif.x == 0 and abs(pos_dif.y) <= shoot_range) \
	or (pos_dif.y == 0 and abs(pos_dif.x) <= shoot_range)

func _display_shoot_plan() -> void:
	var shoot_direction: Vector2i = _get_artillery_direction()

	var launch_icon := TextureRect.new()
	if shoot_direction == Map.NE or shoot_direction == Map.SE:
		launch_icon.texture = preload("res://assets/artillery_arrow_NW.png")
	else:
		launch_icon.texture = preload("res://assets/artillery_arrow_NE.png")
	PLAN.add_child(launch_icon)
	launch_icon.global_position = Map.get_global_mid_position(get_map_position(), get_map_position() + Map.N)
	launch_icon.position -= launch_icon.size * .5
	launch_icon.self_modulate = Color.ORANGE_RED
	
	for target: Vector2i in _get_artillery_targets():
		var land_icon := TextureRect.new()
		if shoot_direction == Map.NE or shoot_direction == Map.SE:
			land_icon.texture = preload("res://assets/artillery_arrow_SW.png")
		else:
			land_icon.texture = preload("res://assets/artillery_arrow_SE.png")
		PLAN.add_child(land_icon)
		land_icon.global_position = Map.get_global_mid_position(target, target + Map.N)
		land_icon.position -= land_icon.size * .5
		land_icon.z_index = 1
		land_icon.self_modulate = Color.ORANGE_RED
	aiming = true
	queue_redraw()

func plan() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	planned_action = Enums.plan.STAND
	planned_target = Vector2i.ZERO
	if reload_counter > 0:
		planned_action = Enums.plan.RELOAD
		planned_target = Map.PLAYER.get_map_position()
	elif _can_shoot(pos_dif):
		# shoot
		_turn(pos_dif)
		planned_action = Enums.plan.SHOOT
		planned_target = Map.PLAYER.get_map_position()
	else:
		planned_action = Enums.plan.STAND

func _get_artillery_targets() -> Array[Vector2i]:
	var targets: Array[Vector2i] = [planned_target]
	if _get_artillery_direction() == Map.NE or _get_artillery_direction() == Map.SW:
		targets.append(planned_target + Map.NW)
		targets.append(planned_target + Map.SE)
	else:
		targets.append(planned_target + Map.NE)
		targets.append(planned_target + Map.SW)
	return targets

func _get_artillery_direction() -> Vector2i:
	var pos_dif = get_map_position() - planned_target
	return pos_dif / pos_dif.length()

func _resolve_shoot() -> void:
	const shell_ceiling: int = 400
	var shells: Array[TextureRect]
	var shell_tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	for target: Vector2i in _get_artillery_targets():
		var shell := TextureRect.new()
		shell.texture = preload("res://assets/bullet/bullet_N.png")
		add_child(shell)
		shells.append(shell)
		shell.global_position = global_position
		shell.position -= shell.size * .5
		shell_tween.tween_property(
			shell, 
			"global_position:y", 
			shell.global_position.y - shell_ceiling, 
			0.25).set_delay(0.01 * shells.size())
	await shell_tween.finished
	await Globals.wait_one_frame()
	shell_tween = create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	for target: Vector2i in _get_artillery_targets():
		var shell := TextureRect.new()
		shell.texture = preload("res://assets/bullet/bullet_S.png")
		add_child(shell)
		shells.append(shell)
		shell.global_position = Map.get_global_position(target)
		shell.position -= shell.size * .5
		shell.position.y -= shell_ceiling
		shell_tween.tween_property(
			shell, 
			"global_position:y", 
			Map.get_global_position(target).y, 
			0.35).set_delay(0.01 * (shells.size() - 3))
	await shell_tween.finished
	for shell: TextureRect in shells:
		shell.queue_free()
	
	for target: Vector2i in _get_artillery_targets():
		if Map.TILEMAP.get_cell_source_id(target) >= 0:
			var fire_icon := TextureRect.new()
			fire_icon.texture = preload("res://assets/fire.png")
			add_child(fire_icon)
			shells.append(fire_icon)
			fire_icon.global_position = Map.get_global_position(target)
			fire_icon.global_position -= fire_icon.size * .5
	await Globals.wait(0.3)
	for target: Vector2i in _get_artillery_targets():
		await Map.destroy_tile(target, false, true)
	
	for shell: TextureRect in shells:
		if shell:
			shell.queue_free()
	aiming = false
	queue_redraw()

func _move() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	var target_dir: Vector2i = Vector2i.ZERO
	if abs(pos_dif.x) >= shoot_range and abs(pos_dif.y) >= shoot_range:
		# too far from player => go closer
		target_dir = Map.vector_to_cardinal(pos_dif)
	else:
		if _can_shoot(pos_dif):
			return
		# close but not aligned with player => try to align
		if abs(pos_dif.x) < abs(pos_dif.y):
			target_dir = Vector2i(floor(sign(pos_dif.x)), 0)
		else:
			target_dir = Vector2i(0, floor(sign(pos_dif.y)))
	
	for dir: Vector2i in Map.get_similar_directions(Map.vector_to_cardinal(target_dir)):
		if Map.can_ennemy_move(get_map_position() + dir):
			_turn(dir)
			await move_one_tile()
			return

func _draw() -> void:
	if aiming:
		var origin: Vector2 = Map.get_global_mid_position(
			get_map_position(),
			get_map_position() + Map.N) - global_position
		for target: Vector2i in _get_artillery_targets():
			draw_line(
				origin,
				Map.get_global_mid_position(target, target + Map.N) - global_position,
				Color.RED
				)
			
			#var line = Line2D.new()
			#line.texture = load("res://assets/dotted_line.png")
			#line.texture_repeat = Line2D.TEXTURE_REPEAT_ENABLED
			#line.texture_mode = Line2D.LINE_TEXTURE_STRETCH 
			#line.modulate = Color.RED
			#line.add_point(origin)
			#line.add_point(Map.get_global_position(_get_artillery_targets()[0]) - global_position)
			#PLAN.add_child(line)
		
