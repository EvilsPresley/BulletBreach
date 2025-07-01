extends TextureRect
class_name PortalScript

const sprite_queue: Array[Texture] = [
	preload("res://assets/player/portal_1.png"),
	preload("res://assets/player/portal_2.png"),
	preload("res://assets/player/portal_3.png"),
	preload("res://assets/player/portal_4.png"),
]
const sprite_speed: float = .4

var sprite_cd: float = .0
var sprite_index: int = 0

func _process(delta: float) -> void:
	sprite_cd += delta
	if sprite_cd > sprite_speed:
		sprite_cd = .0
		sprite_index += 1
		if sprite_index >= sprite_queue.size():
			sprite_index = 0
		texture = sprite_queue[sprite_index]
