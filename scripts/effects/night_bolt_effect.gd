extends RewardEffect
## Night Bolt: shadow bolts fired forward (more directions with more stacks).

func on_walk_after_special(player: Node, direction: Vector2i, stacks: int) -> void:
	await player.trigger_night_bolt(direction, stacks)
