extends MobileObject
class_name Player

## Default move and the automatic move while in bat form.
var walk_ability: MoveAbility = WalkAbility.new()
var flight_step_ability: MoveAbility = FlightStepAbility.new()

var moving: bool = false
var was_special_move: bool = false

var previous_positions: Array[Vector2i] = []
var fly_duration: int = 0
var flight_height: int = 6
var sanguine_pool_use: int = 0

@onready var ORACLE: Control = $Oracle
@onready var MAIN: Main = owner as Main
@onready var GLOBAL_OVERLAY: ColorRect = owner.get_node("Ui/GlobalOverlay")
@onready var LIGHT_FOG: TileMapLayer = $LightFog
@onready var CAMERA: Camera2D = $Sprite/Camera2D

signal turn_complete
signal blood_harvested
signal church_exhausted
signal sun_exhausted
signal enter_coffin
signal died

func intro() -> void:
	sprite.position = Vector2(25, -96)
	await Globals.wait(0.5)
	var tween:= create_tween()
	tween.tween_property(
		sprite,
		"position",
		Vector2(-24, -38),
		1.0
	)
	await tween.finished

func _input(event: InputEvent) -> void:
	# Single click (not "button held"), ignored when the cursor is over the UI layer.
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hovered: Control = get_viewport().gui_get_hovered_control()
		if hovered and MAIN.canvas_layer.is_ancestor_of(hovered):
			return
		var world_position: Vector2 = get_canvas_transform().affine_inverse() * event.position
		try_act(Map.get_map_position(world_position))

## The ability that a click will use right now.
func get_active_ability() -> MoveAbility:
	if fly_duration > 0:
		return flight_step_ability
	if Globals.selected_ability:
		return Globals.selected_ability
	return walk_ability

## Tries to act on the given tile with the active ability.
## Returns true if a move was performed. Also used by the headless smoke test.
func try_act(tile: Vector2i) -> bool:
	if !_can_act():
		return false
	var ability: MoveAbility = get_active_ability()
	if !ability.can_target(self, tile):
		return false
	await _move_start(tile)
	await ability.execute(self, tile)
	return true

func _can_act() -> bool:
	return !Globals.calculating_turn and !MAIN.is_ui_blocking() and !moving

func _move_start(target: Vector2i) -> void:
	Map.re_activate_visible_ennemies(target)
	moving = true
	update_oracle()
	Events.player_move_started.emit(Globals.selected_ability, fly_duration > 0)
	Globals.selected_ability = null
	await _harvest_blood(target)

func can_werewolf_to(target: Vector2i) -> bool:
	var move_dif: Vector2i = get_map_position() - target
	var werewolf_range: int = PlayerRewards.get_werewolf_range()
	if (abs(move_dif.x) <= werewolf_range or abs(move_dif.y) <= werewolf_range) \
	and max(abs(move_dif.x), abs(move_dif.y)) <= werewolf_range:
		return !Map.is_under_fog(target) \
		and (Map.BUILDINGS.get_children().filter(
			func(b) -> bool:
				return b.get_map_position() == target and b is CivilianBuilding
		).size() == 1 \
		or Map.CIVILIANS.get_children().filter(
			func(c) -> bool:return c.get_map_position() == target).size() == 1 \
		or (PlayerRewards.stacks(&"demon_wolf") \
			and Map.ENNEMIES.get_children().filter(
				func(e) -> bool: return e.get_map_position() == target).size() == 1))
	else:
		return false

func werewolf_to(target: Vector2i) -> void:
	direction = Map.vector_to_cardinal(target - get_map_position())
	sprite.texture = preload("res://assets/player/werewolf.png")
	highlight.global_position = Map.TILEMAP.map_to_local(target) + highlight_origin
	var buildings: Array = Map.BUILDINGS.get_children().filter(
		func(b) -> bool:
			return b.get_map_position() == target and b is CivilianBuilding
	)
	var ennemies: Array = Map.ENNEMIES.get_children().filter(
		func(b) -> bool:
			return b.get_map_position() == target
	)
	var claw: TextureRect = TextureRect.new()
	claw.texture = preload("res://assets/player/werewolf_claw.png")
	add_child(claw)
	claw.global_position = Map.get_global_position(target) - claw.size * .5
	var claw_tween := create_tween()
	claw_tween.tween_property(
		claw, 
		"modulate", 
		Colors.RED, 
		Globals.get_anim_duration() * .5)
	await claw_tween.finished
	claw.queue_free()
	if buildings.size() > 0:
		buildings[0].instant_destroy()
		await _harvest_blood(target)
	if ennemies.size() > 0:
		ennemies[0].destroy(false)
	
	await CurveTween.tween_curve_path(
		sprite,
		highlight.global_position,
		Globals.get_anim_duration()
	)
	sprite.texture = preload("res://assets/player/vampire.png")
	move_end()
	_move_end()

