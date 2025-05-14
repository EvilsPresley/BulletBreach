extends MobileObject
class_name Player

var input_direction: Vector2 = Vector2.ZERO
var can_act: bool = false

var blink_range: int = 2
var previous_positions: Array[Vector2i] = []
var jump: int = 0
var max_jump: int = 1
var flight_height: int = 20

@onready var MOVE_BUTTONS: MoveButtons = $"../../CanvasLayer/MoveButtons"
@onready var CAMERA: Camera2D = $Sprite/Camera2D
@onready var ORACLE: Control = $Oracle
@onready var GLOBAL_OVERLAY: ColorRect = $"../../CanvasLayer/GlobalOverlay"

signal turn_complete

func _process(_delta) -> void:
	for child in ORACLE.get_children():
		child.queue_free()
	if can_act:
		for i: int in Map.dimensions.x:
			for j: int in Map.dimensions.y:
				update_orcale(Vector2i(i, j))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position = Map.get_map_position(get_global_mouse_position())
		match Globals.move_mode:
			Enums.move_mode.WALK:
				if can_walk_to(mouse_position):
					walk_to(mouse_position)
			Enums.move_mode.BLINK:
				if can_blink_to(mouse_position):
					blink_to(mouse_position)
			Enums.move_mode.CHARGE:
				if can_charge_to(mouse_position):
					charge_to(mouse_position)
			Enums.move_mode.TIME_TRAVEL:
				if can_time_travel_to(mouse_position):
					time_travel_to(mouse_position)
			Enums.move_mode.JUMP:
				if can_jump_to(mouse_position):
					jump_to(mouse_position)
			_:
				push_error("The move mode %s is not yet managed in player class" % Globals.move_mode)

func can_time_travel_to(target: Vector2i) -> bool:
	return Map.can_move(target) and previous_positions.find(target) >= 0

func time_travel_to(target: Vector2i) -> void:
	if can_act:
		can_act = false
		move_tween = create_tween()
		move_tween.tween_property(
			GLOBAL_OVERLAY, 
			"color", 
			Color(0.411765, 0.411765, 0.411765, 0.66),
			move_duration)
		move_tween.tween_property(
			self,
			"global_position",
			Map.get_global_position(target),
			move_duration * 2)
		move_tween.tween_property(
			GLOBAL_OVERLAY, 
			"color", 
			Color.TRANSPARENT,
			move_duration)
		await move_tween.finished
		player_move_end()

func can_walk_to(target: Vector2i) -> bool:
	return Map.cardinals.find(get_map_position() - target) > - 1 \
		and Map.can_move(target)

func walk_to(target: Vector2i) -> void:
	if can_act:
		can_act = false
		direction = target - get_map_position()
		await move_one_tile()
		player_move_end()

func can_jump_to(target: Vector2i) -> bool:
	return Map.get_distance(get_map_position(), target) == 1 \
		and Map.can_move(target, [Map.BUILDINGS])

func jump_to(target: Vector2i) -> void:
	if can_act:
		can_act = false
		jump = max_jump
		direction = target - get_map_position()
		await _turn_to_plane()
		await move_one_tile()
		player_move_end()

func _turn_to_plane() -> void:
	sprite.texture = preload("res://assets/plane.png")
	sprite_origin.y -= flight_height
	var tween := create_tween()
	tween.tween_property(
		sprite, 
		"position:y", 
		sprite_origin.y,
		move_duration * 2)
	await tween.finished

func _land_as_mech() -> void:
	sprite.texture = preload("res://assets/mech_E.png")
	sprite_origin.y += flight_height
	var tween := create_tween()
	tween.tween_property(
		sprite, 
		"position:y", 
		sprite_origin.y,
		move_duration * 2)
	await tween.finished
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy.get_map_position() == get_map_position():
			ennemy.destroy()

func can_blink_to(target: Vector2i) -> bool:
	if !Map.can_move(target):
		return false
	var move_dif: Vector2i = get_map_position() - target
	if (abs(move_dif.x) == blink_range or abs(move_dif.y) == blink_range) \
	and max(abs(move_dif.x), abs(move_dif.y)) == blink_range:
		return true
	return false

func blink_to(target: Vector2i) -> void:
	if can_act:
		can_act = false
		highlight.global_position = Map.TILEMAP.map_to_local(target) + highlight_origin
		move_tween = create_tween()
		move_tween.tween_property(
			sprite, 
			"modulate", 
			Color(0., 2., 2., 0.),
			move_duration * 2)
		move_tween.tween_callback(move_end)
		await move_tween.finished
		move_tween = create_tween()
		move_tween.tween_property(
			sprite, 
			"modulate", 
			Color.WHITE,
			move_duration * 2)
		player_move_end()

func can_charge_to(tile: Vector2i) -> bool:
	if Map.TILEMAP.get_cell_source_id(tile) < 0:
		return false
	var target_is_aligned: bool = false
	var pos_dif: Vector2i = tile - get_map_position()
	for i in max(Map.dimensions.x, Map.dimensions.y):
		for cardinal: Vector2i in Map.cardinals:
			if pos_dif == (i + 1) * cardinal:
				target_is_aligned = true
	if !target_is_aligned:
		return false
	var target_direction: Vector2i = Map.vector_to_cardinal(pos_dif)
	for i in max(Map.dimensions.x, Map.dimensions.y):
		if tile == get_map_position() + (i + 1) * target_direction:
			return true
		for building: Building in Map.BUILDINGS.get_children():
			if building.get_map_position() == get_map_position() + (i + 1) * target_direction:
				return false
		for ennemy: Ennemy in Map.ENNEMIES.get_children():
			if ennemy.get_map_position() == get_map_position() + (i + 1) * target_direction:
				return false
	return false

