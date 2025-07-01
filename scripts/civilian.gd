extends MapObject
class_name Civilian

func destroy() -> void:
	await Globals.wait(0.0)
	super()