func can_time_travel_to(target: Vector2i) -> bool:
	return Map.can_move(target) \
	and previous_positions.find(target) >= 0 \
	and !Map.is_under_fog(target)

func time_travel_to(target: Vector2i) -> void:
	Events.cooldowns_reduced.emit(PlayerRewards.stacks(&"haste"))
	move_tween = create_tween()
	move_tween.tween_property(
		GLOBAL_OVERLAY, 
		"color", 
		Color(0.411765, 0.411765, 0.411765, 0.66),
		Globals.get_anim_duration())
	move_tween.tween_property(
		self,
		"global_position",
		Map.get_global_position(target),
		Globals.get_anim_duration())
	move_tween.tween_property(
		GLOBAL_OVERLAY, 
		"color", 
		Color.TRANSPARENT,
		Globals.get_anim_duration())
	await move_tween.finished
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		ennemy.confusion()
	await Globals.wait(Globals.get_anim_duration())
	_move_end()

func can_walk_to(target: Vector2i) -> bool:
	var pos_dif: Vector2i = target - get_map_position()
	if Map.get_orthogonal_distance(get_map_position(), target) != 1:
		# Trying to walk more or less than 1 tile
		return false
	# When walking diagonaly, verify that both sides are not blocking
	if (pos_dif == Map.N and !Map.can_move(target + Map.SE) and !Map.can_move(target + Map.SW)) \
	or (pos_dif == Map.S and !Map.can_move(target + Map.NE) and !Map.can_move(target + Map.NW)) \
	or (pos_dif == Map.E and !Map.can_move(target + Map.NW) and !Map.can_move(target + Map.SW)) \
	or (pos_dif == Map.W and !Map.can_move(target + Map.NE) and !Map.can_move(target + Map.SE)):
		return false
	return Map.can_move(target)

func walk_to(target: Vector2i) -> void:
	direction = target - get_map_position()
	await move_one_tile()
	_move_end(false)

func can_fly_to(target: Vector2i) -> bool:
	return Map.get_orthogonal_distance(get_map_position(), target) == 1 \
		and Map.can_move(target)

func fly_to(target: Vector2i) -> void:
	direction = target - get_map_position()
	var previous_tile: Vector2i = get_map_position()
	await move_one_tile()
	var candidate_poison_tiles: Array[Vector2i] = Map.cardinals.duplicate()
	candidate_poison_tiles.remove_at(candidate_poison_tiles.find(Map.get_opposite_vector(direction)))
	candidate_poison_tiles.shuffle()
	for i: int in PlayerRewards.stacks(&"poison_shells") * 2:
		Map.add_poison(get_map_position() + candidate_poison_tiles[i])
	await Map.add_poison(previous_tile)
	_move_end()

func take_off() -> void:
	fly_duration = PlayerRewards.get_fly_duration()
	sprite.texture = preload("res://assets/player/bat.png")
	sprite_origin.y -= flight_height
	var tween := create_tween()
	tween.tween_property(
		sprite, 
		"position:y", 
		sprite_origin.y,
		Globals.get_anim_duration())
	await tween.finished

func _land() -> void:
	sprite.texture = preload("res://assets/player/vampire.png")
	sprite_origin.y += flight_height
	var tween := create_tween()
	tween.tween_property(
		sprite, 
		"position:y", 
		sprite_origin.y,
		Globals.get_anim_duration() * 2)
	await tween.finished
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy.get_map_position() == get_map_position():
			ennemy.destroy(false)

