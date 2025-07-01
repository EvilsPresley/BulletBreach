extends Node

func tween_curve_path(
	object: Control,
	target: Vector2,
	duration: float,
	y_offset: float = 80.0,
) -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_quadratic_bezier.bind(
		object.global_position,
		(object.global_position + target) / 2 + Vector2(0, -y_offset),
		target,
		object
	), 0.0, 1.0, duration)
	await tween.finished

func _quadratic_bezier(
	t: float,
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	object: Control) -> void:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	object.global_position = q0.lerp(q1, t)
