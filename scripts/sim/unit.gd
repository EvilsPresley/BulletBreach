extends RefCounted
class_name Unit
## Pure-data state of one thing on the board. Views (MapObject nodes) mirror it.

## Order matters: units on the same tile are resolved in this order.
enum Kind { PROP, BUILDING, CIVILIAN, ENEMY, PLAYER }

var id: int = 0
var kind: Kind = Kind.PROP
var tile: Vector2i = Vector2i.ZERO
var direction: Vector2i = Vector2i.ZERO
var destructible: bool = true
var alive: bool = true
## Scene the presenter instantiates to show this unit.
var scene: PackedScene

# --- Enemies
var definition: EnemyDefinition
var behaviour: EnemyBehaviour
## Hidden enemies (left in the fog) neither act nor plan.
var visible: bool = true
var reload_time: int = 0
var reload_counter: int = 0
var planned_action: Enums.plan = Enums.plan.STAND
var planned_target: Vector2i = Vector2i.ZERO
var exploding: bool = false

# --- Buildings
## Scene of the ruins left behind (null = default ruins).
var ruins_scene: PackedScene
## A civilian flees when this building is destroyed.
var shelters_civilian: bool = false

# --- Props
var is_coffin: bool = false
var is_portal: bool = false

# --- Player
var fly_duration: int = 0
var previous_positions: Array[Vector2i] = []
var was_special_move: bool = false
var sanguine_pool_use: int = 0

func is_walk_through() -> bool:
	return behaviour != null and behaviour.walk_through

func clone() -> Unit:
	var copy := Unit.new()
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = get(property.name)
			copy.set(property.name, value.duplicate() if value is Array else value)
	return copy
