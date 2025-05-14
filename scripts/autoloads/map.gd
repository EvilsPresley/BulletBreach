extends Node

const N: Vector2i = Vector2i(-1, -1)
const NE: Vector2i = Vector2i(0, -1)
const E: Vector2i = Vector2i(1, -1)
const SE: Vector2i = Vector2i(1, 0)
const S: Vector2i = Vector2i(1, 1)
const SW: Vector2i = Vector2i(0, 1)
const W: Vector2i = Vector2i(-1, 1)
const NW: Vector2i = Vector2i(-1, 0)
const cardinals: Array[Vector2i] = [N, NE, E, SE, S, SW, W, NW]
const orthogonals: Array[Vector2i] = [NE, SE, SW, NW]

const dimensions: Vector2i = Vector2i(16, 16)

@onready var TILEMAP: TileMapLayer = null
@onready var BUILDINGS: Node = null
@onready var ENNEMIES: Node = null
@onready var CIVILIANS: Node = null
@onready var PLAYER: Player = null

func get_map_position(global_pos: Vector2) -> Vector2i:
	return TILEMAP.local_to_map(global_pos)

func get_global_position(map_position: Vector2i) -> Vector2:
	return TILEMAP.map_to_local(map_position) + TILEMAP.global_position

func get_global_mid_position(map_position1: Vector2i, map_position2: Vector2i) -> Vector2:
	return (TILEMAP.map_to_local(map_position1) + TILEMAP.map_to_local(map_position2)) * 0.5 \
	+ TILEMAP.global_position

func vector_to_cardinal(vector: Vector2) -> Vector2i:
	var result: Vector2i = Vector2.ZERO
	if abs(vector.x) > abs(vector.y) * .5:
		if vector.x > 0:
			result.x = 1
		elif vector.x < 0:
			result.x = -1
	if abs(vector.y) > abs(vector.x) * .5:
		if vector.y > 0:
			result.y = 1
		elif vector.y < 0:
			result.y = -1
	return result

func can_ennemy_move(tile: Vector2i) -> bool:
	return can_move(tile, [BUILDINGS, ENNEMIES, PLAYER, CIVILIANS])

func can_move(tile: Vector2i, obstacles: Array[Node] = [BUILDINGS, ENNEMIES, PLAYER]) -> bool:
	if TILEMAP.get_cell_source_id(tile) < 0:
		return false
	if obstacles.find(BUILDINGS) >= 0:
		for building: Building in Map.BUILDINGS.get_children():
			if building.get_map_position() == tile:
				return false
	if obstacles.find(PLAYER) >= 0:
		if PLAYER.get_map_position() == tile:
			return false
	if obstacles.find(ENNEMIES) >= 0:
		for ennemy: Ennemy in Map.ENNEMIES.get_children():
			if ennemy.get_map_position() == tile and !ennemy is LandMines:
				return false
	if obstacles.find(CIVILIANS) >= 0:
		for civilians: Civilians in Map.CIVILIANS.get_children():
			if civilians.get_map_position() == tile:
				return false
	return true

func get_similar_directions(dir: Vector2i) -> Array[Vector2i]:
	var similar_directions: Array[Vector2i] = [dir]
	var clockwise: bool = randi() % 2 == 0
	if clockwise:
		similar_directions.append(cardinals[(cardinals.find(dir) + 1) % cardinals.size()])
		similar_directions.append(cardinals[(cardinals.find(dir) - 1) % cardinals.size()])
	else:
		similar_directions.append(cardinals[(cardinals.find(dir) - 1) % cardinals.size()])
		similar_directions.append(cardinals[(cardinals.find(dir) + 1) % cardinals.size()])
	return similar_directions

func destroy_tile(tile: Vector2i, fast: bool = false, artillery: bool = false) -> bool:
	if Map.TILEMAP.get_cell_source_id(tile) >= 0:
		var something_was_destroyed: bool = false
		var fire_icon := TextureRect.new()
		fire_icon.texture = preload("res://assets/fire.png")
		TILEMAP.add_child(fire_icon)
		fire_icon.global_position = get_global_position(tile)
		fire_icon.global_position -= fire_icon.size * .5
		if fast:
			await Globals.wait_one_frame()
		else:
			await Globals.wait(0.15)
		fire_icon.queue_free()
		for building: Building in BUILDINGS.get_children():
			if building.get_map_position() == tile \
			and building.destroyed_scene != null:
				await building.destroy()
				something_was_destroyed = true
		for ennemy: Ennemy in ENNEMIES.get_children():
			if ennemy.get_map_position() == tile:
				ennemy.destroy()
				something_was_destroyed = true
		if PLAYER.get_map_position() == tile:
			if PLAYER.jump == 0 or artillery:
				PLAYER.get_hit()
				something_was_destroyed = true
		for civilian: Civilians in CIVILIANS.get_children():
			if civilian.get_map_position() == tile:
				civilian.destroy()
				something_was_destroyed = true
		return something_was_destroyed
	else:
		return true

func kill_civilians(tile: Vector2i) -> void:
	for civilian: Civilians in CIVILIANS.get_children():
		if civilian.get_map_position() == tile:
			civilian.destroy()

func is_tile_safe(from: Vector2i, tile: Vector2i) -> bool:
	for ennemy: Ennemy in Map.ENNEMIES.get_children():
		if ennemy is Artillery and ennemy.planned_action == Enums.plan.SHOOT:
			if ennemy._get_artillery_targets().find(tile) > -1:
				return false
		if ennemy is Kamikaze and ennemy.planned_action == Enums.plan.EXPLODE:
			for cardinal: Vector2i in Map.cardinals:
				if ennemy.get_map_position() + cardinal == tile:
					return false
		if ennemy is Tank and ennemy.planned_action == Enums.plan.SHOOT:
			if ennemy._can_shoot(ennemy.get_map_position(), tile) \
			and ennemy.direction == Map.vector_to_cardinal(tile - ennemy.get_map_position()):
				return false
		if ennemy is LandMines and ennemy.get_map_position() == tile \
		and get_distance(from, tile) <= 1:
			return false
	return true

func get_opposite_vector(vector: Vector2i) -> Vector2i:
	return Vector2i(-vector.x, -vector.y)

func get_distance(from: Vector2i, to: Vector2i) -> int:
	var pos_dif: Vector2i = from - to
	return max(abs(pos_dif.x), abs(pos_dif.y))
