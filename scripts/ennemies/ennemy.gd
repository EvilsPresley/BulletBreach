extends MobileObject
class_name Ennemy

@export var reload_time: int = 0
var reload_counter: int = 0

var planned_action: Enums.plan = Enums.plan.STAND
var planned_target: Vector2i = Vector2i.ZERO
var explosion_tween: Tween

var debug_name: String

@onready var PLAN: Control = $Plan
@onready var ORDER: Label = $Sprite/Order

const BULLET = preload("res://scenes/ennemies/bullet.tscn")

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
		
	var hls: Array[TextureRect]
	for dir: Vector2i in Map.get_similar_directions(Map.vector_to_cardinal(pos_dif), false):
		var hl: TextureRect = TextureRect.new()
		hls.append(hl)
		hl.texture = preload("res://assets/map/hl_test.png")
		add_child(hl)
		hl.modulate = Color.ORANGE
		hl.global_position = Map.get_global_position(get_map_position() + dir) - hl.size * .5
	await Globals.wait(.5)
	for hl in hls:
		hl.queue_free()
		
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

func destroy(can_harvest_blood: bool = true) -> void:
	clear_plan()
	if Map.get_orthogonal_distance(Map.PLAYER.get_map_position(),
		get_map_position()) <= PlayerRewards.has_reward("Soul Spores") \
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
