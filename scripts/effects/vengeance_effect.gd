extends RewardEffect
## Vengeance: throws poison behind the player.

func on_walk_after_special(player: Node, direction: Vector2i, stacks: int) -> void:
	await player.trigger_vengeance(direction, stacks)
