extends EnemyBehaviour
class_name TrackerBehaviour
## Drops a hidden land mine on its tile every few turns.

@export var mine: EnemyDefinition

func plan(board: Board, enemy: Unit) -> void:
	if enemy.reload_counter > 0:
		enemy.planned_action = Enums.plan.RELOAD
		enemy.planned_target = board.player.tile
	else:
		enemy.planned_action = Enums.plan.SHOOT

func shoot(board: Board, enemy: Unit, log: Array) -> void:
	Rules.spawn_enemy(board, mine, enemy.tile, log)
