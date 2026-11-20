extends MobileObject
class_name Ennemy

@export var reload_time: int = 0
## Tutorial banner shown the first time this kind of enemy appears.
@export var intro_tuto: Enums.tuto = Enums.tuto.NONE
var reload_counter: int = 0
## Data this enemy was spawned from (EnemyDefinition), null for mines etc.
var definition: Resource = null

var planned_action: Enums.plan = Enums.plan.STAND:
	set(value):
		planned_action = value
		Map.invalidate_threats()
var planned_target: Vector2i = Vector2i.ZERO:
	set(value):
		planned_target = value
		Map.invalidate_threats()
var explosion_tween: Tween

var debug_name: String

@onready var PLAN: Control = $Plan
@onready var ORDER: Label = $Sprite/Order

const BULLET = preload("res://scenes/ennemies/bullet.tscn")

## Tiles hit when the planned action resolves. Override per enemy type.
## This is the single source of truth for the oracle and civilian AI.
func get_threatened_tiles() -> Array[Vector2i]:
	return []

## Whether a player standing on `observer` knows about this threat.
func is_threat_known_from(_observer: Vector2i) -> bool:
	return true

func execute() -> void:
	clear_plan()
	match planned_action:
		Enums.plan.STAND:
			await _stand()
		Enums.plan.EXPLODE:
			await _explode()
		Enums.plan.SHOOT:
			await _shoot()
		Enums.plan.RELOAD:
			await _reload()

func _shoot() -> void:
	await _resolve_shoot()
	if reload_time > 0:
		reload_counter = reload_time

func _can_attack(_from: Vector2i, _to: Vector2i) -> bool:
	return false

func _stand() -> void:
	await Globals.wait(Globals.get_anim_duration() * .5)

func _resolve_shoot() -> void:
	await Globals.wait_one_frame()
	push_error("Undefined function _resolve_shoot for this class of ennemy.")

func _explode() -> void:
	await Globals.wait_one_frame()
	push_error("Undefined function _explode for this class of ennemy.")

func plan() -> void:
	push_error("Undefined function plan for this class of ennemy.")

func _display_shoot_plan() -> void:
	push_error("Undefined function _display_shoot_plan for this class of ennemy.")

func move() -> void:
	var under_fog: bool = Map.is_under_fog(get_map_position())
	if reload_counter <= 0:
		await _move()
	if under_fog and Map.is_under_fog(get_map_position()):
		visible = false

func _move() -> void:
	# Standard move towards the player
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	if Map.cardinals.find(pos_dif) >= 0:
		return

	for dir: Vector2i in Map.get_similar_directions(Map.vector_to_cardinal(pos_dif), false):
		if Map.can_ennemy_move(get_map_position() + dir) \
		and _can_attack(get_map_position() + dir, Map.PLAYER.get_map_position()):
			_turn(dir)
			await move_one_tile()
			return

	for dir: Vector2i in Map.get_similar_directions(Map.vector_to_cardinal(pos_dif), false):
		if Map.can_ennemy_move(get_map_position() + dir):
			_turn(dir)
			await move_one_tile()
			return

func _reload() -> void:
	await _stand()
	reload_counter -= 1

func display_plan() -> void:
	match planned_action:
		Enums.plan.STAND:
			pass
		Enums.plan.EXPLODE:
			var explode_icon := TextureRect.new()
			explode_icon.texture = preload("res://assets/ennemies/exclamation_red.png")
			PLAN.add_child(explode_icon)
			explode_icon.scale = Vector2.ONE * 2
			explode_icon.position = -explode_icon.size + Vector2(0, -8)
			explosion_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_loops()
			explosion_tween.tween_property(
				explode_icon,
				"modulate:a",
				0.2,
				0.5
			)
			explosion_tween.tween_property(
				explode_icon,
				"modulate:a",
				1,
				0.5
			)
		Enums.plan.SHOOT:
			_display_shoot_plan()
		Enums.plan.RELOAD:
			var reload_icon := TextureRect.new()
			if reload_counter == 1:
				reload_icon.texture = preload("res://assets/ennemies/reload1.png")
			else:
				reload_icon.texture = preload("res://assets/ennemies/reload2.png")
			PLAN.add_child(reload_icon)
			reload_icon.position = -reload_icon.size * .5

func clear_plan():
	if explosion_tween and explosion_tween.is_running():
		explosion_tween.kill()
	for child in PLAN.get_children():
		child.queue_free()

func _turn(pos_dif: Vector2i) -> void:
	direction = Map.vector_to_cardinal(pos_dif)
	Map.invalidate_threats()

func destroy(can_harvest_blood: bool = true) -> void:
	clear_plan()
	if Map.get_orthogonal_distance(Map.PLAYER.get_map_position(),
		get_map_position()) <= PlayerRewards.stacks(&"soul_spores") \
	and can_harvest_blood:
		await Map.PLAYER.harvest_ennemy_blood(self)
	global_position = Globals.destroyed_ennemies_position

func is_queued_for_destroy() -> bool:
	return global_position == Globals.destroyed_ennemies_position

func apply_destroy() -> void:
	if is_queued_for_destroy():
		queue_free()

func confusion() -> void:
	planned_action = Enums.plan.STAND
	clear_plan()
	var surprise_icon := TextureRect.new()
	surprise_icon.texture = preload("res://assets/ennemies/exclamation.png")
	PLAN.add_child(surprise_icon)
	surprise_icon.scale = Vector2.ONE * 2
	surprise_icon.position = -surprise_icon.size
	var surprise_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	surprise_tween.tween_property(
		surprise_icon,
		"position:y",
		surprise_icon.position.y - 20,
		Globals.get_anim_duration()
	)
	surprise_tween.tween_property(
		surprise_icon,
		"modulate:a",
		0,
		Globals.get_anim_duration()
	)
	await surprise_tween.finished
	surprise_icon.queue_free()

func show_order(i: int) -> void:
	ORDER.text = str(i)
	ORDER.visible = true

func hide_order() -> void:
	ORDER.visible = false
