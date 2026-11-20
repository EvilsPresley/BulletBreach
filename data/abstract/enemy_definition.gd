extends Resource
class_name EnemyDefinition
## One kind of enemy: its rules (behaviour), stats and the scene that shows it.
## Add a new enemy: a behaviour script, a view scene, one of these .tres, then
## list it in a SpawnTable.

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var behaviour: EnemyBehaviour
## Turns spent reloading after an attack.
@export var reload_time: int = 0
## Tutorial banner shown the first time this enemy appears.
@export var intro_tuto: Enums.tuto = Enums.tuto.NONE
