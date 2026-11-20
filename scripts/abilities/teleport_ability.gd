extends MoveAbility
class_name TeleportAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_teleport_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.teleport_to(tile)
