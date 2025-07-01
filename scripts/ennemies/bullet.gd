extends MobileObject
class_name Bullet

var attack_type: Enums.destruction_type = Enums.destruction_type.FLAMES

func _move() -> void:
	for i in Globals.sight * 2:
		await move_one_tile()
		if is_queued_for_deletion():
			return
	destroy()

func move_one_tile(speed_up_factor: float = 5.0) -> void:
	var bullet_continues: bool = Map.can_arrow_move(get_map_position() + direction)
	await super(speed_up_factor)
	if !bullet_continues:
		await Map.destroy_tile(get_map_position(), attack_type)
		destroy()

func destroy() -> void:
	if move_tween:
		move_tween.kill()
	queue_free()
