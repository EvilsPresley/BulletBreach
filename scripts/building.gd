extends MapObject
class_name Building

@export var destroyed_scene: PackedScene = null

func destroy() -> void:
	await Globals.wait_one_frame()
	if destructible:
		var ruins: Prop
		if destroyed_scene == null:
			ruins = preload("res://scenes/map/ruins.tscn").instantiate()
		else:
			ruins = destroyed_scene.instantiate()
		ruins.global_position = global_position
		Map.PROPS.add_child(ruins)
		queue_free()
