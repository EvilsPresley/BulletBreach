extends EnemyBehaviour
class_name MineBehaviour
## Hidden mine: explodes when the player ends a turn on it. Only known when
## the player stands next to it.

func _init() -> void:
	walk_through = true

func threatened_tiles(_board: Board, enemy: Unit) -> Array[Vector2i]:
	return [enemy.tile]

func is_threat_known(_board: Board, enemy: Unit, observer: Vector2i) -> bool:
	return Grid.distance(observer, enemy.tile) <= 1

func move(board: Board, enemy: Unit, log: Array) -> void:
	if board.player.tile == enemy.tile:
		Rules.destroy_tile(board, enemy.tile, Enums.destruction_type.EXPLOSION, log)
