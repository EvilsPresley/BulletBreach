extends MobileObject
class_name Bullet
## Purely visual projectile (arrow, night bolt). Flies along a path then frees itself.

func fly(path_end: Vector2i, steps: int) -> void:
	await anim_move_to(path_end, 5.0 / maxf(1.0, steps))
	queue_free()
