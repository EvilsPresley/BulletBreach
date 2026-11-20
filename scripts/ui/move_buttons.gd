extends Control
class_name MoveButtons

func _ready() -> void:
	Events.player_move_started.connect(func(_mode, is_flying): apply_move(is_flying))
	Events.cooldowns_reduced.connect(haste)

func apply_move(is_flying: bool) -> void:
	for child: Node in get_children():
		for button: MoveButton in child.get_children():
			if button.ability == Globals.selected_ability:
				button.set_max_reload()
			else:
				if !is_flying:
					button.reload_one()
	Globals.selected_ability = null

func haste(number_of_turns: int) -> void:
	for i in number_of_turns:
		for child: Node in get_children():
			for button: MoveButton in child.get_children():
				button.reload_one()
	
func add_move(skill: Reward) -> void:
	var child_count: int = get_child_count()
	
	var frame: TextureRect = TextureRect.new()
	frame.texture = preload("res://assets/ui/skill_frame.png")
	add_child(frame)
	frame.position = Vector2(-14, 46 + 80 * child_count)
	
	var move_button: MoveButton = preload("res://scenes/ui/move_button.tscn").instantiate()
	move_button.ability = skill.ability
	move_button.reload_time = skill.ability.cooldown
	move_button.texture = skill.texture
	move_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.add_child(move_button)
	move_button.position = Vector2(78, 2)
