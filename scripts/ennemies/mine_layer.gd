extends Ennemy
class_name MineLayer
## Tracker view: shows when a mine is about to be dropped.

func _display_shoot_plan(_plan: Dictionary) -> void:
	var exclamation_icon := TextureRect.new()
	exclamation_icon.texture = preload("res://assets/ennemies/exclamation_red.png")
	PLAN.add_child(exclamation_icon)
	exclamation_icon.scale = Vector2.ONE * 2
	exclamation_icon.position = -exclamation_icon.size + Vector2(0, -8)
