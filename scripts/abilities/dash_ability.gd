extends MoveAbility
class_name DashAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_dash_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.dash_to(tile)
