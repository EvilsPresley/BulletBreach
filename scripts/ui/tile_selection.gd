extends TextureRect
class_name TileSelection

const blink_duration: float = 0.25


var blink_counter: float = 0.0
var last_mouse_position: Vector2i = Vector2i.ZERO

func _physics_process(delta: float) -> void:
	blink_counter += delta
	if blink_counter <= blink_duration:
		visible = true
	elif blink_counter <= 2 * blink_duration:
		visible = false
	else:
		blink_counter = 0.0
	
	if Map.TILEMAP == null:
		return
	var tile_map_layer: TileMapLayer = Map.TILEMAP
	var current_mouse_position = tile_map_layer.local_to_map(get_global_mouse_position())
	if current_mouse_position != last_mouse_position:
		last_mouse_position = current_mouse_position
		position = tile_map_layer.map_to_local(current_mouse_position) - size * .5 + Vector2(0, -1)
	
	if Map.PLAYER:
		if !Map.PLAYER.get_active_ability().can_target(Map.PLAYER, current_mouse_position):
			visible = false
