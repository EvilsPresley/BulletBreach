extends Control
class_name YesNoModal

@onready var LABEL: Label = $Label

signal yes_clicked

func _on_yes_button_pressed() -> void:
	yes_clicked.emit()
	queue_free()

func _on_no_button_pressed() -> void:
	queue_free()

func set_text(text: String) -> void:
	if !LABEL.is_node_ready():
		await LABEL.ready
	LABEL.text = text
