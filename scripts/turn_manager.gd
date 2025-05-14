extends Node
class_name TurnManager

const TANK = preload("res://scenes/tank.tscn")
const ARTILLERY = preload("res://scenes/artillery.tscn")
const KAMIKAZE = preload("res://scenes/kamikaze.tscn")
const MINES_LAYER = preload("res://scenes/mine_layer.tscn")

const TANK_INDEX: int = 0
const ARTILLERY_INDEX: int = 1
const KAMIKAZE_INDEX: int = 2
const MINES_LAYER_INDEX: int = 3

signal turn_completed

func spawn() -> void:
	var spawn_position: Vector2i = _get_free_spawn_point()
	if spawn_position == Vector2i.ZERO:
		return
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
	var next_ennemy: PackedScene = TANK
	var total_ennemies: int = ennemies[0] + ennemies[1] + ennemies[2] + ennemies[3]
	if ennemies[KAMIKAZE_INDEX] < total_ennemies * 0.2 and total_ennemies > 2:
		next_ennemy = KAMIKAZE
	elif ennemies[ARTILLERY_INDEX] < total_ennemies * 0.35 and total_ennemies > 1:
		next_ennemy = ARTILLERY
	elif ennemies[MINES_LAYER_INDEX] < 1 and total_ennemies > 3:
		next_ennemy = MINES_LAYER
	
	if Map.ENNEMIES.get_child_count() < Globals.turn * .5:
		var spawning_ennemy: Ennemy = next_ennemy.instantiate()
		spawning_ennemy.set_map_position(spawn_position)
		Map.ENNEMIES.add_child(spawning_ennemy)
		spawning_ennemy.direction = Map.N
		spawning_ennemy.plan()
		spawning_ennemy.display_plan()

func _get_free_spawn_point() -> Vector2i:
	var free_spawns: Array[Vector2i] = []
	for building: Building in Map.BUILDINGS.get_children():
		if building.skills.find(Enums.building_skill.SPAWNER) > -1 \
		and Map.can_move(building.get_map_position(), [Map.ENNEMIES, Map.PLAYER]):
			free_spawns.append(building.get_map_position())
	if free_spawns.size() == 0:
		return Vector2i.ZERO
	return free_spawns.pick_random()

func take_turn() -> void:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if !ennemy.is_detroyed():
			await ennemy.execute()
		if ennemy.is_detroyed():
			ennemy.queue_free()
		else:
			await ennemy.move()
			ennemy.plan()
			ennemy.display_plan()
	Globals.turn += 1

func _on_player_turn_complete() -> void:
	await Globals.wait_one_frame()
	await take_turn()
	spawn()
	turn_completed.emit()
