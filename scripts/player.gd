extends MobileObject
class_name Player
## View and input of the vampire. Clicks are sent to the TurnManager; the
## rules run on the Board; the Presenter calls the anim_* functions below.

var flight_height: int = 6
var moving: bool = false

## Default move and the automatic move while in bat form.
var walk_ability: MoveAbility = WalkAbility.new()
var flight_step_ability: MoveAbility = FlightStepAbility.new()

@onready var ORACLE: Control = $Oracle
@onready var MAIN: Main = owner as Main
@onready var GLOBAL_OVERLAY: ColorRect = owner.get_node("Ui/GlobalOverlay")
@onready var LIGHT_FOG: TileMapLayer = $LightFog
@onready var CAMERA: Camera2D = $Sprite/Camera2D

@warning_ignore("unused_signal")
signal turn_complete
@warning_ignore("unused_signal")
signal blood_harvested
signal church_exhausted
signal sun_exhausted
@warning_ignore("unused_signal")
signal enter_coffin
@warning_ignore("unused_signal")
signal died

func intro() -> void:
	sprite.position = Vector2(25, -96)
	await Globals.wait(0.5)
	var tween := create_tween()
	tween.tween_property(sprite, "position", Vector2(-24, -38), 1.0)
	await tween.finished

# --- Input ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	# Single click, ignored when the cursor is over the UI layer.
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hovered: Control = get_viewport().gui_get_hovered_control()
		if hovered and MAIN.canvas_layer.is_ancestor_of(hovered):
			return
		var world_position: Vector2 = get_canvas_transform().affine_inverse() * event.position
		try_act(Map.get_map_position(world_position))

## The ability that a click will use right now.
func get_active_ability() -> MoveAbility:
	if Map.board.player.fly_duration > 0:
		return flight_step_ability
	if Globals.selected_ability:
		return Globals.selected_ability
	return walk_ability

## Plays a turn toward `tile` with the active ability. Returns true if it happened.
func try_act(tile: Vector2i) -> bool:
	if !_can_act():
		return false
	return await MAIN.TURN_MANAGER.play_player_turn(get_active_ability(), tile)

func _can_act() -> bool:
	return !Globals.calculating_turn and !MAIN.is_ui_blocking() and !moving \
	and !MAIN.TURN_MANAGER.is_busy()

# --- Oracle (safe / dangerous reachable tiles) ---------------------------------------------

func update_oracle() -> void:
	for child in ORACLE.get_children():
		child.queue_free()
	if !_can_act():
		return
	var board: Board = Map.board
	var ability: MoveAbility = get_active_ability()
	var from: Vector2i = board.player.tile
	var ignores_threats: bool = ability.oracle_ignores_threats or board.player.fly_duration > 0
	for i: int in range(from.x - Globals.sight, from.x + Globals.sight + 1):
		for j: int in range(from.y - Globals.sight, from.y + Globals.sight + 1):
			var tile := Vector2i(i, j)
			if ability.can_target(board, tile):
				_display_oracle(tile, ignores_threats or board.is_tile_safe(from, tile))

func _display_oracle(tile: Vector2i, safe: bool) -> void:
	var oracle_icon := TextureRect.new()
	oracle_icon.texture = preload("res://assets/player/oracle_thick.png")
	ORACLE.add_child(oracle_icon)
	oracle_icon.global_position = Map.get_global_position(tile) - oracle_icon.size * .5
	if safe:
		oracle_icon.modulate = Colors.GREEN
	else:
		oracle_icon.modulate = Colors.RED
		var danger_zone := TextureRect.new()
		danger_zone.texture = preload("res://assets/player/danger.png")
		oracle_icon.add_child(danger_zone)

func enable_highlight() -> void:
	sprite.material.set_shader_parameter("outline_color", Colors.GREEN)
	sprite.material.set_shader_parameter("outline_width", 2.0)

func on_move_start() -> void:
	moving = true
	update_oracle()

func on_move_end() -> void:
	disable_highlight()
	Map.update_fog()
	reveal_land_mines()
	moving = false

## Called when the whole turn (enemies included) has been presented.
func on_turn_completed() -> void:
	update_oracle()
	enable_highlight()

func reveal_land_mines() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy is LandMines:
			ennemy.visible = Map.get_orthogonal_distance(get_map_position(), ennemy.get_map_position()) <= 1

