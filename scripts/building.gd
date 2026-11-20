extends MapObject
class_name Building
## View of a building. `destroyed_scene` = ruins left behind (null = solid,
## e.g. churches: dashes cannot go through).

@export var destroyed_scene: PackedScene = null
