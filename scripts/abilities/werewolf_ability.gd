extends MoveAbility
class_name WerewolfAbility

func can_target(player: Node, tile: Vector2i) -> bool:
	return player.can_werewolf_to(tile)

func execute(player: Node, tile: Vector2i) -> void:
	await player.werewolf_to(tile)
