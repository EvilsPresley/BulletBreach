extends MapObject
class_name MobileObject

@export var move_range: int = 1
@export var directional_sprite: bool = false

@export var direction: Vector2i: set = _set_direction

var sprite_origin: Vector2
var highlight_origin: Vector2

var move_tween: Tween

func _ready() -> void:
	sprite_origin = sprite.position
	highlight_origin = highlight.position

## Slides the sprite to `tile`, then snaps the node there.
func anim_move_to(tile: Vector2i, speed_up_factor: float = 1.0) -> void:
	highlight.global_position = Map.TILEMAP.map_to_local(tile) + highlight_origin
	move_tween = create_tween()
	move_tween.tween_property(
		sprite,
		"global_position",
		highlight.global_position - highlight_origin + sprite_origin,
		Globals.get_anim_duration() / speed_up_factor)
	move_tween.tween_callback(move_end)
	await move_tween.finished

func move_end() -> void:
	self.global_position = highlight.global_position - highlight_origin
	highlight.position = highlight_origin
	sprite.position = sprite_origin

func _set_direction(dir: Vector2i) -> void:
	direction = dir
	if dir == Map.NE or dir == Map.E or dir == Map.SE:
		sprite.flip_h = false
	if dir == Map.NW or dir == Map.W or dir == Map.SW:
		sprite.flip_h = true