func can_dash_to(target: Vector2i) -> bool:
	var move_dif: Vector2i = get_map_position() - target
	var dash_range: Array[int] = PlayerRewards.get_dash_range()
	if move_dif == Vector2i.ZERO:
		return false
	if (move_dif.x != 0 and dash_range.find(abs(move_dif.x)) < 0) \
	or (move_dif.y != 0 and dash_range.find(abs(move_dif.y)) < 0):
		return false
	var move_dir: Vector2i = Map.vector_to_cardinal(-move_dif)
	if Map.cardinals.find(move_dir) < 0:
		return false
	for i: int in dash_range.max():
		if !Map.can_move(get_map_position() + move_dir * (i + 1), []):
			return false
		for building:Building in Map.BUILDINGS.get_children():
			if building.get_map_position() == get_map_position() + move_dir * (i + 1) \
			and building.destroyed_scene == null:
				return false
	return true
	
func dash_to(target: Vector2i) -> void:
	var move_dir: Vector2i = Map.vector_to_cardinal(target - get_map_position())
	for i: int in PlayerRewards.get_dash_range().max():
		Map.destroy_tile(get_map_position() + move_dir * (i + 1), Enums.destruction_type.EXPLOSION)
		if get_map_position() + move_dir * (i + 1) == target:
			break
	await Globals.wait(Globals.get_anim_duration())
	highlight.global_position = Map.TILEMAP.map_to_local(target) + highlight_origin
	move_tween = create_tween()
	move_tween.tween_property(
		sprite, 
		"global_position", 
		highlight.global_position - highlight_origin + sprite_origin, 
		Globals.get_anim_duration() * 1.2)
	move_tween.tween_callback(move_end)
	await move_tween.finished
	if PlayerRewards.stacks(&"blood_dash"):
		await trigger_blood_nova(max(1, PlayerRewards.stacks(&"blood_nova")))
	_move_end()
	
func can_teleport_to(target: Vector2i) -> bool:
	if !Map.can_move(target):
		return false
	var move_dif: Vector2i = get_map_position() - target
	var teleport_range: int = PlayerRewards.get_teleport_range()
	if move_dif == Vector2i.ZERO:
		return false
	if (abs(move_dif.x) <= teleport_range or abs(move_dif.y) <= teleport_range) \
	and max(abs(move_dif.x), abs(move_dif.y)) <= teleport_range:
		return true
	return false

func teleport_to(target: Vector2i) -> void:
	var from_circle: TextureRect = TextureRect.new()
	var to_circle: TextureRect = TextureRect.new()
	from_circle.texture = preload("res://assets/player/teleport_circle.png")
	to_circle.texture = preload("res://assets/player/teleport_circle.png")
	from_circle.modulate.a = 0
	to_circle.modulate.a = 0
	from_circle.show_behind_parent = true
	to_circle.show_behind_parent = true
	highlight.global_position = Map.TILEMAP.map_to_local(target) + highlight_origin
	highlight.visible = true
	highlight.add_child(from_circle)
	highlight.add_child(to_circle)
	from_circle.global_position = global_position - from_circle.size * .5
	to_circle.global_position = Map.TILEMAP.map_to_local(target) - to_circle.size * .5
	move_tween = create_tween().set_parallel(true)
	move_tween.tween_property(
		from_circle, 
		"modulate:a", 
		1,
		Globals.get_anim_duration())
	move_tween.tween_property(
		to_circle, 
		"modulate:a", 
		1,
		Globals.get_anim_duration())
	await move_tween.finished
	move_tween = create_tween()
	move_tween.tween_property(
		sprite, 
		"modulate", 
		Color(0., 2., 2., 0.),
		Globals.get_anim_duration() * 2)
	if PlayerRewards.stacks(&"portal") > 0:
		move_tween.tween_callback(create_portals.bind(target))
	move_tween.tween_callback(move_end)
	await move_tween.finished
	move_tween = create_tween()
	move_tween.tween_property(
		sprite, 
		"modulate", 
		Color.WHITE,
		Globals.get_anim_duration() * 2)
	await move_tween.finished
	move_tween = create_tween().set_parallel(true)
	move_tween.tween_property(
		from_circle, 
		"modulate:a", 
		0,
		Globals.get_anim_duration())
	move_tween.tween_property(
		to_circle, 
		"modulate:a", 
		0,
		Globals.get_anim_duration())
	await move_tween.finished
	from_circle.queue_free()
	to_circle.queue_free()
	highlight.visible = false
	_move_end()

func create_portals(target: Vector2i) -> void:
	for prop: Prop in Map.PROPS.get_children():
		if prop.is_portal:
			prop.queue_free()
	var from_portal: Prop = preload("res://scenes/map/portal.tscn").instantiate()
	var to_portal: Prop = preload("res://scenes/map/portal.tscn").instantiate()
	from_portal.global_position = Map.get_global_position(get_map_position()) - from_portal.size * .5
	to_portal.global_position = Map.get_global_position(target) - from_portal.size * .5
	Map.PROPS.add_child(from_portal)
	Map.PROPS.add_child(to_portal)