func charge_to(target: Vector2i) -> void:
	if can_act:
		can_act = false
		move_duration /= 3.
		direction = Map.vector_to_cardinal(target - get_map_position())
		while Map.can_move(get_map_position() + direction):
			await move_one_tile()
		for building: Building in Map.BUILDINGS.get_children():
			if building.get_map_position() == get_map_position() + direction \
			and building.destroyed_scene != null:
				building.destroy()
				await Globals.wait(move_duration)
		for ennemy: Ennemy in Map.ENNEMIES.get_children():
			if ennemy.get_map_position() == get_map_position() + direction:
				ennemy.destroy()
				await Globals.wait(move_duration * 2)
		move_duration *= 3.
		player_move_end()

func player_move_end() -> void:
	await rescue()
	add_previous_position()
	MOVE_BUTTONS.apply_move()
	_reveal_land_mines()
	turn_complete.emit()

func _on_turn_manager_turn_completed() -> void:
	if jump > 0:
		jump -= 1
		if jump <= 0:
			await _land_as_mech()
	can_act = true

func _reveal_land_mines() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy is LandMines:
			if Map.get_distance(get_map_position(), ennemy.get_map_position()) <= 1:
				ennemy.visible = true
			else:
				ennemy.visible = false

func get_hit() -> void:
	Globals.lives -= 1

func update_orcale(tile: Vector2i) -> void:
	if Map.TILEMAP.get_cell_source_id(tile) < 0:
		return
	match Globals.move_mode:
		Enums.move_mode.WALK:
			if can_walk_to(tile):
				_display_oracle(tile)
		Enums.move_mode.BLINK:
			if can_blink_to(tile):
				_display_oracle(tile)
		Enums.move_mode.CHARGE:
			if can_charge_to(tile):
				_display_oracle(tile)
		Enums.move_mode.TIME_TRAVEL:
			if can_time_travel_to(tile):
				_display_oracle(tile)
		Enums.move_mode.JUMP:
			if can_jump_to(tile):
				_display_oracle(tile)
		_:
			push_error("The move mode %s is not yet managed in player class" % Globals.move_mode)

func _display_oracle(tile: Vector2i) -> void:
	var oracle_icon := TextureRect.new()
	var pos_dif: Vector2i = Map.vector_to_cardinal(tile - get_map_position())
	if Map.is_tile_safe(get_map_position(), tile):
		if pos_dif == Map.E or pos_dif == Map.NE or pos_dif == Map.SE or pos_dif == Map.N:
			oracle_icon.texture = preload("res://assets/oracle_safe_e.png")
		else:
			oracle_icon.texture = preload("res://assets/oracle_safe_w.png")
		oracle_icon.self_modulate = Color.GREEN_YELLOW
	else:
		if pos_dif == Map.E or pos_dif == Map.NE or pos_dif == Map.SE or pos_dif == Map.N:
			oracle_icon.texture = preload("res://assets/oracle_danger_e.png")
		else:
			oracle_icon.texture = preload("res://assets/oracle_danger_w.png")
		oracle_icon.self_modulate = Color.ORANGE_RED
	ORACLE.add_child(oracle_icon)
	oracle_icon.global_position = Map.get_global_position(tile)
	oracle_icon.global_position -= oracle_icon.size * .5

	oracle_icon.self_modulate.a = 0.2

func rescue() -> void:
	for civilians: Civilians in Map.CIVILIANS.get_children():
		if civilians.get_map_position() == get_map_position():
			await _animate_rescue(get_map_position())
			civilians.queue_free()
			Globals.rescued_civilians += 1
			return
	var shuffled_directions: Array[Vector2i] = Map.orthogonals.duplicate()
	shuffled_directions.shuffle()
	for dir: Vector2i in shuffled_directions:
		for civilians: Civilians in Map.CIVILIANS.get_children():
			if civilians.get_map_position() == get_map_position() + dir:
				await _animate_rescue(get_map_position() + dir)
				civilians.queue_free()
				Globals.rescued_civilians += 1
				return
	for dir: Vector2i in shuffled_directions:
		for building: Building in Map.BUILDINGS.get_children():
			if building.get_map_position() == get_map_position() + dir \
			and building.civilians:
				await _animate_rescue(get_map_position() + dir)
				building.rescue()
				Globals.rescued_civilians += 1
				return

func _animate_rescue(tile: Vector2i) -> void:
	var rescue_tween: Tween = create_tween().set_ease(Tween.EASE_IN)
	var civilian := TextureRect.new()
	civilian.texture = preload("res://assets/civilian_icon.png")
	add_child(civilian)
	civilian.global_position = Map.get_global_position(tile)
	civilian.global_position -= civilian.size * .5
	civilian.self_modulate = Color.CYAN
	rescue_tween.tween_property(
		civilian, 
		"global_position", 
		global_position - civilian.size * .5, 
		0.5)
	await rescue_tween.finished
	civilian.queue_free()

func add_previous_position() -> void:
	if previous_positions.size()>= 5:
		previous_positions.remove_at(0)
	previous_positions.append(get_map_position())
