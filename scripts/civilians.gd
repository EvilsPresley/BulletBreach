extends MobileObject
class_name Civilians

func destroy() -> void:
	var tween: Tween = create_tween()
	tween = create_tween()
	tween.tween_property(
		self, 
		"modulate", 
		Color.DARK_RED, 
		0.2)
	await tween.finished
	Globals.alive_civilians -= 1
	queue_free()
