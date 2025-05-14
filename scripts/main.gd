extends Control
class_name Main

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var buildings: Node = $Entities/Buildings
@onready var ennemies: Node = $Entities/Ennemies
@onready var civilians: Node = $Entities/Civilians
@onready var player: Player = $Entities/Player
@onready var map_generator: MapGenerator = $Managers/MapGenerator
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	Globals.turn = 0
	Globals.lives = 3
	
	if not tile_map_layer.is_node_ready():
		await tile_map_layer.ready
	Map.TILEMAP = tile_map_layer
	
	if not buildings.is_node_ready():
		await buildings.ready
	Map.BUILDINGS = buildings
	
	if not ennemies.is_node_ready():
		await ennemies.ready
	Map.ENNEMIES = ennemies
	
	if not civilians.is_node_ready():
		await civilians.ready
	Map.CIVILIANS = civilians
	
	if not player.is_node_ready():
		await player.ready
	Map.PLAYER = player
	
	map_generator.generate_map()
	
	var tuto: Dialog = preload("res://scenes/welcome_dialog.tscn").instantiate()
	canvas_layer.add_child(tuto)
	tuto.connect("tree_exiting", show_tuto2)

func _process(_delta: float) -> void:
	if Globals.lives <= 0 or Globals.alive_civilians < Globals.total_civilians * .5:
		show_defeat()
		set_process(false)
	if Globals.rescued_civilians >= Globals.alive_civilians:
		show_victory()
		set_process(false)

func _enable_play() -> void:
	Map.PLAYER.can_act = true

func show_tuto2() -> void:
	await Globals.wait_one_frame()
	var tuto2: Dialog = preload("res://scenes/welcome_dialog_2.tscn").instantiate()
	canvas_layer.add_child(tuto2)
	tuto2.connect("tree_exiting", _enable_play)

func show_victory() -> void:
	var victory: Dialog = preload("res://scenes/victory_dialog.tscn").instantiate()
	canvas_layer.add_child(victory)
	victory.connect("tree_exiting", _reset)

func show_defeat() -> void:
	var defeat: Dialog = preload("res://scenes/defeat_dialog.tscn").instantiate()
	canvas_layer.add_child(defeat)
	defeat.connect("tree_exiting", _reset)

func _reset() -> void:
	await Globals.wait_one_frame()
	Globals.reset()
	get_tree().reload_current_scene()
