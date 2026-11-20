extends Control
class_name Main

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var buildings: Node = $Entities/Buildings
@onready var ennemies: Node = $Entities/Ennemies
@onready var civilians: Node = $Entities/Civilians
@onready var player: Player = $Entities/Player
@onready var deep_fog: Node = $Entities/DeepFog
@onready var props: Node = $Entities/Props
@onready var crosses: Node = $Entities/Crosses
@onready var TURN_MANAGER: TurnManager = $Managers/TurnManager

@onready var canvas_layer: CanvasLayer = $Ui
@onready var MOVE_BUTTONS: MoveButtons = $Ui/MoveButtons
@onready var XP_BAR: Control = $Ui/XpBar
@onready var LEVEL_LABEL: Label = $Ui/XpBar/ColorRect/ColorRect/Label
@onready var DAY_BAR: ProgressBar = $Ui/DayBar/ColorRect/ColorRect/ProgressBar
@onready var DAY_BAR_CONTAINER: Control = $Ui/DayBar
@onready var DAY_BAR_LABEL: Label = $Ui/DayBar/ColorRect/ColorRect/Label
@onready var GLOBAL_OVERLAY: ColorRect = $Ui/GlobalOverlay
@onready var _123: OrderHoverButton = $"Ui/123"

@onready var FOOTER: Control = $Ui/Footer
@onready var MODAL: Control = $Ui/Modal
@onready var REWARDS_UI: RewardsUi = $Ui/RewardsUi

var arrow_tuto: bool = true
var almost_day_tuto: bool = true
var church_intro_tuto : bool = true
var coffin_intro_tuto : bool = true

var free_hand_reward: bool = false
var game_over: bool = false

func _ready() -> void:
	_reset()

	DAY_BAR.value = 0
	DAY_BAR.max_value = Globals.turns_in_night
	PlayerRewards.initialise()
	
	if not tile_map_layer.is_node_ready():
		await tile_map_layer.ready
	Map.TILEMAP = tile_map_layer
	
	if not buildings.is_node_ready():
		await buildings.ready
	Map.BUILDINGS = buildings
	
	if not civilians.is_node_ready():
		await civilians.ready
	Map.CIVILIANS = civilians
	
	if not ennemies.is_node_ready():
		await ennemies.ready
	Map.ENNEMIES = ennemies
	
	if not props.is_node_ready():
		await props.ready
	Map.PROPS = props
	
	if not crosses.is_node_ready():
		await crosses.ready
	Map.CROSSES = crosses

	if not deep_fog.is_node_ready():
		await deep_fog.ready
	Map.DEEP_FOG = deep_fog

	if not player.is_node_ready():
		await player.ready
	Map.PLAYER = player
	
	player.died.connect(show_defeat)
	player.blood_harvested.connect(RunState.add_blood)
	Events.arrow_fired.connect(arrow_fired)
	Map.board = TURN_MANAGER.build_board()
	if Atmosphere.is_enabled():
		add_child(Atmosphere.new())
	TURN_MANAGER.turn_completed.connect(player.on_turn_completed)
	player.init_light_fog()
	player.enable_highlight()
	init_deep_fog()
	Map.update_fog()
	
	await player.intro()
	
	create_tuto(Enums.tuto.CASTLE_BURN)

func init_deep_fog() -> void:
	Map.DEEP_FOG.modulate = Colors.BLACK
	var map_rectangle: Rect2i = tile_map_layer.get_used_rect()
	for x: int in range(
		map_rectangle.position.x -Globals.map_sight.x,
		map_rectangle.end.x + Globals.map_sight.x,
	):
		for y: int in range(
			map_rectangle.position.y -Globals.map_sight.y,
			map_rectangle.end.y + Globals.map_sight.y,
		):
			var fog = preload("res://scenes/map/deep_fog.tscn").instantiate()
			Map.DEEP_FOG.add_child(fog)
			fog.set_map_position(Vector2i(x, y))

