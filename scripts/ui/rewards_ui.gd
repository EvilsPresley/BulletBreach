extends Control
class_name RewardsUi

const separation: int = 8

signal reward_clicked

func update() -> void:
	for child in get_children():
		child.queue_free()
	
	var upgrades: Array[Reward] = PlayerRewards.owned_rewards.filter(
		func(r: Reward) -> bool:
			return r.type == Enums.reward_type.UPGRADE
			).duplicate()
	upgrades.sort_custom(
		func(r1: Reward, r2: Reward) -> bool:
			return r1.title <= r2.title
			)
	
	for i: int in upgrades.size():
		var icon: IconButton = preload("res://scenes/ui/icon_button.tscn").instantiate()
		var reward: Reward = upgrades[i]
		add_child(icon)
		icon.scale = Vector2.ONE * .5
		icon.position = Vector2(
			-64 - (32 + separation) * floor(i * .2),
			(i % 5) * (32 + separation)
			)
		icon.setup(reward.texture, reward.rarity, reward.title, reward.description)
		icon.connect("pressed", _reward_ui_clicked.bind(reward))
	
func _reward_ui_clicked(reward: Reward) -> void:
	reward_clicked.emit(reward)
