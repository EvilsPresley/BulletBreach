extends TextureRect
class_name  MoveButton

@onready var RELOAD: TextureProgressBar = $Reload
@onready var HIGHLIGHT: TextureRect = $Highlight
@onready var SELECTION: TextureRect = $Selection

## Ability selected by this button (null = walk).
@export var ability: MoveAbility
func _ready() -> void:
	RELOAD.visible = ability != null and ability.cooldown > 0
	if RELOAD.visible:
		RELOAD.max_value = ability.cooldown
	RunState.cooldowns_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	SELECTION.visible = Globals.selected_ability == ability

func _refresh() -> void:
	var remaining: int = get_reload()
	RELOAD.value = remaining
	self_modulate.a = 0.5 if remaining > 0 else 1.0

## Remaining cooldown turns (0 = ready).
func get_reload() -> int:
	return RunState.get_cooldown(ability) if ability else 0

func _on_mouse_entered() -> void:
	HIGHLIGHT.visible = true

func _on_mouse_exited() -> void:
	HIGHLIGHT.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Globals.selected_ability == ability or !RunState.is_ready(ability):
				Globals.selected_ability = null
			else:
				Globals.selected_ability = ability
				if ability != null:
					Map.PLAYER.verify_church_exhausted()
					Map.PLAYER.verify_sun_exhausted()
			Map.PLAYER.update_oracle()
			
