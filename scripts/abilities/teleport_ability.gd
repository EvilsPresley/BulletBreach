extends MoveAbility
class_name TeleportAbility
## Jump to a free tile in range. With Portal, leaves two linked portals.

func can_target(board: Board, tile: Vector2i) -> bool:
	var distance: int = Grid.distance(board.player.tile, tile)
	return board.can_move(tile) and distance > 0 and distance <= PlayerRewards.get_teleport_range()

func simulate(board: Board, tile: Vector2i, log: Array) -> void:
	var from: Vector2i = board.player.tile
	if PlayerRewards.stacks(&"portal") > 0:
		for portal: Unit in board.units.filter(func(u: Unit) -> bool: return u.is_portal):
			Rules._remove(board, portal, log)
		for portal_tile: Vector2i in [from, tile]:
			var portal := Unit.new()
			portal.kind = Unit.Kind.PROP
			portal.tile = portal_tile
			portal.destructible = false
			portal.is_portal = true
			portal.scene = load(Rules.PORTAL_PATH)
			board.add_unit(portal)
			log.append({"type": "spawned", "id": portal.id, "kind": portal.kind, "tile": portal_tile, "scene": portal.scene})
	Rules.move_player(board, tile, "teleport", log)
	Rules.move_end(board, log, true)
