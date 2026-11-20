extends Resource
class_name EnemyDefinition
## One kind of enemy. Add a new enemy by creating its scene + one of these,
## then listing it in a SpawnTable.

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
