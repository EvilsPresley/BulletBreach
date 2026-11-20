extends Control
class_name MoveButtons

func _ready() -> void:
	Events.player_move_started.connect(func(_mode, is_flying): apply_move(is_flying))
	Events.cooldowns_reduced.connect(haste)

func apply_move(is_flying: bool) -> void:
	for child: Node in get_children():
		for button: MoveButton in child.get_children():
			if button.move_mode == Globals.move_mode:
				button.set_max_reload()
			else:
				if !is_flying:
					button.reload_one()
	Globals.move_mode = Enums.move_mode.WALK

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
	match skill.title:
		"Teleportation":
			move_button.move_mode = Enums.move_mode.TELEPORT
			move_button.reload_time = Globals.teleport_cooldown
		"Bat Form":
			move_button.move_mode = Enums.move_mode.FLY
			move_button.reload_time = Globals.bat_cooldown
		"Werewolf Assault":
			move_button.move_mode = Enums.move_mode.WEREWOLF
			move_button.reload_time = Globals.werewolf_cooldown
		"Time Travel":
			move_button.move_mode = Enums.move_mode.TIME_TRAVEL
			move_button.reload_time = Globals.time_travel_cooldown
		"Stallion Dash":
			move_button.move_mode = Enums.move_mode.DASH
			move_button.reload_time = Globals.dash_cooldown
		_:
			push_error("Unsupported skill title: %s" % skill.title)
	move_button.texture = skill.texture
	move_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.add_child(move_button)
	move_button.position = Vector2(78, 2)
