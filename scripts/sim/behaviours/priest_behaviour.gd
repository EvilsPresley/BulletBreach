extends EnemyBehaviour
class_name PriestBehaviour
## Calls holy light on the player's tile and the two tiles beside it.
## Needs no line of sight, and also hits a flying player.

func can_attack(board: Board, _enemy: Unit, from: Vector2i, to: Vector2i) -> bool:
	var d: Vector2i = to - from
	return (d.x == 0 or d.y == 0 or d.x == d.y or d.x == -d.y) and !board.is_under_fog(from)

func plan(board: Board, enemy: Unit) -> void:
	enemy.planned_target = Vector2i.ZERO
	if enemy.reload_counter > 0:
		enemy.planned_action = Enums.plan.RELOAD
		enemy.planned_target = board.player.tile
	elif can_attack(board, enemy, enemy.tile, board.player.tile):
		enemy.direction = Grid.vector_to_cardinal(board.player.tile - enemy.tile)
		enemy.planned_action = Enums.plan.SHOOT
		enemy.planned_target = board.player.tile
	else:
		enemy.planned_action = Enums.plan.STAND

func targets(enemy: Unit) -> Array[Vector2i]:
	var dir: Vector2i = Grid.vector_to_cardinal(enemy.planned_target - enemy.tile)
	var sides: Array[Vector2i] = Grid.side_directions(dir, true)
	return [enemy.planned_target, enemy.planned_target + sides[0], enemy.planned_target + sides[1]]

func threatened_tiles(_board: Board, enemy: Unit) -> Array[Vector2i]:
	if enemy.planned_action != Enums.plan.SHOOT:
		return []
	return targets(enemy)

func shoot(board: Board, enemy: Unit, log: Array) -> void:
	for tile: Vector2i in targets(enemy):
		Rules.destroy_tile(board, tile, Enums.destruction_type.LIGHT, log)
