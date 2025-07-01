extends Control
class_name Footer

@onready var LABEL: RichTextLabel = $Label
@onready var MOUSE_ICON: TextureRect = $MouseClick
@onready var FRAME_LEFT: UiFrame = $PortraitFrame
@onready var PORTRAIT_LEFT: TextureRect = $PortraitFrame/TextureRect
@onready var TITLE: Label = $Title
@onready var TAGS: RichTextLabel = $RichTextLabel
@onready var FRAME_RIGHT: UiFrame = $PortraitFrameRight
@onready var PORTRAIT_RIGHT: TextureRect = $PortraitFrameRight/TextureRect

var click_counter: int = -10
var cleared: bool = false

func setup(
	reward: Reward,
	clickable: bool = false,
) -> void:
	if not TITLE.is_node_ready():
		await TITLE.ready
	TITLE.text = reward.title
	if not LABEL.is_node_ready():
		await LABEL.ready
	LABEL.text = reward.get_description()
	if not MOUSE_ICON.is_node_ready():
		await MOUSE_ICON.ready
	if !clickable:
		MOUSE_ICON.visible = false
	TAGS.text = reward.get_tags_bbcode()
	
	if not PORTRAIT_LEFT.is_node_ready():
		await PORTRAIT_LEFT.ready
	if not PORTRAIT_RIGHT.is_node_ready():
		await PORTRAIT_RIGHT.ready
	PORTRAIT_LEFT.texture = reward.texture
	PORTRAIT_LEFT.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	FRAME_RIGHT.visible = false
	
	position.y += size.y
	var tween_setup: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tween_setup.tween_property(
		self,
		"position:y",
		position.y - size.y,
		0.1
	)
	await tween_setup.finished

func _process(_delta) -> void:
	if MOUSE_ICON.visible:
		click_counter += 1
		if click_counter == 25:
			MOUSE_ICON.texture = preload("res://assets/ui/mouse2.png")
		if click_counter >= 50:
			MOUSE_ICON.texture = preload("res://assets/ui/mouse1.png")
			click_counter = 0

func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed and click_counter >= 0 and !cleared:
			clear()

func clear() -> void:
	cleared = true
	var tween_clear: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tween_clear.tween_property(
		self,
		"position:y",
		position.y + size.y,
		0.1
	)
	await tween_clear.finished
	queue_free()
