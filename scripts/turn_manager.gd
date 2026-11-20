extends Node
class_name TurnManager
## Turn controller: resolves each player turn instantly on the Board (Rules),
## then has the Presenter play it. Keeps a snapshot for "undo last move".

## Which enemies spawn, in which order. Edit the .tres to rebalance.
@export var spawn_table: SpawnTable = preload("res://data/spawn/default_spawn_table.tres")

var presenter: Presenter
var _undo: Dictionary = {}

signal turn_completed
signal first_spawn(tuto: Enums.tuto)

func _ready() -> void:
	presenter = Presenter.new()
	presenter.name = "Presenter"
	add_child(presenter)
	presenter.first_spawn.connect(func(tuto): first_spawn.emit(tuto))

func is_busy() -> bool:
	return presenter.busy

## Builds the Board from the nodes placed in the main scene.
func build_board() -> Board:
	var board := Board.new()
	board.rng.seed = RunState.run_seed
	for cell: Vector2i in Map.TILEMAP.get_used_cells():
		if Map.TILEMAP.get_cell_source_id(cell) == 0:
			board.walkable[cell] = true
	for cross: MapObject in Map.CROSSES.get_children():
		board.crosses[cross.get_map_position()] = true
	for node: MapObject in Map.PROPS.get_children():
		var unit := _unit_from(node, Unit.Kind.PROP)
		unit.is_coffin = node.is_coffin
		unit.is_portal = node.is_portal
	for node: Building in Map.BUILDINGS.get_children():
		var unit := _unit_from(node, Unit.Kind.BUILDING)
		unit.ruins_scene = node.destroyed_scene
		unit.shelters_civilian = node is CivilianBuilding
	for node: MapObject in Map.CIVILIANS.get_children():
		_unit_from(node, Unit.Kind.CIVILIAN)
	for node: MapObject in Map.ENNEMIES.get_children():
		push_warning("Enemies placed in the scene are ignored: %s" % node.name)
	board.player = _unit_from(Map.PLAYER, Unit.Kind.PLAYER)
	for unit: Unit in _pending_units:
		board.add_unit(unit)
		presenter.register(unit.id, _pending_nodes[unit])
	_pending_units.clear()
	_pending_nodes.clear()
	return board

var _pending_units: Array[Unit] = []
var _pending_nodes: Dictionary = {}

func _unit_from(node: MapObject, kind: Unit.Kind) -> Unit:
	var unit := Unit.new()
	unit.kind = kind
	unit.tile = node.get_map_position()
	unit.destructible = node.destructible
	if node.scene_file_path != "":
		unit.scene = load(node.scene_file_path)
	_pending_units.append(unit)
	_pending_nodes[unit] = node
	return unit

## Resolves and presents one player turn. Returns false if the move is illegal.
func play_player_turn(ability: MoveAbility, tile: Vector2i) -> bool:
	var board: Board = Map.board
	if presenter.busy or !ability.can_target(board, tile):
		return false
	_undo = {
		"board": board.clone(),
		"run": RunState.snapshot(),
	}
	var events: Array = Rules.play_turn(board, ability, tile,
		RunState.turn + 1, RunState.night, spawn_table)
	await presenter.play(events)
	turn_completed.emit()
	return true

## Undo is possible if the last turn did not end the run or level up the player.
func can_undo() -> bool:
	return !_undo.is_empty() and !presenter.busy \
	and RunState.level == _undo.run.level and RunState.lives > 0

func undo_last_turn() -> bool:
	if !can_undo():
		return false
	Map.board = _undo.board
	RunState.restore(_undo.run)
	_undo = {}
	presenter.sync_all(Map.board)
	turn_completed.emit()
	return true

## Rest in a coffin: new night, enemies replaced by a bigger wave.
func start_new_night() -> void:
	var board: Board = Map.board
	var events: Array = []
	for enemy: Unit in board.enemies():
		board.remove_unit(enemy)
		events.append({"type": "destroyed", "id": enemy.id})
	board.poison_tiles.clear()
	RunState.night += 1
	RunState.turn = 1
	Rules.spawn_wave(board, RunState.night * 3, spawn_table, events)
	for prop: Unit in board.find_at(board.player.tile, Unit.Kind.PROP):
		if prop.is_coffin:
			Rules._remove(board, prop, events)
	_undo = {}
	Map.clear_poison_markers()
	await presenter.play(events)
