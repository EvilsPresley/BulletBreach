extends Resource
class_name SpawnRule
## "Spawn `enemy` while fewer than `max_alive` of them are on the map."

@export var enemy: EnemyDefinition
@export var max_alive: int = 1