func verify_church_exhausted() -> void:
	if Map.board.is_tile_exhausted(Map.board.player.tile) and PlayerRewards.stacks(&"moon_orb") <= 0:
		church_exhausted.emit()
		Globals.selected_ability = null

func verify_sun_exhausted() -> void:
	if RunState.turn >= Globals.turns_in_night * .9 and PlayerRewards.stacks(&"moon_orb") <= 0:
		sun_exhausted.emit()
		Globals.selected_ability = null

func init_light_fog() -> void:
	LIGHT_FOG.modulate = Colors.BLACK
	for x: int in range(-Globals.map_sight.x, Globals.map_sight.x + 1):
		for y: int in range(-Globals.map_sight.y, Globals.map_sight.y + 1):
			if Vector2i(x, y).distance_to(Vector2i.ZERO) >= Globals.sight:
				LIGHT_FOG.set_cell(Vector2i(x, y), 0, Vector2.ZERO, 0)

func zoom_out() -> void:
	var camera_tween := create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(CAMERA, "zoom", Vector2(1.8, 1.8), .9)
	camera_tween.tween_property(CAMERA, "offset", Vector2(8, 45), .9)
	await camera_tween.finished

# --- Animations (called by the Presenter) ------------------------------------------------

func _face(from: Vector2i, to: Vector2i) -> void:
	if to != from:
		direction = Map.vector_to_cardinal(to - from)

func anim_step(to: Vector2i) -> void:
	_face(get_map_position(), to)
	await anim_move_to(to)

func anim_take_off() -> void:
	sprite.texture = preload("res://assets/player/bat.png")
	sprite_origin.y -= flight_height
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite_origin.y, Globals.get_anim_duration())
	await tween.finished

func anim_land() -> void:
	sprite.texture = preload("res://assets/player/vampire.png")
	sprite_origin.y += flight_height
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite_origin.y, Globals.get_anim_duration() * 2)
	await tween.finished

func anim_teleport(to: Vector2i) -> void:
	var circles: Array[TextureRect] = []
	highlight.global_position = Map.TILEMAP.map_to_local(to) + highlight_origin
	highlight.visible = true
	for pos: Vector2 in [global_position, Map.TILEMAP.map_to_local(to)]:
		var circle := TextureRect.new()
		circle.texture = preload("res://assets/player/teleport_circle.png")
		circle.modulate.a = 0
		circle.show_behind_parent = true
		highlight.add_child(circle)
		circle.global_position = pos - circle.size * .5
		circles.append(circle)
	await _fade_all(circles, 1.0, Globals.get_anim_duration())
	move_tween = create_tween()
	move_tween.tween_property(sprite, "modulate", Color(0., 2., 2., 0.), Globals.get_anim_duration() * 2)
	move_tween.tween_callback(move_end)
	await move_tween.finished
	move_tween = create_tween()
	move_tween.tween_property(sprite, "modulate", Color.WHITE, Globals.get_anim_duration() * 2)
	await move_tween.finished
	await _fade_all(circles, 0.0, Globals.get_anim_duration())
	for circle in circles:
		circle.queue_free()
	highlight.visible = false

func _fade_all(items: Array, alpha: float, duration: float) -> void:
	var tween := create_tween().set_parallel(true)
	for item: CanvasItem in items:
		tween.tween_property(item, "modulate:a", alpha, duration)
	await tween.finished

func anim_portal(to: Vector2i) -> void:
	highlight.global_position = Map.TILEMAP.map_to_local(to) + highlight_origin
	move_tween = create_tween()
	move_tween.tween_property(sprite, "modulate", Color(0., 2., 2., 0.), Globals.get_anim_duration() * 2)
	move_tween.tween_callback(move_end)
	await move_tween.finished
	move_tween = create_tween()
	move_tween.tween_property(sprite, "modulate", Color.WHITE, Globals.get_anim_duration() * 2)
	await move_tween.finished

func anim_time_travel(to: Vector2i) -> void:
	move_tween = create_tween()
	move_tween.tween_property(GLOBAL_OVERLAY, "color", Color(0.411765, 0.411765, 0.411765, 0.66), Globals.get_anim_duration())
	move_tween.tween_property(self, "global_position", Map.get_global_position(to), Globals.get_anim_duration())
	move_tween.tween_property(GLOBAL_OVERLAY, "color", Color.TRANSPARENT, Globals.get_anim_duration())
	await move_tween.finished
	set_map_position(to)

