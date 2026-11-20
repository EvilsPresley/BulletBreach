extends Resource
class_name MoveAbility
## A way for the player to move during their turn (walk, teleport, dash...).
## To add a new active skill: create a script extending MoveAbility, a .tres
## using it, and reference that .tres from a SKILL Reward. No other file changes.
##
## `player` is typed as Node on purpose: referencing the Player class here would
## create a script load cycle (Player preloads scenes that load this script).

@export var id: StringName
## Turns before the skill can be used again (0 = always available).
@export var cooldown: int = 0
## Oracle shows reachable tiles as safe (e.g. bat form is immune to most attacks).
@export var oracle_ignores_threats: bool = false

## Can the player use this ability to reach `tile` right now?
func can_target(_player: Node, _tile: Vector2i) -> bool:
	return false

## Performs the move. Called after the shared move start (blood harvest, cooldowns).
func execute(_player: Node, _tile: Vector2i) -> void:
	pass
