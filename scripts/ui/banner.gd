extends Control
class_name Banner

@onready var LABEL: Label = $Label
@onready var MOUSE_ICON: TextureRect = $MouseClick
@onready var PORTRAIT: TextureRect = $Portrait
@onready var TIMER: Timer = $Timer

var click_counter: int = -10
var cleared: bool = false

const dialog_speed: float = 0.02
var target_label: String
var portrait_tween: Tween
var glow_duration: float = 0.5

func setup(
	label: String,
	portrait: Texture2D = preload("res://assets/portraits/vampire.png"),
) -> void:
	if not LABEL.is_node_ready():
		await LABEL.ready
	target_label = label
	LABEL.text = ""
	if not MOUSE_ICON.is_node_ready():
		await MOUSE_ICON.ready
	MOUSE_ICON.visible = false
	
	if not PORTRAIT.is_node_ready():
		await PORTRAIT.ready
	PORTRAIT.texture = portrait
	await _tween_in()
	start_label_timer()
	
func _tween_in() -> void:
	position.x -= size.x
	PORTRAIT.position.x = PORTRAIT.position.x + size.x * 2
	var tween_setup: Tween = create_tween().set_parallel(true)
	tween_setup.tween_property(
		self,
		"position:x",
		position.x + size.x,
		0.3
	)
	tween_setup.tween_property(
		PORTRAIT,
		"position:x",
		PORTRAIT.position.x - size.x * 2,
		0.3
	)
	await tween_setup.finished
	MOUSE_ICON.visible = true
	portrait_tween = create_tween().set_loops()
	portrait_tween.tween_property(
		PORTRAIT,
		"material:shader_parameter/outline_width",
		3,
		glow_duration
	)
	portrait_tween.tween_property(
		PORTRAIT,
		"material:shader_parameter/outline_width",
		1,
		glow_duration
	)

func start_label_timer() -> void:
	TIMER.start(dialog_speed)

func _on_timer_timeout() -> void:
	LABEL.text = target_label.substr(0, LABEL.text.length() + 1)
	if LABEL.text.length() < target_label.length():
		start_label_timer()

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
			if LABEL.text.length() >= target_label.length():
				clear()
			else:
				LABEL.text = target_label

func clear() -> void:
	cleared = true
	portrait_tween.kill()
	var tween_clear: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tween_clear.tween_property(
		self,
		"position:x",
		position.x + size.x,
		0.2
	)
	await tween_clear.finished
	queue_free()

func show_lose_banner() -> void:
	if not LABEL.is_node_ready():
		await LABEL.ready
	LABEL.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Globals.lives > 0:
		LABEL.text = "The light from the sun devours my flesh, I could not find a shelter on time...\n"
	else:
		LABEL.text = "I underestimated the human's forces, they were just too many to escape them...\n"
	LABEL.text += "You died on night %s, turn %s, and reached level %s. Try again!" % [Globals.night, Globals.turn, Globals.level]
	if not MOUSE_ICON.is_node_ready():
		await MOUSE_ICON.ready
	MOUSE_ICON.visible = false
	
	if not PORTRAIT.is_node_ready():
		await PORTRAIT.ready
	PORTRAIT.texture = preload("res://assets/portraits/game_over.png")
	await _tween_in()
