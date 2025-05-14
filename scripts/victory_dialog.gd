extends Dialog
class_name VictoryDialog

@onready var title: RichTextLabel = $Title
@onready var intro: RichTextLabel = $Intro
@onready var score_labels: RichTextLabel = $ScoreLabels
@onready var score_values: RichTextLabel = $ScoreValues

func _ready() -> void:
	if Globals.rescued_civilians == Globals.alive_civilians:
		title.text = "[center][font_size=32][wave]Flawless Victory!"
		intro.text = """[center][font_size=24]You saved all the civilians from the conflict.
Your name will remain forever in history books."""
		score_labels.text = """[left][font_size=24]Score:
Rescued - [wave]PERFECT![/wave]:
Time elapsed:
Hull status:
Total:"""

	var rescued_score: int = Globals.rescued_civilians * 1000
	var time_score: int = floor(250000.0 / Globals.turn)
	var hull_damage: int = Globals.lives * 3000
	var total: int = rescued_score + time_score + hull_damage
	score_values.text = """[right][font_size=24]
%s
%s
%s
%s""" % [rescued_score, time_score, hull_damage, total]
