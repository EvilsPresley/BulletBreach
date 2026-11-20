extends MoveAbility
## Used automatically while the player is in bat form (one tile per turn).
class_name FlightStepAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_fly_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.fly_to(tile)
