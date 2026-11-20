extends Resource
class_name RewardEffect
## Behaviour attached to an upgrade. All levels of an upgrade (e.g. Night Bolt
## 1/2/3) share the same effect; `stacks` tells how many levels are owned.
## To add a triggered upgrade: extend this, override the hooks you need, create
## a .tres and reference it from the Reward(s). Player code does not change.
## (`player` is a Node to avoid script load cycles with the Player class.)

## Effects with a lower priority run first when several trigger together.
@export var priority: int = 0

## First walk after a special move (skill), in the walking direction.
func on_walk_after_special(_player: Node, _direction: Vector2i, _stacks: int) -> void:
	pass

## End of every player move, before the enemies act.
func on_move_end(_player: Node, _stacks: int) -> void:
	pass
