extends MoveAbility
class_name BatFormAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_fly_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.take_off()
	await player.fly_to(tile)
