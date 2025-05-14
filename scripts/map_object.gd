extends Control
class_name MapObject

@export var hp: int = 0
@export var dmg: int = 0

@onready var sprite: TextureRect = $Sprite
@onready var highlight: TextureRect = $Highlight

func get_map_position() -> Vector2i:
	return Map.get_map_position(global_position)

func set_map_position(pos: Vector2i) -> void:
	global_position = Map.TILEMAP.to_global(Map.TILEMAP.map_to_local(pos))
