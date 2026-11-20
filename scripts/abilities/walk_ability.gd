extends MoveAbility
class_name WalkAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_walk_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.walk_to(tile)