func anim_claw(tile: Vector2i) -> void:
	_face(get_map_position(), tile)
	sprite.texture = preload("res://assets/player/werewolf.png")
	var claw: TextureRect = TextureRect.new()
	claw.texture = preload("res://assets/player/werewolf_claw.png")
	add_child(claw)
	claw.global_position = Map.get_global_position(tile) - claw.size * .5
	var claw_tween := create_tween()
	claw_tween.tween_property(claw, "modulate", Colors.RED, Globals.get_anim_duration() * .5)
	await claw_tween.finished
	claw.queue_free()

func anim_werewolf_leap(to: Vector2i) -> void:
	highlight.global_position = Map.TILEMAP.map_to_local(to) + highlight_origin
	await CurveTween.tween_curve_path(sprite, highlight.global_position, Globals.get_anim_duration())
	sprite.texture = preload("res://assets/player/vampire.png")
	move_end()

func anim_dash(to: Vector2i) -> void:
	_face(get_map_position(), to)
	highlight.global_position = Map.TILEMAP.map_to_local(to) + highlight_origin
	move_tween = create_tween()
	move_tween.tween_property(sprite, "global_position",
		highlight.global_position - highlight_origin + sprite_origin, Globals.get_anim_duration() * 1.2)
	move_tween.tween_callback(move_end)
	await move_tween.finished

## Red particles flowing from `target` to the vampire.
func anim_drain(target: MapObject) -> void:
	if !is_instance_valid(target):
		return
	target.enable_red_highlight()
	enable_red_highlight()
	var animation: CPUParticles2D = preload("res://scenes/ui/blood_harvest.tscn").instantiate()
	target.add_child(animation)
	animation.z_index = 10
	animation.position.y = -target.sprite.size.y * .25
	animation.modulate = Colors.RED
	animation.gravity = (global_position - target.global_position) * 50
	await Globals.wait(Globals.get_anim_duration() * 2)

func anim_blood_pool() -> void:
	for frame: int in [1, 2, 3, 4, 3, 2, 1]:
		sprite.texture = load("res://assets/player/blood_pool%d.png" % frame)
		await Globals.wait(Globals.get_anim_duration() * .25)
	sprite.texture = preload("res://assets/player/vampire.png")

func anim_nova(directions: Array) -> void:
	var novas: Array[TextureRect] = []
	var nova_tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	for dir: Vector2i in directions:
		var nova_icon := TextureRect.new()
		novas.append(nova_icon)
		match Map.vector_to_cardinal(dir):
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
		nova_icon.global_position = get_global_position() - nova_icon.size * .5
		nova_tween.tween_property(nova_icon, "global_position",
			Map.get_global_position(get_map_position() + dir) - nova_icon.size * .5,
			Globals.get_anim_duration() * 0.9)
	await nova_tween.finished
	for nova in novas:
		nova.texture = load(nova.texture.resource_path.left(-5) + "2.png")
	await Globals.wait(Globals.get_anim_duration() * 0.1)
	for nova in novas:
		nova.queue_free()

## Vengeance: poison globes thrown in an arc.
func anim_lob(tiles: Array) -> void:
	var globes: Array[TextureRect] = []
	for target: Vector2i in tiles:
		var globe := TextureRect.new()
		globe.texture = preload("res://assets/map/poison1.png")
		add_child(globe)
		globes.append(globe)
		CurveTween.tween_curve_path(globe, Map.get_global_position(target), Globals.get_anim_duration() * .5)
	await Globals.wait(Globals.get_anim_duration() * .5)
	for globe in globes:
		globe.queue_free()

## Puts the sprite back in the right form after an undo.
func sync_form(flying: bool) -> void:
	var is_bat: bool = sprite.texture == preload("res://assets/player/bat.png")
	if flying and !is_bat:
		sprite.texture = preload("res://assets/player/bat.png")
		sprite_origin.y -= flight_height
	elif !flying and is_bat:
		sprite.texture = preload("res://assets/player/vampire.png")
		sprite_origin.y += flight_height
	sprite.position = sprite_origin
	sprite.modulate = Color.WHITE
