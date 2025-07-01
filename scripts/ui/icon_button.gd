extends Button
class_name IconButton

@onready var ICON: TextureRect = $Icon
@onready var FRAME: TextureRect = $Frame
@onready var RARITY: ColorRect = $Rarity

func setup(
icon_: Texture2D,
rarity: Enums.reward_rarity = Enums.reward_rarity.UNDEFINED,
_title: String = "",
_description: String = "",
) -> void:
	ICON.texture = icon_
	FRAME.self_modulate = Colors.GOLD
	match rarity:
		Enums.reward_rarity.COMMON:
			RARITY.self_modulate = Colors.COMMON
		Enums.reward_rarity.RARE:
			RARITY.self_modulate = Colors.RARE
		Enums.reward_rarity.EPIC:
			RARITY.self_modulate = Colors.EPIC
		_:
			RARITY.self_modulate = Colors.UNDEFINED
