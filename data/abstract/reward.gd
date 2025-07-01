extends Resource
class_name Reward

@export var title: String
@export var type: Enums.reward_type
@export var texture: Texture2D = preload("res://assets/rewards/placeholder.png")
@export var description: String
@export var rarity: Enums.reward_rarity
@export var prerequisites: Array[Reward]
@export var tags: Array[Enums.tag]

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
	if type != Enums.reward_type.SKILL:
		return description
	match title:
		"Bat Form":
			return description + "\n[center][color=%s]Cooldown:[/color] %s turns" % [Colors.BLUE.to_html(), Globals.bat_cooldown]
		"Stallion Dash":
			return description + "\n[center][color=%s]Cooldown:[/color] %s turns" % [Colors.BLUE.to_html(), Globals.dash_cooldown]
		"Teleportation":
			return description + "\n[center][color=%s]Cooldown:[/color] %s turns" % [Colors.BLUE.to_html(), Globals.teleport_cooldown]
		"Time Travel":
			return description + "\n[center][color=%s]Cooldown:[/color] %s turns" % [Colors.BLUE.to_html(), Globals.time_travel_cooldown]
		"Werewolf Assault":
			return description + "\n[center][color=%s]Cooldown:[/color] %s turns" % [Colors.BLUE.to_html(), Globals.werewolf_cooldown]
		_:
			push_error("No cooldown mapped to %s" % title)
			return description
