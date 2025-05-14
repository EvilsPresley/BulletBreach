extends Control
class_name PassiveUi

@onready var score: RichTextLabel = $Score
@onready var turn: Label = $Turn
@onready var heart_1: TextureRect = $Heart1
@onready var heart_2: TextureRect = $Heart2
@onready var heart_3: TextureRect = $Heart3

func _process(_delta: float) -> void:
	var rescued_color: String = "RED"
	var total_color: String = "GREEN"
	if Globals.rescued_civilians > 0:
		rescued_color = "CYAN"
	if Globals.alive_civilians < Globals.total_civilians:
		total_color = "ORANGE"
	score.text = "Rescued: [color=%s]%s[/color]/[color=%s]%s" % [
		rescued_color,
		Globals.rescued_civilians,
		total_color,
		Globals.alive_civilians]
	turn.text = "Turn: %s" % Globals.turn
	match Globals.lives:
		1:
			heart_1.modulate = Color.WHITE
			heart_2.modulate = Color.DIM_GRAY
			heart_3.modulate = Color.DIM_GRAY
		2:
			heart_1.modulate = Color.WHITE
			heart_2.modulate = Color.WHITE
			heart_3.modulate = Color.DIM_GRAY
		3:
			heart_1.modulate = Color.WHITE
			heart_2.modulate = Color.WHITE
			heart_3.modulate = Color.WHITE
