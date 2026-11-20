extends RewardEffect
## Soul Siphon: drains civilians around the player after each move.

func on_move_end(player: Node, stacks: int) -> void:
	await player.harvest_blood_around(stacks)
