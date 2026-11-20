extends CanvasLayer
class_name Ui

@onready var XP_BAR: ProgressBar = $XpBar/ColorRect/ColorRect/ProgressBar

signal level_up

func _ready() -> void:
	RunState.xp_changed.connect(_on_xp_changed)
	RunState.leveled_up.connect(func(_level): level_up.emit())

func _on_xp_changed(xp: float, xp_to_next: int) -> void:
	XP_BAR.max_value = xp_to_next
	XP_BAR.value = xp