func create_choice_modal(title: String, choices: Array[Reward]) -> void:
	var modal: ChoiceModal = preload("res://scenes/ui/choice_modal.tscn").instantiate()
	for child in MODAL.get_children():
		child.queue_free()
	MODAL.add_child(modal)
	modal.setup(title, choices)
	modal.position = ($Ui/GlobalOverlay.size - modal.size) * .5
	modal.connect("reward_selected", create_reward_footer)
	modal.connect("reward_choosen", activate_reward)

func activate_reward(reward: Reward) -> void:
	await clear_footer()
	PlayerRewards.activate_reward(reward)
	REWARDS_UI.update()
	if reward.type == Enums.reward_type.SKILL:
		MOVE_BUTTONS.add_move(reward)
	if RunState.level == 2:
		create_tuto(Enums.tuto.MOVE_MODE)
	elif ((reward.tags.find(Enums.tag.BLOOD) >= 0 and PlayerRewards.stacks(&"hand_of_blood") > 0) \
	or (reward.tags.find(Enums.tag.POISON) >= 0 and PlayerRewards.stacks(&"hand_of_poison") > 0) \
	or (reward.tags.find(Enums.tag.SHADOW) >= 0 and PlayerRewards.stacks(&"hand_of_shadow") > 0)) \
	and !free_hand_reward:
		free_hand_reward = true
		create_choice_modal("Free reward!", PlayerRewards.get_level_up_rewards())
	else:
		free_hand_reward = false
		_enable_play()

func clear_footer() -> void:
	for child: Footer in FOOTER.get_children():
		await child.clear()

func clear_modals() -> void:
	for child in MODAL.get_children():
		await child.tree_exited

func _enable_play() -> void:
	Map.PLAYER.update_oracle()

func show_defeat() -> void:
	if game_over:
		return
	game_over = true
	clear_footer()
	for child in MODAL.get_children():
		child.queue_free()
	var banner: Banner = preload("res://scenes/ui/banner.tscn").instantiate()
	MODAL.add_child(banner)
	banner.position = Vector2(0, ($Ui/GlobalOverlay.size.y - banner.size.y) * .5)
	await banner.show_lose_banner()
	banner.connect("tree_exited", SceneLoader.load_scene.bind("menu"))

func _reset() -> void:
	arrow_tuto = true
	almost_day_tuto = true
	free_hand_reward = false
	game_over = false
	church_intro_tuto = true
	coffin_intro_tuto = true
	Globals.reset()
	RunState.reset()

func _on_ui_level_up() -> void:
	await clear_modals()
	LEVEL_LABEL.text = "LEVEL %s" % RunState.level
	if RunState.level == 2:
		var banner: Banner = await create_tuto(Enums.tuto.POWER_GROWS)
		banner.connect("tree_exited", create_choice_modal.bind("Level up!", PlayerRewards.get_level_up_rewards()))
	else:
		create_choice_modal("Level up!", PlayerRewards.get_level_up_rewards())

func _on_rewards_ui_reward_clicked(reward: Reward) -> void:
	if FOOTER.get_child_count() > 0:
		var displayed_footer: Footer = FOOTER.get_child(0)
		if displayed_footer.TITLE.text == reward.title:
			return
	create_reward_footer(reward, true)

