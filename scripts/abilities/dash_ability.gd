extends MoveAbility
class_name DashAbility
## Charge in a straight line, blowing up everything on the way.

func can_target(board: Board, tile: Vector2i) -> bool:
	var from: Vector2i = board.player.tile
	var move_dif: Vector2i = from - tile
	var dash_range: Array[int] = PlayerRewards.get_dash_range()
	if move_dif == Vector2i.ZERO:
		return false
	if (move_dif.x != 0 and !dash_range.has(absi(move_dif.x))) \
	or (move_dif.y != 0 and !dash_range.has(absi(move_dif.y))):
		return false
	var dir: Vector2i = Grid.vector_to_cardinal(-move_dif)
	if !Grid.cardinals.has(dir):
		return false
	for i: int in dash_range.max():
		var step: Vector2i = from + dir * (i + 1)
		if !board.can_move(step, 0):
			return false
		for building: Unit in board.find_at(step, Unit.Kind.BUILDING):
			if building.ruins_scene == null:  # churches and other solid buildings
				return false
	return true

func simulate(board: Board, tile: Vector2i, log: Array) -> void:
	var from: Vector2i = board.player.tile
	var dir: Vector2i = Grid.vector_to_cardinal(tile - from)
	log.append({"type": "parallel_begin"})
	for i: int in PlayerRewards.get_dash_range().max():
		var step: Vector2i = from + dir * (i + 1)
		Rules.destroy_tile(board, step, Enums.destruction_type.EXPLOSION, log)
		if step == tile:
			break
	log.append({"type": "parallel_end"})
	Rules.move_player(board, tile, "dash", log)
	if PlayerRewards.stacks(&"blood_dash") > 0:
		Rules.blood_nova(board, maxi(1, PlayerRewards.stacks(&"blood_nova")), log)
	Rules.move_end(board, log, true)
