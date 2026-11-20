extends Ennemy
class_name Tank
## Archer view: draws the arrow path.

func _display_shoot_plan(plan: Dictionary) -> void:
	var tiles: Array = plan.tiles
	for i: int in tiles.size():
		var target_tile: Vector2i = tiles[i]
		var previous: Vector2i = plan.from + i * plan.direction
		for pos: Vector2 in [Map.get_global_mid_position(previous, target_tile), Map.get_global_position(target_tile)]:
			var icon := TextureRect.new()
			icon.texture = preload("res://assets/ennemies/bullet_path.png")
			icon.self_modulate = Colors.RED
			PLAN.add_child(icon)
			icon.global_position = pos - icon.size / 2
