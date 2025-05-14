extends Ennemy
class_name Kamikaze

func _explode() -> void:
	var fire_icons: Array[TextureRect]
	for cardinal: Vector2i in Map.cardinals:
		if Map.TILEMAP.get_cell_source_id(get_map_position() + cardinal) >= 0:
			var fire_icon := TextureRect.new()
			fire_icon.texture = preload("res://assets/fire.png")
			add_child(fire_icon)
			fire_icons.append(fire_icon)
			fire_icon.global_position = Map.get_global_position(get_map_position() + cardinal)
			fire_icon.global_position -= fire_icon.size * .5
			Map.destroy_tile(get_map_position() + cardinal)
	await Globals.wait(0.3)
	for icon in fire_icons:
		icon.queue_free()
	destroy(false)

func plan() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	planned_action = Enums.plan.STAND
	planned_target = Vector2i.ZERO
	if Map.cardinals.find(pos_dif) >= 0:
		planned_action = Enums.plan.EXPLODE
		planned_target = get_map_position()
	else:
		planned_action = Enums.plan.STAND

func destroy(explode: bool = true) -> void:
	super()
	if explode:
		await _explode()

func _move() -> void:
	var pos_dif: Vector2i = Map.PLAYER.get_map_position() - get_map_position()
	for dir: Vector2i in Map.get_similar_directions(Map.vector_to_cardinal(pos_dif)):
		if Map.can_ennemy_move(get_map_position() + dir):
			_turn(dir)
			await move_one_tile()
			return
