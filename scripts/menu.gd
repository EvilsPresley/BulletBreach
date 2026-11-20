extends Control
class_name Menu

@onready var ABOUT: Button = $AboutButton
## Clouds are rendered at 1/4 resolution in a SubViewport (see menu.tscn).
@onready var STORM: Control = $Storm

func _on_play_button_pressed() -> void:
	await SceneLoader.load_scene("main")

func _on_about_button_pressed() -> void:
	if ABOUT.get_child_count() <= 0:
		var banner: Banner = preload("res://scenes/ui/banner.tscn").instantiate()
		ABOUT.add_child(banner)
		banner.LABEL.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner.global_position = Vector2(0, (STORM.size.y - banner.size.y) * .5)
		await banner.setup(
			"An early prototype by Baptiste Villain, tribute to Into the Breach.\nMost assets by Oryx and CraftPix. Extra sprites inspired by Ruskom and Captainskolot. Font: enterCommand.",
			preload("res://assets/portraits/dragon.png")
			)
