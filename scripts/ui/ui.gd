extends CanvasLayer
class_name Ui

@onready var XP_BAR: ProgressBar = $XpBar/ColorRect/ColorRect/ProgressBar

signal level_up

func _on_player_blood_harvested() -> void:
	XP_BAR.value += 1 + PlayerRewards.stacks(&"type_o_negative") * 0.35
	if XP_BAR.value >= XP_BAR.max_value:
		Globals.level += 1
		XP_BAR.value = 0
		XP_BAR.max_value = ceil(XP_BAR.max_value * 1.2)
		level_up.emit()
