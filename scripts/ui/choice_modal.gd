extends Control
class_name ChoiceModal

@onready var CONTAINER: HBoxContainer = $ChoicesContainer/HBoxContainer
@onready var TITLE: Label = $Title
@onready var OK_BUTTON: UiFrame = $OKContainer/Button/OKButton

var selected: int = -1
var choices: Array[Reward] = []

signal reward_selected
signal reward_choosen

func setup(title: String, choices_: Array[Reward]) -> void:
	if not TITLE.is_node_ready():
		await TITLE.ready
	TITLE.text = title
	if not CONTAINER.is_node_ready():
		await CONTAINER.ready
	for child: Node in CONTAINER.get_children():
		child.queue_free()
	
	choices = choices_.duplicate()
	for choice: Reward in choices:
		var icon: IconButton = preload("res://scenes/ui/icon_button.tscn").instantiate()
		CONTAINER.add_child(icon)
		icon.setup(choice.texture, choice.rarity, choice.title, choice.description)
		icon.connect("pressed", reward_clicked.bind(choice))
	size.x = 384 + 64 * (choices.size() - 3)
	call_deferred("_resize_ok_button")
	OK_BUTTON.modulate = Colors.GRAY

func reward_clicked(reward: Reward) -> void:
	if choices.find(reward) != selected:
		selected = choices.find(reward)
		OK_BUTTON.modulate = Color.WHITE
		reward_selected.emit(reward)

func _on_button_pressed() -> void:
	if selected >= 0:
		reward_choosen.emit(choices[selected])
		queue_free()

func _resize_ok_button() -> void:
	OK_BUTTON.size.x = size.x - 8

func clear() -> void:
	await Globals.wait_one_frame()
	queue_free()
