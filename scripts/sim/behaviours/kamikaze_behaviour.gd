extends EnemyBehaviour
class_name KamikazeBehaviour
## Explodes on the 8 surrounding tiles when next to the player, or when killed.

func can_attack(_board: Board, _enemy: Unit, from: Vector2i, to: Vector2i) -> bool:
	return Grid.distance(from, to) <= 1

func plan(board: Board, enemy: Unit) -> void:
	enemy.planned_target = Vector2i.ZERO
	if can_attack(board, enemy, enemy.tile, board.player.tile):
		enemy.planned_action = Enums.plan.EXPLODE
		enemy.planned_target = enemy.tile
	else:
		enemy.planned_action = Enums.plan.STAND

func threatened_tiles(_board: Board, enemy: Unit) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if enemy.planned_action == Enums.plan.EXPLODE:
		for cardinal: Vector2i in Grid.cardinals:
			tiles.append(enemy.tile + cardinal)
	return tiles

func explode(board: Board, enemy: Unit, log: Array) -> void:
	if enemy.exploding:
		return
	enemy.exploding = true
	log.append({"type": "parallel_begin"})
	for cardinal: Vector2i in Grid.cardinals:
		Rules.destroy_tile(board, enemy.tile + cardinal, Enums.destruction_type.EXPLOSION, log)
	log.append({"type": "parallel_end"})
	Rules.kill_enemy(board, enemy, log, false)

func move(board: Board, enemy: Unit, log: Array) -> void:
	if !enemy.exploding:
		super(board, enemy, log)

## Killed by anything else: it still blows up (no blood for Soul Spores).
func on_destroyed(board: Board, enemy: Unit, log: Array) -> bool:
	if !enemy.exploding:
		explode(board, enemy, log)
	else:
		Rules.kill_enemy(board, enemy, log, false)
	return true
