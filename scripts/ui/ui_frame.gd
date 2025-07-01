extends ColorRect
class_name UiFrame

@onready var color_rect: ColorRect = $MarginContainer/ColorRect

func _ready() -> void:
	self_modulate = Colors.WHITE
	color_rect.self_modulate = Colors.BLACK
