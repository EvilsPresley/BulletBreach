extends Control
class_name MoveButtons

func apply_move() -> void:
	for button: MoveButton in get_children():
		if button.move_mode == Globals.move_mode:
			button.set_max_reload()
		else:
			button.reload_one()
	Globals.move_mode = Enums.move_mode.WALK
