extends Ennemy
class_name Kamikaze

var exploding: bool = false

func _explode() -> void:
	for cardinal: Vector2i in Map.cardinals:
		if Map.TILEMAP.get_cell_source_id(get_map_position() + cardinal) == 0:
			Map.destroy_tile(get_map_position() + cardinal, Enums.destruction_type.EXPLOSION)
	await Globals.wait(Globals.get_anim_duration())
	await destroy(false)

func plan() -> void:
	planned_target = Vector2i.ZERO
	if _can_attack(get_map_position(), Map.PLAYER.get_map_position()):
		planned_action = Enums.plan.EXPLODE
		planned_target = get_map_position()
	else:
		planned_action = Enums.plan.STAND

func destroy(explode: bool = true) -> void:
	if explode:
		exploding = true
		await _explode()
	super(false)

func _move() -> void:
	if !exploding:
		await super()

func _can_attack(from: Vector2i, to: Vector2i) -> bool:
	return Map.get_orthogonal_distance(from, to) <= 1
