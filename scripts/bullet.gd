extends MobileObject
class_name Bullet

var shoot_range: int = 0

func _move() -> void:
	for i in shoot_range:
		await move_one_tile()
		if is_queued_for_deletion():
			return
	destroy()

func move_one_tile() -> void:
	await super()
	var bullet_hit: bool = await Map.destroy_tile(get_map_position(), true)
	if bullet_hit:
		destroy()

func destroy() -> void:
	if move_tween:
		move_tween.kill()
	queue_free()