func portal_teleport(target: Vector2i) -> void:
	highlight.global_position = Map.TILEMAP.map_to_local(target) + highlight_origin
	move_tween = create_tween()
	move_tween.tween_property(
		sprite, 
		"modulate", 
		Color(0., 2., 2., 0.),
		Globals.get_anim_duration() * 2)
	move_tween.tween_callback(move_end)
	await move_tween.finished
	move_tween = create_tween()
	move_tween.tween_property(
		sprite, 
		"modulate", 
		Color.WHITE,
		Globals.get_anim_duration() * 2)
	await move_tween.finished

func _move_end(is_special_move: bool = true) -> void:
	add_previous_position()
	if !is_special_move:
		var walked_into_portal: bool = false
		var target_portal: Vector2i
		for prop: Prop in Map.PROPS.get_children():
			if prop.is_portal:
				if prop.get_map_position() == get_map_position():
					walked_into_portal = true
				if prop.get_map_position() != get_map_position():
					target_portal = prop.get_map_position()
		if walked_into_portal:
			await portal_teleport(target_portal)
			add_previous_position()
	var effects: Array[Dictionary] = PlayerRewards.get_effects()
	if was_special_move and !is_special_move:
		for entry: Dictionary in effects:
			await entry.effect.on_walk_after_special(self, direction, entry.stacks)
	was_special_move = is_special_move
	for entry: Dictionary in effects:
		await entry.effect.on_move_end(self, entry.stacks)
	disable_highlight()
	Map.update_fog()
	_reveal_land_mines()
	sanguine_pool_use = 0
	moving = false
	turn_complete.emit()

func harvest_blood_around(level: int) -> void:
	var target_dirs: Array[Vector2i] = []
	match level:
		0: return
		1:
			target_dirs.append_array([
				Map.NE,
				Map.SE,
				Map.NW,
				Map.SW,
			])
		2: target_dirs = Map.cardinals
		3:
			target_dirs = Map.cardinals.duplicate()
			target_dirs.append_array([
				Map.NE * 2,
				Map.SE * 2,
				Map.NW * 2,
				Map.SW * 2
			])
		_:
			push_error("Soul Siphon upgrade has unexpected value")
	for dir: Vector2i in target_dirs:
		await _harvest_blood(get_map_position() + dir)

func _harvest_blood(tile: Vector2i) -> void:
	var civilians: Array = Map.get_objects_at(tile).filter(func(o): return o is Civilian)
	for civilian: Civilian in civilians:
		if is_instance_valid(civilian) and !civilian.is_queued_for_deletion():
			civilian.enable_red_highlight()
			enable_red_highlight()
			var animation: CPUParticles2D = preload("res://scenes/ui/blood_harvest.tscn").instantiate()
			civilian.add_child(animation)
			animation.z_index = 10
			animation.position.y = -civilian.sprite.size.y * .25
			animation.modulate = Colors.RED
			animation.gravity = (global_position - civilian.global_position) * 50
			await Globals.wait(Globals.get_anim_duration() * 2)
			# The civilian may have been killed by a concurrent effect (dash
			# explosions, arrows...) while we were draining it.
			if is_instance_valid(civilian) and !civilian.is_queued_for_deletion():
				await civilian.destroy()
			blood_harvested.emit()

func harvest_ennemy_blood(ennemy: Ennemy) -> void:
	ennemy.enable_red_highlight()
	enable_red_highlight()
	var animation: CPUParticles2D = preload("res://scenes/ui/blood_harvest.tscn").instantiate()
	ennemy.add_child(animation)
	animation.z_index = 10
	animation.position.y = -ennemy.sprite.size.y * .25
	animation.modulate = Colors.RED
	animation.gravity = (global_position - ennemy.global_position) * 50
	await Globals.wait(Globals.get_anim_duration() * 2)
	blood_harvested.emit()

func enable_highlight() -> void:
	sprite.material.set_shader_parameter("outline_color", Colors.GREEN)
	sprite.material.set_shader_parameter("outline_width", 2.0)

