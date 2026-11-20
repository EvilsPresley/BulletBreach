extends FlightStepAbility
class_name BatFormAbility
## Turn into a bat for a few turns: most attacks miss, arrows fly over.

func simulate(board: Board, tile: Vector2i, log: Array) -> void:
	board.player.fly_duration = PlayerRewards.get_fly_duration()
	log.append({"type": "take_off"})
	super(board, tile, log)
