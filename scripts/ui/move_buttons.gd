extends Control
class_name MoveButtons

func add_move(skill: Reward) -> void:
	var child_count: int = get_child_count()
	
	var frame: TextureRect = TextureRect.new()
	frame.texture = preload("res://assets/ui/skill_frame.png")
	add_child(frame)
	frame.position = Vector2(-14, 46 + 80 * child_count)
	
	var move_button: MoveButton = preload("res://scenes/ui/move_button.tscn").instantiate()
	move_button.ability = skill.ability
	RunState.register_ability(skill.ability)
	move_button.texture = skill.texture
	move_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.add_child(move_button)
	move_button.position = Vector2(78, 2)
