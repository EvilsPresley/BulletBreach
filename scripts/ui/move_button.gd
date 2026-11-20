extends TextureRect
class_name  MoveButton

@onready var RELOAD: TextureProgressBar = $Reload
@onready var HIGHLIGHT: TextureRect = $Highlight
@onready var SELECTION: TextureRect = $Selection

## Ability selected by this button (null = walk).
@export var ability: MoveAbility
@export var reload_time: int = 0

func _ready() -> void:
	set_reload_time(reload_time)
	RELOAD.value = 0

func _process(_delta: float) -> void:
	if Globals.selected_ability == ability:
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
		_disable()

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
				_enable()

func _on_mouse_entered() -> void:
	HIGHLIGHT.visible = true

func _on_mouse_exited() -> void:
	HIGHLIGHT.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Globals.selected_ability == ability or self_modulate.a < 1:
				Globals.selected_ability = null
			else:
				Globals.selected_ability = ability
				if ability != null:
					Map.PLAYER.verify_church_exhausted()
					Map.PLAYER.verify_sun_exhausted()
			Map.PLAYER.update_oracle()
			
func _disable() -> void:
	self_modulate.a = 0.5

func _enable() -> void:
	self_modulate.a = 1
