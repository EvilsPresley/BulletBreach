extends MoveAbility
class_name FlightStepAbility
## Used automatically while the player is in bat form (one tile per turn).
## Leaves poison behind (more with Poison Shells).

func can_target(board: Board, tile: Vector2i) -> bool:
	return Grid.distance(board.player.tile, tile) == 1 and board.can_move(tile)

func simulate(board: Board, tile: Vector2i, events: Array) -> void:
	var player: Unit = board.player
	player.direction = tile - player.tile
	var previous: Vector2i = player.tile
	Rules.move_player(board, tile, "fly", events)
	var candidates: Array[Vector2i] = Grid.cardinals.duplicate()
	candidates.erase(Grid.opposite(player.direction))
	candidates.assign(board.shuffled(candidates))
	for i: int in PlayerRewards.stacks(&"poison_shells") * 2:
		Rules.add_poison(board, player.tile + candidates[i], events)
	Rules.add_poison(board, previous, events)
	Rules.move_end(board, events, true)
