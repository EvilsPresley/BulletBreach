extends RewardEffect
## Blood Nova: shadow blast around the player.

func on_walk_after_special(board: Board, _direction: Vector2i, stacks: int, log: Array) -> void:
	Rules.blood_nova(board, stacks, log)
