extends TextureRect
class_name OrderHoverButton

func _on_mouse_entered() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		ennemy.show_order(ennemy.get_index() + 1)

func _on_mouse_exited() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		ennemy.hide_order()
