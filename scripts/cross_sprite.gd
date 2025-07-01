extends TextureRect
class_name CrossSprite

func _ready() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(
		self,
		"modulate:a",
		0.6,
		Globals.get_anim_duration() * 2
	)
	tween.tween_property(
		self,
		"modulate:a",
		0.1,
		Globals.get_anim_duration() * 2
	)
