extends Resource
class_name Reward

## Stable identifier (file name). Never derive logic from `title`.
@export var id: StringName
## Levels of the same upgrade share a group, e.g. night_bolt1..3 -> night_bolt.
@export var stack_group: StringName
@export var title: String
@export var type: Enums.reward_type
@export var texture: Texture2D = preload("res://assets/rewards/placeholder.png")
@export var description: String
@export var rarity: Enums.reward_rarity
@export var prerequisites: Array[Reward]
@export var tags: Array[Enums.tag]
## SKILL rewards: the move ability granted.
@export var ability: MoveAbility
## Triggered behaviour for upgrades (shared by all levels of a stack group).
@export var effect: RewardEffect

func get_tags_bbcode() -> String:
	var code: String = ""
	var prefix: String = ""
	if type == Enums.reward_type.SKILL:
		prefix = "[outline_size=4][outline_color=%s][color=%s]NEW ACTIVE SKILL[/color][/outline_color][/outline_size] " % [Colors.GOLD.to_html(), Colors.WHITE.to_html()]
	match rarity:
		Enums.reward_rarity.COMMON:
			code += "%s[color=%s]COMMON[/color]" % [prefix, Colors.COMMON.to_html()]
		Enums.reward_rarity.RARE:
			code += "%s[wave amp=10.0 freq=5.0][color=%s]RARE[/color][/wave]" % [prefix, Colors.RARE.to_html()]
		Enums.reward_rarity.EPIC:
			code += "%s[wave amp=15.0 freq=8.0][color=%s]EPIC[/color][/wave]" % [prefix, Colors.EPIC.to_html()]

	for tag: Enums.tag in tags:
		match tag:
			Enums.tag.SHADOW:
				code += " [pulse freq=0.5 color=%s ease=-2.0][color=%s]SHADOW[/color][/pulse]" % [Colors.BLACK.to_html(), Colors.PURPLE.to_html()]
			Enums.tag.ATTACK:
				code += " [shake rate=10.0 level=3][color=%s]ATTACK[/color][/shake]" % Colors.RED.to_html()
			Enums.tag.BLOOD:
				code += " [fade start=2 length=4][color=%s]BLOOD[/color][/fade]" % [Colors.RED.to_html()]
			Enums.tag.POISON:
				code += " [outline_size=5][outline_color=%s][color=%s]POISON[/color][/outline_color][/outline_size] " % [Colors.GREEN.to_html(), Colors.GOLD.to_html()]
	return code

func get_description() -> String:
	if type != Enums.reward_type.SKILL or ability == null:
		return description
	return description + "\n[center][color=%s]Cooldown:[/color] %s turns" % [Colors.BLUE.to_html(), ability.cooldown]
