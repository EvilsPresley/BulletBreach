extends MoveAbility
class_name TimeTravelAbility
## Go back to a recent position; every enemy is confused and cancels its action.

func can_target(board: Board, tile: Vector2i) -> bool:
	return board.can_move(tile) and board.player.previous_positions.has(tile) \
	and !board.is_under_fog(tile)

func simulate(board: Board, tile: Vector2i, log: Array) -> void:
	log.append({"type": "cooldowns_reduced", "turns": PlayerRewards.stacks(&"haste")})
	Rules.move_player(board, tile, "time_travel", log)
	for enemy: Unit in board.alive_enemies():
		enemy.planned_action = Enums.plan.STAND
		log.append({"type": "confused", "id": enemy.id})
	board.invalidate()
	Rules.move_end(board, log, true)
