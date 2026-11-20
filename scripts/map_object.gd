extends Control
class_name MapObject
## View of a board unit (building, prop, civilian, enemy, player).
## The exported flags are read once to build the Board.

@onready var sprite: TextureRect = $Sprite
@onready var highlight: TextureRect = $Highlight
@export var destructible: bool = true
@export var is_coffin: bool = false
@export var is_portal: bool = false

## Id of the Board unit this node displays (0 = not a board unit).
var unit_id: int = 0

func get_map_position() -> Vector2i:
	return Map.get_map_position(global_position)

func set_map_position(pos: Vector2i) -> void:
	global_position = Map.TILEMAP.to_global(Map.TILEMAP.map_to_local(pos))

func enable_highlight() -> void:
	sprite.material.set_shader_parameter("outline_color", Colors.WHITE)
	sprite.material.set_shader_parameter("outline_width", 2.0)

func enable_red_highlight() -> void:
	sprite.material.set_shader_parameter("outline_color", Colors.RED)
	sprite.material.set_shader_parameter("outline_width", 2.0)

func disable_highlight() -> void:
	sprite.material.set_shader_parameter("outline_width", 0.0)
