extends Resource
class_name EnemyBehaviour
## Rules of one kind of enemy, run on a Board (no nodes, no animation).
## Override what differs from the default "walk toward the player" enemy.
## To add an enemy: a behaviour script + an EnemyDefinition .tres + a view scene.

## Units can walk through this enemy (hidden land mines).
@export var walk_through: bool = false

## Could this enemy hit `to` if it stood on `from`?
func can_attack(_board: Board, _enemy: Unit, _from: Vector2i, _to: Vector2i) -> bool:
	return false

## Decide next turn's action (planned_action / planned_target / direction).
func plan(_board: Board, enemy: Unit) -> void:
	enemy.planned_action = Enums.plan.STAND

## Tiles hit when the planned action resolves. Must not use randomness.
func threatened_tiles(_board: Board, _enemy: Unit) -> Array[Vector2i]:
	return []

## Does a player standing on `observer` know about this threat?
func is_threat_known(_board: Board, _enemy: Unit, _observer: Vector2i) -> bool:
	return true

## Resolve the action planned last turn.
func execute(board: Board, enemy: Unit, log: Array) -> void:
	match enemy.planned_action:
		Enums.plan.SHOOT:
			shoot(board, enemy, log)
			if enemy.reload_time > 0:
				enemy.reload_counter = enemy.reload_time
		Enums.plan.RELOAD:
			enemy.reload_counter -= 1
		Enums.plan.EXPLODE:
			explode(board, enemy, log)

func shoot(_board: Board, _enemy: Unit, _log: Array) -> void:
	pass

func explode(_board: Board, _enemy: Unit, _log: Array) -> void:
	pass

## Default movement: one step toward the player, preferring a tile from
## which it can attack.
func move(board: Board, enemy: Unit, log: Array) -> void:
	var pos_dif: Vector2i = board.player.tile - enemy.tile
	if Grid.cardinals.has(pos_dif):
		return
	var toward: Vector2i = Grid.vector_to_cardinal(pos_dif)
	for dir: Vector2i in board.similar_directions(toward, false):
		if board.can_enemy_move(enemy.tile + dir) \
		and can_attack(board, enemy, enemy.tile + dir, board.player.tile):
			Rules.step_enemy(board, enemy, dir, log)
			return
	for dir: Vector2i in board.similar_directions(toward, false):
		if board.can_enemy_move(enemy.tile + dir):
			Rules.step_enemy(board, enemy, dir, log)
			return

## Called when something destroys this enemy. Return true if handled here.
func on_destroyed(_board: Board, _enemy: Unit, _log: Array) -> bool:
	return false

## Extra data the view needs to draw the plan (e.g. arrow path).
func plan_display_tiles(board: Board, enemy: Unit) -> Array[Vector2i]:
	return threatened_tiles(board, enemy)
