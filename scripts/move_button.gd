extends TextureRect
class_name  MoveButton

@onready var RELOAD: ProgressBar = $Reload
@onready var HIGHLIGHT: TextureRect = $Highlight
@onready var SELECTION: TextureRect = $Selection

@export var move_mode: Enums.move_mode = Enums.move_mode.WALK
@export var reload_time: int = 0

func _ready() -> void:
	set_reload_time(reload_time)
	RELOAD.value = 0

func _process(_delta: float) -> void:
	if Globals.move_mode == move_mode:
		SELECTION.visible = true
	else:
		SELECTION.visible = false

func set_reload_time(max_value: int) -> void:
	if max_value > 0:
		RELOAD.max_value = max_value
	else:
		RELOAD.max_value = 1
		RELOAD.visible = false

func set_max_reload() -> void:
	RELOAD.value = reload_time
	if RELOAD.value > 0:
		self_modulate.a = 0.5

func get_reload() -> int:
	if RELOAD.visible:
		return floor(RELOAD.value)
	else:
		return 0

func reload_one() -> void:
	if RELOAD.visible:
		if get_reload() > 0:
			RELOAD.value -= 1
			if get_reload() <= 0:
				self_modulate.a = 1

func _on_mouse_entered() -> void:
	HIGHLIGHT.visible = true

func _on_mouse_exited() -> void:
	HIGHLIGHT.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Globals.move_mode == move_mode or get_reload() > 0:
				Globals.move_mode = Enums.move_mode.WALK
			else:
				Globals.move_mode = move_mode