func create_tuto(tuto_id: Enums.tuto) -> Banner:
	await clear_modals()
	var label: String
	var portrait: Texture2D = preload("res://assets/portraits/vampire_blood.png")
	var next_tuto: Enums.tuto = Enums.tuto.NONE
	match tuto_id:
		Enums.tuto.CASTLE_BURN:
			label = "My castle! It is burning!\nI can only flee now, before sunlight."
			next_tuto = Enums.tuto.WITCH_DIE
			portrait = preload("res://assets/portraits/vampire.png")
		Enums.tuto.WITCH_DIE:
			label = "Burn the demon, burn the witch!\nYour reign of terror ends tonight!"
			next_tuto = Enums.tuto.VENGEANCE
			portrait = preload("res://assets/portraits/peasant.png")
		Enums.tuto.VENGEANCE:
			portrait = preload("res://assets/portraits/vampire.png")
			label = "Poor simple man, he's no idea what he just did.\nMy vengeance will be terrible now."
		Enums.tuto.POWER_GROWS:
			label = "My power grows as I drink more blood. Let's make a rampage in town!\nThe more civilians I can feed to, the more powerful I will become.\nHowever, it looks like they are all hidding in their houses for now..."
			XP_BAR.visible = true
		Enums.tuto.MOVE_MODE:
			label = "I can now also use my new ability to move instead of walking if need be. But let's keep in mind that this ability can not be used every turn, so I should save it for when it becomes necessary."
			MOVE_BUTTONS.visible = true
			player.zoom_out()
		Enums.tuto.ARCHER_INTRO:
			label = "Damn you demon, I will hunt you down from afar, and people will sing my name for centuries to come."
			next_tuto = Enums.tuto.ORACLE_INTRO
			_123.visible = true
			portrait = preload("res://assets/portraits/archer.png")
		Enums.tuto.ORACLE_INTRO:
			label = "It looks like my first attack did not stay unnoticed. The king will likely send more and more troops to me, I need to be careful.\nFortunately, they are so predictable that I can anticipate their attacks and guess where to step safely."
		Enums.tuto.FRIENDLY_FIRE:
			if civilians.get_child_count() == 0:
				label = "Flaming arrows! They are quite serious!\nI wonder what will happen if they start hitting the villagers houses?"
			else:
				label = "Flaming arrows! They are quite serious!\nWith a little luck, I can even let them burn their own village to ashes."
		Enums.tuto.PRIEST_INTRO:
			label = "I will guide god's hand from the holy books. You will soon perish, evil vampire."
			next_tuto = Enums.tuto.PRIEST_SIGHT
			portrait = preload("res://assets/portraits/priest.png")
		Enums.tuto.PRIEST_SIGHT:
			label = "This guy will target me even without a line of sight."
		Enums.tuto.KAMIKAZE_INTRO:
			label = "My life is pointless.\nIn my sacrifice, I will find sense."
			portrait = preload("res://assets/portraits/kamikaze.png")
		Enums.tuto.TRACKER_INTRO:
			label = "My traps have caught bigger preys than you."
			portrait = preload("res://assets/portraits/tracker.png")
		Enums.tuto.DAY_NIGHT_CYCLE:
			label = "The night and day cycle can't be stopped. I need to find a coffin in the southern part of the city to hide and regenerate before dawn."
		Enums.tuto.ALMOST_DAY:
			label = "The sun is at the horizon, already weakening me.\nI really need to walk to a coffin in the south now.\nI feel my powers are already gone, and in %s turns the sun will kill me." % floori(Globals.turns_in_night * 0.1)
		Enums.tuto.CHURCH_INTRO:
			label = "I can see the village church.\nLet's not go too close to it, my powers are disabled there."
		Enums.tuto.CHURCH_EXHAUSTED:
			label = "I am too weak for that. I must move away from this church."
		Enums.tuto.SUN_EXHAUSTED:
			label = "I am too weak for that. I must rest in a coffin before the sun burns me."
		Enums.tuto.NEW_DAY:
			label = "I feel stronger than ever, but the villagers have found me.\nI will need to hide in another coffin before dawn."
		Enums.tuto.COFFIN_INTRO:
			label = "Here, I can see a coffin. I must reach it before the end of the night, but meanwhile I can gather as much blood as possible."
		_:
			push_error("Non managed tuto ID %s" %tuto_id)
	await clear_modals()
	var banner: Banner = preload("res://scenes/ui/banner.tscn").instantiate()
	MODAL.add_child(banner)
	banner.position = Vector2(0, ($Ui/GlobalOverlay.size.y - banner.size.y) * .5)
	await banner.setup(label, portrait)
	if next_tuto != Enums.tuto.NONE:
		banner.connect("tree_exited", create_tuto.bind(next_tuto))
	else:
		banner.connect("tree_exited", _enable_play)
	return banner

