extends EnemyBehaviour
class_name ArcherBehaviour
## Shoots a flaming arrow in a straight line; the arrow burns the first thing
## it hits (houses, civilians, other enemies: friendly fire).

func can_attack(board: Board, _enemy: Unit, from: Vector2i, to: Vector2i) -> bool:
	if board.is_under_fog(from):
		return false
	var pos_dif: Vector2i = to - from
	var aligned: bool = false
	for i: int in Board.SIGHT:
		for cardinal: Vector2i in Grid.cardinals:
			if pos_dif == (i + 1) * cardinal:
				aligned = true
	if !aligned:
		return false
	var dir: Vector2i = Grid.vector_to_cardinal(pos_dif)
	for i: int in Board.SIGHT:
		if to == from + (i + 1) * dir:
			return true
		if !board.can_arrow_move(from + (i + 1) * dir, false):
			return false
	return false

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

func threatened_tiles(board: Board, enemy: Unit) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if enemy.planned_action != Enums.plan.SHOOT:
		return tiles
	for i: int in Board.SIGHT:
		var tile: Vector2i = enemy.tile + (i + 1) * enemy.direction
		if can_attack(board, enemy, enemy.tile, tile):
			tiles.append(tile)
	return tiles

## The drawn path stops at the player, like the arrow will.
func plan_display_tiles(board: Board, enemy: Unit) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in threatened_tiles(board, enemy):
		tiles.append(tile)
		if tile == board.player.tile:
			break
	return tiles

func shoot(board: Board, enemy: Unit, log: Array) -> void:
	Rules.fire_projectiles(board, enemy.tile, [enemy.direction],
		Enums.destruction_type.FLAMES, "arrow", log, enemy.id)
	log.append({"type": "arrow_fired"})
