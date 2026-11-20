extends Node
class_name Atmosphere
## Art-direction prototype: "cold moonlight, warm danger".
## The world is tinted in night blues; everything that can hurt the vampire
## (torches, fire, holy light) emits warm light. Purely visual: remove this
## node (or run with -- --no-atmosphere) to get the original look.

const NIGHT_TINT := Color(0.2, 0.25, 0.46)
const TORCH := Color(1.0, 0.62, 0.28)
const HOLY := Color(1.0, 0.92, 0.6)
const POISON := Color(0.45, 1.0, 0.45)
const SHADOW := Color(0.7, 0.35, 1.0)
const MOON := Color(0.6, 0.8, 1.0)

var _light_texture: Texture2D

static func is_enabled() -> bool:
	return !OS.get_cmdline_user_args().has("--no-atmosphere")

func _ready() -> void:
	_light_texture = _make_light_texture()
	var night := CanvasModulate.new()
	night.color = NIGHT_TINT
	get_parent().add_child.call_deferred(night)
	get_tree().node_added.connect(_on_node_added)
	Map.atmosphere = self
	# Fog of war is never lit (thousands of nodes: lighting them is expensive).
	for fog: CanvasItem in Map.DEEP_FOG.get_children():
		fog.light_mask = 0
		for child in fog.get_children():
			if child is CanvasItem:
				child.light_mask = 0
	Map.PLAYER.LIGHT_FOG.light_mask = 0
	# Lights for things already in the scene.
	await get_tree().process_frame
	_add_light(Map.PLAYER, MOON, 0.45, 0.9, Vector2(0, -18))
	Map.PLAYER.ORACLE.modulate = unlit_gain()
	Map.PLAYER.ORACLE.light_mask = 0
	for icon in Map.PLAYER.ORACLE.get_children():
		_set_unlit_recursive(icon)
	var selection: CanvasItem = get_parent().get_node_or_null("Entities/TileSelection")
	if selection:
		selection.modulate = unlit_gain()
		selection.light_mask = 0
	for enemy in Map.ENNEMIES.get_children():
		_set_unlit_recursive(enemy.get_node("Plan"))
	var castle: Node = get_parent().get_node_or_null("Entities/CastlePlaceholder")
	if castle:
		var light := _add_light(castle, TORCH, 0.9, 2.6, Vector2(70, 150))
		_flicker(light, 0.9)
	for enemy in Map.ENNEMIES.get_children():
		_on_node_added(enemy)

## Gain that cancels the night tint: telegraphs and attack effects keep
## full brightness so the danger always reads (and "danger glows").
func unlit_gain() -> Color:
	return Color(1.0 / NIGHT_TINT.r, 1.0 / NIGHT_TINT.g, 1.0 / NIGHT_TINT.b)

## Telegraphs (oracle, enemy plans, hover) and attack visuals are "unlit":
## no torchlight on them, and the night tint is cancelled, so they keep
## their exact UI colours.
func _is_overlay(node: Node) -> bool:
	if Map.PLAYER and Map.PLAYER.ORACLE.is_ancestor_of(node):
		return true
	var parent: Node = node.get_parent()
	while parent:
		if parent.name == "Plan" and parent.get_parent() is Ennemy:
			return true
		parent = parent.get_parent()
	return false

func _on_node_added(node: Node) -> void:
	if node is CanvasItem and _is_overlay(node):
		node.light_mask = 0
	# Attack visuals and markers spawned on the tile map.
	if node is CanvasItem and node.get_parent() == Map.TILEMAP and !(node is PointLight2D):
		node.light_mask = 0
		node.self_modulate = node.self_modulate * unlit_gain()
	if node is Ennemy:
		node.get_node("Plan").modulate = unlit_gain()
	if node is Ennemy and !(node is LandMines) and !node.has_node("Torch"):
		var torch := _add_light(node, TORCH, 0.85, 1.25, Vector2(6, -22))
		torch.name = "Torch"
		_flicker(torch, 0.85)

## Short light burst for an attack visual.
func flash(tile: Vector2i, type: Enums.destruction_type) -> void:
	var color: Color = TORCH
	var energy: float = 1.2
	match type:
		Enums.destruction_type.LIGHT:
			color = HOLY
			energy = 1.4
		Enums.destruction_type.POISON:
			color = POISON
			energy = 0.9
		Enums.destruction_type.SHADOW:
			color = SHADOW
			energy = 0.8
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.color = color
	light.energy = energy
	light.texture_scale = 1.1
	Map.TILEMAP.add_child(light)
	light.global_position = Map.get_global_position(tile)
	var tween := light.create_tween()
	tween.tween_property(light, "energy", 0.0, Globals.get_anim_duration() * 1.5)
	tween.tween_callback(light.queue_free)

func _set_unlit_recursive(node: Node) -> void:
	if node is CanvasItem:
		node.light_mask = 0
	for child in node.get_children():
		_set_unlit_recursive(child)

func _add_light(parent: Node, color: Color, energy: float, scale: float, offset: Vector2) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.color = color
	light.energy = energy
	light.texture_scale = scale
	light.position = offset
	parent.add_child(light)
	return light

func _flicker(light: PointLight2D, base: float) -> void:
	var tween := light.create_tween().set_loops()
	tween.tween_property(light, "energy", base * 0.82, randf_range(0.18, 0.32))
	tween.tween_property(light, "energy", base, randf_range(0.18, 0.32))

func _make_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.45, Color(1, 1, 1, 0.45))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture
