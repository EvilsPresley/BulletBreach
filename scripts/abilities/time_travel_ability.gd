extends MoveAbility
class_name TimeTravelAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_time_travel_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.time_travel_to(tile)
