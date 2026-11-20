extends MobileObject
class_name Ennemy
## View of an enemy: shows its telegraphed plan and plays its animations.
## Its rules live in an EnemyBehaviour (scripts/sim/behaviours).

var explosion_tween: Tween

@onready var PLAN: Control = $Plan
@onready var ORDER: Label = $Sprite/Order

## Shows the plan described by a "planned" event (see Rules.plan_enemy).
func show_plan(plan: Dictionary) -> void:
	clear_plan()
	direction = plan.direction
	match plan.action:
		Enums.plan.EXPLODE:
			var explode_icon := TextureRect.new()
			explode_icon.texture = preload("res://assets/ennemies/exclamation_red.png")
			PLAN.add_child(explode_icon)
			explode_icon.scale = Vector2.ONE * 2
			explode_icon.position = -explode_icon.size + Vector2(0, -8)
			explosion_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_loops()
			explosion_tween.tween_property(explode_icon, "modulate:a", 0.2, 0.5)
			explosion_tween.tween_property(explode_icon, "modulate:a", 1, 0.5)
		Enums.plan.SHOOT:
			_display_shoot_plan(plan)
		Enums.plan.RELOAD:
			var reload_icon := TextureRect.new()
			if plan.reload_counter == 1:
				reload_icon.texture = preload("res://assets/ennemies/reload1.png")
			else:
				reload_icon.texture = preload("res://assets/ennemies/reload2.png")
			PLAN.add_child(reload_icon)
			reload_icon.position = -reload_icon.size * .5

func _display_shoot_plan(_plan: Dictionary) -> void:
	pass

func clear_plan() -> void:
	if explosion_tween and explosion_tween.is_running():
		explosion_tween.kill()
	for child in PLAN.get_children():
		child.queue_free()

func play_confusion() -> void:
	clear_plan()
	var surprise_icon := TextureRect.new()
	surprise_icon.texture = preload("res://assets/ennemies/exclamation.png")
	PLAN.add_child(surprise_icon)
	surprise_icon.scale = Vector2.ONE * 2
	surprise_icon.position = -surprise_icon.size
	var surprise_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	surprise_tween.tween_property(surprise_icon, "position:y",
		surprise_icon.position.y - 20, Globals.get_anim_duration())
	surprise_tween.tween_property(surprise_icon, "modulate:a", 0, Globals.get_anim_duration())
	await surprise_tween.finished
	if is_instance_valid(surprise_icon):
		surprise_icon.queue_free()

func show_order(i: int) -> void:
	ORDER.text = str(i)
	ORDER.visible = true

func hide_order() -> void:
	ORDER.visible = false
