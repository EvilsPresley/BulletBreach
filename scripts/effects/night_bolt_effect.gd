extends RewardEffect
## Night Bolt: shadow bolts fired forward (3 directions at level 2, 5 at level 3).

func on_walk_after_special(board: Board, direction: Vector2i, stacks: int, log: Array) -> void:
	if stacks <= 0:
		return
	var dir: Vector2i = Grid.vector_to_cardinal(direction)
	var directions: Array[Vector2i] = [dir]
	if stacks >= 2:
		directions.append_array(Grid.side_directions(dir, false))
	if stacks >= 3:
		directions.append_array(Grid.side_directions(dir, true))
	Rules.fire_projectiles(board, board.player.tile, directions,
		Enums.destruction_type.SHADOW, "night_bolt", log, board.player.id)