func _on_turn_manager_turn_completed() -> void:
	if fly_duration > 0:
		fly_duration -= 1
		if fly_duration <= 0:
			await _land()
	for prop: Prop in Map.PROPS.get_children():
		if prop.is_coffin and prop.get_map_position() == get_map_position():
			enter_coffin.emit()
	update_oracle()
	enable_highlight()

func _reveal_land_mines() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy is LandMines:
			if Map.get_orthogonal_distance(get_map_position(), ennemy.get_map_position()) <= 1:
				ennemy.visible = true
			else:
				ennemy.visible = false

func get_hit() -> void:
	if PlayerRewards.stacks(&"sanguine_pool") > sanguine_pool_use:
		sanguine_pool_use += 1
		if randi() % 3 <= PlayerRewards.stacks(&"sixth_sense"):
			sprite.texture = preload("res://assets/player/blood_pool1.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/blood_pool2.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/blood_pool3.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/blood_pool4.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/blood_pool3.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/blood_pool2.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/blood_pool1.png")
			await Globals.wait(Globals.get_anim_duration() * .25)
			sprite.texture = preload("res://assets/player/vampire.png")
			return
	RunState.lives -= 1
	if RunState.lives <= 0:
		died.emit()

func _update_oracle_on_tile(tile: Vector2i) -> void:
	var ability: MoveAbility = get_active_ability()
	if ability.can_target(self, tile):
		_display_oracle(tile, ability.oracle_ignores_threats or fly_duration > 0)

func _display_oracle(tile: Vector2i, fly_mode: bool = fly_duration > 0) -> void:
	var oracle_icon := TextureRect.new()
	oracle_icon.texture = preload("res://assets/player/oracle_thick.png")
	ORACLE.add_child(oracle_icon)
	oracle_icon.global_position = Map.get_global_position(tile)
	oracle_icon.global_position -= oracle_icon.size * .5
	if Map.is_tile_safe(get_map_position(), tile) or fly_mode:
		oracle_icon.modulate = Colors.GREEN
	else:
		oracle_icon.modulate = Colors.RED
		var danger_zone := TextureRect.new()
		danger_zone.texture = preload("res://assets/player/danger.png")
		oracle_icon.add_child(danger_zone)

func add_previous_position() -> void:
	if previous_positions.size() >= 10:
		previous_positions.remove_at(0)
	previous_positions.append(get_map_position())

func init_light_fog() -> void:
	LIGHT_FOG.modulate = Colors.BLACK
	for x: int in range(
		-Globals.map_sight.x,
		Globals.map_sight.x + 1
	):
		for y: int in range(
			-Globals.map_sight.y,
			Globals.map_sight.y + 1
		):
			if Vector2i(x, y).distance_to(Vector2i.ZERO) >= Globals.sight:
				LIGHT_FOG.set_cell(Vector2i(x, y), 0, Vector2.ZERO, 0)

func trigger_night_bolt(dir: Vector2i, level: int) -> void:
	if level == 0:
		return
	var target_directions: Array[Vector2i] = [dir]
	if level >= 2:
		target_directions.append_array(Map.get_similar_directions(dir, false))
	if level >= 3:
		target_directions.append_array(Map.get_similar_directions(dir, true))
	var bolts: Array[Bullet] = []
	for target: Vector2i in target_directions:
		var bolt: Bullet = preload("res://scenes/ennemies/bullet.tscn").instantiate()
		add_child(bolt)
		bolts.append(bolt)
		bolt.attack_type = Enums.destruction_type.SHADOW
		bolt.sprite.texture = preload("res://assets/player/bolt.png")
		if sprite.flip_h:
			if !bolt.sprite.is_node_ready():
				await bolt.sprite.ready
			bolt.sprite.flip_h = true
		bolt.direction = Map.vector_to_cardinal(target)
		bolt._move()
	for bolt: Bullet in bolts:
		if bolt:
			await bolt.tree_exited

