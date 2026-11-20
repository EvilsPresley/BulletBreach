extends Control
class_name MapObject

@onready var sprite: TextureRect = $Sprite
@onready var highlight: TextureRect = $Highlight
@export var destructible: bool = true
@export var is_coffin: bool = false
@export var is_portal: bool = false

## Bumped whenever any map object moves, appears or disappears. The Map
## autoload compares it with the version it last indexed (no direct reference
## to Map here, which would create a script/scene load cycle).
static var board_version: int = 0

func _enter_tree() -> void:
	set_notify_transform(true)
	board_version += 1

func _exit_tree() -> void:
	board_version += 1

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		board_version += 1

func get_map_position() -> Vector2i:
	return Map.get_map_position(global_position)

func set_map_position(pos: Vector2i) -> void:
	global_position = Map.TILEMAP.to_global(Map.TILEMAP.map_to_local(pos))

## Objects that never block movement (e.g. hidden land mines).
func is_walk_through() -> bool:
	return false

func destroy() -> void:
	await Globals.wait_one_frame()
	if destructible:
		queue_free()

func enable_highlight() -> void:
	sprite.material.set_shader_parameter("outline_color", Colors.WHITE)
	sprite.material.set_shader_parameter("outline_width", 2.0)

func enable_red_highlight() -> void:
	sprite.material.set_shader_parameter("outline_color", Colors.RED)
	sprite.material.set_shader_parameter("outline_width", 2.0)

func disable_highlight() -> void:
	sprite.material.set_shader_parameter("outline_width", 0.0)
