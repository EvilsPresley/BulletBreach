extends CanvasLayer

@onready var COLOR_RECT: ColorRect = $ColorRect
@onready var LOADING_CIRCLE: TextureRect = $LoadingCircle

const timeout_value: float = .5

var loading_completed: bool = false
var next_scene_path: String = ""

var circle_tween: Tween

func _ready() -> void:
	LOADING_CIRCLE.visible = false
	var rect_x: float = get_viewport().get_visible_rect().size.x
	for rect: ColorRect in [COLOR_RECT]:
		rect.modulate = Colors.BLACK
		rect.size = get_viewport().get_visible_rect().size
		rect.position = Vector2(-rect_x, 0)

func load_scene(target_scene: String) -> void:
	next_scene_path = ""
	await loader_in()
	load_async(target_scene)

func _process(_delta: float) -> void:
	if ResourceLoader.load_threaded_get_status(next_scene_path) \
			== ResourceLoader.THREAD_LOAD_LOADED and !loading_completed:
		loading_completed = true
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(next_scene_path))
		await loader_out()

func loader_in() -> void:
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(COLOR_RECT, "position:x", 0, timeout_value).set_ease(Tween.EASE_OUT)
	await tween.finished
	tween.kill()
	LOADING_CIRCLE.visible = true
	circle_tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT)
	circle_tween.tween_property(
		LOADING_CIRCLE,
		"rotation_degrees",
		360,
		.5
	)
	circle_tween.tween_property(
		LOADING_CIRCLE,
		"rotation_degrees",
		-360,
		.5
	)

func loader_out() -> void:
	circle_tween.kill()
	LOADING_CIRCLE.visible = false
	var tween := get_tree().create_tween()
	tween.tween_property(COLOR_RECT, "position:x", \
	get_viewport().get_visible_rect().size.x, timeout_value)
	await tween.finished
	tween.kill()

func load_async(target_scene: String) -> void:
	next_scene_path = "res://scenes/%s.tscn" % target_scene
	ResourceLoader.load_threaded_request(next_scene_path)
	loading_completed = false
