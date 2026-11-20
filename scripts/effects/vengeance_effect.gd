extends RewardEffect
## Vengeance: throws poison two tiles behind the player (wider with stacks).

func on_walk_after_special(board: Board, direction: Vector2i, stacks: int, log: Array) -> void:
	if stacks <= 0:
		return
	var back: Vector2i = Grid.opposite(direction)
	var center: Vector2i = board.player.tile + back * 2
	var targets: Array[Vector2i] = [center]
	if stacks >= 2:
		var sides: Array[Vector2i] = Grid.side_directions(back, false)
		targets.append_array([center + sides[0], center + sides[1]])
		if stacks >= 3:
			targets.append_array([center + sides[0] * 2, center + sides[1] * 2])
	log.append({"type": "lob", "origin": board.player.tile,
		"tiles": targets.filter(func(t: Vector2i) -> bool: return board.is_ground(t))})
	for tile: Vector2i in targets:
		Rules.add_poison(board, tile, log)
