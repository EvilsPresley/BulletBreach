extends Node
class_name TurnManager

@onready var MODALS: Control = owner.get_node("Ui/Modal")

const TANK = preload("res://scenes/ennemies/tank.tscn")
const ARTILLERY = preload("res://scenes/ennemies/artillery.tscn")
const KAMIKAZE = preload("res://scenes/ennemies/kamikaze.tscn")
const MINES_LAYER = preload("res://scenes/ennemies/mine_layer.tscn")

const TANK_INDEX: int = 0
const ARTILLERY_INDEX: int = 1
const KAMIKAZE_INDEX: int = 2
const MINES_LAYER_INDEX: int = 3
var _introduced_tutos: Dictionary = {}

signal turn_completed
signal first_spawn

func get_spawn_ennemy() -> PackedScene:
	var ennemies: Array[int] = [0, 0, 0, 0]
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy is Tank:
			ennemies[TANK_INDEX] += 1
		elif ennemy is Artillery:
			ennemies[ARTILLERY_INDEX] += 1
		elif ennemy is Kamikaze:
			ennemies[KAMIKAZE_INDEX] += 1
		elif ennemy is MineLayer:
			ennemies[MINES_LAYER_INDEX] += 1
	
	if ennemies[TANK_INDEX] < 2:
		return TANK
	if ennemies[ARTILLERY_INDEX] < 1:
		return ARTILLERY
	if ennemies[TANK_INDEX] < 3:
		return TANK
	if ennemies[KAMIKAZE_INDEX] < 1:
		return KAMIKAZE
	if ennemies[TANK_INDEX] < 4:
		return TANK
	if ennemies[ARTILLERY_INDEX] < 2:
		return ARTILLERY
	if ennemies[KAMIKAZE_INDEX] < 2:
		return KAMIKAZE
	if ennemies[MINES_LAYER_INDEX] < 1:
		return MINES_LAYER
	return TANK

func take_turn() -> void:
	Globals.calculating_turn = true
	Globals.set_anim_duration(Map.ENNEMIES.get_child_count())
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if !ennemy.is_queued_for_destroy():
			if ennemy:
				if ennemy.visible:
					ennemy.enable_highlight()
					await ennemy.execute()
					await Globals.wait_one_frame()
			if ennemy:
				ennemy.enable_highlight()
				await ennemy.move()
				ennemy.disable_highlight()
			if ennemy:
				if ennemy.visible:
					ennemy.enable_highlight()
					ennemy.plan()
					ennemy.display_plan()
					if ennemy:
						ennemy.disable_highlight()
				else:
					ennemy.planned_action = Enums.plan.STAND
			await Globals.wait_one_frame()
	await Map.apply_poison()
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		ennemy.apply_destroy()
	Globals.set_anim_duration(1)
	Globals.calculating_turn = false

func _on_player_turn_complete() -> void:
	if MODALS.get_child_count() > 0:
		await MODALS.get_child(0).tree_exited
		await Globals.wait(Globals.anim_duration * .25)
	await Globals.wait_one_frame()
	await take_turn()
	if Globals.night >= 2 or Globals.turn >= 20:
		await spawn(Globals.night)
	elif Globals.turn % 2 == 0 and Globals.turn > 2:
		await spawn(1)
	turn_completed.emit()

func spawn(number_of_spawns: int = 1) -> void:
	var spawn_positions: Array[Vector2i] = []
	
	var cur_pos: Vector2i = Map.PLAYER.get_map_position()
	for x: int in range(cur_pos.x - Globals.sight, cur_pos.x + Globals.sight + 1):
		for y: int in range(cur_pos.y - Globals.sight, cur_pos.y + Globals.sight + 1):
			var tile := Vector2i(x, y)
			var distance: float = tile.distance_to(cur_pos)
			if distance >= Globals.sight and distance < Globals.sight + 1 \
			and Map.can_ennemy_move(tile) \
			and tile.distance_to(Map.PLAYER.previous_positions[0]) >= Globals.sight:
				spawn_positions.append(tile)
	spawn_positions.shuffle()
	
	for spawn_position: Vector2i in spawn_positions.slice(0, number_of_spawns):
		var spawning_ennemy: Ennemy = get_spawn_ennemy().instantiate()
		spawning_ennemy.set_map_position(spawn_position)
		Map.ENNEMIES.add_child(spawning_ennemy)
		spawning_ennemy.enable_highlight()
		await spawning_ennemy.move()
		spawning_ennemy.plan()
		spawning_ennemy.display_plan()
		spawning_ennemy.disable_highlight()
		Events.enemy_spawned.emit(spawning_ennemy)
		var tuto: Enums.tuto = spawning_ennemy.intro_tuto
		if tuto != Enums.tuto.NONE and !_introduced_tutos.has(tuto):
			_introduced_tutos[tuto] = true
			first_spawn.emit(tuto)
