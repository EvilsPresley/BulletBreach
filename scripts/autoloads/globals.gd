extends Node

var move_mode: Enums.move_mode = Enums.move_mode.WALK
var turn: int = 0
var lives: int = 3

const total_civilians: int = 25
var rescued_civilians: int = 0
var alive_civilians: int = total_civilians

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
	alive_civilians = total_civilians
	rescued_civilians = 0
	turn = 0
	lives = 3
