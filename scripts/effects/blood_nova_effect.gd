extends RewardEffect
## Blood Nova: shadow blast around the player.

func on_walk_after_special(player: Node, _direction: Vector2i, stacks: int) -> void:
	await player.trigger_blood_nova(stacks)
