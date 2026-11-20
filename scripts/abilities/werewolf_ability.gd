extends MoveAbility
class_name WerewolfAbility
## Leap onto a house or civilian in range (or an enemy, with Demon Wolf).

func can_target(board: Board, tile: Vector2i) -> bool:
	if Grid.distance(board.player.tile, tile) > PlayerRewards.get_werewolf_range() \
	or board.is_under_fog(tile):
		return false
	for unit: Unit in board.units_at(tile):
		if unit.kind == Unit.Kind.BUILDING and unit.shelters_civilian:
			return true
		if unit.kind == Unit.Kind.CIVILIAN:
			return true
		if unit.kind == Unit.Kind.ENEMY and PlayerRewards.stacks(&"demon_wolf") > 0:
			return true
	return false

func simulate(board: Board, tile: Vector2i, log: Array) -> void:
	var player: Unit = board.player
	player.direction = Grid.vector_to_cardinal(tile - player.tile)
	log.append({"type": "werewolf_strike", "tile": tile})
	for building: Unit in board.find_at(tile, Unit.Kind.BUILDING):
		if building.shelters_civilian:
			# The house is torn open: its civilian is drained on the spot.
			var civilian := Unit.new()
			civilian.kind = Unit.Kind.CIVILIAN
			civilian.tile = tile
			civilian.scene = load(Rules.CIVILIAN_PATH)
			board.add_unit(civilian)
			log.append({"type": "spawned", "id": civilian.id, "kind": civilian.kind, "tile": tile, "scene": civilian.scene})
			Rules._remove(board, building, log)
			var ruins := Unit.new()
			ruins.kind = Unit.Kind.PROP
			ruins.tile = tile
			ruins.destructible = false
			ruins.scene = building.ruins_scene if building.ruins_scene else load(Rules.DEFAULT_RUINS_PATH)
			board.add_unit(ruins)
			log.append({"type": "spawned", "id": ruins.id, "kind": ruins.kind, "tile": tile, "scene": ruins.scene})
			Rules.harvest_at(board, tile, log)
	for enemy: Unit in board.find_at(tile, Unit.Kind.ENEMY):
		Rules.destroy_unit(board, enemy, log, false, false)
	Rules.move_player(board, tile, "werewolf", log)
	Rules.move_end(board, log, true)
