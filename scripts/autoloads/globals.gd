extends Node

var move_mode: Enums.move_mode = Enums.move_mode.WALK
var turn: int = 0
var night: int = 1
var lives: int = 1
var level: int = 1
var anim_duration: float = 0.5
var calculating_turn: bool = false

const sight: int = 7
const map_sight: Vector2i = Vector2i(15, 15)
const turns_in_night: int = 50

const destroyed_ennemies_position: Vector2 = Vector2(-10000, -10000)

const bat_cooldown: int = 9
const werewolf_cooldown: int = 10
const teleport_cooldown: int = 6
const time_travel_cooldown: int = 6
const dash_cooldown: int = 7

func wait(duration_factor: float = 1.0) -> void:
	await get_tree().create_timer(duration_factor).timeout

func wait_one_frame() -> void:
	await get_tree().process_frame

func get_direction_string(direction: Vector2i) -> String:
	match direction:
		Map.N:
			return "N"
		Map.NE:
			return "NE"
		Map.E:
			return "E"
		Map.SE:
			return "SE"
		Map.S:
			return "S"
		Map.SW:
			return "SW"
		Map.W:
			return "W"
		Map.NW:
			return "NW"
	return "N"

func reset() -> void:
	move_mode = Enums.move_mode.WALK
	turn = 0
	night = 1
	lives = 1
	level = 1
	anim_duration = 0.5
	calculating_turn = false

func get_anim_duration() -> float:
	return anim_duration

func set_anim_duration(ennemies_count: int) -> void:
	if ennemies_count <= 4:
		anim_duration = 0.5
	elif ennemies_count <= 10:
		anim_duration = 0.31
	elif ennemies_count <= 15:
		anim_duration = 0.21
	else:
		anim_duration = 0.12
