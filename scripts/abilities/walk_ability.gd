extends MoveAbility
class_name WalkAbility

func can_target(board: Board, tile: Vector2i) -> bool:
	var from: Vector2i = board.player.tile
	if Grid.distance(from, tile) != 1:
		return false
	# Diagonal steps are blocked when both sides are blocked.
	var d: Vector2i = tile - from
	if (d == Grid.N and !board.can_move(tile + Grid.SE) and !board.can_move(tile + Grid.SW)) \
	or (d == Grid.S and !board.can_move(tile + Grid.NE) and !board.can_move(tile + Grid.NW)) \
	or (d == Grid.E and !board.can_move(tile + Grid.NW) and !board.can_move(tile + Grid.SW)) \
	or (d == Grid.W and !board.can_move(tile + Grid.NE) and !board.can_move(tile + Grid.SE)):
		return false
	return board.can_move(tile)

func simulate(board: Board, tile: Vector2i, log: Array) -> void:
	board.player.direction = tile - board.player.tile
	Rules.move_player(board, tile, "walk", log)
	Rules.move_end(board, log, false)
