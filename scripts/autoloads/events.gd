extends Node
## Global signal bus. Gameplay code emits here instead of reaching through the
## scene tree (get_parent().get_parent()...), so nodes can be moved freely.
## Keep this file free of class_name types (Ennemy, Player...): it is loaded
## first, and typed references here would create script load cycles.

## An enemy arrow was shot (used by the friendly-fire tutorial).
signal arrow_fired
## The player started a move. `is_flying` is true while in bat form.
## `ability` is the selected MoveAbility, or null for a plain walk.
signal player_move_started(ability: Resource, is_flying: bool)
## Reduce every active skill cooldown by `turns` (Haste upgrade).
signal cooldowns_reduced(turns: int)
## An enemy was spawned on the map and finished its first plan.
signal enemy_spawned(enemy: Node)
