extends Ennemy
class_name Artillery
## Priest view: draws the holy light target tiles and aiming lines.

var _aim_targets: Array = []

func _display_shoot_plan(plan: Dictionary) -> void:
	var shoot_direction: Vector2i = Map.vector_to_cardinal(plan.tiles[0] - plan.from)
	var launch_icon := TextureRect.new()
	var land_icon_texture: Texture2D
	match shoot_direction:
		Map.N, Map.S:
			launch_icon.texture = preload("res://assets/arrows/arrow_N.png")
			land_icon_texture = preload("res://assets/arrows/arrow_S.png")
		Map.E, Map.SE, Map.NE:
			launch_icon.texture = preload("res://assets/arrows/arrow_NE.png")
			land_icon_texture = preload("res://assets/arrows/arrow_SE.png")
		_:
			launch_icon.texture = preload("res://assets/arrows/arrow_NE.png")
			land_icon_texture = preload("res://assets/arrows/arrow_SW.png")
			launch_icon.flip_h = true
	PLAN.add_child(launch_icon)
	launch_icon.global_position = Map.get_global_mid_position(plan.from, plan.from + Map.N)
	launch_icon.position -= launch_icon.size * .5
	for target: Vector2i in plan.tiles:
		var land_icon := TextureRect.new()
		land_icon.texture = land_icon_texture
		PLAN.add_child(land_icon)
		land_icon.global_position = Map.get_global_mid_position(target, target + Map.N)
		land_icon.position -= land_icon.size * .5
		land_icon.z_index = 1
	_aim_targets = plan.tiles
	queue_redraw()

func _draw() -> void:
	if _aim_targets.is_empty():
		return
	var origin: Vector2 = Map.get_global_mid_position(get_map_position(), get_map_position() + Map.N) - global_position
	for target: Vector2i in _aim_targets:
		draw_line(origin, Map.get_global_mid_position(target, target + Map.N) - global_position, Color.RED, 2)

func clear_plan() -> void:
	super()
	_aim_targets = []
	queue_redraw()