func trigger_vengeance(dir: Vector2i, level: int) -> void:
	if level == 0:
		return
	var target_tiles: Array[Vector2i] = [
		get_map_position() + Map.get_opposite_vector(dir) * 2
	]
	if level >= 2:
		var similar_dirs: Array[Vector2i] = Map.get_similar_directions(Map.get_opposite_vector(dir), false)
		target_tiles.append(target_tiles[0] + similar_dirs[1])
		target_tiles.append(target_tiles[0] + similar_dirs[2])
		if level >= 3:
			target_tiles.append(target_tiles[0] + similar_dirs[1] * 2)
			target_tiles.append(target_tiles[0] + similar_dirs[2] * 2)
	var poison_globes: Array[TextureRect] = []
	for target: Vector2i in target_tiles:
		if Map.TILEMAP.get_cell_source_id(target) == 0:
			var poison_globe := TextureRect.new()
			poison_globes.append(poison_globe)
			poison_globe.texture = preload("res://assets/map/poison1.png")
			add_child(poison_globe)
			CurveTween.tween_curve_path(
				poison_globe,
				Map.get_global_position(target),
				Globals.get_anim_duration() * .5
			)
	await Globals.wait(Globals.get_anim_duration() * .5)
	for target: Vector2i in target_tiles:
		await Map.add_poison(target)
	for globe: TextureRect in poison_globes:
		globe.queue_free()

func update_oracle() -> void:
	for child in ORACLE.get_children():
		child.queue_free()
	if _can_act():
		for i: int in range(
			get_map_position().x - Globals.sight,
			get_map_position().x + Globals.sight + 1
		):
			for j: int in range(
				get_map_position().y - Globals.sight,
				get_map_position().y + Globals.sight + 1
			):
				_update_oracle_on_tile(Vector2i(i, j))

func trigger_blood_nova(nova_range: int) -> void:
	var directions: Array[Vector2i]
	match nova_range:
		0:
			return
		1:
			directions = [Map.NE, Map.SE, Map.SW, Map.NW]
		2:
			directions = Map.cardinals
		3:
			directions = Map.cardinals.duplicate()
			directions.append_array([Map.NE * 2, Map.SE * 2, Map.SW * 2, Map.NW * 2])	
	var novas: Array[TextureRect] = []
	var nova_tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	for dir: Vector2i in directions:
		var nova_icon := TextureRect.new()
		novas.append(nova_icon)
		match(Map.vector_to_cardinal(dir)):
			Map.N:
				nova_icon.texture = preload("res://assets/player/novaN1.png")
			Map.S:
				nova_icon.texture = preload("res://assets/player/novaN1.png")
				nova_icon.flip_v = true
			Map.E:
				nova_icon.texture = preload("res://assets/player/novaE1.png")
			Map.W:
				nova_icon.texture = preload("res://assets/player/novaE1.png")
				nova_icon.flip_h = true
			Map.NE:
				nova_icon.texture = preload("res://assets/player/novaNE1.png")
			Map.NW:
				nova_icon.texture = preload("res://assets/player/novaNE1.png")
				nova_icon.flip_h = true
			Map.SE:
				nova_icon.texture = preload("res://assets/player/novaNE1.png")
				nova_icon.flip_v = true
			Map.SW:
				nova_icon.texture = preload("res://assets/player/novaNE1.png")
				nova_icon.flip_h = true
				nova_icon.flip_v = true
		add_child(nova_icon)
		nova_icon.global_position = get_global_position()
		nova_icon.global_position -= nova_icon.size * .5
		nova_tween.tween_property(
			nova_icon,
			"global_position",
			Map.get_global_position(get_map_position() + dir) - nova_icon.size * .5,
			Globals.get_anim_duration() * 0.9
		)
	await nova_tween.finished
	for nova in novas:
		nova.texture = load(nova.texture.resource_path.left(-5) + "2.png")
	await Globals.wait(Globals.get_anim_duration() * 0.1)
	for nova in novas:
		nova.queue_free()
	for dir: Vector2i in directions:
		Map.destroy_tile(get_map_position() + dir, Enums.destruction_type.SHADOW)
	await Globals.wait(Globals.get_anim_duration())

func zoom_out() -> void:
	var camera_tween := create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(
		CAMERA,
		"zoom",
		Vector2(1.8, 1.8),
		.9
	)
	camera_tween.tween_property(
		CAMERA,
		"offset",
		Vector2(8, 45),
		.9
	)
	await camera_tween.finished

func verify_church_exhausted() -> void:
	if Map.is_tile_exhausted(get_map_position()) \
	and PlayerRewards.stacks(&"moon_orb") <= 0:
		church_exhausted.emit()
		Globals.selected_ability = null

func verify_sun_exhausted() -> void:
	if RunState.turn >= Globals.turns_in_night * .9\
	and PlayerRewards.stacks(&"moon_orb") <= 0:
		sun_exhausted.emit()
		Globals.selected_ability = null
