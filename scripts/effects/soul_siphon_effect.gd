extends RewardEffect
## Soul Siphon: drains civilians around the player after each move.

func on_move_end(board: Board, stacks: int, events: Array) -> void:
	var dirs: Array[Vector2i] = []
	match stacks:
		0:
			return
		1:
			dirs = [Grid.NE, Grid.SE, Grid.NW, Grid.SW]
		2:
			dirs = Grid.cardinals.duplicate()
		_:
			dirs = Grid.cardinals.duplicate()
			dirs.append_array([Grid.NE * 2, Grid.SE * 2, Grid.NW * 2, Grid.SW * 2])
	for dir: Vector2i in dirs:
		Rules.harvest_at(board, board.player.tile + dir, events)