func create_reward_footer(reward: Reward, clickable: bool = false) -> void:
	await clear_footer()
	var footer: Footer = preload("res://scenes/ui/footer.tscn").instantiate()
	FOOTER.add_child(footer)
	footer.position = Vector2(0, ($Ui/GlobalOverlay.size.y - footer.size.y))
	await footer.setup(
		reward,
		clickable)

func _on_turn_manager_first_spawn(tuto: Enums.tuto) -> void:
	create_tuto(tuto)

func is_ui_blocking() -> bool:
	return MODAL.get_child_count() > 0

func arrow_fired() -> void:
	if arrow_tuto:
		arrow_tuto = false
		await Globals.wait_one_frame()
		create_tuto(Enums.tuto.FRIENDLY_FIRE)

func _on_player_turn_complete() -> void:
	RunState.turn += 1
	DAY_BAR.value = RunState.turn
	if RunState.turn == 2 and RunState.night == 1:
		create_tuto(Enums.tuto.DAY_NIGHT_CYCLE)
		DAY_BAR_CONTAINER.visible = true
	if RunState.turn >= Globals.turns_in_night:
		show_defeat()
	elif RunState.turn >= Globals.turns_in_night * .9:
		if almost_day_tuto:
			almost_day_tuto = false
			create_tuto(Enums.tuto.ALMOST_DAY)
		DAY_BAR.modulate = Colors.RED
	elif RunState.turn >= Globals.turns_in_night * .8:
		DAY_BAR.modulate = Colors.GOLD
	if church_intro_tuto:
		if player.get_map_position().x + player.get_map_position().y >= 6:
			church_intro_tuto = false
			create_tuto(Enums.tuto.CHURCH_INTRO)
	if coffin_intro_tuto:
		for prop: Prop in Map.PROPS.get_children():
			if prop.is_coffin:
				if !Map.is_under_fog(prop.get_map_position()):
					coffin_intro_tuto = false
					create_tuto(Enums.tuto.COFFIN_INTRO)

func _on_player_church_exhausted() -> void:
	create_tuto(Enums.tuto.CHURCH_EXHAUSTED)

func _on_player_sun_exhausted() -> void:
	create_tuto(Enums.tuto.SUN_EXHAUSTED)

func _on_player_enter_coffin() -> void:
	await clear_modals()
	var modal: YesNoModal = preload("res://scenes/ui/yes_no_modal.tscn").instantiate()
	MODAL.add_child(modal)
	modal.position = ($Ui/GlobalOverlay.size - modal.size) * .5
	modal.set_text("""
Rest in this coffin for the day?
You have %s turns remaining this night, before sunset.
""" % (Globals.turns_in_night - RunState.turn))
	modal.connect("yes_clicked", _rest_in_coffin)

func _rest_in_coffin() -> void:
	var tween = create_tween()
	tween.tween_property(GLOBAL_OVERLAY, "color", Colors.BLACK, Globals.get_anim_duration() * 3)
	Globals.calculating_turn = true
	await tween.finished
	await TURN_MANAGER.start_new_night()
	DAY_BAR.value = RunState.turn
	DAY_BAR_LABEL.text = "NIGHT " + str(RunState.night)
	tween = create_tween()
	tween.tween_property(GLOBAL_OVERLAY, "color", Color.TRANSPARENT, Globals.get_anim_duration() * 3)
	await tween.finished
	Globals.calculating_turn = false
	var banner: Banner = await create_tuto(Enums.tuto.NEW_DAY)
	banner.connect("tree_exited", create_choice_modal.bind("New active skill", PlayerRewards._get_level_up_skills()))

## Undo the last move (U key or Ctrl+Z).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo \
	and (event.keycode == KEY_U or (event.keycode == KEY_Z and event.ctrl_pressed)):
		if !is_ui_blocking() and TURN_MANAGER.undo_last_turn():
			DAY_BAR.value = RunState.turn
