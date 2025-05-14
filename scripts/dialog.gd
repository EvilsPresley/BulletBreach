extends Control
class_name Dialog

var tween: Tween
var destroyed: bool = false

func _ready() -> void:
	global_position.y = -get_viewport().size.y
	tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(
		self, 
		"global_position:y", 
		0, 
		0.5)
	await tween.finished
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !destroyed:
			destroyed = true
			if tween and tween.is_running():
				tween.kill()
			tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(
				self, 
				"global_position:y", 
				-get_viewport().size.y, 
				0.5)
			await tween.finished
			queue_free()
