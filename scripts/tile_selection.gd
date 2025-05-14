extends TextureRect
class_name TileSelection

const blink_duration: float = 0.25

@onready var tile_map_layer: TileMapLayer = $"../../TileMapLayer"

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
	
	var current_mouse_position = tile_map_layer.local_to_map(get_global_mouse_position())
	if current_mouse_position != last_mouse_position:
		last_mouse_position = current_mouse_position
		position = tile_map_layer.map_to_local(current_mouse_position) - size * .5
	
	if Map.PLAYER:
		match Globals.move_mode:
			Enums.move_mode.WALK:
				if !Map.PLAYER.can_walk_to(current_mouse_position):
					visible = false
			Enums.move_mode.BLINK:
				if !Map.PLAYER.can_blink_to(current_mouse_position):
					visible = false
			Enums.move_mode.CHARGE:
				if !Map.PLAYER.can_charge_to(current_mouse_position):
					visible = false
			Enums.move_mode.TIME_TRAVEL:
				if !Map.PLAYER.can_time_travel_to(current_mouse_position):
					visible = false
			Enums.move_mode.JUMP:
				if !Map.PLAYER.can_jump_to(current_mouse_position):
					visible = false
			_:
				push_error("The move mode %s is not yet managed in TileSelection class" % Globals.move_mode)
