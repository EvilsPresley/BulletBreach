extends MobileObject
class_name Ennemy

const walk_duration: float = 0.3
@export var shoot_range: int = 5
@export var reload_time: int = 0
var reload_counter: int = 0

var planned_action: Enums.plan = Enums.plan.STAND
var planned_target: Vector2i = Vector2i.ZERO

@onready var FIRE: TextureRect = $Fire
@onready var PLAN: Control = $Plan

const BULLET = preload("res://scenes/bullet.tscn")

func execute() -> void:
	clear_plan()
	match planned_action:
		Enums.plan.STAND:
			pass
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
	if reload_counter <= 0:
		await _move()

func _move() -> void:
	await Globals.wait_one_frame()
	push_error("Undefined function _move for this class of ennemy.")

func _reload() -> void:
	await Globals.wait_one_frame()
	reload_counter -= 1

func display_plan() -> void:
	match planned_action:
		Enums.plan.STAND:
			pass
		Enums.plan.EXPLODE:
			var explode_icon := TextureRect.new()
			explode_icon.texture = preload("res://assets/exclamation.png")
			PLAN.add_child(explode_icon)
			explode_icon.position = -explode_icon.size * .5
			explode_icon.self_modulate = Color.ORANGE_RED
		Enums.plan.SHOOT:
			_display_shoot_plan()
		Enums.plan.RELOAD:
			for i :int in reload_counter:
				var reload_icon := TextureRect.new()
				reload_icon.texture = preload("res://assets/reload.png")
				PLAN.add_child(reload_icon)
				reload_icon.position = -reload_icon.size * .5
				reload_icon.position.x -= reload_counter * reload_icon.size.x
				reload_icon.position.x += i * 2 * reload_icon.size.x

func clear_plan():
	for child in PLAN.get_children():
		child.queue_free()

func _turn(pos_dif: Vector2i) -> void:
	direction = Map.vector_to_cardinal(pos_dif)

func destroy() -> void:
	FIRE.visible = true
	PLAN.visible = false

func is_detroyed() -> bool:
	return FIRE.visible

func move_one_tile() -> void:
	await super()
	Map.kill_civilians(get_map_position())
